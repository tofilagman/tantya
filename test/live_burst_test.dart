// Momentum bursts on real Binance data. Skipped by default (needs the network); run with
//   BURSTS=BTCUSDT,ETHUSDT:5m,1h flutter test test/live_burst_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tantya/burst.dart';
import 'package:tantya/candles.dart';
import 'package:tantya/indicators.dart';
import 'package:tantya/sources/binance.dart';

void main() {
  final spec = Platform.environment['BURSTS'];
  test('live bursts', () async {
    final parts = spec!.split(':');
    final frames = parts[1].split(',').map((f) => Timeframe.values.firstWhere((x) => BinanceApi.intervalOf(x) == f));
    String pct(double? v) => v == null ? '—' : '${(v * 100).toStringAsFixed(0)}%';
    String ret(double? v) => v == null ? '—' : '${v >= 0 ? '+' : ''}${(v * 100).toStringAsFixed(2)}%';
    String r(double? v) => v == null ? '—' : '${v >= 0 ? '+' : ''}${v.toStringAsFixed(2)}';
    final totals = <String, List<BurstOutcome>>{};
    for (final f in frames) {
      for (final symbol in parts[0].split(',')) {
        final c = await BinanceApi().longHistory(symbol, f, 5000);
        final s = burstStats(c, detectBursts(c, Indicators.of(c)));
        (totals[f.label] ??= []).addAll(s.outcomes);
        // ignore: avoid_print
        print('$symbol ${f.label}: ${s.count} bursts · continued after 3/12/24: '
            '${pct(s.continuation(3))} ${pct(s.continuation(12))} ${pct(s.continuation(24))} · '
            'avg move 24: ${ret(s.avgForward(24))} · ride trade win ${pct(s.tradeWinRate)} avg R ${r(s.tradeAvgR)}');
      }
    }
    for (final MapEntry(key: f, value: o) in totals.entries) {
      final s = BurstStats(o);
      final strong = s.where((e) => e.strength == 4);
      // ignore: avoid_print
      print('ALL $f: ${s.count} bursts · continued ${pct(s.continuation(3))} / ${pct(s.continuation(12))} / ${pct(s.continuation(24))}'
          ' · ride win ${pct(s.tradeWinRate)} avg R ${r(s.tradeAvgR)}'
          ' | all-4-signal: ${strong.count} · cont24 ${pct(strong.continuation(24))} · avg R ${r(strong.tradeAvgR)}'
          ' | up ${s.where((e) => e.dir > 0).count} avgR ${r(s.where((e) => e.dir > 0).tradeAvgR)}'
          ' · down ${s.where((e) => e.dir < 0).count} avgR ${r(s.where((e) => e.dir < 0).tradeAvgR)}');
    }
  }, skip: spec == null ? 'set BURSTS=SYMBOL[,SYMBOL]:interval[,interval] to run' : false,
      timeout: const Timeout(Duration(minutes: 15)));
}
