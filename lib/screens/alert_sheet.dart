import 'package:flutter/material.dart';

import '../watchlist.dart';

class AlertSheetResult {
  AlertSheetResult.save(WatchItem this.item) : remove = false;
  AlertSheetResult.remove()
      : item = null,
        remove = true;

  final WatchItem? item;
  final bool remove;
}

String describeRules(WatchItem w) {
  final parts = <String>[
    if (w.movePoints > 0) 'moves ±${w.movePoints} pts',
    if (w.above != null) 'rises above ${pct(w.above!)}',
    if (w.below != null) 'falls below ${pct(w.below!)}',
  ];
  return parts.isEmpty ? 'Only when it closes' : 'Alert when it ${parts.join(', or ')}';
}

class AlertSheet extends StatefulWidget {
  const AlertSheet({super.key, required this.item, required this.isNew, required this.currentPrice});

  final WatchItem item;
  final bool isNew;
  final double currentPrice;

  @override
  State<AlertSheet> createState() => _AlertSheetState();
}

class _AlertSheetState extends State<AlertSheet> {
  late double _move = widget.item.movePoints.toDouble();
  late final _above = TextEditingController(text: _fmt(widget.item.above));
  late final _below = TextEditingController(text: _fmt(widget.item.below));
  String? _error;

  static String _fmt(double? v) => v == null ? '' : (v * 100).round().toString();

  @override
  void dispose() {
    _above.dispose();
    _below.dispose();
    super.dispose();
  }

  /// Parses a 1–99 percent field; null when blank, throws on junk.
  double? _parse(TextEditingController c, String name) {
    final t = c.text.trim();
    if (t.isEmpty) return null;
    final v = double.tryParse(t);
    if (v == null || v <= 0 || v >= 100) throw FormatException('$name must be between 1 and 99');
    return v / 100;
  }

  void _save() {
    final double? above;
    final double? below;
    try {
      above = _parse(_above, 'Above');
      below = _parse(_below, 'Below');
    } on FormatException catch (e) {
      setState(() => _error = e.message);
      return;
    }
    final now = widget.currentPrice;
    final w = widget.item;
    Navigator.pop(
      context,
      AlertSheetResult.save(WatchItem(
        marketId: w.marketId,
        question: w.question,
        outcomeIndex: w.outcomeIndex,
        outcome: w.outcome,
        // Saving restarts move tracking from today's price.
        baseline: now,
        lastPrice: now,
        movePoints: _move.round(),
        above: above,
        below: below,
        resolved: w.resolved,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Alert: ${widget.item.outcome}', style: text.titleLarge),
          Text('Now ${pct(widget.currentPrice)}', style: text.bodyMedium),
          const SizedBox(height: 16),
          Text(_move == 0 ? 'Big moves: off' : 'When it moves ±${_move.round()} points', style: text.titleSmall),
          Slider(
            value: _move,
            min: 0,
            max: 25,
            divisions: 25,
            label: _move == 0 ? 'off' : '${_move.round()} pts',
            onChanged: (v) => setState(() => _move = v),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _above,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Rises above', suffixText: '%', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _below,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Falls below', suffixText: '%', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          const SizedBox(height: 8),
          Text('You\'ll also be notified when the market closes. Checks run about every 15 minutes.',
              style: text.bodySmall),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: Text(widget.isNew ? 'Watch' : 'Save')),
          if (!widget.isNew)
            TextButton(
              onPressed: () => Navigator.pop(context, AlertSheetResult.remove()),
              child: const Text('Stop watching'),
            ),
        ],
      ),
    );
  }
}
