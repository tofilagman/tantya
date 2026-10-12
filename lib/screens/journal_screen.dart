import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../journal.dart';
import '../sizing.dart';
import '../trade.dart';
import 'position_size_sheet.dart';
import 'widgets.dart';

/// Your real trades: size, fills, exits, and the habits that cost money.
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  List<JournalEntry>? _items;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await JournalStore.load();
    if (mounted) setState(() => _items = items);
  }

  Future<void> _edit(JournalEntry? e) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => JournalEntrySheet(entry: e),
    );
    if (saved == true) _load();
  }

  Future<void> _remove(JournalEntry e) async {
    await JournalStore.remove(e.id);
    setState(() => _items!.removeWhere((x) => x.id == e.id));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Deleted'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () async {
          await JournalStore.upsert(e);
          _load();
        },
      ),
    ));
  }

  void _export() {
    final items = _items ?? const [];
    final csv = [JournalEntry.csvHeader, for (final e in items.reversed) e.toCsv()].join('\n');
    Clipboard.setData(ClipboardData(text: csv));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${items.length} trades copied as CSV: paste into Sheets or Excel'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trade journal'),
        actions: [
          if (items != null && items.isNotEmpty)
            IconButton(tooltip: 'Copy as CSV', icon: const Icon(Icons.file_download_outlined), onPressed: _export),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(null),
        icon: const Icon(Icons.add),
        label: const Text('Add trade'),
      ),
      body: items == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
              children: [
                _StatsCard(JournalStats(items)),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No trades yet. On a chart, tap "Size this trade" and log it, or add one here. '
                      'Close it with your exit price to see your real results.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                for (final e in items)
                  Dismissible(
                    key: ValueKey(e.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => _remove(e),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: const Icon(Icons.delete_outline),
                    ),
                    child: _EntryTile(e, onTap: () => _edit(e)),
                  ),
              ],
            ),
    );
  }
}

Color? _pnlColor(double? v) => v == null ? null : (v >= 0 ? Colors.green.shade600 : Colors.red.shade400);
String _r(double r) => '${r >= 0 ? '+' : ''}${r.toStringAsFixed(2)}R';

