import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart' show DateFormat;

import '../evidence.dart';
import '../track_record.dart';
import '../trade.dart';
import 'widgets.dart';

/// The public track record, as published by the hourly job on the `track-record` branch.
class TrackRecordScreen extends StatefulWidget {
  const TrackRecordScreen({super.key});

  @override
  State<TrackRecordScreen> createState() => _TrackRecordScreenState();
}

enum _Show { all, open, closed }

class _TrackRecordScreenState extends State<TrackRecordScreen> {
  TrackRecord? _record;
  DateTime? _updated;
  Object? _error;
  _Show _show = _Show.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$trackRecordRaw/signals.json')),
        http.get(Uri.parse('$trackRecordRaw/summary.json')),
      ]).timeout(const Duration(seconds: 20));
      if (responses.first.statusCode == 404) throw 'the record hasn\'t started yet';
      for (final r in responses) {
        if (r.statusCode != 200) throw 'HTTP ${r.statusCode}';
      }
      final record = TrackRecord.fromJson(jsonDecode(responses[0].body) as List);
      final summary = jsonDecode(responses[1].body) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _record = record;
        _updated = DateTime.tryParse(summary['updated'] as String? ?? '');
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _copyLink() {
    Clipboard.setData(const ClipboardData(text: trackRecordPage));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied')));
  }

  @override
  Widget build(BuildContext context) {
    final r = _record;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Public track record'),
        actions: [IconButton(tooltip: 'Copy link', icon: const Icon(Icons.link), onPressed: _copyLink)],
      ),
      body: r == null
          ? _error != null
              ? ErrorRetry(error: _error!, onRetry: _load)
              : const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                children: [
                  _Summary(record: r, updated: _updated),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final s in _Show.values)
                        ChoiceChip(
                          label: Text(switch (s) {
                            _Show.all => 'All',
                            _Show.open => 'Open',
                            _Show.closed => 'Closed',
                          }),
                          selected: _show == s,
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) => setState(() => _show = s),
                        ),
                    ],
                  ),
                  for (final s in r.signals
                      .where((s) => switch (_show) {
                            _Show.all => true,
                            _Show.open => s.status == SetupStatus.open,
                            _Show.closed => s.status != SetupStatus.open,
                          })
                      .take(200))
                    _SignalTile(s),
                  if (r.signals.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No signals yet. The job checks every hour.', textAlign: TextAlign.center),
                    ),
                ],
              ),
            ),
    );
  }
}

String _r(double r) => '${r >= 0 ? '+' : ''}${r.toStringAsFixed(2)}';
Color? _rColor(double? r) => r == null ? null : (r >= 0 ? Colors.green.shade600 : Colors.red.shade400);

class _Summary extends StatelessWidget {
  const _Summary({required this.record, this.updated});
  final TrackRecord record;
  final DateTime? updated;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final st = record.stats;
    final fmt = DateFormat('MMM d, HH:mm');
    final since = record.since;
    Widget stat(String label, String value, {Color? color}) => Expanded(
          child: Column(
            children: [
              Text(value, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: color)),
              Text(label, style: text.labelSmall, textAlign: TextAlign.center),
            ],
          ),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Every setup the engine produces on ${trackPairs.length} Binance pairs '
              '(${trackFrames.map((f) => f.label).join(' and ')}), logged automatically every hour and settled by the '
              'same rules as your tracked setups. None are picked by hand or removed.',
              style: text.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              [
                if (since != null) 'Since ${fmt.format(since.toLocal())}',
                if (updated != null) 'updated ${fmt.format(updated!.toLocal())}',
              ].join(' · '),
              style: text.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                stat('closed', '${st.closed.length}'),
                stat('open', '${st.open}'),
                stat('hit rate', st.hitRate == null ? '—' : '${(st.hitRate! * 100).round()}%'),
                stat('avg R\nafter fees', st.avgNetR == null ? '—' : _r(st.avgNetR!), color: _rColor(st.avgNetR)),
              ],
            ),
            if (st.closed.length >= 2) ...[
              const SizedBox(height: 12),
              SizedBox(height: 90, child: CustomPaint(painter: _EquityPainter(st.equity, Theme.of(context).colorScheme))),
              const SizedBox(height: 4),
              Text(
                'Total ${_r(st.totalNetR)} R after fees (${_r(st.totalR)} R before) · max drawdown '
                '${st.maxDrawdownR.toStringAsFixed(1)} R',
                style: text.bodySmall,
              ),
            ],
            const Divider(height: 24),
            _Table(rows: [
              for (final MapEntry(key: f, value: s) in record.byFrame.entries) (f.label, s),
              for (final MapEntry(key: e, value: s) in record.byEvidence.entries)
                (
                  switch (e) {
                    EvidenceLevel.strong => 'Strong evidence',
                    EvidenceLevel.mixed => 'Mixed evidence',
                    EvidenceLevel.weak => 'Weak evidence',
                  },
                  s
                ),
            ]),
            const SizedBox(height: 12),
            Text(
              'Before this record started, a test over 30 pairs and about 14,500 past setups found no edge after '
              'fees: the setups were roughly breakeven before fees and lost after them. This record checks that '
              'live, in public. Use the wave count to read the chart, not as a signal to trade blindly. '
              'Fees: ${(takerFee * 100).toStringAsFixed(1)}% on entry and exit.',
              style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _Table extends StatelessWidget {
  const _Table({required this.rows});
  final List<(String, TrackStats)> rows;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = text.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    Widget cells(String a, String b, String c, String d, {TextStyle? style, Color? dColor}) => Row(
          children: [
            Expanded(flex: 4, child: Text(a, style: style)),
            Expanded(flex: 3, child: Text(b, style: style, textAlign: TextAlign.end)),
            Expanded(flex: 2, child: Text(c, style: style, textAlign: TextAlign.end)),
            Expanded(
              flex: 3,
              child: Text(d,
                  style: style?.copyWith(color: dColor, fontWeight: dColor == null ? null : FontWeight.w700),
                  textAlign: TextAlign.end),
            ),
          ],
        );
    return Column(
      children: [
        cells('', 'closed (open)', 'hit', 'net R', style: muted),
        for (final (label, s) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: cells(
              label,
              '${s.closed.length}${s.open > 0 ? ' (${s.open})' : ''}',
              s.hitRate == null ? '—' : '${(s.hitRate! * 100).round()}%',
              s.avgNetR == null ? '—' : _r(s.avgNetR!),
              style: text.bodyMedium,
              dColor: _rColor(s.avgNetR),
            ),
          ),
      ],
    );
  }
}

