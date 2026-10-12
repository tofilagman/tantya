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

/// EMA of closing prices, aligned with [candles].
List<double?> emaOf(List<Candle> candles, int n) => ema([for (final c in candles) c.close], n);

/// RSI with Wilder's smoothing: the first average gain/loss is a simple mean over [n]
/// changes, then avg = (prev × (n−1) + current) / n. RSI = 100 − 100/(1 + gain/loss).
List<double?> rsi(List<Candle> candles, {int n = 14}) {
  final out = List<double?>.filled(candles.length, null);
  if (candles.length <= n) return out;
  var gain = 0.0, loss = 0.0;
  for (var i = 1; i <= n; i++) {
    final d = candles[i].close - candles[i - 1].close;
    d > 0 ? gain += d : loss -= d;
  }
  gain /= n;
  loss /= n;
  double value(double g, double l) => l == 0 ? (g == 0 ? 50 : 100) : 100 - 100 / (1 + g / l);
  out[n] = value(gain, loss);
  for (var i = n + 1; i < candles.length; i++) {
    final d = candles[i].close - candles[i - 1].close;
    gain = (gain * (n - 1) + math.max(d, 0)) / n;
    loss = (loss * (n - 1) + math.max(-d, 0)) / n;
    out[i] = value(gain, loss);
  }
  return out;
}

/// Average Directional Index (Wilder, n = 14): trend strength regardless of direction.
/// Below ~20 is a range, above ~25 a trend. Causal: the value at i uses candles ≤ i.
List<double?> adx(List<Candle> candles, {int n = 14}) {
  final out = List<double?>.filled(candles.length, null);
  if (candles.length < 2 * n + 1) return out;
  var tr = 0.0, plus = 0.0, minus = 0.0;
  double? adxV;
  final dxs = <double>[];
  for (var i = 1; i < candles.length; i++) {
    final c = candles[i], p = candles[i - 1];
    final t = math.max(c.high - c.low, math.max((c.high - p.close).abs(), (c.low - p.close).abs()));
    final up = c.high - p.high, down = p.low - c.low;
    final pdm = up > down && up > 0 ? up : 0.0;
    final mdm = down > up && down > 0 ? down : 0.0;
    if (i <= n) {
      tr += t;
      plus += pdm;
      minus += mdm;
      if (i < n) continue;
    } else {
      tr = tr - tr / n + t;
      plus = plus - plus / n + pdm;
      minus = minus - minus / n + mdm;
    }
    if (tr == 0) continue;
    final pdi = 100 * plus / tr, mdi = 100 * minus / tr;
    final dx = pdi + mdi == 0 ? 0.0 : 100 * (pdi - mdi).abs() / (pdi + mdi);
    if (adxV == null) {
      dxs.add(dx);
      if (dxs.length == n) {
        adxV = dxs.reduce((a, b) => a + b) / n;
        out[i] = adxV;
      }
    } else {
      adxV = (adxV * (n - 1) + dx) / n;
      out[i] = adxV;
    }
  }
  return out;
}

/// Commodity Channel Index: (typical price − its n-period average) / (0.015 × mean
/// deviation), typical price = (high + low + close) / 3. Around ±100 is a strong move.
List<double?> cci(List<Candle> candles, {int n = 20}) {
  final out = List<double?>.filled(candles.length, null);
  final tp = [for (final c in candles) (c.high + c.low + c.close) / 3];
  for (var i = n - 1; i < candles.length; i++) {
    final window = tp.sublist(i - n + 1, i + 1);
    final mean = window.reduce((a, b) => a + b) / n;
    final dev = window.fold(0.0, (t, v) => t + (v - mean).abs()) / n;
    out[i] = dev == 0 ? 0 : (tp[i] - mean) / (0.015 * dev);
  }
  return out;
}

/// Average volume per candle from [from] (exclusive) to [to] (inclusive): the candles
/// that make up the move between two pivots. Null if there's no volume data.
double? waveVolume(List<Candle> candles, int from, int to) {
  var sum = 0.0, n = 0;
  for (var i = math.max(from + 1, 0); i <= to && i < candles.length; i++) {
    sum += candles[i].volume;
    n++;
  }
  return n == 0 || sum == 0 ? null : sum / n;
}

/// EMA periods drawn on the chart, matching Binance's default set: a very fast 3 to
/// see candles flip, then 25 / 50 / 100 / 200.
const emaPeriods = [3, 25, 50, 100, 200];

/// Every indicator the evidence report uses, computed once per series.
class Indicators {
  Indicators.of(this.candles)
      : emas = {for (final n in emaPeriods) n: emaOf(candles, n)},
        macd = Macd.of(candles),
        rsi14 = rsi(candles),
        adx14 = adx(candles),
        cci20 = cci(candles);

  final List<Candle> candles;
  /// EMA lines by period ([emaPeriods]), as on Binance's chart.
  final Map<int, List<double?>> emas;
  List<double?> get ema25 => emas[25]!;
  List<double?> get ema50 => emas[50]!;
  List<double?> get ema100 => emas[100]!;
  List<double?> get ema200 => emas[200]!;
  final Macd macd;
  final List<double?> rsi14;
  final List<double?> adx14;
  final List<double?> cci20;
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
double? legMomentum(Macd m, Pivot from, Pivot to) => legExtreme(m.line, from.index, to.index, up: to.price > from.price);

/// The most extreme value of [vs] between candle indexes [from] and [to] (inclusive), in
/// the move's direction: the highest for an up move, the lowest for a down move.
double? legExtreme(List<double?> vs, int from, int to, {required bool up}) {
  double? best;
  for (var i = math.max(from, 0); i <= to && i < vs.length; i++) {
    final v = vs[i];
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
