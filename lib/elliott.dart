/// Elliott Wave counting on candle series.
///
/// Pipeline: zigzag swings (at several sensitivities) → candidate wave counts
/// ending at the latest swing → hard-rule filter → Fibonacci-guideline score →
/// projection (target zone + invalidation) for the wave in progress.
///
/// Everything here is pure and deterministic so it can be unit-tested.
library;

import 'dart:math' as math;

import 'candles.dart';

class Pivot {
  const Pivot(this.index, this.price, {required this.high});

  /// Candle index in the series the pivot came from.
  final int index;
  final double price;
  final bool high;

  @override
  String toString() => '${high ? 'H' : 'L'}@$index:${price.toStringAsFixed(3)}';
}

/// Swing highs/lows: a new swing starts once price reverses by [threshold].
/// The last pivot is the running extreme, so it may still move.
List<Pivot> zigzag(List<Candle> candles, double threshold) {
  if (candles.length < 2) return const [];
  final pivots = <Pivot>[];
  var hi = Pivot(0, candles[0].high, high: true);
  var lo = Pivot(0, candles[0].low, high: false);
  var trend = 0; // +1 tracking a rising leg's high, -1 a falling leg's low
  Pivot? ext;

  for (var i = 1; i < candles.length; i++) {
    final c = candles[i];
    if (trend == 0) {
      if (c.high > hi.price) hi = Pivot(i, c.high, high: true);
      if (c.low < lo.price) lo = Pivot(i, c.low, high: false);
      if (hi.price - lo.price >= threshold) {
        if (lo.index <= hi.index) {
          pivots.add(lo);
          trend = 1;
          ext = hi;
        } else {
          pivots.add(hi);
          trend = -1;
          ext = lo;
        }
      }
    } else if (trend == 1) {
      if (c.high >= ext!.price) {
        ext = Pivot(i, c.high, high: true);
      } else if (ext.price - c.low >= threshold) {
        pivots.add(ext);
        trend = -1;
        ext = Pivot(i, c.low, high: false);
      }
    } else {
      if (c.low <= ext!.price) {
        ext = Pivot(i, c.low, high: false);
      } else if (c.high - ext.price >= threshold) {
        pivots.add(ext);
        trend = 1;
        ext = Pivot(i, c.high, high: true);
      }
    }
  }
  if (ext != null) pivots.add(ext);
  return pivots;
}

class WavePoint {
  const WavePoint(this.pivot, this.label);
  final Pivot pivot;

  /// '' for the origin, otherwise '1'..'5', 'A', 'B', 'C'.
  final String label;
}

enum ScenarioKind { impulse, correction }

class Scenario {
  Scenario({
    required this.kind,
    required this.trend,
    required this.points,
    required this.next,
    required this.direction,
    required this.targetLow,
    required this.targetHigh,
    required this.invalidation,
    required double score,
    required this.notes,
    required this.legBars,
  }) : fit = score;

  final ScenarioKind kind;

  /// Direction of the structure's first wave: +1 up, -1 down.
  final int trend;
  final List<WavePoint> points;

  /// Label of the wave now in progress, e.g. '3' or 'C'. 'new trend' after a finished ABC.
  final String next;

  /// Expected direction of the wave in progress.
  final int direction;
  double targetLow;
  double targetHigh;

  /// The count is wrong if price trades through this level.
  final double invalidation;

  /// Guideline fit × completeness × rule penalties, 0..1: how textbook the shape is.
  final double fit;

  /// How big the count is relative to the chart, 0..1 (1 = spans enough candles and
  /// enough of the price range). Set by [analyze].
  double size = 1;

  /// Ranking score: [fit], discounted for small counts down to 30% for a tiny one.
  /// Not a probability.
  double get score => fit * (0.3 + 0.7 * size);
  final List<String> notes;

  /// Rough duration estimate, in candles, of the wave in progress (for drawing the projection).
  final int legBars;

  /// Relative weight among the alternatives it was ranked with; set by [analyze].
  double share = 0;

