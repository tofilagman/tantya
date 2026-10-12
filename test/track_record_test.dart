import 'package:flutter_test/flutter_test.dart';
import 'package:tantya/candles.dart';
import 'package:tantya/track_record.dart';
import 'package:tantya/trade.dart';

void main() {
  final t0 = DateTime.utc(2026, 10, 12, 10);
  PublicSignal long({DateTime? open}) => PublicSignal(
        symbol: 'BTCUSDT', frame: Timeframe.h1, side: Side.long,
        entry: 100, stop: 95, tp1: 110, tp2: 120,
        count: 'Impulse ↑ · wave 3', wave: '3', score: 0.6,
        candleOpen: open ?? t0, madeAt: t0.add(const Duration(minutes: 5)), engine: 'abc1234',
      );
  Candle c(int h, double hi, double lo, [double close = 100]) =>
      Candle(t0.add(Duration(hours: h)), 100, hi, lo, close);

  test('TP1 first is a win, net of fees', () {
    final s = long()..settle([c(0, 102, 99), c(1, 111, 98)], t0.add(const Duration(hours: 5)));
    expect(s.status, SetupStatus.target);
    expect(s.r, 2);
    expect(s.feeR, closeTo(0.001 * 210 / 5, 1e-12));
    expect(s.netR, closeTo(2 - 0.042, 1e-12));
    expect(s.closedAt, t0.add(const Duration(hours: 2)));
  });

  test('a candle touching both counts as the stop', () {
    final s = long()..settle([c(0, 111, 94)], t0.add(const Duration(hours: 2)));
    expect(s.status, SetupStatus.stopped);
    expect(s.r, -1);
  });

  test('candles before entry and still forming are ignored', () {
    final s = long()..settle([c(-1, 200, 50), c(0, 102, 99), c(1, 111, 98)], t0.add(const Duration(minutes: 90)));
    expect(s.status, SetupStatus.open); // the 11:00 candle hasn't closed yet
  });

  test('expires at the close of the 50th candle', () {
    final candles = [for (var h = 0; h < 60; h++) c(h, 101, 99, 102)];
    final s = long()..settle(candles, t0.add(const Duration(days: 5)));
    expect(s.status, SetupStatus.expired);
    expect(s.exit, 102);
    expect(s.closedAt, t0.add(const Duration(hours: expiryCandles)));
  });

  test('one open signal per pair and frame; no duplicates', () {
    final r = TrackRecord([]);
    expect(r.add(long()), isTrue);
    expect(r.add(long()), isFalse);
    expect(r.add(long(open: t0.add(const Duration(hours: 1)))), isFalse); // first still open
    r.signals.first.settle([c(0, 111, 99)], t0.add(const Duration(hours: 2)));
    expect(r.add(long(open: t0.add(const Duration(hours: 1)))), isTrue);
    expect(r.stats.closed, hasLength(1));
    expect(r.stats.open, 1);
  });

  test('JSON round trip', () {
    final s = long()..settle([c(0, 111, 99)], t0.add(const Duration(hours: 2)));
    final back = TrackRecord.fromJson([s.toJson()]).signals.single;
    expect(back.toJson(), s.toJson());
    expect(back.netR, s.netR);
  });

  test('stats: equity and drawdown use net R', () {
    final win = long()..settle([c(0, 111, 99)], t0.add(const Duration(hours: 2)));
    final loss = long(open: t0.add(const Duration(hours: 3)))..settle([c(3, 101, 94)], t0.add(const Duration(hours: 5)));
    final st = TrackStats([win, loss]);
    expect(st.hitRate, 0.5);
    expect(st.equity.first, win.netR);
    expect(st.maxDrawdownR, closeTo(-loss.netR!, 1e-12));
  });

  test('detect skips a candle that opened too long ago', () {
    final candles = [for (var h = -300; h <= 0; h++) c(h, 101, 99)];
    expect(PublicSignal.detect('X', Timeframe.h1, candles, t0.add(const Duration(minutes: 30))), isNull);
  });
}
