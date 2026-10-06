import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../sources/binance.dart';
import 'instrument_screen.dart';
import 'scanner_view.dart';
import 'widgets.dart';

/// Binance spot pairs by 24h volume with search, and the setup scanner.
class CryptoScreen extends StatefulWidget {
  const CryptoScreen({super.key});

  @override
  State<CryptoScreen> createState() => CryptoScreenState();
}

class CryptoScreenState extends State<CryptoScreen> {
  final _api = BinanceApi();
  List<Ticker>? _all;
  Object? _error;
  String _query = '';
  bool _scanner = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Switches to the scanner view (e.g. from a background-scan notification).
  void showScanner() => setState(() => _scanner = true);

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final t = await _api.tickers();
      t.sort((a, b) => b.quoteVolume.compareTo(a.quoteVolume));
      if (mounted) setState(() => _all = t);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  List<Ticker> get _shown {
    final all = _all ?? const <Ticker>[];
    final q = _query.toUpperCase().replaceAll('/', '');
    if (q.isEmpty) return all.where((t) => t.mainstream).take(100).toList();
    return all.where((t) => t.symbol.contains(q)).take(100).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: false, icon: Icon(Icons.list), label: Text('Pairs')),
                ButtonSegment(value: true, icon: Icon(Icons.radar), label: Text('Scanner')),
              ],
              selected: {_scanner},
              onSelectionChanged: (s) => setState(() => _scanner = s.first),
            ),
          ),
          Expanded(
            // IndexedStack keeps the scan results and the pair list alive while switching.
            child: IndexedStack(
              index: _scanner ? 1 : 0,
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: SearchBar(
                        hintText: 'Search pairs, e.g. BTC, SOLUSDT',
                        leading: const Icon(Icons.search),
                        onChanged: (t) => setState(() => _query = t.trim()),
                      ),
                    ),
                    Expanded(child: _body()),
                  ],
                ),
                _all == null
                    ? (_error != null
                        ? ErrorRetry(error: _error!, onRetry: _load)
                        : const Center(child: CircularProgressIndicator()))
                    : ScannerView(tickers: _all!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_all == null) {
      return _error != null ? ErrorRetry(error: _error!, onRetry: _load) : const Center(child: CircularProgressIndicator());
    }
    final shown = _shown;
    if (shown.isEmpty) return const Center(child: Text('No matching pairs'));
    final vol = NumberFormat.compactSimpleCurrency(decimalDigits: 1);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: shown.length,
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, i) {
          final t = shown[i];
          final pair = t.pair;
          final up = t.changePct >= 0;
          return ListTile(
            title: Text(pair == null ? t.symbol : '${pair.$1}/${pair.$2}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Vol ${vol.format(t.quoteVolume)}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(t.last.toStringAsFixed(decimalsFor(t.last)),
                    style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
                Text(
                  '${up ? '+' : ''}${t.changePct.toStringAsFixed(2)}%',
                  style: TextStyle(color: up ? Colors.green.shade600 : Colors.red.shade400, fontSize: 12),
                ),
              ],
            ),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => InstrumentScreen(source: BinanceSource(t.symbol, base: pair?.$1, quote: pair?.$2)),
            )),
          );
        },
      ),
    );
  }
}