  double get targetMid => (targetLow + targetHigh) / 2;

  /// Which way price must go to invalidate: +1 above [invalidation], -1 below.
  int get invalidSide {
    final diff = invalidation - points.last.pivot.price;
    // After a finished wave the level is the wave's own end: invalid if price extends past it.
    if (diff == 0) return -direction;
    return diff > 0 ? 1 : -1;
  }

  bool invalidatedBy(double price) => _beyond(price, invalidation, invalidSide);

  /// Protective level for a trade in [direction]: the invalidation level when it sits
  /// behind the trade, otherwise the start of the wave in progress (e.g. a wave-2 count
  /// is invalidated *below* wave 1's origin, but a short is wrong once price takes out
  /// wave 1's end).
  double get stop => invalidSide == -direction ? invalidation : points.last.pivot.price;

  /// Whether [price] has reached the near edge of the target zone.
  bool reachedBy(double price) => direction > 0 ? price >= targetLow : price <= targetHigh;

  String get title {
    final arrow = trend > 0 ? '↑' : '↓';
    final structure = kind == ScenarioKind.impulse ? 'Impulse $arrow' : 'Correction $arrow';
    if (next == 'new trend') return '$structure · ABC complete';
    return '$structure · wave $next in progress';
  }

  String get key => '${kind.name}|${points.map((p) => '${p.pivot.index}${p.label}').join(',')}|$next';
}

class EwAnalysis {
  const EwAnalysis(this.scenarios, this.price);

  /// Best first. Empty when no count passes the rules.
  final List<Scenario> scenarios;
  final double price;

  Scenario? get primary => scenarios.isEmpty ? null : scenarios.first;

  /// True when the top counts (up to 3) expect the same direction.
  bool get consensus {
    final top = scenarios.take(3).toList();
    return top.length > 1 && top.every((s) => s.direction == top.first.direction);
  }
}

/// Swing sizes as fractions of the series' range; several sizes ≈ several wave degrees.
const swingSensitivities = [0.05, 0.08, 0.12, 0.18];

/// [bounds] clamps targets for bounded prices (Polymarket's 0–1).
EwAnalysis analyze(List<Candle> candles, {int maxScenarios = 5, (double, double)? bounds}) {
  if (candles.length < 8) return EwAnalysis(const [], candles.isEmpty ? 0 : candles.last.close);
  final price = candles.last.close;
  final hi = candles.map((c) => c.high).reduce(math.max);
  final lo = candles.map((c) => c.low).reduce(math.min);
  final range = hi - lo;
  // Flat market: under 0.4% of price (or 0.4 points on a 0–1 market), nothing to count.
  if (range < 0.004 * math.max(price.abs(), bounds == null ? 0 : 1)) return EwAnalysis(const [], price);

  final byKey = <String, Scenario>{};
  for (final f in swingSensitivities) {
    final pivots = zigzag(candles, range * f);
    for (final s in _scenarios(pivots, price)) {
      final existing = byKey[s.key];
      if (existing == null || s.score > existing.score) byKey[s.key] = s;
    }
  }
  for (final s in byKey.values) {
    _sizeUp(s, candles, price, range);
  }
  if (bounds != null) {
    final (minP, maxP) = bounds;
    for (final s in byKey.values) {
      s.targetLow = s.targetLow.clamp(minP, maxP);
      s.targetHigh = s.targetHigh.clamp(minP, maxP);
    }
  }
  final ranked = byKey.values.toList()..sort((a, b) => b.score.compareTo(a.score));
  final top = ranked.take(maxScenarios).toList();
  final total = top.fold<double>(0, (t, s) => t + s.score);
  for (final s in top) {
    s.share = total == 0 ? 0 : s.score / total;
  }
  return EwAnalysis(top, price);
}

/// A count should span at least this share of the chart's candles (and at least
/// [minCountBars])…
const minCountSpan = 0.08;
const minCountBars = 12;

/// …and at least this share of its price range, to count at full weight.
const minCountAmplitude = 0.25;

