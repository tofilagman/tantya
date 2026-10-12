import 'package:flutter/material.dart';

import '../alerts.dart';
import '../candles.dart';
import '../pair_watch.dart';
import '../sources/binance.dart';

/// What the sheet returns: rules to save (with the chosen timeframe), or a removal.
class PairAlertResult {
  PairAlertResult.save(PairWatch this.watch) : remove = false;
  PairAlertResult.remove()
      : watch = null,
        remove = true;
  final PairWatch? watch;
  final bool remove;
}

/// One-line summary of a watch's rules, for lists.
String describePairRules(PairWatch w) {
  String f(double p) => p.toStringAsFixed(decimalsFor(p));
  final parts = [
    if (w.setups) 'new setups',
    if (w.countChanges) 'count changes',
    if (w.targets) 'target / invalidation',
    if (w.above != null) 'above ${f(w.above!)}',
    if (w.below != null) 'below ${f(w.below!)}',
    if (w.movePct > 0) '±${w.movePct.toStringAsFixed(0)}% moves',
  ];
  return parts.isEmpty ? 'No alerts on' : 'Alerts: ${parts.join(' · ')}';
}

class PairAlertSheet extends StatefulWidget {
  const PairAlertSheet({super.key, required this.watch, required this.isNew, required this.price});

  /// The existing watch, or a fresh one with default rules.
  final PairWatch watch;
  final bool isNew;
  final double price;

  @override
  State<PairAlertSheet> createState() => _PairAlertSheetState();
}

class _PairAlertSheetState extends State<PairAlertSheet> {
  late Timeframe _frame = widget.watch.frame;
  late bool _setups = widget.watch.setups;
  late bool _count = widget.watch.countChanges;
  late bool _targets = widget.watch.targets;
  late double _move = widget.watch.movePct;
  late final _above = TextEditingController(text: _fmt(widget.watch.above));
  late final _below = TextEditingController(text: _fmt(widget.watch.below));
  String? _error;

  static String _fmt(double? v) => v == null ? '' : v.toStringAsFixed(decimalsFor(v));

  @override
  void dispose() {
    _above.dispose();
    _below.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c, String name) {
    final t = c.text.trim().replaceAll(',', '');
    if (t.isEmpty) return null;
    final v = double.tryParse(t);
    if (v == null || v <= 0) throw FormatException('$name must be a price above 0');
    return v;
  }

  void _save() {
    final double? above, below;
    try {
      above = _parse(_above, 'Above');
      below = _parse(_below, 'Below');
    } on FormatException catch (e) {
      setState(() => _error = e.message);
      return;
    }
    if (above != null && above <= widget.price) {
      setState(() => _error = '"Rises above" should be above today\'s price');
      return;
    }
    if (below != null && below >= widget.price) {
      setState(() => _error = '"Falls below" should be below today\'s price');
      return;
    }
    final w = widget.watch;
    Navigator.pop(
      context,
      PairAlertResult.save(PairWatch(
        symbol: w.symbol,
        title: w.title,
        frame: _frame,
        lastPrice: widget.price,
        baseline: widget.price,
        setups: _setups,
        countChanges: _count,
        targets: _targets,
        above: above,
        below: below,
        movePct: _move,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget toggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) => SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(title),
          subtitle: Text(subtitle),
          value: value,
          onChanged: onChanged,
        );
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Alerts: ${widget.watch.title}', style: text.titleLarge),
          Text('Now ${_fmt(widget.price)}', style: text.bodyMedium),
          const SizedBox(height: 12),
          Text('Timeframe', style: text.titleSmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            children: [
              for (final f in pairWatchFrames)
                ChoiceChip(
                  label: Text(f.label),
                  selected: f == _frame,
                  visualDensity: VisualDensity.compact,
                  // Only for a new watch: changing it would be a different watch.
                  onSelected: widget.isNew ? (_) => setState(() => _frame = f) : null,
                ),
            ],
          ),
          const SizedBox(height: 8),
          toggle('New buy / sell setup', 'The wave count gives a trade with reward:risk of 1 or better',
              _setups, (v) => setState(() => _setups = v)),
          toggle('Wave count changes', 'e.g. wave 3 → wave 4, or the count flips direction', _count,
              (v) => setState(() => _count = v)),
          toggle('Target reached or count invalidated', 'Price reaches the target zone, or breaks the invalidation level',
              _targets, (v) => setState(() => _targets = v)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _above,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Rises above', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _below,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Falls below', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(_move == 0 ? 'Big moves: off' : 'When it moves ±${_move.round()}%', style: text.titleSmall),
          Slider(
            value: _move,
            min: 0,
            max: 20,
            divisions: 20,
            label: _move == 0 ? 'off' : '${_move.round()}%',
            onChanged: (v) => setState(() => _move = v),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          Text(
            'Checked $backgroundCadence, on closed ${_frame.label} candles. A setup is the wave count\'s trade plan, '
            'not a guarantee: see the public track record on the Setups tab for how they have done.',
            style: text.bodySmall,
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: Text(widget.isNew ? 'Watch' : 'Save')),
          if (!widget.isNew)
            TextButton(
              onPressed: () => Navigator.pop(context, PairAlertResult.remove()),
              child: const Text('Stop watching'),
            ),
        ],
      ),
    );
  }
}
