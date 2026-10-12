import 'package:flutter/material.dart';

import '../alerts.dart';
import '../candles.dart';
import '../pair_watch.dart';
import '../sources/binance.dart';
import '../sources/source.dart';
import 'ew_panel.dart';
import 'pair_alert_sheet.dart';

/// Full-screen live chart + Elliott Wave setup for any source (used for Binance pairs).
class InstrumentScreen extends StatefulWidget {
  const InstrumentScreen({super.key, required this.source, this.initialFrame});

  final CandleSource source;
  final Timeframe? initialFrame;

  @override
  State<InstrumentScreen> createState() => _InstrumentScreenState();
}

class _InstrumentScreenState extends State<InstrumentScreen> {
  final _price = ValueNotifier<double?>(null);
  late Timeframe _frame = widget.initialFrame ?? widget.source.defaultFrame;

  /// This pair's watches (any timeframe); null until loaded or for non-Binance sources.
  List<PairWatch>? _watches;

  BinanceSource? get _binance => switch (widget.source) {
        final BinanceSource b => b,
        _ => null,
      };

  @override
  void initState() {
    super.initState();
    _loadWatches();
  }

  Future<void> _loadWatches() async {
    final b = _binance;
    if (b == null) return;
    final all = await PairWatchStore.load();
    if (mounted) setState(() => _watches = all.where((w) => w.symbol == b.symbol).toList());
  }

  Future<void> _editAlerts() async {
    final b = _binance, price = _price.value;
    if (b == null || price == null) return;
    // Edit the watch for the chart's timeframe if there is one, else the pair's only one.
    final mine = _watches ?? const <PairWatch>[];
    final existing = mine.where((w) => w.frame == _frame).firstOrNull ?? (mine.length == 1 ? mine.first : null);
    final frame = pairWatchFrames.contains(_frame) ? _frame : Timeframe.h1;
    final result = await showModalBottomSheet<PairAlertResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => PairAlertSheet(
        watch: existing ??
            PairWatch(symbol: b.symbol, title: b.title, frame: frame, lastPrice: price, baseline: price),
        isNew: existing == null,
        price: price,
      ),
    );
    if (result == null) return;
    if (result.remove) {
      await PairWatchStore.remove(existing!.key);
    } else {
      final rules = result.watch!;
      final PairWatch w;
      if (existing != null) {
        w = existing..applyRules(rules);
        if (rules.movePct != existing.movePct) w.baseline = price;
      } else {
        w = rules;
        // Record what the chart shows now, so the first alert is a real change.
        try {
          final candles = await BinanceApi().klines(w.symbol, w.frame, limit: 301);
          final closed = candles.isNotEmpty && candles.last.start.add(w.frame.size).isAfter(DateTime.now())
              ? candles.sublist(0, candles.length - 1)
              : candles;
          w.prime(PairSnapshot.of(closed, candles.last.close));
        } catch (_) {
          // The first background check records it instead.
        }
      }
      final granted = await requestNotificationPermission();
      await PairWatchStore.upsert(w);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(granted
              ? 'Watching ${w.title} ${w.frame.label}, checked $backgroundCadence'
              : 'Saved, but notifications are blocked. Allow them in system settings.'),
        ));
      }
    }
    if (result.remove && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stopped watching')));
    }
    await _loadWatches();
  }

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.source.title),
            Text(widget.source.subtitle, style: text.labelSmall),
          ],
        ),
        actions: [
          if (_binance != null)
            ValueListenableBuilder(
              valueListenable: _price,
              builder: (_, p, _) => IconButton(
                tooltip: 'Alerts',
                icon: Icon((_watches ?? const []).isEmpty ? Icons.notifications_none : Icons.notifications_active),
                onPressed: p == null ? null : _editAlerts,
              ),
            ),
          ValueListenableBuilder(
            valueListenable: _price,
            builder: (_, p, _) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(p == null ? '' : widget.source.format(p),
                  style: text.titleLarge?.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
            ),
          ),
        ],
      ),
      // Wide windows (desktop, tablets): chart fills the screen with the setup beside it.
      body: MediaQuery.sizeOf(context).width >= 1000
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: EwPanel(
                source: widget.source,
                initialFrame: widget.initialFrame,
                wide: true,
                onPrice: (p) => _price.value = p,
                onFrame: (f) => _frame = f,
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              children: [
                EwPanel(
                  source: widget.source,
                  initialFrame: widget.initialFrame,
                  onPrice: (p) => _price.value = p,
                  onFrame: (f) => _frame = f,
                ),
              ],
            ),
    );
  }
}
