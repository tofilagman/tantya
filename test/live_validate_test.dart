// Dumps every backtest trade (unfiltered) per pair to CSV, for out-of-sample validation
// of filters such as evidence level and ADX. Skipped by default (needs the network):
//   VALIDATE=BTCUSDT,ETHUSDT:1h:5000 OUT=/tmp/trades.csv flutter test test/live_validate_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tantya/backtest.dart';
import 'package:tantya/candles.dart';
import 'package:tantya/setup.dart';
import 'package:tantya/sources/binance.dart';

void main() {
  final spec = Platform.environment['VALIDATE'];
  test('live validate', () async {
    final parts = spec!.split(':');
    final frame = Timeframe.values.firstWhere((f) => BinanceApi.intervalOf(f) == (parts.length > 1 ? parts[1] : '1h'));
    final n = parts.length > 2 ? int.parse(parts[2]) : 5000;
    final out = File(Platform.environment['OUT'] ?? 'trades.csv');
    final sink = out.openWrite()
      ..writeln('symbol,frame,made_at,side,entry,stop,tp1,exit,status,r,wave,score,evidence,macd,adx');
    for (final symbol in parts[0].split(',')) {
      try {
        final candles = await BinanceApi().longHistory(symbol, frame, n);
        final r = runBacktest(candles, frame, const BacktestConfig());
        for (final t in r.trades) {
          sink.writeln([
            symbol, frame.label, t.madeAt.toUtc().toIso8601String(), t.side == Side.long ? 'long' : 'short',
            t.entry, t.stop, t.tp1, t.exit, t.status.name, t.r, t.wave, t.score.toStringAsFixed(3),
            t.evidence?.toStringAsFixed(3) ?? '', t.macd?.name ?? '', t.adx?.toStringAsFixed(1) ?? '',
          ].join(','));
        }
        // ignore: avoid_print
        print('$symbol: ${r.trades.length} trades, total ${r.totalR.toStringAsFixed(1)} R');
      } catch (e) {
        // ignore: avoid_print
        print('$symbol: failed ($e)');
      }
    }
    await sink.close();
  }, skip: spec == null ? 'set VALIDATE=SYMBOL[,SYMBOL]:interval:candles to run' : false, timeout: const Timeout(Duration(minutes: 60)));
}
