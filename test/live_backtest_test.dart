// Backtests on real Binance history. Skipped by default (needs the network); run with
//   BACKTEST=BTCUSDT,ETHUSDT:1h:3000 flutter test test/live_backtest_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tantya/backtest.dart';
import 'package:tantya/candles.dart';
import 'package:tantya/evidence.dart';
import 'package:tantya/indicators.dart';
import 'package:tantya/sources/binance.dart';

void main() {
  final spec = Platform.environment['BACKTEST'];
  test('live backtest', () async {
    final parts = spec!.split(':');
    final frame = Timeframe.values.firstWhere((f) => BinanceApi.intervalOf(f) == (parts.length > 1 ? parts[1] : '1h'));
    final n = parts.length > 2 ? int.parse(parts[2]) : 2000;
    String f(double? v, [int d = 2]) => v == null ? '—' : v.toStringAsFixed(d);
    for (final symbol in parts[0].split(',')) {
      final candles = await BinanceApi().longHistory(symbol, frame, n);
      final sw = Stopwatch()..start();
      final r = runBacktest(candles, frame, const BacktestConfig());
      sw.stop();
      // ignore: avoid_print
      print('$symbol ${frame.label}: ${candles.length} candles ${r.from} → ${r.to} (${sw.elapsedMilliseconds} ms)\n'
          '  trades ${r.trades.length} · wins ${r.wins} · losses ${r.losses} · expired ${r.expired} · '
          'hit ${f(r.hitRate == null ? null : r.hitRate! * 100, 0)}% · avg R ${f(r.avgR)} · total ${f(r.totalR, 1)} R · '
          'max DD ${f(r.maxDrawdownR, 1)} R · worst streak ${r.longestLosingStreak}');
      for (final MapEntry(key: e, value: g)
          in r.groupBy((t) => EvidenceReport.levelOf(t.evidence), EvidenceLevel.values).entries) {
        // ignore: avoid_print
        print('    evidence ${e.name}: ${g.trades.length} trades · hit ${f(g.hitRate == null ? null : g.hitRate! * 100, 0)}% · avg R ${f(g.avgR)}');
      }
      for (final MapEntry(key: m, value: g) in r.groupBy((t) => t.macd, MacdVerdict.values).entries) {
        // ignore: avoid_print
        print('    MACD ${m.name}: ${g.trades.length} trades · hit ${f(g.hitRate == null ? null : g.hitRate! * 100, 0)}% · avg R ${f(g.avgR)}');
      }
      for (final MapEntry(key: w, value: g)
          in r.groupBy((t) => t.wave, const ['1', '2', '3', '4', '5', 'A', 'B', 'C']).entries) {
        // ignore: avoid_print
        print('    wave $w: ${g.trades.length} trades · hit ${f(g.hitRate == null ? null : g.hitRate! * 100, 0)}% · avg R ${f(g.avgR)}');
      }
    }
  }, skip: spec == null ? 'set BACKTEST=SYMBOL[,SYMBOL]:interval:candles to run' : false, timeout: const Timeout(Duration(minutes: 10)));
}
