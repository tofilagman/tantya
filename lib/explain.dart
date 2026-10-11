/// "How this was computed": a setup's numbers, step by step, from the swings to the
/// reward:risk. Everything is recomputed from the count's points so the explanation
/// shows real values; tests check it reproduces the engine's targets exactly.
library;

import 'dart:math' as math;

import 'candles.dart';
import 'elliott.dart';
import 'setup.dart';

class CalcLine {
  const CalcLine(this.label, this.value, [this.note]);
  final String label;
  final String value;

  /// How the value was obtained, e.g. "1.0–1.618 × W1 from W2's end".
  final String? note;
}

class CalcSection {
  const CalcSection(this.title, this.lines);
  final String title;
  final List<CalcLine> lines;
}

/// One measured wave ratio against its Fibonacci guide.
class RatioCheck {
  const RatioCheck(this.label, this.measured, this.ideals, this.fit);
  final String label;
  final double measured;
  final List<double> ideals;
  final double fit;
}

/// The rule behind a count's target zone and invalidation level.
class TargetRule {
  const TargetRule({
    required this.wave,
    required this.from,
    required this.dir,
    required this.base,
    required this.baseLabel,
    required this.lo,
    required this.hi,
    required this.ratioText,
    required this.invalidation,
    required this.invalidationWhy,
  });

  /// The wave being projected, e.g. '3'.
  final String wave;

  /// The price the move starts from (the last confirmed pivot).
  final double from;
  final int dir;

  /// The length the ratios apply to, and what it is ("W1", "the whole 1–5 move").
  final double base;
  final String baseLabel;

  /// Ratio range, already multiplied in for capped wave-5 targets (then [base] is 1).
  final double lo, hi;
  final String ratioText;
  final double invalidation;
  final String invalidationWhy;

  (double, double) get zone {
    final a = from + dir * base * lo, b = from + dir * base * hi;
    return (math.min(a, b), math.max(a, b));
  }
}

double _len(List<Pivot> p, int i) => (p[i].price - p[i - 1].price).abs();

/// The same ratios the engine scores, measured on this count.
List<RatioCheck> ratioChecks(Scenario s) {
  final p = s.points.map((w) => w.pivot).toList();
  final legs = p.length - 1;
  final g = {for (final x in fibGuides) x.wave: x.ratios};
  final out = <RatioCheck>[];
  void add(String label, double r, List<double> ideals) => out.add(RatioCheck(label, r, ideals, fibFit(r, ideals)));
  if (s.kind == ScenarioKind.impulse) {
    if (legs >= 2) add('W2 ÷ W1', _len(p, 2) / _len(p, 1), g['Wave 2']!);
    if (legs >= 3) add('W3 ÷ W1', _len(p, 3) / _len(p, 1), g['Wave 3']!);
    if (legs >= 4) add('W4 ÷ W3', _len(p, 4) / _len(p, 3), g['Wave 4']!);
    if (legs >= 5) add('W5 ÷ W1', _len(p, 5) / _len(p, 1), g['Wave 5']!);
    if (legs >= 7) add('B ÷ A', _len(p, 7) / _len(p, 6), g['Wave B']!);
  } else {
    if (legs >= 2) add('B ÷ A', _len(p, 2) / _len(p, 1), g['Wave B']!);
    if (legs >= 3) add('C ÷ A', _len(p, 3) / _len(p, 1), g['Wave C']!);
  }
  return out;
}

/// Whether waves 2 and 4 alternate (one sharp, one shallow): scored 1 if their
/// retracements differ by more than 15 points, else 0.5. Null before wave 4.
double? alternationScore(Scenario s) {
  final p = s.points.map((w) => w.pivot).toList();
  if (s.kind != ScenarioKind.impulse || p.length - 1 < 4) return null;
  return ((_len(p, 2) / _len(p, 1)) - (_len(p, 4) / _len(p, 3))).abs() > 0.15 ? 1 : 0.5;
}

