import 'package:flutter_test/flutter_test.dart';
import 'package:tantya/candles.dart';
import 'package:tantya/elliott.dart';

/// Candles walking linearly through [path] (prices), [bars] candles per leg, with a little wick.
List<Candle> walk(List<double> path, {int bars = 6}) {
  final out = <Candle>[];
  var t = DateTime(2026, 10, 1);
  var prev = path.first;
  for (var leg = 1; leg < path.length; leg++) {
    for (var i = 1; i <= bars; i++) {
      final p = path[leg - 1] + (path[leg] - path[leg - 1]) * i / bars;
      final hi = (p > prev ? p : prev) + path.first * 0.005;
      final lo = (p < prev ? p : prev) - path.first * 0.005;
      out.add(Candle(t, prev, hi, lo, p));
      prev = p;
      t = t.add(const Duration(hours: 1));
    }
  }
  return out;
}

void main() {
  group('zigzag', () {
    test('finds the swings of a clean path', () {
      final piv = zigzag(walk([0.20, 0.30, 0.25, 0.41, 0.35, 0.45]), 0.03);
      expect(piv.map((p) => p.high), [false, true, false, true, false, true]);
      expect(piv.first.price, closeTo(0.199, 0.002));
      expect(piv.last.price, closeTo(0.451, 0.002));
    });

    test('ignores wiggles smaller than the threshold', () {
      final piv = zigzag(walk([0.20, 0.30, 0.29, 0.40]), 0.03);
      expect(piv, hasLength(2));
    });
  });

  test('fibFit peaks at the ideal ratio', () {
    expect(fibFit(0.618, [0.618]), closeTo(1, 1e-9));
    expect(fibFit(0.5, [0.618]), lessThan(0.6));
    expect(fibFit(0.9, [0.618]), lessThan(0.1));
  });

  group('analyze', () {
    test('textbook impulse up → complete, expects wave A down', () {
      // W1 .10, W2 50%, W3 1.6×, W4 ~38%, W5 = W1
      final a = analyze(walk([0.20, 0.30, 0.25, 0.41, 0.35, 0.45, 0.445]));
      final s = a.primary!;
      expect(s.kind, ScenarioKind.impulse);
      expect(s.next, 'A');
      expect(s.direction, -1);
      expect(s.points.map((p) => p.label), ['', '1', '2', '3', '4', '5']);
      // retrace 38–62% of the whole .20→.45 move
      expect(s.targetHigh, closeTo(0.45 - 0.25 * 0.382, 0.01));
      expect(s.targetLow, closeTo(0.45 - 0.25 * 0.618, 0.01));
      expect(s.invalidation, closeTo(0.451, 0.002));
      expect(s.invalidSide, 1);
    });

    test('W4 overlapping W1 is never counted as an impulse', () {
      final a = analyze(walk([0.20, 0.30, 0.25, 0.41, 0.28, 0.45, 0.445]));
      final full = a.scenarios.where((s) => s.kind == ScenarioKind.impulse && s.next == 'A' &&
          s.points.first.pivot.price < 0.21);
      expect(full, isEmpty);
    });

    test('after W1-W2, a wave-3 count projects above W1 and is invalidated below the origin', () {
      final a = analyze(walk([0.30, 0.20, 0.30, 0.25, 0.26]));
      final w3 = a.scenarios.firstWhere((s) => s.next == '3');
      expect(w3.direction, 1);
      expect(w3.targetLow, closeTo(0.35, 0.01)); // W3 ≥ 1.0× W1 from W2's end
      expect(w3.invalidation, closeTo(0.199, 0.002));
      expect(w3.invalidatedBy(0.19), isTrue);
      expect(w3.invalidatedBy(0.22), isFalse);
      expect(w3.reachedBy(0.36), isTrue);
    });

    test('drops counts whose target is already behind the price', () {
      final a = analyze(walk([0.30, 0.20, 0.30, 0.25, 0.26]));
      for (final s in a.scenarios) {
        final far = s.direction > 0 ? s.targetHigh : s.targetLow;
        expect(s.direction > 0 ? a.price <= far : a.price >= far, isTrue, reason: s.title);
        expect(s.invalidatedBy(a.price), isFalse, reason: s.title);
      }
    });

    test('shares sum to 1 and scores are ordered', () {
      final a = analyze(walk([0.20, 0.30, 0.25, 0.41, 0.35, 0.45, 0.445]));
      expect(a.scenarios.fold<double>(0, (t, s) => t + s.share), closeTo(1, 1e-9));
      for (var i = 1; i < a.scenarios.length; i++) {
        expect(a.scenarios[i - 1].score, greaterThanOrEqualTo(a.scenarios[i].score));
      }
    });

    test('targets stay inside 0–100%', () {
      final a = analyze(walk([0.60, 0.80, 0.70, 0.97, 0.90, 0.985]), bounds: (0.005, 0.995));
      for (final s in a.scenarios) {
        expect(s.targetLow, inInclusiveRange(0.005, 0.995));
        expect(s.targetHigh, inInclusiveRange(0.005, 0.995));
      }
    });

    test('works at any price scale (BTC-like)', () {
      final small = analyze(walk([0.20, 0.30, 0.25, 0.41, 0.35, 0.45, 0.445])).primary!;
      final big = analyze(walk([20000, 30000, 25000, 41000, 35000, 45000, 44500])).primary!;
      expect(big.next, small.next);
      expect(big.targetLow, closeTo(small.targetLow * 100000, 300));
    });

    test('stop sits behind the trade', () {
      final a = analyze(walk([0.30, 0.20, 0.30, 0.25, 0.26]));
      for (final s in a.scenarios) {
        expect(s.direction > 0 ? s.stop < a.price : s.stop > a.price, isTrue, reason: s.title);
      }
    });

    test('a small wiggle at the end does not outrank the big structure', () {
      // Big impulse up over ~70 candles, then a tiny A-B-C over the last few candles
      // using a small slice of the range.
      final big = walk([0.20, 0.30, 0.215, 0.37, 0.30, 0.45], bars: 14); // real-world messy ratios
      final tiny = walk([0.45, 0.42, 0.435, 0.405], bars: 2);
      var t = big.last.start;
      final candles = [
        ...big,
        for (final c in tiny) Candle(t = t.add(const Duration(hours: 1)), c.open, c.high, c.low, c.close),
      ];
      final p = analyze(candles).primary!;
      final first = p.points.first.pivot.index;
      expect(candles.length - 1 - first, greaterThan(20), reason: 'primary was ${p.title} from bar $first');
    });

    test('small counts say so', () {
      final big = walk([0.20, 0.30, 0.215, 0.37, 0.30, 0.45], bars: 14); // real-world messy ratios
      final tiny = walk([0.45, 0.42, 0.435, 0.405], bars: 2);
      var t = big.last.start;
      final candles = [
        ...big,
        for (final c in tiny) Candle(t = t.add(const Duration(hours: 1)), c.open, c.high, c.low, c.close),
      ];
      final small = analyze(candles, maxScenarios: 50).scenarios.where((s) => s.size < 0.5);
      expect(small, isNotEmpty);
      expect(small.first.notes.any((n) => n.startsWith('Small count')), isTrue);
    });

    test('flat or tiny series yields nothing', () {
      final flat = [for (var i = 0; i < 30; i++) Candle(DateTime(2026, 10, 1, i), 0.5, 0.5005, 0.4995, 0.5)];
      expect(analyze(flat).scenarios, isEmpty);
      expect(analyze(walk([0.5, 0.6], bars: 3)).scenarios, isEmpty);
    });
  });
}
