/// Volume "buckets": how much traded at each price level, one bucket per calendar
/// year (e.g. 2024, 2025, 2026), on a shared price grid so the years compare.
///
/// The idea (from the users): heavy volume that traded *above* today's price is
/// "trapped water in the bucket" — buyers from that year who still hold are at a
/// loss, and those levels tend to act as overhead supply when price comes back.
/// Exchange data shows what *traded* at a price, not who still holds, so this is
/// the standard estimate, not a position count.
library;

import 'dart:math' as math;

import 'candles.dart';

/// One year's volume by price, in quote currency (e.g. USDT).
class YearProfile {
  YearProfile(this.year, this.volume);

  final int year;

  /// Quote volume per price bin of the shared grid.
  final List<double> volume;

  double get total => volume.fold(0.0, (a, b) => a + b);

  /// Bin with the most volume: the Point of Control.
  int get pocBin {
    var best = 0;
    for (var i = 1; i < volume.length; i++) {
      if (volume[i] > volume[best]) best = i;
    }
    return best;
  }

  /// Bins holding [share] of the year's volume, grown outward from the POC, always
  /// taking the heavier neighbour next: the usual "value area" (70%).
  (int, int) valueArea([double share = 0.7]) {
    final target = total * share;
    var lo = pocBin, hi = pocBin;
    var sum = volume[pocBin];
    while (sum < target && (lo > 0 || hi < volume.length - 1)) {
      final down = lo > 0 ? volume[lo - 1] : -1.0;
      final up = hi < volume.length - 1 ? volume[hi + 1] : -1.0;
      if (up >= down) {
        hi++;
        sum += up;
      } else {
        lo--;
        sum += down;
      }
    }
    return (lo, hi);
  }
}

/// A price zone where a lot traded.
class VolumeZone {
  const VolumeZone(this.low, this.high, this.volume, this.year);
  final double low, high;
  final double volume;

  /// The year contributing most of the zone's volume.
  final int year;
}

class VolumeBuckets {
  VolumeBuckets(this.low, this.step, this.years);

  /// Bottom of the grid and bin height.
  final double low, step;

  /// Oldest year first.
  final List<YearProfile> years;

  int get bins => years.isEmpty ? 0 : years.first.volume.length;
  double priceLow(int bin) => low + bin * step;
  double priceHigh(int bin) => low + (bin + 1) * step;
  double priceMid(int bin) => low + (bin + 0.5) * step;

  /// All years together, per bin.
  List<double> get combined => [
        for (var i = 0; i < bins; i++) years.fold(0.0, (t, y) => t + y.volume[i]),
      ];

  /// Share of [y]'s volume that traded above [price] (bins straddling it count by
  /// the fraction above).
  double shareAbove(YearProfile y, double price) {
    if (y.total == 0) return 0;
    var above = 0.0;
    for (var i = 0; i < bins; i++) {
      final lo = priceLow(i), hi = priceHigh(i);
      if (lo >= price) {
        above += y.volume[i];
      } else if (hi > price) {
        above += y.volume[i] * (hi - price) / step;
      }
    }
    return above / y.total;
  }

  /// The heaviest cluster of volume above [price] (overhead supply: trapped buyers) and
  /// below it (where buyers stepped in before), across all years.
  ({VolumeZone? above, VolumeZone? below}) nearestZones(double price) {
    final all = combined;
    if (all.isEmpty) return (above: null, below: null);
    final avg = all.reduce((a, b) => a + b) / all.length;
    VolumeZone? best(bool up) {
      // Contiguous runs of heavy bins (≥ 1.5× average) on one side of the price; pick
      // the one with the most volume.
      VolumeZone? top;
      var i = 0;
      while (i < bins) {
        final side = up ? priceLow(i) >= price : priceHigh(i) <= price;
        if (!side || all[i] < avg * 1.5) {
          i++;
          continue;
        }
        final start = i;
        var vol = 0.0;
        final byYear = <int, double>{};
        while (i < bins && all[i] >= avg * 1.5 && (up ? priceLow(i) >= price : priceHigh(i) <= price)) {
          vol += all[i];
          for (final y in years) {
            byYear[y.year] = (byYear[y.year] ?? 0) + y.volume[i];
          }
          i++;
        }
        final year = byYear.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
        final z = VolumeZone(priceLow(start), priceHigh(i - 1), vol, year);
        if (top == null || z.volume > top.volume) top = z;
      }
      return top;
    }

    return (above: best(true), below: best(false));
  }

  /// Builds the buckets from daily candles: the current calendar year and the [years]
  /// − 1 before it. Each candle's quote volume is spread evenly over its high–low range.
  static VolumeBuckets? build(List<Candle> daily, {int years = 3, int bins = 100, DateTime? now}) {
    if (daily.isEmpty) return null;
    final lastYear = (now ?? daily.last.start).toLocal().year;
    final firstYear = lastYear - years + 1;
    final used = daily.where((c) => c.start.toLocal().year >= firstYear && c.volume > 0).toList();
    if (used.isEmpty) return null;
    final lo = used.map((c) => c.low).reduce(math.min);
    final hi = used.map((c) => c.high).reduce(math.max);
    if (hi <= lo) return null;
    final step = (hi - lo) / bins;
    final profiles = {
      for (var y = firstYear; y <= lastYear; y++) y: List<double>.filled(bins, 0),
    };
    for (final c in used) {
      final v = profiles[c.start.toLocal().year]!;
      final quote = c.volume * (c.high + c.low + c.close) / 3;
      final range = c.high - c.low;
      if (range <= 0) {
        v[((c.close - lo) / step).floor().clamp(0, bins - 1)] += quote;
        continue;
      }
      final b0 = ((c.low - lo) / step).floor().clamp(0, bins - 1);
      final b1 = ((c.high - lo) / step).floor().clamp(0, bins - 1);
      for (var b = b0; b <= b1; b++) {
        final overlap = math.min(c.high, lo + (b + 1) * step) - math.max(c.low, lo + b * step);
        if (overlap > 0) v[b] += quote * overlap / range;
      }
    }
    return VolumeBuckets(lo, step, [
      for (final e in profiles.entries)
        if (e.value.any((x) => x > 0)) YearProfile(e.key, e.value),
    ]);
  }
}