class _EquityPainter extends CustomPainter {
  _EquityPainter(this.equity, this.colors);
  final List<double> equity;
  final ColorScheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    final values = [0.0, ...equity];
    final lo = math.min(0.0, values.reduce(math.min)), hi = math.max(0.0, values.reduce(math.max));
    final span = hi - lo == 0 ? 1.0 : hi - lo;
    double y(double v) => size.height - (v - lo) / span * size.height;
    double x(int i) => i / (values.length - 1) * size.width;
    canvas.drawLine(Offset(0, y(0)), Offset(size.width, y(0)),
        Paint()..color = colors.outlineVariant..strokeWidth = 1);
    final path = Path()..moveTo(0, y(0));
    for (var i = 1; i < values.length; i++) {
      path.lineTo(x(i), y(values[i]));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = values.last >= 0 ? Colors.green.shade600 : Colors.red.shade400
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_EquityPainter old) => old.equity != equity;
}

class _SignalTile extends StatelessWidget {
  const _SignalTile(this.s);
  final PublicSignal s;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final long = s.side == Side.long;
    final (label, color) = switch (s.status) {
      SetupStatus.open => ('OPEN', Colors.blueGrey),
      SetupStatus.target => ('TARGET', Colors.green.shade600),
      SetupStatus.stopped => ('STOPPED', Colors.red.shade400),
      SetupStatus.expired => ('EXPIRED', Colors.grey),
    };
    String p(double v) => v.toStringAsPrecision(6).replaceFirst(RegExp(r'\.?0+$'), '');
    final net = s.netR;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(long ? 'LONG' : 'SHORT',
                    style: text.labelLarge?.copyWith(
                        color: long ? Colors.green.shade600 : Colors.red.shade400, fontWeight: FontWeight.w800)),
                const SizedBox(width: 8),
                Expanded(child: Text('${s.symbol} · ${s.frame.label}', style: text.titleSmall)),
                if (net != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text('${_r(net)} R',
                        style: text.labelLarge?.copyWith(color: _rColor(net), fontWeight: FontWeight.w700)),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                  child: Text(label, style: text.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              [
                s.count,
                if (s.evidence != null) 'evidence ${(s.evidence! * 100).round()}%',
                if (s.adx != null) 'ADX ${s.adx!.round()}',
              ].join(' · '),
              style: text.bodySmall,
            ),
            const SizedBox(height: 2),
            Text(
              'Entry ${p(s.entry)} · stop ${p(s.stop)} · TP1 ${p(s.tp1)}'
              '${s.exit != null && s.status == SetupStatus.expired ? ' · closed ${p(s.exit!)}' : ''}',
              style: text.bodySmall,
            ),
            Text(
              '${DateFormat('MMM d, HH:mm').format(s.madeAt.toLocal())}'
              '${s.closedAt != null ? ' → ${DateFormat('MMM d, HH:mm').format(s.closedAt!.toLocal())}' : ''}',
              style: text.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
