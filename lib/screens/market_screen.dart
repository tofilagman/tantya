import 'package:flutter/material.dart';

import '../alerts.dart';
import '../api.dart';
import '../format.dart';
import '../sources/polymarket_source.dart';
import '../watchlist.dart';
import 'alert_sheet.dart';
import 'ew_panel.dart';
import 'widgets.dart';

/// One Polymarket market: outcome picker, live chart with Elliott Wave count, alerts.
class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key, required this.marketId, this.initial, this.title});

  final String marketId;

  /// Shown immediately while the fresh copy loads.
  final Market? initial;

  /// Parent event title, for context above the question.
  final String? title;

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final _api = PolymarketApi();
  late Market? _market = widget.initial;
  Object? _error;

  int _outcome = 0;
  double? _livePrice;
  WatchItem? _watch;
  bool _jumpedToWatched = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final m = await _api.market(widget.marketId);
      if (!mounted) return;
      setState(() => _market = m);
      await _loadWatch();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _loadWatch() async {
    final items = await WatchStore.load();
    final mine = items.where((i) => i.marketId == widget.marketId).toList();
    if (!mounted) return;
    setState(() {
      _watch = mine.where((i) => i.outcomeIndex == _outcome).firstOrNull;
      // Open on the outcome the user watches, if it is not the first one.
      if (!_jumpedToWatched && _watch == null && mine.isNotEmpty) {
        _outcome = mine.first.outcomeIndex;
        _watch = mine.first;
      }
      _jumpedToWatched = true;
    });
  }

  Future<void> _editAlert() async {
    final m = _market!;
    final price = _livePrice ?? m.prices[_outcome];
    final item = _watch ??
        WatchItem(
          marketId: m.id,
          question: m.question,
          outcomeIndex: _outcome,
          outcome: m.outcomes[_outcome],
          baseline: price,
          lastPrice: price,
        );
    final result = await showModalBottomSheet<AlertSheetResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AlertSheet(item: item, isNew: _watch == null, currentPrice: price),
    );
    if (result == null) return;
    if (result.remove) {
      await WatchStore.remove(item.key);
    } else {
      await requestNotificationPermission();
      await WatchStore.upsert(result.item!);
    }
    await _loadWatch();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.remove ? 'Removed from watchlist' : 'Watching, checked $backgroundCadence'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _market;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market'),
        actions: [
          if (m != null && !m.closed)
            IconButton(
              tooltip: _watch == null ? 'Watch' : 'Edit alert',
              icon: Icon(_watch == null ? Icons.notifications_none : Icons.notifications_active),
              onPressed: _editAlert,
            ),
        ],
      ),
      body: m == null
          ? (_error != null
              ? ErrorRetry(error: _error!, onRetry: _load)
              : const Center(child: CircularProgressIndicator()))
          : _body(m),
    );
  }

  Widget _body(Market m) {
    final text = Theme.of(context).textTheme;
    final price = _livePrice ?? (m.prices.isEmpty ? 0.0 : m.prices[_outcome]);
    final hasToken = _outcome < m.tokenIds.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
      children: [
        if (widget.title != null && widget.title != m.question)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(widget.title!, style: text.labelLarge),
          ),
        Text(m.question, style: text.headlineSmall),
        const SizedBox(height: 12),
        if (m.outcomes.length > 1)
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              for (var i = 0; i < m.outcomes.length; i++)
                ButtonSegment(value: i, label: Text(m.outcomes[i], overflow: TextOverflow.ellipsis)),
            ],
            selected: {_outcome},
            onSelectionChanged: (s) {
              setState(() {
                _outcome = s.first;
                _livePrice = null;
              });
              _loadWatch();
            },
          ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(pct(price), style: text.displaySmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Text('chance', style: text.titleMedium),
            const Spacer(),
            // Gamma's 24h change is for the first outcome; flip it for the second of a binary pair.
            ChangeText(
              m.dayChange == null || (_outcome > 0 && m.outcomes.length != 2)
                  ? (_outcome == 0 ? m.dayChange : null)
                  : (_outcome == 0 ? m.dayChange : -m.dayChange!),
              style: text.titleSmall,
            ),
          ],
        ),
        if (m.closed)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Chip(label: Text('Closed'), avatar: Icon(Icons.lock, size: 16)),
          ),
        const SizedBox(height: 8),
        if (hasToken && !m.closed)
          EwPanel(
            source: PolymarketSource(
              marketId: m.id,
              tokenId: m.tokenIds[_outcome],
              question: m.question,
              outcome: m.outcomes[_outcome],
            ),
            onPrice: (p) {
              if (mounted && p != _livePrice) setState(() => _livePrice = p);
            },
          ),
        const SizedBox(height: 16),
        if (_watch != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_active),
              title: Text('Watching ${_watch!.outcome}'),
              subtitle: Text(describeRules(_watch!)),
              trailing: const Icon(Icons.edit),
              onTap: _editAlert,
            ),
          )
        else if (!m.closed)
          OutlinedButton.icon(
            onPressed: _editAlert,
            icon: const Icon(Icons.notifications_none),
            label: Text('Alert me about ${m.outcomes.isEmpty ? 'this' : m.outcomes[_outcome]}'),
          ),
        const SizedBox(height: 16),
        _stat('Volume', money(m.volume)),
        _stat('24h volume', money(m.volume24hr)),
        _stat('Ends', shortDate(m.endDate)),
        const SizedBox(height: 12),
        if (m.description.isNotEmpty)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Resolution rules'),
            children: [Text(m.description, style: text.bodyMedium)],
          ),
      ],
    );
  }

  Widget _stat(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [Text(label), const Spacer(), Text(value, style: const TextStyle(fontWeight: FontWeight.w600))]),
      );
}
