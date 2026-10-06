import 'package:flutter_test/flutter_test.dart';
import 'package:tantya/candles.dart';
import 'package:tantya/elliott.dart';
import 'package:tantya/mtf.dart';
import 'package:tantya/setup.dart';
import 'package:tantya/sources/binance.dart';
import 'package:tantya/sources/source.dart';

final t0 = DateTime(2026, 10, 6, 10);
Candle c(int min, double lo, double hi, [double? close]) =>
    Candle(t0.add(Duration(minutes: min)), lo, hi, lo, close ?? hi);

TrackedSetup longSetup() => TrackedSetup(
      id: 'x',
      source: BinanceSource('BTCUSDT', base: 'BTC', quote: 'USDT'),
      frame: Timeframe.m5,
      side: Side.long,
      entry: 100,
      stop: 95,
      tp1: 110,
      tp2: 120,
      count: 'Impulse ↑ · wave 3 in progress',
      fit: 0.7,
      madeAt: t0,
    );

Scenario scenario({required int dir, required double lo, required double hi, required double inval, required double start}) =>
    Scenario(
      kind: ScenarioKind.impulse,
      trend: dir,
      points: [WavePoint(Pivot(0, start, high: dir < 0), '2')],
      next: '3',
      direction: dir,
      targetLow: lo,
      targetHigh: hi,
      invalidation: inval,
      score: 0.7,
      notes: const [],
      legBars: 5,
    );

