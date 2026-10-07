/// MACD and how it reads against an Elliott Wave count.
library;

import 'dart:math' as math;

import 'candles.dart';
import 'elliott.dart';
import 'setup.dart';

/// Exponential moving average, seeded with the simple average of the first [n] values.
/// Entries before the first full window are null, so the result lines up with [xs].
List<double?> ema(List<double> xs, int n) {
  final out = List<double?>.filled(xs.length, null);
  if (xs.length < n) return out;
  var e = xs.take(n).reduce((a, b) => a + b) / n;
  out[n - 1] = e;
  final k = 2 / (n + 1);
  for (var i = n; i < xs.length; i++) {
    e = xs[i] * k + e * (1 - k);
    out[i] = e;
  }
  return out;
}

/// MACD (fast EMA − slow EMA), its signal line (EMA of MACD) and the histogram
/// (MACD − signal), each aligned with the candles; null where not yet defined.
class Macd {
  Macd._(this.line, this.signal, this.histogram);

  static const fast = 12, slow = 26, smooth = 9;

  final List<double?> line;
  final List<double?> signal;
  final List<double?> histogram;

  factory Macd.of(List<Candle> candles) {
    final closes = [for (final c in candles) c.close];
    final f = ema(closes, fast), s = ema(closes, slow);
    final line = [for (var i = 0; i < closes.length; i++) f[i] != null && s[i] != null ? f[i]! - s[i]! : null];
    // The signal is an EMA of the MACD values that exist.
    final firstLine = line.indexWhere((v) => v != null);
    final signal = List<double?>.filled(closes.length, null);
    if (firstLine >= 0) {
      final e = ema([for (final v in line.skip(firstLine)) v!], smooth);
      for (var i = 0; i < e.length; i++) {
        signal[firstLine + i] = e[i];
      }
    }
    final hist = [for (var i = 0; i < closes.length; i++) line[i] != null && signal[i] != null ? line[i]! - signal[i]! : null];
    return Macd._(line, signal, hist);
  }

  bool get ready => histogram.isNotEmpty && histogram.last != null;
}

enum MacdVerdict { agree, turning, against }

/// MACD's state at the latest candle.
class MacdState {
  MacdState({
    required this.line,
    required this.signal,
    required this.histogram,
    required this.rising,
    required this.crossAgo,
  });

  final double line;
  final double signal;
  final double histogram;

  /// Histogram growing more positive (or less negative) than the previous candle.
  final bool rising;

  /// Candles since MACD last crossed its signal line; null if not within the series.
  final int? crossAgo;

  bool get bullish => histogram > 0;

  static MacdState? of(Macd m) {
    if (!m.ready) return null;
    final h = m.histogram;
    final n = h.length;
    final prev = n > 1 ? h[n - 2] : null;
    int? crossAgo;
    for (var i = n - 1; i > 0; i--) {
      final a = h[i], b = h[i - 1];
      if (a == null || b == null) break;
      if ((a > 0) != (b > 0)) {
        crossAgo = n - 1 - i;
        break;
      }
    }
    return MacdState(
      line: m.line.last!,
      signal: m.signal.last!,
      histogram: h.last!,
      rising: prev == null ? false : h.last! > prev,
      crossAgo: crossAgo,
    );
  }

  /// Does momentum back a trade in [side]? Histogram on the trade's side agrees; on the
  /// wrong side but moving toward it is "turning"; otherwise against.
  MacdVerdict verdictFor(Side side) {
    final long = side == Side.long;
    if (long ? histogram > 0 : histogram < 0) return MacdVerdict.agree;
    if (long ? rising : !rising) return MacdVerdict.turning;
    return MacdVerdict.against;
  }
}

/// A MACD observation about a wave count: [good] true supports the count, false
/// argues against it, null is neutral.
class MacdNote {
  const MacdNote(this.text, {this.good});
  final String text;
  final bool? good;
}

/// Momentum of the move between two pivots: the MACD line's extreme in the move's
/// direction over those candles. Null if MACD isn't defined there yet.
double? legMomentum(Macd m, Pivot from, Pivot to) {
  final up = to.price > from.price;
  double? best;
  for (var i = math.max(from.index, 0); i <= to.index && i < m.line.length; i++) {
    final v = m.line[i];
    if (v == null) continue;
    best = best == null ? v : (up ? math.max(best, v) : math.min(best, v));
  }
  return best;
}

/// What MACD says about [s] on [candles]: whether wave 3 carries the most momentum,
/// whether a wave 5 (or wave C) shows the divergence that typically ends it.
List<MacdNote> macdNotes(Scenario s, Macd m, List<Candle> candles) {
  final p = s.points.map((w) => w.pivot).toList();
  double? leg(int i) => i + 1 < p.length ? legMomentum(m, p[i], p[i + 1]) : null;
  final notes = <MacdNote>[];

  // The wave in progress, from the last pivot to the latest candle.
  double? current() {
    final last = p.last;
    final now = Pivot(candles.length - 1, candles.last.close, high: !last.high);
    return legMomentum(m, last, now);
  }

  if (s.kind == ScenarioKind.impulse) {
    final legs = p.length - 1;
    final w1 = leg(0), w3 = leg(2);
    if (legs >= 3 && w1 != null && w3 != null) {
      final w5 = legs >= 5 ? leg(4) : null;
      final strongest = w3.abs() >= w1.abs() && (w5 == null || w3.abs() >= w5.abs());
      notes.add(strongest
          ? const MacdNote('MACD peaks in wave 3, as it should', good: true)
          : const MacdNote('Wave 3 isn\'t the momentum peak, which is unusual for a wave 3', good: false));
    }
    if (legs >= 5 && w3 != null) {
      final w5 = leg(4);
      final priceBeyond = s.trend > 0 ? p[5].price > p[3].price : p[5].price < p[3].price;
      if (w5 != null && priceBeyond && w5.abs() < w3.abs()) {
        notes.add(const MacdNote('Divergence: wave 5 made a new extreme on weaker MACD, typical of an ending impulse',
            good: true));
      } else if (w5 != null && priceBeyond) {
        notes.add(const MacdNote('No divergence at wave 5: momentum is as strong as wave 3, so the impulse may extend',
            good: false));
      }
    }
    if (legs == 4 && w3 != null) {
      // Wave 5 in progress: is it already beyond wave 3 on less momentum?
      final now = current();
      final beyond = s.trend > 0 ? candles.last.close > p[3].price : candles.last.close < p[3].price;
      if (now != null && beyond && now.abs() < w3.abs()) {
        notes.add(const MacdNote('Divergence building: price is past wave 3 on weaker MACD, so wave 5 may be ending'));
      }
    }
  } else {
    // Correction: wave C commonly ends on weaker momentum than wave A.
    final legs = p.length - 1;
    final a = leg(0);
    final c = legs >= 3 ? leg(2) : (legs == 2 ? current() : null);
    if (a != null && c != null) {
      // C's end (or, while C is still running, the current price) past A's end.
      final cEnd = legs >= 3 ? p[3].price : candles.last.close;
      final beyondA = s.trend > 0 ? cEnd > p[1].price : cEnd < p[1].price;
      if (beyondA && c.abs() < a.abs()) {
        notes.add(MacdNote('Wave C ${legs >= 3 ? 'ran' : 'is running'} on weaker MACD than wave A, typical as a correction ends',
            good: legs >= 3 ? true : null));
      } else if (beyondA) {
        notes.add(MacdNote('Wave C ${legs >= 3 ? 'ran' : 'is running'} on stronger MACD than wave A, so the correction '
            'may not be finished', good: false));
      }
    }
  }
  return notes;
}