/// Mirrors the engine's projection for the wave in progress.
TargetRule targetRule(Scenario s) {
  final p = s.points.map((w) => w.pivot).toList();
  final legs = p.length - 1;
  final d = s.trend;
  final last = p.last.price;
  TargetRule r(String wave, int dir, double base, String baseLabel, double lo, double hi, String ratioText,
          double inval, String why) =>
      TargetRule(
        wave: wave,
        from: last,
        dir: dir,
        base: base,
        baseLabel: baseLabel,
        lo: lo,
        hi: hi,
        ratioText: ratioText,
        invalidation: inval,
        invalidationWhy: why,
      );
  if (s.kind == ScenarioKind.impulse) {
    switch (legs) {
      case 1:
        return r('2', -d, _len(p, 1), 'W1', 0.5, 0.618, '50–61.8% of W1', p[0].price,
            'wave 2 can never go past the start of wave 1');
      case 2:
        return r('3', d, _len(p, 1), 'W1', 1.0, 1.618, '1–1.618 × W1', p[0].price,
            'wave 2 can never go past the start of wave 1');
      case 3:
        return r('4', -d, _len(p, 3), 'W3', 0.236, 0.382, '23.6–38.2% of W3', p[1].price,
            'wave 4 can never enter wave 1\'s price territory');
      case 4:
        final w1 = _len(p, 1), w3 = _len(p, 3);
        final cap = w3 < w1 ? w3 * 0.99 : double.infinity;
        return r('5', d, 1, 'W1', math.min(0.618 * w1, cap), math.min(w1, cap),
            '0.618–1 × W1${cap.isFinite ? ', capped so wave 3 isn\'t the shortest' : ''}', p[1].price,
            'wave 4 can never enter wave 1\'s price territory');
      case 5:
        return r('A', -d, (p[5].price - p[0].price).abs(), 'the whole 1–5 move', 0.382, 0.618,
            '38.2–61.8% of 1–5', p[5].price, 'a new extreme past wave 5 means the impulse is still going');
      case 6:
        return r('B', d, _len(p, 6), 'A', 0.5, 0.618, '50–61.8% of A', p[5].price,
            'B going past the end of wave 5 breaks the count');
      default:
        return r('C', -d, _len(p, 6), 'A', 1.0, 1.618, '1–1.618 × A', p[5].price,
            'price past the end of wave 5 breaks the count');
    }
  }
  switch (legs) {
    case 1:
      return r('B', -d, _len(p, 1), 'A', 0.5, 0.618, '50–61.8% of A', p[0].price, 'B can never go past the start of A');
    case 2:
      return r('C', d, _len(p, 1), 'A', 1.0, 1.618, '1–1.618 × A', p[0].price, 'B can never go past the start of A');
    default:
      return r('1', -d, (p[3].price - p[0].price).abs(), 'the whole A–C move', 0.618, 1.0, '61.8–100% of A–C',
          p[3].price, 'a new extreme past C means the correction isn\'t over');
  }
}

/// Mirrors [projectPath]'s rule for each step after the first.
String projectionRule(ScenarioKind kind, String label, bool first) {
  if (first) return 'middle of the target zone';
  if (kind == ScenarioKind.impulse) {
    return switch (label) {
      '2' => '55% pullback of W1',
      '3' => '1.618 × W1',
      '4' => '38.2% pullback of W3',
      '5' => '= W1',
      'A' => '50% of the whole 1–5',
      'B' => '50% of A back',
      _ => '= A',
    };
  }
  return label == 'B' ? '55% of A back' : '= A';
}

