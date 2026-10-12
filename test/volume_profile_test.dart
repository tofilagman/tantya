import 'package:flutter_test/flutter_test.dart';
import 'package:tantya/candles.dart';
import 'package:tantya/volume_profile.dart';

Candle day(int y, int m, int d, double lo, double hi, double vol) =>
    Candle(DateTime(y, m, d, 12), lo, hi, lo, hi, vol);

void main() {
  test('one bucket per calendar year, oldest first; older years dropped', () {
    final b = VolumeBuckets.build([
      day(2023, 6, 1, 10, 20, 100), // outside the 3-year window
      day(2024, 3, 1, 10, 20, 100),
      day(2025, 3, 1, 10, 20, 100),
      day(2026, 3, 1, 10, 20, 100),
    ], bins: 10)!;
    expect(b.years.map((y) => y.year), [2024, 2025, 2026]);
  });

  test('volume is quote value, spread evenly over the candle\'s range', () {
    final b = VolumeBuckets.build([day(2026, 1, 2, 10, 20, 3)], bins: 10)!;
    final y = b.years.single;
    // quote = 3 × (20 + 10 + 20)/3 = 50, over 10 bins of 1 → 5 each
    expect(y.total, closeTo(50, 1e-9));
    for (final v in y.volume) {
      expect(v, closeTo(5, 1e-9));
    }
  });

  test('POC, value area and share above a price', () {
    final b = VolumeBuckets.build([
      day(2026, 1, 1, 0, 100, 1), // thin, everywhere
      day(2026, 1, 2, 60, 70, 40), // heavy cluster at 60–70
    ], bins: 10)!;
    final y = b.years.single;
    expect(b.priceMid(y.pocBin), 65);
    final (lo, hi) = y.valueArea();
    expect(b.priceLow(lo) <= 60 && b.priceHigh(hi) >= 70, isTrue);
    // Above 50: the whole cluster plus half the thin candle
    final total = y.total;
    final expected = (40 * (60 + 70 + 70) / 3 + 1 * (0 + 100 + 100) / 3 * 0.5) / total;
    expect(b.shareAbove(y, 50), closeTo(expected, 1e-9));
    expect(b.shareAbove(y, 100), 0);
    expect(b.shareAbove(y, 0), closeTo(1, 1e-9));
  });

  test('nearest heavy zones above and below, attributed to the year that built them', () {
    final b = VolumeBuckets.build([
      day(2024, 5, 1, 0, 100, 1),
      day(2025, 5, 1, 0, 100, 1),
      day(2025, 6, 1, 80, 90, 30), // 2025 bought heavily at 80–90
      day(2026, 5, 1, 20, 30, 30), // 2026 heavy at 20–30
    ], bins: 10)!;
    final z = b.nearestZones(50);
    expect(z.above!.low, 80);
    expect(z.above!.high, 90);
    expect(z.above!.year, 2025);
    expect(z.below!.low, 20);
    expect(z.below!.year, 2026);
  });

  test('no volume → no buckets', () {
    expect(VolumeBuckets.build([]), isNull);
    expect(VolumeBuckets.build([day(2026, 1, 1, 1, 2, 0)]), isNull);
  });
}
