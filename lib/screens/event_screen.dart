import 'package:flutter/material.dart';

import '../api.dart';
import '../format.dart';
import 'market_screen.dart';
import 'widgets.dart';

/// A multi-market event, e.g. "What price will Bitcoin hit in October?".
class EventScreen extends StatefulWidget {
  const EventScreen({super.key, required this.event});

  final Event event;

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  final _api = PolymarketApi();
  late Event _event = widget.event;

  Future<void> _refresh() async {
    try {
      final fresh = await _api.event(_event.id);
      if (mounted) setState(() => _event = fresh);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Refresh failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Event')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(_event.title, style: text.headlineSmall),
            const SizedBox(height: 6),
            Text(
              '${money(_event.volume)} vol  ·  ${money(_event.volume24hr)} 24h  ·  ends ${shortDate(_event.endDate)}',
              style: text.labelMedium,
            ),
            const SizedBox(height: 16),
            for (final m in _event.markets)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(m.label),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: ProbabilityBar(price: m.prices.first),
                ),
                trailing: SizedBox(width: 72, child: Align(alignment: Alignment.centerRight, child: ChangeText(m.dayChange))),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => MarketScreen(marketId: m.id, initial: m, title: _event.title),
                )),
              ),
          ],
        ),
      ),
    );
  }
}