class _StatsCard extends StatelessWidget {
  const _StatsCard(this.s);
  final JournalStats s;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget stat(String label, String value, {Color? color}) => Expanded(
          child: Column(
            children: [
              Text(value, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: color)),
              Text(label, style: text.labelSmall),
            ],
          ),
        );
    final followed = s.where((e) => e.followedPlan == true);
    final broke = s.where((e) => e.followedPlan == false);
    final mistakes = s.byMistake.entries.toList()..sort((a, b) => a.value.totalPnl.compareTo(b.value.totalPnl));
    Widget line(String label, JournalStats g) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(child: Text(label)),
              Text('${g.closed.length} · '),
              Text(g.avgR == null ? '—' : 'avg ${_r(g.avgR!)}',
                  style: TextStyle(color: _pnlColor(g.avgR), fontWeight: FontWeight.w600)),
              Text('  ${formatMoney(g.totalPnl)}', style: TextStyle(color: _pnlColor(g.totalPnl))),
            ],
          ),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                stat('closed', '${s.closed.length}'),
                stat('open', '${s.open}'),
                stat('win rate', s.winRate == null ? '—' : '${(s.winRate! * 100).round()}%'),
                stat('avg R', s.avgR == null ? '—' : _r(s.avgR!), color: _pnlColor(s.avgR)),
              ],
            ),
            if (s.closed.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Total ${formatMoney(s.totalPnl)} after fees · best ${_r(s.bestR!)} · worst ${_r(s.worstR!)}',
                  style: text.bodySmall),
            ],
            if (s.closed.length >= 2) ...[
              const SizedBox(height: 10),
              SizedBox(height: 80, child: EquityLine(s.equity)),
            ],
            if (followed.closed.isNotEmpty || broke.closed.isNotEmpty) ...[
              const Divider(height: 24),
              Text('Did following the plan pay?', style: text.titleSmall),
              const SizedBox(height: 4),
              if (followed.closed.isNotEmpty) line('Followed the plan', followed),
              if (broke.closed.isNotEmpty) line('Broke the plan', broke),
            ],
            if (mistakes.isNotEmpty) ...[
              const Divider(height: 24),
              Text('What mistakes cost', style: text.titleSmall),
              const SizedBox(height: 4),
              for (final m in mistakes) line(m.key, m.value),
            ],
          ],
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile(this.e, {required this.onTap});
  final JournalEntry e;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final long = e.side == Side.long;
    String p(double v) => v.toStringAsPrecision(6).replaceFirst(RegExp(r'\.?0+$'), '');
    final (label, color) = switch (e.status) {
      JournalStatus.open => ('OPEN', Colors.blueGrey),
      JournalStatus.cancelled => ('CANCELLED', Colors.grey),
      JournalStatus.closed => (e.pnl! >= 0 ? 'WIN' : 'LOSS', _pnlColor(e.pnl)!),
    };
    final fmt = DateFormat('MMM d, HH:mm');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                  Expanded(
                    child: Text('${e.title}${e.frame == null ? '' : ' · ${e.frame}'}',
                        style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  if (e.pnl != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text('${formatMoney(e.pnl!)} · ${_r(e.r!)}',
                          style: text.labelLarge?.copyWith(color: _pnlColor(e.pnl), fontWeight: FontWeight.w700)),
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
                '${formatSize(e.size)} @ ${p(e.entry)} · stop ${p(e.stop)}'
                '${e.tp1 != null ? ' · TP1 ${p(e.tp1!)}' : ''}'
                '${e.exit != null ? ' · exit ${p(e.exit!)}' : ''}'
                '${e.leverage > 1 ? ' · ${e.leverage}x' : ''}',
                style: text.bodySmall,
              ),
              Text(
                [
                  fmt.format(e.openedAt),
                  if (e.closedAt != null) '→ ${fmt.format(e.closedAt!)}',
                  if (e.followedPlan == false) 'broke plan',
                  ...e.mistakes,
                ].join(' · '),
                style: text.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              if (e.notes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(e.notes, style: text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Add a trade by hand, or update one: close it, mark mistakes, write notes.
class JournalEntrySheet extends StatefulWidget {
  const JournalEntrySheet({super.key, this.entry});

  /// Null for a new trade.
  final JournalEntry? entry;

  @override
  State<JournalEntrySheet> createState() => _JournalEntrySheetState();
}

class _JournalEntrySheetState extends State<JournalEntrySheet> {
  late final JournalEntry? _e = widget.entry;
  late final _title = TextEditingController(text: _e?.title ?? '');
  late Side _side = _e?.side ?? Side.long;
  late final _entry = TextEditingController(text: _n(_e?.entry));
  late final _stop = TextEditingController(text: _n(_e?.stop));
  late final _tp1 = TextEditingController(text: _n(_e?.tp1));
  late final _size = TextEditingController(text: _e == null ? '' : formatSize(_e.size));
  late final _exit = TextEditingController(text: _n(_e?.exit));
  late final _notes = TextEditingController(text: _e?.notes ?? '');
  late JournalStatus _status = _e?.status ?? JournalStatus.open;
  late bool? _followed = _e?.followedPlan;
  late final Set<String> _mistakes = {...?_e?.mistakes};
  String? _error;

  static String _n(double? v) => v == null ? '' : v.toString();

  @override
  void dispose() {
    for (final c in [_title, _entry, _stop, _tp1, _size, _exit, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', ''));

  Future<void> _save() async {
    final entry = _num(_entry), stop = _num(_stop), size = _num(_size), exit = _num(_exit);
    final title = _title.text.trim();
    String? err;
    if (title.isEmpty) {
      err = 'Enter the pair, e.g. BTC/USDT';
    } else if (entry == null || entry <= 0 || stop == null || stop <= 0 || size == null || size <= 0) {
      err = 'Entry, stop and size must be numbers above 0';
    } else if ((_side == Side.long) != (stop < entry)) {
      err = _side == Side.long ? 'A long\'s stop must be below the entry' : 'A short\'s stop must be above the entry';
    } else if (_status == JournalStatus.closed && (exit == null || exit <= 0)) {
      err = 'Enter the exit price to close the trade';
    }
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    final fee = _e?.feeRate ?? defaultFeeRate;
    // Risk is what the original stop would have cost, fees included.
    final risk = size! * ((entry! - stop!).abs() + fee * (entry + stop));
    final e = _e ??
        JournalEntry(
          id: '${DateTime.now().microsecondsSinceEpoch}',
          title: title,
          side: _side,
          entry: entry,
          stop: stop,
          size: size,
          riskAmount: risk,
          openedAt: DateTime.now(),
        );
    e
      ..title = title
      ..side = _side
      ..entry = entry
      ..stop = stop
      ..tp1 = _num(_tp1)
      ..size = size
      ..riskAmount = risk
      ..status = _status
      ..exit = _status == JournalStatus.closed ? exit : null
      ..closedAt = _status == JournalStatus.closed ? (e.closedAt ?? DateTime.now()) : null
      ..followedPlan = _followed
      ..mistakes = [for (final m in journalMistakes) if (_mistakes.contains(m)) m]
      ..notes = _notes.text.trim();
    await JournalStore.upsert(e);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget field(TextEditingController c, String label, {bool number = true}) => TextField(
          controller: c,
          keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          textCapitalization: number ? TextCapitalization.none : TextCapitalization.characters,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
        );
    final r = _e?.r;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_e == null ? 'Add a trade' : 'Trade', style: text.titleLarge),
          if (_e?.count != null) Text(_e!.count!, style: text.bodySmall),
          if (r != null)
            Text('${formatMoney(_e!.pnl!)} · ${_r(r)}',
                style: text.titleMedium?.copyWith(color: _pnlColor(r), fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: field(_title, 'Pair', number: false)),
              const SizedBox(width: 10),
              SegmentedButton<Side>(
                segments: const [
                  ButtonSegment(value: Side.long, label: Text('Long')),
                  ButtonSegment(value: Side.short, label: Text('Short')),
                ],
                selected: {_side},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _side = s.first),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: field(_entry, 'Entry')),
              const SizedBox(width: 10),
              Expanded(child: field(_stop, 'Original stop')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: field(_tp1, 'Target')),
              const SizedBox(width: 10),
              Expanded(child: field(_size, 'Size (units)')),
            ],
          ),
          const SizedBox(height: 14),
          SegmentedButton<JournalStatus>(
            segments: const [
              ButtonSegment(value: JournalStatus.open, label: Text('Open')),
              ButtonSegment(value: JournalStatus.closed, label: Text('Closed')),
              ButtonSegment(value: JournalStatus.cancelled, label: Text('Cancelled')),
            ],
            selected: {_status},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _status = s.first),
          ),
          if (_status == JournalStatus.closed) ...[
            const SizedBox(height: 10),
            field(_exit, 'Exit price'),
          ],
          const SizedBox(height: 14),
          Text('Did you follow your plan?', style: text.titleSmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            children: [
              for (final (v, label) in const [(true, 'Yes'), (false, 'No')])
                ChoiceChip(
                  label: Text(label),
                  selected: _followed == v,
                  onSelected: (on) => setState(() => _followed = on ? v : null),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Mistakes', style: text.titleSmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final m in journalMistakes)
                FilterChip(
                  label: Text(m),
                  selected: _mistakes.contains(m),
                  visualDensity: VisualDensity.compact,
                  onSelected: (on) => setState(() => on ? _mistakes.add(m) : _mistakes.remove(m)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes: why you took it, how you felt',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
    );
  }
}
