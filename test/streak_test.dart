import 'package:flutter_test/flutter_test.dart';
import 'package:tantya/candles.dart';
import 'package:tantya/streak.dart';

void main() {
  final t0 = DateTime.utc(2026, 10, 12);
  const m3 = Duration(minutes: 3);
  // 60 flat-ish alternating candles, then a run of red ones.
  List<Candle> series(int reds) {
    final out = <Candle>[];
    var p = 100.0;
    for (var i = 0; i < 60 + reds; i++) {
      final red = i >= 60 || i.isEven;
      final next = red ? p - (i >= 60 ? 1.0 : 0.2) : p + 0.2;
      out.add(Candle(t0.add(m3 * i), p, (p > next ? p : next) + 0.1, (p < next ? p : next) - 0.1, next));
      p = next;
    }
    return out;
  }

  test('fires once per red streak, at the third candle', () {
    final s = detectStreaks(series(8), m3, cfg: const StreakConfig(macd: false, confirm: false));
    final drops = s.where((x) => x.index >= 60).toList();
    expect(drops.single.index, 62);
    expect(drops.single.dir, -1);
    expect(drops.single.extreme, closeTo(100.1, 1e-9)); // high of the streak's first candle
  });

  test('higher-timeframe candles are built only from candles up to the signal', () {
    final low = series(8);
    final htf = htfAt(low, 62, m3 * 5, count: 2);
    expect(htf.last.start, t0.add(const Duration(minutes: 180))); // bucket of candle 60
    expect(htf.last.close, low[62].close); // the forming candle stops at 62
  });

  test('full signal needs MACD and the 15m confirmation', () {
    final full = detectStreaks(series(12), m3).where((x) => x.index >= 60).toList();
    expect(full, isNotEmpty);
    expect(full.first.index, greaterThanOrEqualTo(62));
    expect(full.every((x) => x.dir == -1), isTrue);
  });
}
