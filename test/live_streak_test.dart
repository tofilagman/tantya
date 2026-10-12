// Tests the "streak" signal on real Binance history. Skipped by default (needs the network):
//   STREAKS=BTCUSDT,ETHUSDT:3m:20000 [FACTOR=5] flutter test test/live_streak_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:tantya/candles.dart';
import 'package:tantya/streak.dart';

Future<List<Candle>> fetch(String symbol, String interval, int count) async {
  final out = <Candle>[];
  int? end;
  while (out.length < count) {
    final limit = math.min(1000, count - out.length);
    final uri = Uri.parse('https://data-api.binance.vision/api/v3/klines').replace(queryParameters: {
      'symbol': symbol, 'interval': interval, 'limit': '$limit', if (end != null) 'endTime': '$end',
    });
    final rows = jsonDecode((await http.get(uri)).body) as List;
    if (rows.isEmpty) break;
    final page = [
      for (final k in rows)
        Candle(DateTime.fromMillisecondsSinceEpoch(k[0] as int, isUtc: true), double.parse(k[1] as String),
            double.parse(k[2] as String), double.parse(k[3] as String), double.parse(k[4] as String),
            double.parse(k[5] as String)),
    ];
    out.insertAll(0, page);
    end = page.first.start.millisecondsSinceEpoch - 1;
    if (page.length < limit) break;
  }
  return out;
}

class Tally {
  final fwd = <int, List<double>>{for (final h in horizons) h: []};
  final trades = <double>[], net = <double>[];
  static const horizons = [5, 10, 20, 40];

  void add(List<Candle> c, StreakSignal s) {
    final e = c[s.index].close;
    for (final h in horizons) {
      if (s.index + h < c.length) fwd[h]!.add(s.dir * (c[s.index + h].close - e) / e);
    }
    // Trade: stop past the streak's extreme, target 1R, closed after 20 candles.
    final risk = (e - s.extreme).abs();
    if (risk <= 0 || s.index + 20 >= c.length) return;
    final target = e + s.dir * risk;
    double? exit;
    for (var j = s.index + 1; j <= s.index + 20; j++) {
      if (s.dir < 0 ? c[j].high >= s.extreme : c[j].low <= s.extreme) { exit = s.extreme; break; }
      if (s.dir < 0 ? c[j].low <= target : c[j].high >= target) { exit = target; break; }
    }
    exit ??= c[s.index + 20].close;
    final r = s.dir * (exit - e) / risk;
    trades.add(r);
    net.add(r - 0.001 * (e + exit) / risk);
  }

  String get line {
    String pct(List<double> v) => v.isEmpty ? '—' : '${(v.where((x) => x > 0).length / v.length * 100).round()}%';
    String bps(List<double> v) => v.isEmpty ? '—' : (v.reduce((a, b) => a + b) / v.length * 1e4).toStringAsFixed(1);
    double avg(List<double> v) => v.isEmpty ? double.nan : v.reduce((a, b) => a + b) / v.length;
    return 'n=${fwd[5]!.length.toString().padLeft(5)} | continued after 5 candles ${pct(fwd[5]!)} 10 ${pct(fwd[10]!)} '
        '20 ${pct(fwd[20]!)} 40 ${pct(fwd[40]!)} | avg move after 20 ${bps(fwd[20]!)} bps | '
        'trade 1R: win ${pct(trades)} avgR ${avg(trades).toStringAsFixed(3)} net ${avg(net).toStringAsFixed(3)}';
  }
}

void main() {
  final spec = Platform.environment['STREAKS'];
  test('live streaks', () async {
    final parts = spec!.split(':');
    final interval = parts.length > 1 ? parts[1] : '3m';
    final n = parts.length > 2 ? int.parse(parts[2]) : 20000;
    final size = Duration(minutes: int.parse(interval.replaceAll('m', '')));
    // Low-timeframe candles per higher one: 5 for 3m → 15m, 4 for 15m → 1h.
    final f = int.parse(Platform.environment['FACTOR'] ?? '5');
    final configs = {
      'A streak only        ': StreakConfig(macd: false, confirm: false, factor: f),
      'B + MACD             ': StreakConfig(confirm: false, factor: f),
      'C + MACD + higher x2 ': StreakConfig(factor: f),
      'D + MACD + higher x3 ': StreakConfig(highRun: 3, factor: f),
      'E higher x2, no MACD ': StreakConfig(macd: false, factor: f),
    };
    final total = {for (final k in configs.keys) k: Tally()};
    final halves = {for (final k in configs.keys) k: [Tally(), Tally()]};
    final byDir = {for (final k in configs.keys) k: {-1: Tally(), 1: Tally()}};
    for (final sym in parts[0].split(',')) {
      final c = await fetch(sym, interval, n);
      for (final MapEntry(key: k, value: cfg) in configs.entries) {
        for (final s in detectStreaks(c, size, cfg: cfg)) {
          total[k]!.add(c, s);
          halves[k]![s.index < c.length ~/ 2 ? 0 : 1].add(c, s);
          byDir[k]![s.dir]!.add(c, s);
        }
      }
      // ignore: avoid_print
      print('$sym: ${c.length} candles ${c.first.start.toIso8601String().substring(0, 10)} → ${c.last.start.toIso8601String().substring(0, 10)}');
    }
    for (final k in configs.keys) {
      // ignore: avoid_print
      print('$k ${total[k]!.line}\n'
          '    first half  ${halves[k]![0].line}\n    second half ${halves[k]![1].line}\n'
          '    drops       ${byDir[k]![-1]!.line}\n    rises       ${byDir[k]![1]!.line}');
    }
  }, skip: spec == null ? 'set STREAKS=SYMBOL[,SYMBOL]:3m:candles to run' : false, timeout: const Timeout(Duration(minutes: 30)));
}