void main() {
  group('TradeSetup.from', () {
    test('long: entry now, stop at invalidation, TP1 near edge, R:R', () {
      final s = TradeSetup.from(scenario(dir: 1, lo: 110, hi: 120, inval: 95, start: 97), 100)!;
      expect(s.side, Side.long);
      expect([s.entry, s.stop, s.tp1, s.tp2], [100, 95, 110, 120]);
      expect(s.rr1, 2);
      expect(s.rr2, 4);
      expect(s.poorRR, isFalse);
    });

    test('short uses the high edge of the zone as TP1', () {
      final s = TradeSetup.from(scenario(dir: -1, lo: 80, hi: 90, inval: 105, start: 103), 100)!;
      expect(s.side, Side.short);
      expect(s.tp1, 90);
      expect(s.tp2, 80);
      expect(s.stop, 105);
    });

    test('invalidation on the target side → stop at the wave start instead', () {
      // e.g. wave 2 down: invalid below wave-1 origin (past target); a short is wrong above wave 1's end.
      final s = TradeSetup.from(scenario(dir: -1, lo: 90, hi: 94, inval: 85, start: 104), 100)!;
      expect(s.stop, 104);
    });

    test('buffer pushes the stop beyond invalidation, away from the trade', () {
      final long = TradeSetup.from(scenario(dir: 1, lo: 110, hi: 120, inval: 95, start: 97), 100, buffer: 1)!;
      expect(long.stop, 94);
      final short = TradeSetup.from(scenario(dir: -1, lo: 80, hi: 90, inval: 105, start: 103), 100, buffer: 1)!;
      expect(short.stop, 106);
    });

    test('atr is the mean true range', () {
      final cs = [Candle(t0, 10, 11, 9, 10), Candle(t0, 10, 12, 10, 11), Candle(t0, 11, 11, 8, 9)];
      expect(atr(cs), closeTo((2 + 3) / 2, 1e-9));
    });

    test('no setup once price is past TP1', () {
      expect(TradeSetup.from(scenario(dir: 1, lo: 110, hi: 120, inval: 95, start: 97), 111), isNull);
    });
  });

  group('TrackedSetup.resolve', () {
    test('target first', () {
      final s = longSetup()..resolve([c(0, 99, 101), c(5, 100, 106), c(10, 104, 111)], t0.add(const Duration(hours: 1)));
      expect(s.status, SetupStatus.target);
      expect(s.resultR, 2);
    });

    test('stop first', () {
      final s = longSetup()..resolve([c(0, 99, 101), c(5, 94, 100), c(10, 104, 111)], t0.add(const Duration(hours: 1)));
      expect(s.status, SetupStatus.stopped);
      expect(s.resultR, -1);
    });

    test('a candle spanning both counts as the stop (conservative)', () {
      final s = longSetup()..resolve([c(0, 94, 111)], t0.add(const Duration(hours: 1)));
      expect(s.status, SetupStatus.stopped);
    });

    test('candles that closed before the setup are ignored', () {
      final s = longSetup()..resolve([c(-10, 90, 100), c(-5, 92, 100), c(0, 99, 101)], t0.add(const Duration(minutes: 3)));
      expect(s.status, SetupStatus.open);
    });

    test('expires after 50 candles at the last price', () {
      final candles = [for (var i = 0; i < 60; i++) c(i * 5, 99, 102.5, 102.5)];
      final s = longSetup()..resolve(candles, t0.add(const Duration(hours: 6)));
      expect(s.status, SetupStatus.expired);
      expect(s.resultR, closeTo(0.5, 1e-9));
    });

    test('stays open before expiry when nothing is hit', () {
      final s = longSetup()..resolve([c(0, 99, 102)], t0.add(const Duration(minutes: 30)));
      expect(s.status, SetupStatus.open);
      expect(s.resultR, isNull);
    });
  });

  test('scorecard: hit rate excludes expiries, avg R includes them', () {
    final win = longSetup()..resolve([c(0, 100, 111)], t0.add(const Duration(hours: 1)));
    final loss = longSetup()..resolve([c(0, 94, 100)], t0.add(const Duration(hours: 1)));
    final exp = longSetup()..resolve([for (var i = 0; i < 60; i++) c(i * 5, 99, 100, 100)], t0.add(const Duration(hours: 6)));
    final open = longSetup();
    final card = Scorecard([win, loss, exp, open]);
    expect(card.open, 1);
    expect(card.hitRate, 0.5);
    expect(card.totalR, closeTo(2 - 1 + 0, 1e-9));
    expect(card.avgR, closeTo(1 / 3, 1e-9));
  });

  test('scorecard splits results by higher-timeframe verdict', () {
    TrackedSetup make(HtfVerdict? v) => TrackedSetup(
          id: 'x', source: BinanceSource('BTCUSDT'), frame: Timeframe.m5, side: Side.long,
          entry: 100, stop: 95, tp1: 110, tp2: 120, count: 'c', fit: 0.7, madeAt: t0, htf: v);
    final now = t0.add(const Duration(hours: 1));
    final card = Scorecard([
      make(HtfVerdict.agree)..resolve([c(0, 100, 111)], now), // +2
      make(HtfVerdict.agree)..resolve([c(0, 94, 100)], now), // -1
      make(HtfVerdict.conflict)..resolve([c(0, 94, 100)], now), // -1
      make(null)..resolve([c(0, 100, 111)], now), // unchecked: not in the split
      make(HtfVerdict.agree), // open: not in the split
    ]);
    final split = card.byHtf;
    expect(split.keys, unorderedEquals([HtfVerdict.agree, HtfVerdict.conflict]));
    expect(split[HtfVerdict.agree]!.closed.length, 2);
    expect(split[HtfVerdict.agree]!.open, 0, reason: 'open setups are not part of the verdict split');
    expect(split[HtfVerdict.agree]!.avgR, closeTo(0.5, 1e-9));
    expect(split[HtfVerdict.agree]!.hitRate, 0.5);
    expect(split[HtfVerdict.conflict]!.avgR, -1);
    final back = TrackedSetup.fromJson(make(HtfVerdict.conflict).toJson());
    expect(back.htf, HtfVerdict.conflict);
    expect(TrackedSetup.fromJson(make(null).toJson()).htf, isNull);
  });

  test('scorecard per timeframe: grouped, ordered small to large, open counted', () {
    TrackedSetup make(Timeframe f) => TrackedSetup(
          id: 'x', source: BinanceSource('BTCUSDT'), frame: f, side: Side.long,
          entry: 100, stop: 95, tp1: 110, tp2: 120, count: 'c', fit: 0.7, madeAt: t0);
    final now = t0.add(const Duration(days: 30));
    final card = Scorecard([
      make(Timeframe.h4)..resolve([c(0, 100, 111)], now), // +2
      make(Timeframe.m5)..resolve([c(0, 94, 100)], now), // -1
      make(Timeframe.m5)..resolve([c(0, 94, 100)], now), // -1
      make(Timeframe.h4), // open
      make(Timeframe.h1), // open only
    ]);
    final f = card.byFrame;
    expect(f.keys.toList(), [Timeframe.m5, Timeframe.h1, Timeframe.h4]);
    expect(f[Timeframe.m5]!.avgR, -1);
    expect(f[Timeframe.m5]!.hitRate, 0);
    expect(f[Timeframe.h4]!.closed.length, 1);
    expect(f[Timeframe.h4]!.open, 1);
    expect(f[Timeframe.h4]!.avgR, 2);
    expect(f[Timeframe.h1]!.avgR, isNull, reason: 'nothing closed yet');
    expect(f[Timeframe.h1]!.open, 1);
    // Sub-scorecards are full scorecards: they can be split again.
    expect(f[Timeframe.m5]!.byHtf, isEmpty);
  });

  test('tracked setup round-trips through JSON with its source', () {
    final s = longSetup()..resolve([c(0, 100, 111)], t0.add(const Duration(hours: 1)));
    final back = TrackedSetup.fromJson(s.toJson());
    expect(back.source.id, 'binance:BTCUSDT');
    expect(back.source, isA<CandleSource>());
    expect(back.status, SetupStatus.target);
    expect(back.resultR, 2);
    expect(back.frame, Timeframe.m5);
  });

  group('Binance ticker', () {
    Ticker t(String s) => Ticker(symbol: s, last: 1, changePct: 0, quoteVolume: 1, trades: 1);
    test('pair split and mainstream filter', () {
      expect(t('BTCUSDT').pair, ('BTC', 'USDT'));
      expect(t('ETHBTC').pair, ('ETH', 'BTC'));
      expect(t('BTCUSDT').mainstream, isTrue);
      expect(t('USDCUSDT').mainstream, isFalse);
      expect(t('BTCUPUSDT').mainstream, isFalse);
      expect(t('ETHBTC').mainstream, isFalse);
    });
    test('decimals by price', () {
      expect(decimalsFor(86058), 2);
      expect(decimalsFor(2.5), 4);
      expect(decimalsFor(0.00001234), 8);
    });
  });
}
