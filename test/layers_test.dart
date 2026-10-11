import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tantya/candles.dart';
import 'package:tantya/elliott.dart';
import 'package:tantya/layers.dart';

final t0 = DateTime(2026, 10, 7, 10);
List<Candle> hourly(int n) =>
    [for (var i = 0; i < n; i++) Candle(t0.add(Duration(hours: i)), 1, 1, 1, 1)];

Scenario zone(int dir, double lo, double hi, {int pivotIndex = 2}) => Scenario(
      kind: ScenarioKind.impulse,
      trend: dir,
      points: [WavePoint(Pivot(pivotIndex, (lo + hi) / 2, high: dir < 0), '2')],
      next: '3',
      direction: dir,
      targetLow: lo,
      targetHigh: hi,
      invalidation: 0,
      score: 0.7,
      notes: const [],
      legBars: 5,
    );

void main() {
  test('every timeframe has its own colour: 5m red, 15m yellow, 30m blue, 1h orange', () {
    expect(timeframeColors.keys.toSet(), Timeframe.values.toSet());
    expect(timeframeColors.values.toSet(), hasLength(Timeframe.values.length));
    double hue(Timeframe f) => HSVColor.fromColor(colorOf(f)).hue;
    expect(hue(Timeframe.m5), anyOf(lessThan(15), greaterThan(345)), reason: 'red');
    expect(hue(Timeframe.m15), inInclusiveRange(40, 65), reason: 'yellow');
    expect(hue(Timeframe.m30), inInclusiveRange(195, 240), reason: 'blue');
    expect(hue(Timeframe.h1), inInclusiveRange(25, 40), reason: 'orange');
  });

  test('neighbouring timeframes are far apart in hue (no gradient)', () {
    double diff(Color a, Color b) {
      final d = (HSVColor.fromColor(a).hue - HSVColor.fromColor(b).hue).abs();
      return d > 180 ? 360 - d : d;
    }
    for (var i = 1; i < Timeframe.values.length; i++) {
      final a = Timeframe.values[i - 1], b = Timeframe.values[i];
      expect(diff(colorOf(a), colorOf(b)), greaterThanOrEqualTo(40), reason: '${a.label} vs ${b.label}');
    }
  });

  group('indexAt', () {
    final c = hourly(10);
    test('candle start is i-0.5, centre is i', () {
      expect(indexAt(c, Timeframe.h1, t0.add(const Duration(hours: 3))), closeTo(2.5, 1e-9));
      expect(indexAt(c, Timeframe.h1, t0.add(const Duration(hours: 3, minutes: 30))), closeTo(3, 1e-9));
    });
    test('extrapolates before the first and after the last candle', () {
      expect(indexAt(c, Timeframe.h1, t0.subtract(const Duration(hours: 2))), closeTo(-2.5, 1e-9));
      expect(indexAt(c, Timeframe.h1, t0.add(const Duration(hours: 15))), closeTo(14.5, 1e-9));
    });
    test('a 5m moment inside a 1h candle lands inside that candle', () {
      final i = indexAt(c, Timeframe.h1, t0.add(const Duration(hours: 4, minutes: 5)));
      expect(i, inInclusiveRange(3.5, 4.5));
    });
  });

  test('Layer places pivots at candle centres and projects into the future', () {
    final c = hourly(10);
    final l = Layer.of(Timeframe.h1, zone(1, 2, 3, pivotIndex: 4), c);
    expect(indexAt(c, Timeframe.h1, l.points.single.time), closeTo(4, 1e-9));
    expect(l.projectTo.isAfter(c.last.start), isTrue);
    expect(l.color, colorOf(Timeframe.h1));
  });

  group('findConfluence', () {
    test('same-direction overlapping zones', () {
      final c = findConfluence({
        Timeframe.m5: zone(1, 100, 110),
        Timeframe.h1: zone(1, 105, 120),
      });
      expect(c, hasLength(1));
      expect(c.single.frames, [Timeframe.m5, Timeframe.h1]);
      expect([c.single.low, c.single.high], [105, 110]);
      expect(c.single.direction, 1);
    });
    test('opposite directions or touching edges are not confluence', () {
      expect(findConfluence({Timeframe.m5: zone(1, 100, 110), Timeframe.h1: zone(-1, 105, 120)}), isEmpty);
      expect(findConfluence({Timeframe.m5: zone(1, 100, 110), Timeframe.h1: zone(1, 110, 120)}), isEmpty);
    });
    test('pairs spanning more degrees come first', () {
      final c = findConfluence({
        Timeframe.m5: zone(1, 100, 110),
        Timeframe.m15: zone(1, 100, 110),
        Timeframe.h4: zone(1, 100, 110),
      });
      expect(c.first.frames, [Timeframe.m5, Timeframe.h4]);
      expect(c, hasLength(3));
    });
  });

  test('alignment counts directions', () {
    final a = alignment({Timeframe.m5: zone(1, 1, 2), Timeframe.h1: zone(1, 1, 2), Timeframe.h4: zone(-1, 1, 2)});
    expect(a.up, 2);
    expect(a.down, 1);
  });
}
