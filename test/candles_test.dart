import 'package:flutter_test/flutter_test.dart';
import 'package:tantya/candles.dart';
import 'package:tantya/live.dart';

DateTime at(int h, int m) => DateTime(2026, 10, 6, h, m);
({DateTime time, double price}) p(int h, int m, double price) => (time: at(h, m), price: price);

void main() {
  group('buildCandles', () {
    test('groups samples into buckets with OHLC', () {
      final c = buildCandles([
        p(10, 0, 0.50), p(10, 20, 0.55), p(10, 40, 0.48), p(10, 59, 0.52),
        p(11, 5, 0.60), p(11, 30, 0.58),
      ], Timeframe.h1);
      expect(c, hasLength(2));
      expect([c[0].open, c[0].high, c[0].low, c[0].close], [0.50, 0.55, 0.48, 0.52]);
      expect(c[0].start, at(10, 0));
    });

    test('each candle opens at the previous close', () {
      final c = buildCandles([p(10, 30, 0.50), p(11, 30, 0.60)], Timeframe.h1);
      expect(c[1].open, 0.50);
      expect(c[1].low, 0.50);
      expect(c[1].high, 0.60);
    });

    test('sorts unordered input', () {
      final c = buildCandles([p(11, 0, 0.6), p(10, 0, 0.5)], Timeframe.h1);
      expect(c.first.start, at(10, 0));
    });
  });

  test('daily candles start at local midnight', () {
    expect(Timeframe.d1.bucketOf(DateTime(2026, 10, 6, 7, 30)), DateTime(2026, 10, 6));
    expect(Timeframe.d1.bucketOf(DateTime(2026, 10, 6, 23, 59)), DateTime(2026, 10, 6));
  });

  group('applyTick', () {
    test('extends the current candle', () {
      final c = buildCandles([p(10, 0, 0.50)], Timeframe.h1);
      expect(applyTick(c, Timeframe.h1, at(10, 30), 0.57), isTrue);
      expect(c.single.high, 0.57);
      expect(c.single.close, 0.57);
    });

    test('opens a new candle in a later bucket and caps the series', () {
      final c = [for (var i = 0; i < 5; i++) Candle(at(4, i * 5), .5, .5, .5, .5)];
      applyTick(c, Timeframe.m5, at(4, 25), 0.6, maxCandles: 5);
      expect(c, hasLength(5));
      expect(c.last.open, 0.5);
      expect(c.last.close, 0.6);
    });

    test('ignores ticks older than the last candle', () {
      final c = buildCandles([p(11, 0, 0.50)], Timeframe.h1);
      expect(applyTick(c, Timeframe.h1, at(10, 30), 0.9), isFalse);
      expect(c.single.high, 0.50);
    });
  });

  group('mergeCandle', () {
    test('replaces the in-progress candle, appends the next, ignores stale', () {
      final c = [Candle(at(10, 0), 1, 2, 0.5, 1.5, 10)];
      expect(mergeCandle(c, Candle(at(10, 0), 1, 2.5, 0.5, 2.2, 12)), isTrue);
      expect(c.single.close, 2.2);
      expect(c.single.volume, 12);
      mergeCandle(c, Candle(at(11, 0), 2.2, 2.3, 2.1, 2.25, 1));
      expect(c, hasLength(2));
      expect(mergeCandle(c, Candle(at(9, 0), 1, 1, 1, 1)), isFalse);
    });
  });

  group('QuoteState', () {
    const token = 'T';
    final now = DateTime.utc(2026);

    test('book sets top of book regardless of level order', () {
      final s = QuoteState();
      final q = s.apply({
        'event_type': 'book',
        'asset_id': token,
        'bids': [{'price': '0.01', 'size': '1'}, {'price': '0.58', 'size': '1'}],
        'asks': [{'price': '0.99', 'size': '1'}, {'price': '0.60', 'size': '1'}],
        'timestamp': '1791295894834',
      }, token, now);
      expect(q!.price, closeTo(0.59, 1e-9));
      expect(q.time.millisecondsSinceEpoch, 1791295894834);
    });

    test('price_change only uses our asset', () {
      final s = QuoteState()..bid = 0.40..ask = 0.42;
      expect(s.apply({
        'event_type': 'price_change',
        'price_changes': [{'asset_id': 'other', 'best_bid': '0.1', 'best_ask': '0.2'}],
      }, token, now), isNull);
      final q = s.apply({
        'event_type': 'price_change',
        'price_changes': [{'asset_id': token, 'best_bid': '0.44', 'best_ask': '0.46'}],
      }, token, now);
      expect(q!.price, closeTo(0.45, 1e-9));
    });

    test('unchanged price emits nothing, but a trade always emits', () {
      final s = QuoteState()..bid = 0.40..ask = 0.42;
      final same = {'event_type': 'price_change', 'price_changes': [{'asset_id': token, 'best_bid': '0.40', 'best_ask': '0.42'}]};
      expect(s.apply(same, token, now), isNull);
      final t = s.apply({'event_type': 'last_trade_price', 'asset_id': token, 'price': '0.41', 'size': '10'}, token, now);
      expect(t!.trade, isTrue);
      expect(t.price, closeTo(0.41, 1e-9)); // still the midpoint
    });

    test('wide spread falls back to last trade', () {
      final s = QuoteState()..bid = 0.20..ask = 0.60..lastTrade = 0.33;
      expect(s.price, 0.33);
      s.lastTrade = null;
      expect(s.price, closeTo(0.40, 1e-9));
    });
  });
}
