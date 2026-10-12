import 'package:flutter/material.dart';

import '../alerts.dart';
import '../api.dart';
import '../pair_watch.dart';
import '../sources/binance.dart';
import '../watchlist.dart';
import 'alert_sheet.dart';
import 'instrument_screen.dart';
import 'market_screen.dart';
import 'pair_alert_sheet.dart';
import 'widgets.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => WatchlistScreenState();
}

class WatchlistScreenState extends State<WatchlistScreen> {
  List<WatchItem>? _items;
  List<PairWatch> _pairs = [];
  Map<String, Market> _markets = {};
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  /// Shows stored items immediately, then fetches live prices (which also runs the alert check).
  Future<void> refresh() async {
    final stored = await WatchStore.load();
    final pairs = await PairWatchStore.load();
    if (!mounted) return;
    setState(() {
      _items = stored;
      _pairs = pairs;
      _refreshing = true;
    });
    try {
      final markets = await checkWatchlist();
      await checkPairs();
      final items = await WatchStore.load();
      final freshPairs = await PairWatchStore.load();
      if (!mounted) return;
      setState(() {
        _markets = markets;
        _items = items;
        _pairs = freshPairs;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Refresh failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _remove(WatchItem item) async {
    await WatchStore.remove(item.key);
    setState(() => _items!.removeWhere((i) => i.key == item.key));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Removed'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () async {
          await WatchStore.upsert(item);
          refresh();
        },
      ),
    ));
  }

  Future<void> _removePair(PairWatch w) async {
    await PairWatchStore.remove(w.key);
    setState(() => _pairs.removeWhere((p) => p.key == w.key));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Removed'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () async {
          await PairWatchStore.upsert(w);
          refresh();
        },
      ),
    ));
  }

  Widget _pairTile(PairWatch w) {
    final text = Theme.of(context).textTheme;
    final parts = w.title.split('/');
    return Dismissible(
      key: ValueKey('pair:${w.key}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Theme.of(context).colorScheme.errorContainer,
        child: const Icon(Icons.delete_outline),
      ),
      onDismissed: (_) => _removePair(w),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 5),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => InstrumentScreen(
                source: BinanceSource(w.symbol, base: parts.length == 2 ? parts[0] : null, quote: parts.length == 2 ? parts[1] : null),
                initialFrame: w.frame,
              ),
            ));
            refresh();
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('${w.title} · ${w.frame.label}', style: text.titleMedium)),
                    Text(w.lastPrice.toStringAsFixed(decimalsFor(w.lastPrice)),
                        style: text.titleMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                  ],
                ),
                if (w.count != null) ...[
                  const SizedBox(height: 4),
                  Text(w.count!, style: text.bodyMedium),
                ],
                const SizedBox(height: 6),
                Text(describePairRules(w), style: text.labelMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Text('Watchlist', style: Theme.of(context).textTheme.headlineSmall),
                const Spacer(),
                if (_refreshing) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
          ),
          Expanded(
            child: items == null
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: refresh,
                    child: items.isEmpty && _pairs.isEmpty ? _empty() : _list(items),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _empty() => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Icon(Icons.notifications_none, size: 48),
          SizedBox(height: 12),
          Center(child: Text('Nothing watched yet')),
          SizedBox(height: 4),
          Center(
            child: Text('Open a crypto pair or a Polymarket market and tap the bell.', textAlign: TextAlign.center),
          ),
        ],
      );

  Widget _list(List<WatchItem> items) => ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
        itemCount: _pairs.length + items.length,
        itemBuilder: (_, i) {
          if (i < _pairs.length) return _pairTile(_pairs[i]);
          final item = items[i - _pairs.length];
          final m = _markets[item.marketId];
          final price = m != null && item.outcomeIndex < m.prices.length ? m.prices[item.outcomeIndex] : item.lastPrice;
          return Dismissible(
            key: ValueKey(item.key),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              color: Theme.of(context).colorScheme.errorContainer,
              child: const Icon(Icons.delete_outline),
            ),
            onDismissed: (_) => _remove(item),
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 5),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => MarketScreen(marketId: item.marketId, initial: m),
                  ));
                  refresh();
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.question, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(flex: 2, child: Text(item.outcome, maxLines: 1, overflow: TextOverflow.ellipsis)),
                          Expanded(flex: 3, child: ProbabilityBar(price: price)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.resolved || (m?.closed ?? false) ? 'Closed' : describeRules(item),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
}
