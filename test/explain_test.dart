import 'package:flutter_test/flutter_test.dart';
import 'package:tantya/candles.dart';
import 'package:tantya/elliott.dart';
import 'package:tantya/explain.dart';
import 'package:tantya/setup.dart';

List<Candle> walk(List<double> path, {int bars = 8}) {
  final out = <Candle>[];
  var t = DateTime(2026, 10, 1);
  var prev = path.first;
  for (var leg = 1; leg < path.length; leg++) {
    for (var i = 1; i <= bars; i++) {
      final p = path[leg - 1] + (path[leg] - path[leg - 1]) * i / bars;
      final w = path.first * 0.004;
      out.add(Candle(t, prev, (p > prev ? p : prev) + w, (p < prev ? p : prev) - w, p, 1));
      prev = p;
      t = t.add(const Duration(hours: 1));
    }
  }
  return out;
}

const paths = <List<double>>[
  [0.20, 0.30, 0.25, 0.41, 0.35, 0.45, 0.445],
  [0.30, 0.20, 0.30, 0.25, 0.26],
  [100.0, 110, 104, 125, 118, 131, 120, 126, 112],
  [50.0, 40, 45, 35, 38],
  [20000.0, 30000, 25000, 41000, 35000, 45000],
];

void main() {
  test('explained target rules reproduce the engine\'s zones and invalidation exactly', () {
    var checked = 0;
    for (final path in paths) {
      for (final s in analyze(walk(path), maxScenarios: 50).scenarios) {
        final r = targetRule(s);
        final (lo, hi) = r.zone;
        expect(lo, closeTo(s.targetLow, 1e-9), reason: '${s.title} low');
        expect(hi, closeTo(s.targetHigh, 1e-9), reason: '${s.title} high');
        expect(r.invalidation, s.invalidation, reason: s.title);
        checked++;
      }
    }
    expect(checked, greaterThan(10), reason: 'enough counts exercised');
  });

  test('ratio checks match the engine\'s ratio notes', () {
    final s = analyze(walk(paths[0])).primary!;
    final checks = {for (final c in ratioChecks(s)) c.label: c};
    // e.g. note "W3 = 1.60× W1" vs measured W3 ÷ W1
    for (final n in s.notes.where((n) => n.startsWith('W3 = '))) {
      final noted = double.parse(n.substring(5, n.indexOf('×')));
      expect(checks['W3 ÷ W1']!.measured, closeTo(noted, 0.006));
    }
    for (final c in checks.values) {
      expect(c.fit, inInclusiveRange(0, 1));
    }
  });

  test('explain produces every section, with the trade and path when present', () {
    final candles = walk(paths[1]);
    final s = analyze(candles).primary!;
    final setup = TradeSetup.from(s, candles.last.close);
    final sections = explain(s, setup, candles, (v) => v.toStringAsFixed(4), atrValue: 0.01);
    final titles = sections.map((x) => x.title).toList();
    expect(titles.take(4), ['1 · The swings', '2 · Fibonacci fit', '3 · Score', '4 · Target & invalidation']);
    if (setup != null) expect(titles, contains('5 · Trade levels'));
    expect(titles.last, contains('Projected path'));
    final score = sections[2].lines.firstWhere((l) => l.label == 'Score');
    expect(score.value, '${(s.score * 100).toStringAsFixed(1)}%');
  });
}