/// Sets [Scenario.size]: the geometric mean of how well the count meets the minimum
/// span and amplitude. A three-candle A-B-C inside a big trend is a valid reading, but
/// it is mostly noise at this timeframe, so it shouldn't outrank the structure around it.
void _sizeUp(Scenario s, List<Candle> candles, double price, double range) {
  final first = s.points.first.pivot.index;
  final span = candles.length - 1 - first; // through the wave in progress
  final minSpan = math.max(minCountBars, candles.length * minCountSpan);
  final prices = [...s.points.map((p) => p.pivot.price), price];
  final amp = (prices.reduce(math.max) - prices.reduce(math.min)) / range;
  final spanFit = math.min(1.0, span / minSpan);
  final ampFit = math.min(1.0, amp / minCountAmplitude);
  s.size = math.sqrt(spanFit * ampFit);
  if (s.size < 0.5) {
    s.notes.add('Small count: $span candles, ${(amp * 100).round()}% of the range');
  }
}

/// How close [x] is to the nearest ideal ratio, 0..1 (1 = exact). Tolerance ~±15% in log space.
double fibFit(double x, List<double> ideals) {
  if (x <= 0) return 0;
  return ideals
      .map((t) => math.exp(-math.pow(math.log(x / t), 2) / (2 * 0.15 * 0.15)))
      .reduce(math.max);
}

/// Ideal Fibonacci ratios each wave is scored against (also shown on the About tab).
const fibGuides = <({String wave, String measure, List<double> ratios})>[
  (wave: 'Wave 2', measure: 'retrace of wave 1', ratios: [0.5, 0.618]),
  (wave: 'Wave 3', measure: '× wave 1', ratios: [1.618, 2.618, 1.0]),
  (wave: 'Wave 4', measure: 'retrace of wave 3', ratios: [0.382, 0.236, 0.5]),
  (wave: 'Wave 5', measure: '× wave 1', ratios: [1.0, 0.618, 1.618]),
  (wave: 'Wave B', measure: 'retrace of A', ratios: [0.5, 0.618, 0.382, 0.786]),
  (wave: 'Wave C', measure: '× wave A', ratios: [1.0, 1.618, 0.618]),
];
final _r2 = fibGuides[0].ratios;
final _r3 = fibGuides[1].ratios;
final _r4 = fibGuides[2].ratios;
final _r5 = fibGuides[3].ratios;
final _rB = fibGuides[4].ratios;
final _rC = fibGuides[5].ratios;

String _pct(double r) => '${(r * 100).round()}%';
String _x(double r) => '${r.toStringAsFixed(2)}×';

/// Every count that ends at the latest swing, in two readings: the last pivot
/// ended a wave, or the last pivot is still part of the wave in progress.
Iterable<Scenario> _scenarios(List<Pivot> pivots, double price) sync* {
  final n = pivots.length;
  if (n < 2) return;
  for (final end in [n - 1, n - 2]) {
    if (end < 1) continue;
    for (var s = end - 1; s >= math.max(0, end - 7); s--) {
      final pts = pivots.sublist(s, end + 1);
      final prior = s > 0 ? (pivots[s].price - pivots[s - 1].price).abs() : null;
      final imp = _impulse(pts, prior);
      if (imp != null && _alive(imp, price, pivots.last, end == n - 2)) yield imp;
      if (pts.length <= 4) {
        final abc = _correction(pts, prior);
        if (abc != null && _alive(abc, price, pivots.last, end == n - 2)) yield abc;
      }
    }
  }
}

/// Drops counts already invalidated, or whose target has already been reached.
bool _alive(Scenario sc, double price, Pivot latest, bool latestInsideLeg) {
  final d = sc.direction;
  final far = d > 0 ? sc.targetHigh : sc.targetLow;
  final near = d > 0 ? sc.targetLow : sc.targetHigh;
  if (sc.invalidatedBy(price)) return false;
  if (_beyond(price, far, d)) return false;
  // Reading "the latest extreme belongs to the wave in progress": it must point the right way and not
  // already have reached the target.
  if (latestInsideLeg) {
    final start = sc.points.last.pivot.price;
    if (d * (latest.price - start) <= 0) return false;
    if (_beyond(latest.price, near, d)) return false;
  }
  return true;
}

