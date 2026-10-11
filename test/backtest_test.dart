import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:tantya/backtest.dart';
import 'package:tantya/candles.dart';
import 'package:tantya/setup.dart';

final t0 = DateTime(2026, 1, 1);

/// A seeded random walk with swings, so the engine finds counts to trade.
List<Candle> market(int n, {int seed = 7}) {
  final rnd = math.Random(seed);
  final out = <Candle>[];
  var p = 100.0;
  for (var i = 0; i < n; i++) {
    final drift = math.sin(i / 23) * 0.6 + math.sin(i / 71) * 0.9;
    final next = p * (1 + (drift + (rnd.nextDouble() - 0.5) * 1.6) / 100);
    final hi = math.max(p, next) * (1 + rnd.nextDouble() * 0.003);
    final lo = math.min(p, next) * (1 - rnd.nextDouble() * 0.003);
    out.add(Candle(t0.add(Duration(hours: i)), p, hi, lo, next, 100 + rnd.nextDouble() * 50));
    p = next;
  }
  return out;
}

BacktestTrade trade({Side side = Side.long, int at = 0}) => BacktestTrade(
      entryIndex: at,
      madeAt: t0,
      side: side,
      entry: 100,
      stop: 95,
      tp1: 110,
      tp2: 120,
      count: 'c',
      wave: '3',
      score: 0.7,
      evidence: null,
      macd: null,
    );

Candle bar(int i, double lo, double hi, [double? close]) => Candle(t0.add(Duration(hours: i)), lo, hi, lo, close ?? hi);

void main() {
  group('settleTrade', () {
    test('target, stop, both-in-one-candle = stop, expiry at the close', () {
      final win = trade();
      settleTrade(win, [bar(0, 99, 101), bar(1, 99, 105), bar(2, 104, 111)]);
      expect([win.status, win.exitIndex, win.r], [SetupStatus.target, 2, 2]);

      final loss = trade();
      settleTrade(loss, [bar(0, 99, 101), bar(1, 94, 100)]);
      expect([loss.status, loss.r], [SetupStatus.stopped, -1]);

      final both = trade();
      settleTrade(both, [bar(0, 99, 101), bar(1, 94, 111)]);
      expect(both.status, SetupStatus.stopped);

      final slow = trade();
      settleTrade(slow, [for (var i = 0; i <= expiryCandles + 5; i++) bar(i, 99, 102.5, 102.5)]);
      expect(slow.status, SetupStatus.expired);
      expect(slow.exitIndex, expiryCandles);
      expect(slow.r, closeTo(0.5, 1e-9));
    });

    test('short mirrors long', () {
      final s = BacktestTrade(
          entryIndex: 0, madeAt: t0, side: Side.short, entry: 100, stop: 105, tp1: 90, tp2: 80,
          count: 'c', wave: 'A', score: 0.6, evidence: null, macd: null);
      settleTrade(s, [bar(0, 99, 101), bar(1, 89, 100)]);
      expect([s.status, s.r], [SetupStatus.target, 2]);
    });

    test('not enough candles after entry: stays open', () {
      final t = trade();
      settleTrade(t, [bar(0, 99, 101), bar(1, 99, 102)]);
      expect(t.status, SetupStatus.open);
    });
  });

  test('stats: equity, drawdown, streak, hit rate', () {
    BacktestTrade done(double r, SetupStatus st) => trade()
      ..status = st
      ..exit = 100 + r * 5;
    final res = BacktestResult([
      done(2, SetupStatus.target),
      done(-1, SetupStatus.stopped),
      done(-1, SetupStatus.stopped),
      done(-1, SetupStatus.stopped),
      done(0.5, SetupStatus.expired),
      done(2, SetupStatus.target),
    ], candles: 0, from: t0, to: t0, steps: 0);
    expect(res.equity, [2, 1, 0, -1, -0.5, 1.5]);
    expect(res.maxDrawdownR, 3);
    expect(res.longestLosingStreak, 3);
    expect(res.hitRate, 2 / 5);
    expect(res.avgR, closeTo(1.5 / 6, 1e-9));
    expect(res.groupBy((t) => t.status, SetupStatus.values).keys,
        [SetupStatus.target, SetupStatus.stopped, SetupStatus.expired]);
  });

  test('finds trades on a realistic series, one at a time, all closed', () {
    final candles = market(1200);
    final res = runBacktest(candles, Timeframe.h1, const BacktestConfig());
    expect(res.trades, isNotEmpty);
    for (var i = 0; i < res.trades.length; i++) {
      final t = res.trades[i];
      expect(t.status, isNot(SetupStatus.open));
      expect(t.exitIndex! > t.entryIndex, isTrue);
      if (i > 0) expect(t.entryIndex > res.trades[i - 1].exitIndex!, isTrue, reason: 'no overlapping trades');
      expect(t.entryIndex, greaterThanOrEqualTo(299), reason: 'needs a full 300-candle window');
    }
  });

  test('no look-ahead: adding later candles never changes earlier trades', () {
    final full = market(1400);
    final short = runBacktest(full.sublist(0, 900), Timeframe.h1, const BacktestConfig());
    final long = runBacktest(full, Timeframe.h1, const BacktestConfig());
    expect(short.trades, isNotEmpty);
    for (var i = 0; i < short.trades.length; i++) {
      final a = short.trades[i], b = long.trades[i];
      expect([b.entryIndex, b.side, b.entry, b.stop, b.tp1, b.status, b.exitIndex],
          [a.entryIndex, a.side, a.entry, a.stop, a.tp1, a.status, a.exitIndex]);
    }
  });

  test('filters: higher minimum R:R never adds trades with lower R:R', () {
    final candles = market(1200);
    final strict = runBacktest(candles, Timeframe.h1, const BacktestConfig(minRR: 2));
    for (final t in strict.trades) {
      expect((t.tp1 - t.entry).abs() / t.risk, greaterThanOrEqualTo(2 - 1e-9));
    }
  });
}