List<CalcSection> explain(
  Scenario s,
  TradeSetup? setup,
  List<Candle> candles,
  String Function(double) fmt, {
  double? atrValue,
  double stopBufferAtr = 0.5,
}) {
  final p = s.points;
  String pct(double r) => '${(r * 100).toStringAsFixed(1)}%';
  String x(double r) => '${r.toStringAsFixed(3)}×';
  String ideals(List<double> v) => v.map((r) => r < 1 ? pct(r) : '$r×').join(' / ');

  // 1. Swings
  final swings = <CalcLine>[
    for (var i = 1; i < p.length; i++)
      CalcLine(
        'Wave ${p[i].label}',
        '${fmt(p[i - 1].pivot.price)} → ${fmt(p[i].pivot.price)}',
        '${(p[i].pivot.price - p[i - 1].pivot.price) >= 0 ? '+' : '−'}${fmt((p[i].pivot.price - p[i - 1].pivot.price).abs())}'
            ' (${pct((p[i].pivot.price - p[i - 1].pivot.price).abs() / p[i - 1].pivot.price)})'
            ' over ${p[i].pivot.index - p[i - 1].pivot.index} candles',
      ),
  ];

  // 2. Fibonacci fit
  final checks = ratioChecks(s);
  final alt = alternationScore(s);
  final scores = [for (final c in checks) c.fit, ?alt];
  final avg = scores.isEmpty ? 0.5 : scores.reduce((a, b) => a + b) / scores.length;
  final fibLines = <CalcLine>[
    for (final c in checks) CalcLine(c.label, x(c.measured), 'ideal ${ideals(c.ideals)} → fit ${pct(c.fit)}'),
    if (alt != null) CalcLine('Alternation (W2 vs W4)', alt == 1 ? 'yes' : 'no', 'scores ${alt == 1 ? '100%' : '50%'}'),
    CalcLine('Average fit', pct(avg), scores.isEmpty ? 'too few waves to measure: 50% assumed' : null),
  ];

  // 3. Score
  final legs = p.length - 1;
  final completeness = completenessOf(legs);
  final rest = avg * completeness == 0 ? 1.0 : s.fit / (avg * completeness);
  final spanFit = s.minSpanBars == 0 ? 1.0 : math.min(1.0, s.spanBars / s.minSpanBars);
  final ampFit = math.min(1.0, s.amplitude / minCountAmplitude);
  final scoreLines = <CalcLine>[
    CalcLine('Average fit', pct(avg)),
    CalcLine('× completeness', x(completeness), '$legs confirmed waves: 0.4 + 0.12 × $legs, max 1'),
    if ((rest - 1).abs() > 0.005)
      CalcLine('× rule adjustments', x(rest),
          s.kind == ScenarioKind.correction ? 'standalone corrections ×0.9, plus any penalties' : 'e.g. truncated wave 5, or a small first wave'),
    CalcLine('= Fit', pct(s.fit)),
    CalcLine('Span', '${s.spanBars} candles', 'needs ${s.minSpanBars.round()} for full weight → ${pct(spanFit)}'),
    CalcLine('Amplitude', '${pct(s.amplitude)} of the chart\'s range', 'needs ${pct(minCountAmplitude)} → ${pct(ampFit)}'),
    CalcLine('Size', pct(s.size), '√(span × amplitude)'),
    CalcLine('Score', pct(s.score), 'fit × (0.3 + 0.7 × size)'),
  ];

  // 4. Target
  final rule = targetRule(s);
  final (zLo, zHi) = rule.zone;
  final targetLines = <CalcLine>[
    CalcLine('Wave ${rule.wave} starts at', fmt(rule.from), 'the last confirmed swing'),
    if (rule.base != 1) CalcLine('${rule.baseLabel} length', fmt(rule.base)),
    CalcLine('Target zone', '${fmt(s.targetLow)} – ${fmt(s.targetHigh)}',
        '${rule.ratioText}, ${rule.dir > 0 ? 'up' : 'down'} from ${fmt(rule.from)}'
        '${((zLo - s.targetLow).abs() > 1e-9 || (zHi - s.targetHigh).abs() > 1e-9) ? ' (kept inside the price limits)' : ''}'),
    CalcLine('Invalidation', fmt(s.invalidation), rule.invalidationWhy),
  ];

  final sections = [
    CalcSection('1 · The swings', swings),
    CalcSection('2 · Fibonacci fit', fibLines),
    CalcSection('3 · Score', scoreLines),
    CalcSection('4 · Target & invalidation', targetLines),
  ];

  // 5. Trade
  if (setup != null) {
    final buffer = atrValue == null ? null : atrValue * stopBufferAtr;
    sections.add(CalcSection('5 · Trade levels', [
      CalcLine('Entry', fmt(setup.entry), 'the current price'),
      CalcLine(
        'Stop',
        fmt(setup.stop),
        '${s.stop == s.invalidation ? 'invalidation' : 'start of wave ${rule.wave}'} ${fmt(s.stop)}'
            '${buffer == null ? '' : ' ${setup.side == Side.long ? '−' : '+'} ${fmt(buffer)} (½ × ATR(14) of ${fmt(atrValue!)})'}',
      ),
      CalcLine('Risk', fmt(setup.risk), '|entry − stop| = ${pct(setup.risk / setup.entry)} of price'),
      CalcLine('TP1', fmt(setup.tp1), 'near edge of the zone · R:R ${setup.rr1.toStringAsFixed(2)} = ${fmt((setup.tp1 - setup.entry).abs())} ÷ ${fmt(setup.risk)}'),
      CalcLine('TP2', fmt(setup.tp2), 'far edge · R:R ${setup.rr2.toStringAsFixed(2)}'),
    ]));
  }

  // 6. Projected path
  final path = projectPath(s);
  if (path.isNotEmpty) {
    sections.add(CalcSection('${setup == null ? 5 : 6} · Projected path', [
      for (var k = 0; k < path.length; k++)
        CalcLine('Wave ${path[k].label}', fmt(path[k].price), projectionRule(s.kind, path[k].label, k == 0)),
    ]));
  }
  return sections;
}