/// Whether [price] has passed [level] moving in direction [d].
bool _beyond(double price, double level, int d) => d > 0 ? price > level : price < level;

double _completeness(int legs) => math.min(1.0, 0.4 + 0.12 * legs);

(double, double) _zone(double from, int dir, double size, double a, double b) {
  final p = from + dir * size * a;
  final q = from + dir * size * b;
  return (math.min(p, q), math.max(p, q));
}

Scenario? _impulse(List<Pivot> p, double? prior) {
  final legs = p.length - 1; // confirmed waves
  if (legs < 1 || legs > 7) return null;
  final d = p[1].price > p[0].price ? 1 : -1;
  double w(int i) => (p[i].price - p[i - 1].price).abs();
  final notes = <String>[];
  final fits = <double>[];
  var penalty = 1.0;

  // Hard rules on whatever is confirmed.
  if (legs >= 2 && d * (p[2].price - p[0].price) <= 0) return null; // W2 beyond W1 start
  if (legs >= 3 && d * (p[3].price - p[1].price) <= 0) return null; // W3 must pass W1's end
  if (legs >= 4 && d * (p[4].price - p[1].price) <= 0) return null; // W4 overlaps W1
  if (legs >= 5) {
    if (w(3) < w(1) && w(3) < w(5)) return null; // W3 the shortest
    if (d * (p[5].price - p[3].price) <= 0) {
      penalty *= 0.6;
      notes.add('Wave 5 truncated (fails to pass wave 3)');
    }
  }
  if (legs >= 7 && d * (p[7].price - p[5].price) >= 0) penalty *= 0.7; // B past A's start: flat, not zigzag

  if (legs >= 2) {
    final r = w(2) / w(1);
    fits.add(fibFit(r, _r2));
    notes.add('W2 retraced ${_pct(r)} of W1');
  }
  if (legs >= 3) {
    final r = w(3) / w(1);
    fits.add(fibFit(r, _r3));
    notes.add('W3 = ${_x(r)} W1');
  }
  if (legs >= 4) {
    final r = w(4) / w(3);
    fits.add(fibFit(r, _r4));
    notes.add('W4 retraced ${_pct(r)} of W3');
    final alt = ((w(2) / w(1)) - r).abs() > 0.15;
    fits.add(alt ? 1 : 0.5);
    if (alt) notes.add('W2/W4 alternate');
  }
  if (legs >= 5) {
    final r = w(5) / w(1);
    fits.add(fibFit(r, _r5));
    notes.add('W5 = ${_x(r)} W1');
  }
  if (legs >= 7) {
    final rb = w(7) / w(6);
    fits.add(fibFit(rb, _rB));
    notes.add('B retraced ${_pct(rb)} of A');
  }
  // A small first wave after a much bigger opposite move looks more like a correction.
  if (legs <= 2 && prior != null && prior > w(1) * 1.5) penalty *= 0.85;

  final fit = fits.isEmpty ? 0.5 : fits.reduce((a, b) => a + b) / fits.length;
  final last = p.last.price;
  final double lowT, highT, inval;
  final int dir;
  final String next;
  final int bars;
  switch (legs) {
    case 1: // in W2
      dir = -d;
      next = '2';
      (lowT, highT) = _zone(last, -d, w(1), 0.5, 0.618);
      inval = p[0].price;
      bars = p[1].index - p[0].index;
    case 2: // in W3
      dir = d;
      next = '3';
      (lowT, highT) = _zone(last, d, w(1), 1.0, 1.618);
      inval = p[0].price;
      bars = ((p[1].index - p[0].index) * 1.5).round();
    case 3: // in W4
      dir = -d;
      next = '4';
      (lowT, highT) = _zone(last, -d, w(3), 0.236, 0.382);
      inval = p[1].price;
      bars = p[2].index - p[1].index;
    case 4: // in W5 — capped so W3 doesn't become the shortest
      dir = d;
      next = '5';
      final cap = w(3) < w(1) ? w(3) * 0.99 : double.infinity;
      (lowT, highT) = _zone(last, d, 1, math.min(0.618 * w(1), cap), math.min(w(1), cap));
      inval = p[1].price;
      bars = p[1].index - p[0].index;
    case 5: // impulse done → wave A against it
      dir = -d;
      next = 'A';
      (lowT, highT) = _zone(last, -d, (p[5].price - p[0].price).abs(), 0.382, 0.618);
      inval = p[5].price;
      bars = ((p[5].index - p[0].index) / 3).round();
    case 6: // in B
      dir = d;
      next = 'B';
      (lowT, highT) = _zone(last, d, w(6), 0.5, 0.618);
      inval = p[5].price;
      bars = p[6].index - p[5].index;
    default: // 7: in C
      dir = -d;
      next = 'C';
      (lowT, highT) = _zone(last, -d, w(6), 1.0, 1.618);
      inval = p[5].price;
      bars = p[6].index - p[5].index;
  }
  const labels = ['', '1', '2', '3', '4', '5', 'A', 'B'];
  return Scenario(
    kind: ScenarioKind.impulse,
    trend: d,
    points: [for (var i = 0; i < p.length; i++) WavePoint(p[i], labels[i])],
    next: next,
    direction: dir,
    targetLow: lowT,
    targetHigh: highT,
    invalidation: inval,
    score: fit * _completeness(legs) * penalty,
    notes: notes,
    legBars: math.max(2, bars),
  );
}

