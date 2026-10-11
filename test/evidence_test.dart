import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:tantya/candles.dart';
import 'package:tantya/elliott.dart';
import 'package:tantya/evidence.dart';
import 'package:tantya/indicators.dart';

final t0 = DateTime(2026, 10, 1);

/// Candles from (close, volume) pairs; high/low a hair around the close.
List<Candle> series(List<(double, double)> xs) => [
      for (var i = 0; i < xs.length; i++)
        Candle(t0.add(Duration(hours: i)), i == 0 ? xs[0].$1 : xs[i - 1].$1, math.max(xs[i].$1, i == 0 ? xs[0].$1 : xs[i - 1].$1) + 0.01,
            math.min(xs[i].$1, i == 0 ? xs[0].$1 : xs[i - 1].$1) - 0.01, xs[i].$1, xs[i].$2),
    ];

/// Builder: a flat warm-up (so EMA 200 exists), then legs. Records each leg's end index.
class Path {
  Path(double start, {int warmup = 210}) {
    for (var i = 0; i < warmup; i++) {
      pts.add((start, 100));
    }
    pivots.add(pts.length - 1);
  }
  final pts = <(double, double)>[];
  final pivots = <int>[];

  /// A leg to [to] over [bars] candles at [volume] each. [curve] > 1 accelerates.
  void leg(double to, int bars, double volume, {double curve = 1}) {
    final from = pts.last.$1;
    for (var i = 1; i <= bars; i++) {
      pts.add((from + (to - from) * math.pow(i / bars, curve), volume));
    }
    pivots.add(pts.length - 1);
  }

  List<Candle> get candles => series(pts);

  Scenario scenario(ScenarioKind kind, String next, {required int confirmedLegs, int dir = 1}) {
    const imp = ['', '1', '2', '3', '4', '5', 'A', 'B'];
    const cor = ['', 'A', 'B', 'C'];
    return Scenario(
      kind: kind,
      trend: pts[pivots[1]].$1 > pts[pivots[0]].$1 ? 1 : -1,
      points: [
        for (var i = 0; i <= confirmedLegs; i++)
          WavePoint(Pivot(pivots[i], pts[pivots[i]].$1, high: i > 0 && pts[pivots[i]].$1 > pts[pivots[i - 1]].$1),
              kind == ScenarioKind.impulse ? imp[i] : cor[i]),
      ],
      next: next,
      direction: dir,
      targetLow: 0,
      targetHigh: 1,
      invalidation: 0,
      score: 0.7,
      notes: const [],
      legBars: 5,
    );
  }
}

Evidence item(EvidenceReport r, String startsWith) => r.items.firstWhere((e) => e.label.startsWith(startsWith));

