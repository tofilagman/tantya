/// The "evidence report": does the indicator evidence fit the wave the count says is
/// in progress? Follows the layered method the users sent (price → EMA + volume →
/// MACD → RSI/CCI → Elliott Wave): indicators are evidence, price is the result.
///
/// Three templates:
/// - **Wave 3 in progress**: the healthy-wave-3 story: EMAs stacked with the trend,
///   MACD speeding up, CCI beyond ±100, RSI strong but not exhausted, volume higher
///   than in wave 2.
/// - **Wave 5 in progress or just finished**: the exhaustion story: price past wave 3
///   but MACD, RSI, CCI and volume all weaker than in wave 3.
/// - **Any other wave**: trend context for the trade: EMA stack, MACD, RSI room, CCI
///   and whether volume fits the kind of wave (impulsive waves on rising volume,
///   pullbacks on lighter volume).
library;

import 'elliott.dart';
import 'indicators.dart';

class Evidence {
  const Evidence(this.label, this.ok, this.detail);

  /// What is being checked, e.g. "EMAs stacked".
  final String label;

  /// true = supports the reading, false = argues against it, null = can't tell yet.
  final bool? ok;

  /// The numbers behind it, e.g. "price > 20 > 50 > 200".
  final String detail;
}

enum EvidenceLevel { strong, mixed, weak }

class EvidenceReport {
  const EvidenceReport(this.title, this.question, this.items);

  /// e.g. "Healthy wave 3?"
  final String title;

  /// What a "yes" means, in plain words.
  final String question;
  final List<Evidence> items;

  int get confirmed => items.where((e) => e.ok == true).length;
  int get checked => items.where((e) => e.ok != null).length;

  /// Share of checkable items that support the reading; null if none could be checked.
  double? get ratio => checked == 0 ? null : confirmed / checked;

  EvidenceLevel? get level => levelOf(ratio);

  static EvidenceLevel? levelOf(double? r) => r == null
      ? null
      : r >= 2 / 3
          ? EvidenceLevel.strong
          : r >= 1 / 3
              ? EvidenceLevel.mixed
              : EvidenceLevel.weak;
}

/// The wave in progress, as the count sees it: its label, the candle index it started at,
/// and the expected direction (+1 up, −1 down).
({String label, int start, int dir}) _inProgress(Scenario s) {
  final label = s.next == 'new trend' ? '1' : s.next;
  return (label: label, start: s.points.last.pivot.index, dir: s.direction);
}

EvidenceReport evidenceReport(Scenario s, Indicators ind) {
  final c = ind.candles;
  final p = s.points.map((w) => w.pivot).toList();
  final legs = p.length - 1;
  final now = c.length - 1;
  final w = _inProgress(s);

  if (s.kind == ScenarioKind.impulse && w.label == '3' && legs >= 2) {
    return _healthyWave3(ind, p, now, w.dir);
  }
  if (s.kind == ScenarioKind.impulse && legs >= 4 && (w.label == '5' || (w.label == 'A' && legs == 5))) {
    return _wave5Exhaustion(ind, p, legs, now, s.trend);
  }
  return _context(ind, p, now, w);
}

/// Wave 3: "the workers are going in the same direction, working faster, strong, not
/// exhausted yet, and many are participating."
EvidenceReport _healthyWave3(Indicators ind, List<Pivot> p, int now, int d) {
  final c = ind.candles;
  final up = d > 0;
  final items = <Evidence>[
    _emaStack(ind, now, d),
    _macdSpeed(ind, now, d),
    _cciStrength(ind, now, d),
    () {
      final r = ind.rsi14[now];
      if (r == null) return const Evidence('RSI strong, not exhausted', null, 'not enough history');
      // Ideal 60–70 (or 30–40 for a down move), with a little tolerance either side.
      final v = up ? r : 100 - r;
      final ok = v >= 55 && v <= 75;
      final note = v > 75 ? 'stretched' : (v < 55 ? 'weak for a wave 3' : 'strong, room left');
      return Evidence('RSI strong, not exhausted', ok, 'RSI ${r.toStringAsFixed(0)} · $note');
    }(),
    () {
      if (p[2].index >= now) return const Evidence('Volume higher than wave 2', null, 'wave 3 just started');
      final w2 = waveVolume(c, p[1].index, p[2].index);
      final w3 = waveVolume(c, p[2].index, now);
      if (w2 == null || w3 == null) return const Evidence('Volume higher than wave 2', null, 'no volume data');
      return Evidence('Volume higher than wave 2', w3 > w2, '${_x(w3 / w2)} wave 2\'s average');
    }(),
  ];
  return EvidenceReport('Healthy wave 3?', 'Does the evidence back a strong wave 3?', items);
}

