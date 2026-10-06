import 'package:flutter_test/flutter_test.dart';
import 'package:tantya/candles.dart';
import 'package:tantya/elliott.dart';
import 'package:tantya/scanner.dart';
import 'package:tantya/setup.dart';
import 'package:tantya/sources/binance.dart';

final ticker = Ticker(symbol: 'BTCUSDT', last: 1, changePct: 0, quoteVolume: 1, trades: 1);

List<Candle> walk(List<double> path, {int bars = 6}) {
  final out = <Candle>[];
  var t = DateTime(2026, 10, 1);
  var prev = path.first;
  for (var leg = 1; leg < path.length; leg++) {
    for (var i = 1; i <= bars; i++) {
      final p = path[leg - 1] + (path[leg] - path[leg - 1]) * i / bars;
      final w = path.first * 0.005;
      out.add(Candle(t, prev, (p > prev ? p : prev) + w, (p < prev ? p : prev) - w, p));
      prev = p;
      t = t.add(const Duration(hours: 1));
    }
  }
  return out;
}

Scenario sc(double score) => Scenario(
      kind: ScenarioKind.impulse,
      trend: 1,
      points: [WavePoint(const Pivot(0, 97, high: false), '2')],
      next: '3',
      direction: 1,
      targetLow: 110,
      targetHigh: 120,
      invalidation: 95,
      score: score,
      notes: const [],
      legBars: 5,
    );

void main() {
  test('evaluatePair matches the chart pipeline: primary count, buffered stop', () {
    final candles = walk([20000, 30000, 25000, 41000, 35000, 45000, 44500]);
    final r = evaluatePair(ticker, candles)!;
    final a = analyze(candles);
    expect(r.scenario.key, a.primary!.key);
    expect(r.setup.stop, closeTo(a.primary!.stop - a.primary!.direction * atr(candles) * stopBufferAtr, 1e-6));
    expect(r.progress, inInclusiveRange(0, 1));
  });

  test('evaluatePair needs enough history', () {
    expect(evaluatePair(ticker, walk([1, 2, 1.5], bars: 3)), isNull);
  });

  group('rankSetup', () {
    final setup = TradeSetup.from(sc(0.8), 100)!; // R:R 2
    test('rewards fit, R:R (capped at 3), freshness and agreement', () {
      final base = rankSetup(setup, progress: 0, consensus: true);
      expect(base, closeTo(0.8 * 2 / 3, 1e-9));
      expect(rankSetup(setup, progress: 1, consensus: true), closeTo(base / 2, 1e-9));
      expect(rankSetup(setup, progress: 0, consensus: false), closeTo(base * 0.8, 1e-9));
      final big = TradeSetup.from(sc(0.8), 100, buffer: -4)!; // stop 99 → R:R 10, capped
      expect(rankSetup(big, progress: 0, consensus: true), closeTo(0.8, 1e-9));
    });
  });
}
