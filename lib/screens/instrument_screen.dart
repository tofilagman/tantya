import 'package:flutter/material.dart';

import '../candles.dart';
import '../sources/source.dart';
import 'ew_panel.dart';

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
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              children: [
                EwPanel(source: widget.source, initialFrame: widget.initialFrame, onPrice: (p) => _price.value = p),
              ],
            ),
    );
  }
}