/// Wave 5: "the workers are still working, but they're getting tired." Every item here
/// compares wave 5 with wave 3; a ✓ is a sign of exhaustion.
EvidenceReport _wave5Exhaustion(Indicators ind, List<Pivot> p, int legs, int now, int trend) {
  final c = ind.candles;
  final up = trend > 0;
  final w3 = (from: p[2].index, to: p[3].index);
  final w5 = (from: p[4].index, to: legs >= 5 ? p[5].index : now);
  final w5End = legs >= 5 ? p[5].price : c[now].close;
  final beyond = up ? w5End > p[3].price : w5End < p[3].price;

  Evidence weaker(String label, List<double?> vs, String Function(double) fmt) {
    final a = legExtreme(vs, w3.from, w3.to, up: up);
    final b = legExtreme(vs, w5.from, w5.to, up: up);
    if (a == null || b == null) return Evidence(label, null, 'not enough history');
    final weaker = up ? b < a : b > a;
    return Evidence(label, weaker, 'wave 3 ${fmt(a)} → wave 5 ${fmt(b)}');
  }

  final items = <Evidence>[
    Evidence('Price past wave 3', beyond, beyond ? 'new ${up ? 'high' : 'low'} made' : 'not past wave 3 yet'),
    weaker('MACD weaker than wave 3', ind.macd.line, _num),
    weaker('RSI weaker than wave 3 (divergence)', ind.rsi14, (v) => v.toStringAsFixed(0)),
    weaker('CCI weaker than wave 3', ind.cci20, (v) => v.toStringAsFixed(0)),
    () {
      final v3 = waveVolume(c, w3.from, w3.to);
      final v5 = waveVolume(c, w5.from, w5.to);
      if (v3 == null || v5 == null) return const Evidence('Volume lower than wave 3', null, 'no volume data');
      return Evidence('Volume lower than wave 3', v5 < v3, 'wave 5 at ${_x(v5 / v3)} wave 3\'s average');
    }(),
  ];
  return EvidenceReport(
    'Wave 5 exhaustion?',
    'Is wave 5 running out of steam? Watch for exhaustion, then wait for price to confirm.',
    items,
  );
}

/// Any other wave: does the evidence back a move in the expected direction?
EvidenceReport _context(Indicators ind, List<Pivot> p, int now, ({String label, int start, int dir}) w) {
  final c = ind.candles;
  final d = w.dir;
  // Impulsive waves (1, 3, 5, A, C) should come on rising participation; pullbacks
  // (2, 4, B) on lighter volume than the move before them.
  final impulsive = const {'1', '3', '5', 'A', 'C'}.contains(w.label);
  final prev = p.length >= 2 ? (from: p[p.length - 2].index, to: p.last.index) : null;
  final items = <Evidence>[
    _emaStack(ind, now, d),
    _macdSpeed(ind, now, d),
    () {
      final r = ind.rsi14[now];
      if (r == null) return const Evidence('RSI has room', null, 'not enough history');
      final room = d > 0 ? r < 70 : r > 30;
      return Evidence('RSI has room', room, 'RSI ${r.toStringAsFixed(0)}${room ? '' : ' · already stretched'}');
    }(),
    _cciStrength(ind, now, d, threshold: 0),
    () {
      final label = impulsive ? 'Volume rising with the move' : 'Pullback on lighter volume';
      if (prev == null) return Evidence(label, null, 'no earlier wave to compare');
      if (w.start >= now) return Evidence(label, null, 'wave ${w.label} just started');
      final before = waveVolume(c, prev.from, prev.to);
      final current = waveVolume(c, w.start, now);
      if (before == null || current == null) return Evidence(label, null, 'no volume data');
      final r = current / before;
      return Evidence(label, impulsive ? r > 1 : r < 1, '${_x(r)} the previous wave\'s average');
    }(),
  ];
  final dir = d > 0 ? 'up' : 'down';
  return EvidenceReport('Evidence for wave ${w.label} $dir', 'Does the evidence back a move $dir?', items);
}

Evidence _emaStack(Indicators ind, int i, int d) {
  final price = ind.candles[i].close;
  final e20 = ind.ema20[i], e50 = ind.ema50[i], e200 = ind.ema200[i];
  if (e20 == null || e50 == null) return const Evidence('EMAs stacked with the move', null, 'not enough history');
  final chain = [price, e20, e50, ?e200];
  bool ordered(bool up) {
    for (var k = 1; k < chain.length; k++) {
      if (up ? chain[k - 1] <= chain[k] : chain[k - 1] >= chain[k]) return false;
    }
    return true;
  }
  final ok = ordered(d > 0);
  final sym = d > 0 ? '>' : '<';
  final detail = ok
      ? 'price $sym 20 $sym 50${e200 != null ? ' $sym 200' : ''}'
      : ordered(d < 0)
          ? 'stacked the other way'
          : 'mixed (price ${price > e20 ? 'above' : 'below'} EMA 20, ${e200 == null ? 'no 200 yet' : '${price > e200 ? 'above' : 'below'} EMA 200'})';
  return Evidence('EMAs stacked with the move', ok, detail);
}

Evidence _macdSpeed(Indicators ind, int i, int d) {
  final h = ind.macd.histogram;
  final now = h[i], prev = i > 0 ? h[i - 1] : null;
  if (now == null || prev == null) return const Evidence('MACD speeding up', null, 'not enough history');
  final withMove = d > 0 ? now > 0 : now < 0;
  final growing = d > 0 ? now > prev : now < prev;
  return Evidence(
    'MACD speeding up',
    withMove && growing,
    'histogram ${withMove ? 'with' : 'against'} the move, ${growing ? 'growing' : 'shrinking'}',
  );
}

Evidence _cciStrength(Indicators ind, int i, int d, {double threshold = 100}) {
  final v = ind.cci20[i];
  final label = threshold == 0 ? 'CCI on the move\'s side' : 'CCI beyond ${d > 0 ? '+' : '−'}100';
  if (v == null) return Evidence(label, null, 'not enough history');
  final ok = d > 0 ? v >= threshold : v <= -threshold;
  final strength = v.abs() >= 200 ? 'very strong' : v.abs() >= 100 ? 'strong' : 'normal';
  return Evidence(label, ok, 'CCI ${v.toStringAsFixed(0)} · $strength');
}

String _x(double r) => '${r.toStringAsFixed(2)}×';

String _num(double v) {
  final a = v.abs();
  return v.toStringAsFixed(a >= 100 ? 1 : a >= 1 ? 2 : a >= 0.01 ? 4 : 6);
}
