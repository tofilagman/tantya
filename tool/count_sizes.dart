// Diagnostic: how big are the primary counts across the top pairs?
// Usage: dart run tool/count_sizes.dart [interval] [pairs]
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:tantya/candles.dart';
import 'package:tantya/elliott.dart';

Future<dynamic> get(String url) async {
  final c = HttpClient();
  final res = await (await c.getUrl(Uri.parse(url))).close();
  final body = await res.transform(utf8.decoder).join();
  c.close();
  return jsonDecode(body);
}

Future<void> main(List<String> args) async {
  final interval = args.isNotEmpty ? args[0] : '1h';
  final n = args.length > 1 ? int.parse(args[1]) : 50;
  final tickers = (await get('https://data-api.binance.vision/api/v3/ticker/24hr') as List)
      .cast<Map<String, dynamic>>()
      .where((t) => (t['symbol'] as String).endsWith('USDT'))
      .toList()
    ..sort((a, b) => double.parse(b['quoteVolume']).compareTo(double.parse(a['quoteVolume'])));
  stdout.writeln('symbol        span  bars%  amp%   fit  size  score  title');
  final spans = <int>[];
  for (final t in tickers.take(n)) {
    final k = await get('https://data-api.binance.vision/api/v3/klines?symbol=${t['symbol']}&interval=$interval&limit=300') as List;
    final candles = k.map((r) => Candle(DateTime.fromMillisecondsSinceEpoch(r[0]), double.parse(r[1]), double.parse(r[2]), double.parse(r[3]), double.parse(r[4]))).toList();
    final p = analyze(candles).primary;
    if (p == null) continue;
    final idx = p.points.map((w) => w.pivot.index);
    final prices = p.points.map((w) => w.pivot.price);
    final span = idx.reduce(math.max) - idx.reduce(math.min);
    final hi = candles.map((c) => c.high).reduce(math.max), lo = candles.map((c) => c.low).reduce(math.min);
    final amp = (prices.reduce(math.max) - prices.reduce(math.min)) / (hi - lo);
    stdout.writeln('${(t['symbol'] as String).padRight(12)} ${span.toString().padLeft(5)} '
        '${(span / candles.length * 100).toStringAsFixed(0).padLeft(5)} ${(amp * 100).toStringAsFixed(0).padLeft(5)} '
        '${p.fit.toStringAsFixed(2).padLeft(5)} ${p.size.toStringAsFixed(2).padLeft(5)} '
        '${p.score.toStringAsFixed(2).padLeft(6)}  ${p.title}');
    spans.add(span);
  }
  spans.sort();
  stdout.writeln('\nprimaries: ${spans.length} · median span ${spans[spans.length ~/ 2]} candles · '
      'under 10 candles: ${spans.where((s) => s < 10).length}');
}
