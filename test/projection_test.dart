import 'package:flutter_test/flutter_test.dart';
import 'package:tantya/elliott.dart';

/// A scenario whose pivots sit at [prices], 10 candles apart.
Scenario at(List<double> prices, ScenarioKind kind, {required String next, double lo = 0, double hi = 0, int legBars = 10}) {
  const imp = ['', '1', '2', '3', '4', '5', 'A', 'B'];
  const cor = ['', 'A', 'B', 'C'];
  return Scenario(
    kind: kind,
    trend: prices[1] > prices[0] ? 1 : -1,
    points: [
      for (var i = 0; i < prices.length; i++)
        WavePoint(Pivot(i * 10, prices[i], high: i > 0 && prices[i] > prices[i - 1]),
            kind == ScenarioKind.impulse ? imp[i] : cor[i]),
    ],
    next: next,
    direction: 1,
    targetLow: lo,
    targetHigh: hi,
    invalidation: 0,
    score: 0.7,
    notes: const [],
    legBars: legBars,
  );
}

void main() {
  test('from wave 2: 3 → 4 → 5, starting at the target zone middle', () {
    // W1 = 10 (100 → 110), W2 back to 105. Target zone for W3: 115–121.18.
    final path = projectPath(at([100, 110, 105], ScenarioKind.impulse, next: '3', lo: 115, hi: 121.18));
    expect(path.map((w) => w.label), ['3', '4', '5']);
    expect(path[0].price, closeTo(118.09, 0.01)); // zone middle
    // W4 = 38.2% retrace of the projected W3 (105 → 118.09 = 13.09)
    expect(path[1].price, closeTo(118.09 - 0.382 * 13.09, 0.01));
    // W5 = W1 length from W4
    expect(path[2].price, closeTo(path[1].price + 10, 0.01));
    // Time keeps moving forward.
    expect(path[1].barsAhead, greaterThan(path[0].barsAhead));
    expect(path[2].barsAhead, greaterThan(path[1].barsAhead));
  });

  test('down impulse mirrors the ratios', () {
    final path = projectPath(at([110, 100, 105], ScenarioKind.impulse, next: '3', lo: 88.82, hi: 95));
    expect(path[0].price, closeTo(91.91, 0.01));
    expect(path[1].price, greaterThan(path[0].price), reason: 'wave 4 bounces up');
    expect(path[2].price, lessThan(path[1].price), reason: 'wave 5 falls again');
  });

  test('after a full impulse: A → B → C', () {
    final path = projectPath(at([100, 110, 105, 121, 115, 125], ScenarioKind.impulse, next: 'A', lo: 110, hi: 115));
    expect(path.map((w) => w.label), ['A', 'B', 'C']);
    final a = 125 - path[0].price;
    expect(path[1].price, closeTo(path[0].price + 0.5 * a, 0.01)); // B: half of A back
    expect(path[2].price, closeTo(path[1].price - a, 0.01)); // C = A
  });

  test('stops at wave C', () {
    final inC = projectPath(at([100, 110, 105, 121, 115, 125, 115, 120], ScenarioKind.impulse, next: 'C', lo: 105, hi: 110));
    expect(inC.map((w) => w.label), ['C']);
    final corrInB = projectPath(at([100, 90], ScenarioKind.correction, next: 'B', lo: 94, hi: 95.5));
    expect(corrInB.map((w) => w.label), ['B', 'C']);
  });

  test('finished A-B-C: just the new trend\'s first wave', () {
    final path = projectPath(at([100, 90, 95, 85], ScenarioKind.correction, next: 'new trend', lo: 94, hi: 100));
    expect(path.single.label, '1');
    expect(path.single.price, 97);
  });

  test('maxWaves limits the path', () {
    expect(projectPath(at([100, 110, 105], ScenarioKind.impulse, next: '3', lo: 115, hi: 121), maxWaves: 1), hasLength(1));
  });
}
