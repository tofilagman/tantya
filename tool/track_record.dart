// Updates the public track record. Run hourly by .github/workflows/track-record.yml:
//   dart run tool/track_record.dart <data-dir>
// Reads <data-dir>/signals.json, settles open signals on fresh candles, logs any new
// signal on the fixed pair list, and rewrites signals.json, summary.json and README.md.
// Prints a one-line change summary (used as the commit message).
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:tantya/candles.dart';
import 'package:tantya/track_record.dart';
import 'package:tantya/trade.dart';

const _rest = 'https://data-api.binance.vision';
const _intervals = {Timeframe.h1: '1h', Timeframe.h4: '4h'};

Future<List<Candle>> _klines(http.Client client, String symbol, Timeframe f, {int limit = 301, DateTime? start}) async {
  final uri = Uri.parse('$_rest/api/v3/klines').replace(queryParameters: {
    'symbol': symbol,
    'interval': _intervals[f]!,
    'limit': '$limit',
    if (start != null) 'startTime': '${start.millisecondsSinceEpoch}',
  });
  final res = await client.get(uri).timeout(const Duration(seconds: 20));
  if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
  return [
    for (final k in jsonDecode(res.body) as List)
      Candle(
        DateTime.fromMillisecondsSinceEpoch(k[0] as int, isUtc: true),
        double.parse(k[1] as String),
        double.parse(k[2] as String),
        double.parse(k[3] as String),
        double.parse(k[4] as String),
        double.parse(k[5] as String),
      ),
  ];
}

Future<void> main(List<String> args) async {
  final dir = Directory(args.isEmpty ? 'track' : args.first)..createSync(recursive: true);
  final file = File('${dir.path}/signals.json');
  final record = file.existsSync() ? TrackRecord.fromJson(jsonDecode(file.readAsStringSync()) as List) : TrackRecord([]);
  final sha = Platform.environment['GITHUB_SHA'];
  final engine = sha == null || sha.length < 7 ? 'local' : sha.substring(0, 7);
  // Local dry runs only: widen the entry window (minutes) to see signals mid-candle.
  final delay = Duration(minutes: int.tryParse(Platform.environment['TRACK_MAX_DELAY_MIN'] ?? '') ?? maxEntryDelay.inMinutes);
  final client = http.Client();
  final now = DateTime.now().toUtc();
  var added = 0, settled = 0, errors = 0;

  for (final symbol in trackPairs) {
    for (final frame in trackFrames) {
      try {
        final candles = await _klines(client, symbol, frame);
        for (final s in record.signals.where((s) => s.symbol == symbol && s.frame == frame && s.status == SetupStatus.open)) {
          // Normally covered by the latest 301 candles; fetch from the entry if not.
          final history = candles.first.start.isAfter(s.candleOpen)
              ? await _klines(client, symbol, frame, limit: expiryCandles + 1, start: s.candleOpen)
              : candles;
          s.settle(history, now);
          if (s.status != SetupStatus.open) settled++;
        }
        final s = PublicSignal.detect(symbol, frame, candles, now, engine: engine, maxDelay: delay);
        if (s != null && record.add(s)) added++;
      } catch (e) {
        errors++;
        stderr.writeln('$symbol ${frame.label}: $e');
      }
    }
  }
  client.close();

  const enc = JsonEncoder.withIndent(' ');
  file.writeAsStringSync('${enc.convert(record.toJson())}\n');
  File('${dir.path}/summary.json').writeAsStringSync('${enc.convert({
        'updated': now.toIso8601String(),
        'since': record.since?.toIso8601String(),
        'pairs': trackPairs,
        'frames': [for (final f in trackFrames) f.name],
        'takerFee': takerFee,
        'all': record.stats.toJson(),
        'byFrame': {for (final e in record.byFrame.entries) e.key.name: e.value.toJson()},
        'byEvidence': {for (final e in record.byEvidence.entries) e.key.name: e.value.toJson()},
      })}\n');
  File('${dir.path}/README.md').writeAsStringSync(_readme(record, now));
  stdout.writeln('Track record: $added new, $settled closed${errors > 0 ? ', $errors errors' : ''}');
}

String _f(double? v, [int d = 2]) => v == null ? '—' : (v >= 0 ? '+' : '') + v.toStringAsFixed(d);
String _pct(double? v) => v == null ? '—' : '${(v * 100).round()}%';

String _row(String name, TrackStats s) =>
    '| $name | ${s.closed.length} | ${s.open} | ${_pct(s.hitRate)} | ${_f(s.avgR)} | ${_f(s.avgNetR)} | ${_f(s.totalNetR, 1)} | ${s.maxDrawdownR.toStringAsFixed(1)} |';

String _readme(TrackRecord r, DateTime now) {
  final b = StringBuffer()
    ..writeln('# Tantya public track record')
    ..writeln()
    ..writeln('Every setup the Tantya Elliott Wave engine produces on ${trackPairs.length} Binance pairs '
        '(${trackFrames.map((f) => f.label).join(', ')}), logged automatically by a scheduled GitHub Action '
        'when it appears and settled later. Nothing is chosen by hand and nothing is deleted: '
        'the [commit history]($trackRecordHistory) shows each signal was published before its outcome.')
    ..writeln()
    ..writeln('Rules: enter at the price when the signal is published; stop beyond the invalidation level '
        '(+½ ATR); take profit at TP1; a candle touching both counts as the stop; closed at market after '
        '$expiryCandles candles. Net R deducts ${(takerFee * 100).toStringAsFixed(1)}% taker fees on entry and exit. '
        'Not financial advice — an out-of-sample test before launch found **no edge** after fees.')
    ..writeln()
    ..writeln('Updated ${now.toIso8601String().substring(0, 16)} UTC · since ${r.since?.toIso8601String().substring(0, 10) ?? '—'}')
    ..writeln()
    ..writeln('| | Closed | Open | Hit rate | Avg R | Avg net R | Total net R | Max DD (R) |')
    ..writeln('|---|---:|---:|---:|---:|---:|---:|---:|')
    ..writeln(_row('**All**', r.stats));
  for (final e in r.byFrame.entries) {
    b.writeln(_row(e.key.label, e.value));
  }
  for (final e in r.byEvidence.entries) {
    b.writeln(_row('Evidence ${e.key.name}', e.value));
  }
  b
    ..writeln()
    ..writeln('## Latest signals')
    ..writeln()
    ..writeln('| Published (UTC) | Pair | TF | Side | Entry | Stop | TP1 | Wave | Evidence | Status | Net R |')
    ..writeln('|---|---|---|---|---:|---:|---:|---|---|---|---:|');
  for (final s in r.signals.take(50)) {
    b.writeln('| ${s.madeAt.toIso8601String().substring(0, 16)} | ${s.symbol} | ${s.frame.label} | ${s.side.name} | '
        '${s.entry} | ${s.stop.toStringAsPrecision(6)} | ${s.tp1.toStringAsPrecision(6)} | ${s.wave} | '
        '${s.evidenceLevel?.name ?? '—'} | ${s.status.name} | ${_f(s.netR)} |');
  }
  b
    ..writeln()
    ..writeln('All signals: [signals.json](signals.json) · totals: [summary.json](summary.json)');
  return b.toString();
}
