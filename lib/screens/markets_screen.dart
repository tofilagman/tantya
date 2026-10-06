import 'dart:async';

import 'package:flutter/material.dart';

import '../api.dart';
import '../format.dart';
import 'event_screen.dart';
import 'market_screen.dart';
import 'widgets.dart';

const _categories = <(String, String?)>[
  ('Trending', null),
  ('Politics', 'politics'),
  ('Crypto', 'crypto'),
  ('Sports', 'sports'),
  ('Economy', 'economy'),
  ('Tech', 'tech'),
  ('World', 'world'),
];

class MarketsScreen extends StatefulWidget {
  const MarketsScreen({super.key});

  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen> {
  final _api = PolymarketApi();
  final _scroll = ScrollController();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  String? _tag;
  String _query = '';
  final List<Event> _events = [];

  /// Raw rows fetched so far — differs from _events.length because closed events are dropped.
  int _offset = 0;
  bool _loading = false;
  bool _hasMore = true;
  Object? _error;

  /// Bumped on every reset so responses from a stale filter are dropped.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 600) _loadMore();
    });
    _reset();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    _generation++;
    setState(() {
      _events.clear();
      _offset = 0;
      _hasMore = true;
      _error = null;
      _loading = false;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    final gen = _generation;
    setState(() => _loading = true);
    try {
      final List<Event> page;
      if (_query.isNotEmpty) {
        page = await _api.search(_query);
      } else {
        page = await _api.trendingEvents(offset: _offset, tag: _tag);
      }
      if (gen != _generation || !mounted) return;
      setState(() {
        _offset += page.length;
        // Events with nothing left to trade on are noise in a live list.
        _events.addAll(page.where((e) => e.markets.any((m) => !m.decided)));
        // Search returns a single page; trending pages until the API runs dry.
        _hasMore = _query.isEmpty && page.length >= 20;
        _loading = false;
      });
    } catch (e) {
      if (gen != _generation || !mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final q = text.trim();
      if (q == _query) return;
      _query = q;
      _reset();
    });
  }

  void _open(Event e) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => e.markets.length == 1
          ? MarketScreen(marketId: e.markets.first.id, initial: e.markets.first, title: e.title)
          : EventScreen(event: e),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchBar(
              controller: _searchCtrl,
              hintText: 'Search markets',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchCtrl.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchCtrl.clear();
                      _onSearchChanged('');
                      setState(() {});
                    },
                  ),
              ],
              onChanged: (t) {
                setState(() {}); // toggle the clear button
                _onSearchChanged(t);
              },
            ),
          ),
          if (_query.isEmpty)
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final (label, tag) = _categories[i];
                  return ChoiceChip(
                    label: Text(label),
                    selected: _tag == tag,
                    onSelected: (_) {
                      if (_tag == tag) return;
                      _tag = tag;
                      _reset();
                    },
                  );
                },
              ),
            ),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_events.isEmpty && _error != null) {
      return ErrorRetry(error: _error!, onRetry: _reset);
    }
    if (_events.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_events.isEmpty) {
      return const Center(child: Text('No open markets found'));
    }
    return RefreshIndicator(
      onRefresh: _reset,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
        itemCount: _events.length + (_hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == _events.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return EventCard(event: _events[i], onTap: () => _open(_events[i]));
        },
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event, required this.onTap});

  final Event event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final single = event.markets.length == 1 ? event.markets.first : null;
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
              Text(event.title, style: text.titleMedium),
              const SizedBox(height: 10),
              if (single != null)
                for (var i = 0; i < single.outcomes.length && i < 2; i++)
                  _OutcomeRow(label: single.outcomes[i], price: single.prices[i])
              else
                for (final m in event.markets.where((m) => !m.decided).take(3)) _OutcomeRow(label: m.label, price: m.prices.first),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text('${money(event.volume)} vol', style: text.labelMedium),
                  if (event.markets.length > 3) ...[
                    const Text('  ·  '),
                    Text('${event.markets.length} markets', style: text.labelMedium),
                  ],
                  const Spacer(),
                  if (single != null) ChangeText(single.dayChange),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutcomeRow extends StatelessWidget {
  const _OutcomeRow({required this.label, required this.price});

  final String label;
  final double price;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Expanded(flex: 4, child: ProbabilityBar(price: price)),
        ],
      ),
    );
  }
}