void main() {
  group('indicators', () {
    test('RSI: all gains → 100, alternating ±1 → 50', () {
      final up = rsi(series([for (var i = 0; i < 30; i++) (i.toDouble(), 1)]));
      expect(up[13], isNull);
      expect(up[14], 100);
      expect(up.last, 100);
      final flat = rsi(series([for (var i = 0; i < 30; i++) (i.isEven ? 10.0 : 11.0, 1)]));
      expect(flat[14], closeTo(50, 1e-9));
    });

    test('CCI: flat → 0; steady trend → mean deviation maths (≈126.7 for n=20)', () {
      final flat = cci(series([for (var i = 0; i < 30; i++) (5.0, 1)]));
      expect(flat[18], isNull);
      expect(flat[19], 0);
      // Typical price is linear; window mean lags by 9.5, mean deviation is 5.
      final candles = [for (var i = 0; i < 40; i++) Candle(t0, i.toDouble(), i.toDouble(), i.toDouble(), i.toDouble())];
      expect(cci(candles).last, closeTo(9.5 / (0.015 * 5), 1e-9));
    });

    test('waveVolume averages the candles after the start pivot', () {
      final c = series([(1, 10), (2, 20), (3, 30), (4, 40)]);
      expect(waveVolume(c, 0, 2), 25); // candles 1 and 2
      expect(waveVolume(series([(1, 0), (2, 0)]), 0, 1), isNull);
    });

    test('EMA stack needs 200 candles for EMA 200', () {
      final ind = Indicators.of(series([for (var i = 0; i < 100; i++) (i.toDouble(), 1)]));
      expect(ind.ema50.last, isNotNull);
      expect(ind.ema200.last, isNull);
    });
  });

  group('templates', () {
    test('healthy wave 3: EMAs stacked, volume above wave 2, MACD speeding up, CCI strong', () {
      final p = Path(100)
        ..leg(110, 20, 100)
        ..leg(105, 10, 50)
        ..leg(125, 15, 250, curve: 2); // accelerating, heavy
      final r = evidenceReport(p.scenario(ScenarioKind.impulse, '3', confirmedLegs: 2), Indicators.of(p.candles));
      expect(r.title, 'Healthy wave 3?');
      expect(item(r, 'EMAs').ok, isTrue);
      expect(item(r, 'Volume').ok, isTrue);
      expect(item(r, 'MACD').ok, isTrue);
      expect(item(r, 'CCI').ok, isTrue);
      expect(r.items, hasLength(5));
    });

    test('a wave 3 on falling volume is flagged', () {
      final p = Path(100)
        ..leg(110, 20, 100)
        ..leg(105, 10, 300)
        ..leg(115, 15, 80);
      final r = evidenceReport(p.scenario(ScenarioKind.impulse, '3', confirmedLegs: 2), Indicators.of(p.candles));
      expect(item(r, 'Volume').ok, isFalse);
    });

    test('wave 5 exhaustion: new high on weaker MACD, RSI, CCI and volume', () {
      final p = Path(100)
        ..leg(110, 20, 100)
        ..leg(105, 10, 50)
        ..leg(130, 15, 300) // steep, heavy wave 3
        ..leg(122, 10, 60)
        ..leg(133, 30, 80); // gentle, light wave 5 to a marginal new high
      final r = evidenceReport(p.scenario(ScenarioKind.impulse, '5', confirmedLegs: 4), Indicators.of(p.candles));
      expect(r.title, 'Wave 5 exhaustion?');
      expect(item(r, 'Price past').ok, isTrue);
      expect(item(r, 'MACD weaker').ok, isTrue);
      expect(item(r, 'RSI weaker').ok, isTrue);
      expect(item(r, 'Volume lower').ok, isTrue);
      expect(r.level, EvidenceLevel.strong);
    });

    test('completed impulse (wave A next) still reads the wave 5 just finished', () {
      final p = Path(100)
        ..leg(110, 20, 100)
        ..leg(105, 10, 50)
        ..leg(130, 15, 300)
        ..leg(122, 10, 60)
        ..leg(133, 30, 80);
      final r = evidenceReport(p.scenario(ScenarioKind.impulse, 'A', confirmedLegs: 5, dir: -1), Indicators.of(p.candles));
      expect(r.title, 'Wave 5 exhaustion?');
    });

    test('other waves: pullback on lighter volume fits a wave 4', () {
      final p = Path(100)
        ..leg(110, 20, 100)
        ..leg(105, 10, 50)
        ..leg(130, 15, 300)
        ..leg(124, 8, 90);
      final r = evidenceReport(p.scenario(ScenarioKind.impulse, '4', confirmedLegs: 3, dir: -1), Indicators.of(p.candles));
      expect(r.title, startsWith('Evidence for wave 4 down'));
      expect(item(r, 'Pullback on lighter volume').ok, isTrue);
    });
  });

  test('a wave that starts on the latest candle says so instead of "no volume data"', () {
    final p = Path(100)
      ..leg(110, 20, 100)
      ..leg(105, 10, 50);
    final r = evidenceReport(p.scenario(ScenarioKind.impulse, '3', confirmedLegs: 2), Indicators.of(p.candles));
    expect(item(r, 'Volume').detail, 'wave 3 just started');
    expect(item(r, 'Volume').ok, isNull);
  });

  test('evidence levels: ≥⅔ strong, ≥⅓ mixed, else weak', () {
    expect(EvidenceReport.levelOf(0.8), EvidenceLevel.strong);
    expect(EvidenceReport.levelOf(0.5), EvidenceLevel.mixed);
    expect(EvidenceReport.levelOf(0.2), EvidenceLevel.weak);
    expect(EvidenceReport.levelOf(null), isNull);
  });
}
