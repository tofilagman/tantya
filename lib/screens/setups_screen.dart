import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../candles.dart';
import '../indicators.dart';
import '../mtf.dart';
import '../setup.dart';
import '../sources/binance.dart';
import 'instrument_screen.dart';
import 'market_screen.dart';
import '../sources/polymarket_source.dart';

/// Tracked setups and the method's real track record.
class SetupsScreen extends StatefulWidget {
  const SetupsScreen({super.key});

  @override
  State<SetupsScreen> createState() => SetupsScreenState();
}

class SetupsScreenState extends State<SetupsScreen> {
  List<TrackedSetup>? _items;
  bool _busy = false;

  /// Shows one timeframe's setups and scorecard; null = all.
  Timeframe? _frame;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  /// Shows stored setups, then settles any open ones against fresh prices.
  Future<void> refresh() async {
    final stored = await SetupStore.load();
    if (!mounted) return;
    setState(() {
      _items = stored;
      _busy = true;
    });
    await SetupStore.resolveOpen();
    final items = await SetupStore.load();
    if (mounted) {
      setState(() {
        _items = items;
        _busy = false;
      });
    }
  }

  Future<void> _remove(TrackedSetup s) async {
    await SetupStore.remove(s.id);
    setState(() => _items!.removeWhere((e) => e.id == s.id));
  }

  void _open(TrackedSetup s) {
    final src = s.source;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => switch (src) {
        PolymarketSource() => MarketScreen(marketId: src.marketId),
        BinanceSource() => InstrumentScreen(source: src),
        _ => InstrumentScreen(source: src),
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    final all = _items;
    final frames = all == null ? const <Timeframe>[] : Scorecard(all).byFrame.keys.toList();
    final frame = frames.contains(_frame) ? _frame : null;
    final items = all?.where((s) => frame == null || s.frame == frame).toList();
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Text('Setups', style: Theme.of(context).textTheme.headlineSmall),
                const Spacer(),
                if (_busy) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
          ),
          Expanded(
            child: items == null
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                      children: [
                        if (frames.length > 1)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                for (final f in <Timeframe?>[null, ...frames])
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      label: Text(f?.label ?? 'All'),
                                      selected: f == frame,
                                      visualDensity: VisualDensity.compact,
                                      onSelected: (_) => setState(() => _frame = f),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        _ScoreCard(
                          Scorecard(items),
                          frame: frame,
                          onFrame: (f) => setState(() => _frame = f),
                        ),
                        if (items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'No setups yet. Open a chart and tap "Track this setup" to see whether the '
                              'wave count hits its target or its stop first.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        for (final s in items)
                          Dismissible(
                            key: ValueKey(s.id),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => _remove(s),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              color: Theme.of(context).colorScheme.errorContainer,
                              child: const Icon(Icons.delete_outline),
                            ),
                            child: _SetupTile(setup: s, onTap: () => _open(s)),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard(this.card, {this.frame, this.onFrame});
  final Scorecard card;

  /// The timeframe the card is filtered to; null = all.
  final Timeframe? frame;
  final ValueChanged<Timeframe>? onFrame;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final avg = card.avgR;
    final hit = card.hitRate;
    Widget stat(String label, String value, {Color? color}) => Expanded(
          child: Column(
            children: [
              Text(value, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: color)),
              Text(label, style: text.labelSmall),
            ],
          ),
        );
    final byFrame = card.byFrame;
    final byHtf = card.byHtf;
    final byMacd = card.byMacd;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(frame == null ? 'Track record' : 'Track record · ${frame!.label}', style: text.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                stat('closed', '${card.closed.length}'),
                stat('open', '${card.open}'),
                stat('hit rate', hit == null ? '—' : '${(hit * 100).round()}%'),
                stat('avg R', avg == null ? '—' : _r(avg), color: _rColor(avg)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${card.wins} target · ${card.losses} stopped · ${card.expired} expired. '
              'A setup closes at whichever it touches first, TP1 or the stop; after $expiryCandles candles it expires at the market price. '
              'Avg R above 0 means the method made money per unit of risk. Give it 30+ setups before trusting it.',
              style: text.bodySmall,
            ),
            if (frame == null && byFrame.length > 1) ...[
              const Divider(height: 24),
              _Breakdown(
                title: 'By timeframe',
                rows: [
                  for (final MapEntry(key: f, value: g) in byFrame.entries)
                    (label: f.label, card: g, onTap: onFrame == null ? null : () => onFrame!(f)),
                ],
                footer: 'Tap a timeframe to see only its setups. Lower timeframes are noisier; this shows whether '
                    'that costs you.',
              ),
            ],
            if (byHtf.isNotEmpty) ...[
              const Divider(height: 24),
              _Breakdown(
                title: 'By higher timeframe',
                rows: [
                  for (final MapEntry(key: v, value: g) in byHtf.entries)
                    (
                      label: switch (v) {
                        HtfVerdict.agree => 'Agreed',
                        HtfVerdict.conflict => 'Against',
                        HtfVerdict.unknown => 'Unclear',
                      },
                      card: g,
                      onTap: null,
                    ),
                ],
                footer: 'If agreeing setups don\'t beat the rest over time, the check isn\'t helping.',
              ),
            ],
            if (byMacd.isNotEmpty) ...[
              const Divider(height: 24),
              _Breakdown(
                title: 'By MACD momentum',
                rows: [
                  for (final MapEntry(key: v, value: g) in byMacd.entries)
                    (
                      label: switch (v) {
                        MacdVerdict.agree => 'Backed',
                        MacdVerdict.turning => 'Turning',
                        MacdVerdict.against => 'Against',
                      },
                      card: g,
                      onTap: null,
                    ),
                ],
                footer: 'Whether MACD momentum was behind the trade when you tracked it. If "Backed" doesn\'t '
                    'beat "Against" over time, MACD isn\'t adding anything here.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _r(double r) => '${r >= 0 ? '+' : ''}${r.toStringAsFixed(2)}';
Color? _rColor(double? r) => r == null ? null : (r >= 0 ? Colors.green.shade600 : Colors.red.shade400);

/// A small table: one row per group with closed/open counts, hit rate and average R.
class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.title, required this.rows, required this.footer});

  final String title;
  final List<({String label, Scorecard card, VoidCallback? onTap})> rows;
  final String footer;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = text.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    Widget cells(String a, String b, String c, String d, {TextStyle? style, Color? dColor}) => Row(
          children: [
            Expanded(flex: 3, child: Text(a, style: style)),
            Expanded(flex: 3, child: Text(b, style: style, textAlign: TextAlign.end)),
            Expanded(flex: 2, child: Text(c, style: style, textAlign: TextAlign.end)),
            Expanded(
              flex: 2,
              child: Text(d,
                  style: (style ?? text.bodyMedium)?.copyWith(color: dColor, fontWeight: dColor == null ? null : FontWeight.w700),
                  textAlign: TextAlign.end),
            ),
          ],
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: text.titleSmall),
        const SizedBox(height: 6),
        cells('', 'closed (open)', 'hit', 'avg R', style: muted),
        const SizedBox(height: 2),
        for (final r in rows)
          InkWell(
            onTap: r.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: cells(
                r.label,
                '${r.card.closed.length}${r.card.open > 0 ? ' (${r.card.open})' : ''}',
                r.card.hitRate == null ? '—' : '${(r.card.hitRate! * 100).round()}%',
                r.card.avgR == null ? '—' : _r(r.card.avgR!),
                style: text.bodyMedium,
                dColor: _rColor(r.card.avgR),
              ),
            ),
          ),
        const SizedBox(height: 4),
        Text(footer, style: text.bodySmall),
      ],
    );
  }
}