/// A standalone A-B-C (not preceded by a counted impulse).
Scenario? _correction(List<Pivot> p, double? prior) {
  final legs = p.length - 1;
  if (legs < 1 || legs > 3) return null;
  final d = p[1].price > p[0].price ? 1 : -1;
  double w(int i) => (p[i].price - p[i - 1].price).abs();
  final notes = <String>[];
  final fits = <double>[];
  var penalty = 1.0;

  if (legs >= 2 && d * (p[2].price - p[0].price) <= 0) return null; // B beyond A's start
  if (legs >= 2) {
    final r = w(2) / w(1);
    fits.add(fibFit(r, _rB));
    notes.add('B retraced ${_pct(r)} of A');
  }
  if (legs >= 3) {
    final r = w(3) / w(1);
    fits.add(fibFit(r, _rC));
    notes.add('C = ${_x(r)} A');
  }
  // A correction should be smaller than the move it corrects.
  if (prior == null || prior < w(1)) penalty *= 0.8;

  final fit = fits.isEmpty ? 0.5 : fits.reduce((a, b) => a + b) / fits.length;
  final last = p.last.price;
  final double lowT, highT, inval;
  final int dir;
  final String next;
  final int bars;
  switch (legs) {
    case 1:
      dir = -d;
      next = 'B';
      (lowT, highT) = _zone(last, -d, w(1), 0.5, 0.618);
      inval = p[0].price;
      bars = p[1].index - p[0].index;
    case 2:
      dir = d;
      next = 'C';
      (lowT, highT) = _zone(last, d, w(1), 1.0, 1.618);
      inval = p[0].price;
      bars = p[1].index - p[0].index;
    default: // ABC done → prior trend resumes
      dir = -d;
      next = 'new trend';
      (lowT, highT) = _zone(last, -d, (p[3].price - p[0].price).abs(), 0.618, 1.0);
      inval = p[3].price;
      bars = p[3].index - p[0].index;
  }
  const labels = ['', 'A', 'B', 'C'];
  return Scenario(
    kind: ScenarioKind.correction,
    trend: d,
    points: [for (var i = 0; i < p.length; i++) WavePoint(p[i], labels[i])],
    next: next,
    direction: dir,
    targetLow: lowT,
    targetHigh: highT,
    invalidation: inval,
    score: fit * _completeness(legs) * penalty * 0.9,
    notes: notes,
    legBars: math.max(2, bars),
  );
}
