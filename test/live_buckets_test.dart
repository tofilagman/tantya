// Volume buckets on real Binance data. Skipped by default (needs the network); run with
//   BUCKETS=BTCUSDT,ETHUSDT flutter test test/live_buckets_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tantya/sources/binance.dart';
import 'package:tantya/volume_profile.dart';

void main() {
  final spec = Platform.environment['BUCKETS'];
  test('live volume buckets', () async {
    for (final symbol in spec!.split(',')) {
      final daily = await BinanceSource(symbol).volumeHistory(3)!;
      final b = VolumeBuckets.build(daily)!;
      final price = daily.last.close;
      String m(double v) => v >= 1e9 ? '\$${(v / 1e9).toStringAsFixed(1)}B' : '\$${(v / 1e6).toStringAsFixed(0)}M';
      String p(double v) => v.toStringAsFixed(v >= 100 ? 0 : 4);
      // ignore: avoid_print
      print('$symbol: ${daily.length} days, price ${p(price)}');
      for (final y in b.years) {
        final (lo, hi) = y.valueArea();
        // ignore: avoid_print
        print('  ${y.year}: ${m(y.total)} traded · POC ${p(b.priceMid(y.pocBin))} · value area '
            '${p(b.priceLow(lo))}–${p(b.priceHigh(hi))} · ${(b.shareAbove(y, price) * 100).round()}% above today');
      }
      final z = b.nearestZones(price);
      // ignore: avoid_print
      print('  heaviest above: ${z.above == null ? '—' : '${p(z.above!.low)}–${p(z.above!.high)} (${z.above!.year}, ${m(z.above!.volume)})'}'
          '\n  heaviest below: ${z.below == null ? '—' : '${p(z.below!.low)}–${p(z.below!.high)} (${z.below!.year}, ${m(z.below!.volume)})'}');
    }
  }, skip: spec == null ? 'set BUCKETS=SYMBOL[,SYMBOL] to run' : false, timeout: const Timeout(Duration(minutes: 5)));
}