class _SetupTile extends StatelessWidget {
  const _SetupTile({required this.setup, required this.onTap});

  final TrackedSetup setup;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = setup;
    final text = Theme.of(context).textTheme;
    final fmt = s.source.format;
    final long = s.side == Side.long;
    final (statusLabel, statusColor) = switch (s.status) {
      SetupStatus.open => ('OPEN', Colors.blueGrey),
      SetupStatus.target => ('TARGET', Colors.green.shade600),
      SetupStatus.stopped => ('STOPPED', Colors.red.shade400),
      SetupStatus.expired => ('EXPIRED', Colors.grey),
    };
    final r = s.resultR;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(long ? 'LONG' : 'SHORT',
                      style: text.labelLarge?.copyWith(
                          color: long ? Colors.green.shade600 : Colors.red.shade400, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${s.source.title} · ${s.frame.label}',
                        style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(4)),
                    child: Text(statusLabel, style: text.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                [
                  s.count,
                  if (s.macd != null)
                    switch (s.macd!) {
                      MacdVerdict.agree => 'MACD backed',
                      MacdVerdict.turning => 'MACD turning',
                      MacdVerdict.against => 'MACD against',
                    },
                  if (s.htf != null && s.frame.higher != null)
                    switch (s.htf!) {
                      HtfVerdict.agree => '${s.frame.higher!.label} agreed',
                      HtfVerdict.conflict => 'against ${s.frame.higher!.label}',
                      HtfVerdict.unknown => '${s.frame.higher!.label} unclear',
                    },
                ].join(' · '),
                style: text.bodySmall,
              ),
              const SizedBox(height: 6),
              Text('Entry ${fmt(s.entry)} · SL ${fmt(s.stop)} · TP1 ${fmt(s.tp1)}', style: text.bodyMedium),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(DateFormat('MMM d HH:mm').format(s.madeAt), style: text.labelSmall),
                  if (s.resolvedAt != null)
                    Text(' → ${DateFormat('MMM d HH:mm').format(s.resolvedAt!)}', style: text.labelSmall),
                  const Spacer(),
                  if (r != null)
                    Text('${r >= 0 ? '+' : ''}${r.toStringAsFixed(2)} R',
                        style: text.labelLarge?.copyWith(
                            color: r >= 0 ? Colors.green.shade600 : Colors.red.shade400, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
