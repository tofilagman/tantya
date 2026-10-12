import 'package:flutter/material.dart';

import '../journal.dart';
import '../sizing.dart';
import '../trade.dart';

/// Units with decimals that suit their size (0.00123 BTC, 12.5 SOL, 4,200 PEPE).
String formatSize(double v) => v.toStringAsFixed(v >= 1000 ? 0 : v >= 100 ? 2 : v >= 1 ? 4 : 6);

/// Money in the quote currency.
String formatMoney(double v) => '${v < 0 ? '−' : ''}${v.abs().toStringAsFixed(2)}';

/// "Size this trade": how much to buy so the stop loses exactly what you chose to risk,
/// and whether that needs leverage. Can log the trade to the journal.
class PositionSizeSheet extends StatefulWidget {
  const PositionSizeSheet({
    super.key,
    required this.title,
    required this.entry,
    required this.stop,
    required this.format,
    this.tp1,
    this.tp2,
    this.sourceId,
    this.frame,
    this.count,
    this.quote = 'USDT',
    this.leverageAllowed = true,
  });

  final String title;
  final double entry, stop;
  final double? tp1, tp2;
  final String Function(double) format;
  final String? sourceId, frame, count;

  /// Currency the balance is in.
  final String quote;

  /// False where leverage doesn't exist (Polymarket).
  final bool leverageAllowed;

  @override
  State<PositionSizeSheet> createState() => _PositionSizeSheetState();
}

class _PositionSizeSheetState extends State<PositionSizeSheet> {
  final _balance = TextEditingController();
  final _risk = TextEditingController(text: '1');
  final _fee = TextEditingController(text: '0.1');
  late final _entry = TextEditingController(text: widget.format(widget.entry));
  late final _stop = TextEditingController(text: widget.format(widget.stop));

  @override
  void initState() {
    super.initState();
    SizingDefaults.load().then((d) {
      if (!mounted) return;
      setState(() {
        if (d.balance != null && _balance.text.isEmpty) _balance.text = _trim(d.balance!);
        _risk.text = _trim(d.riskPct);
        _fee.text = _trim(d.feePct);
      });
    });
  }

  static String _trim(double v) => v.toString().replaceFirst(RegExp(r'\.0$'), '');

  @override
  void dispose() {
    for (final c in [_balance, _risk, _fee, _entry, _stop]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', ''));

  PositionPlan? get _plan {
    final fee = _num(_fee);
    return PositionPlan.compute(
      balance: _num(_balance) ?? 0,
      riskPct: _num(_risk) ?? 0,
      entry: _num(_entry) ?? 0,
      stop: _num(_stop) ?? 0,
      tp1: widget.tp1,
      tp2: widget.tp2,
      feeRate: fee == null ? defaultFeeRate : fee / 100,
    );
  }

  Future<void> _log(PositionPlan p) async {
    await SizingDefaults(balance: p.balance, riskPct: p.riskPct, feePct: p.feeRate * 100).save();
    await JournalStore.upsert(JournalEntry.fromPlan(p,
        title: widget.title, sourceId: widget.sourceId, frame: widget.frame, count: widget.count));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final p = _plan;
    Widget field(TextEditingController c, String label, {String? suffix}) => TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: label, suffixText: suffix, border: const OutlineInputBorder(), isDense: true),
        );
    Widget row(String label, String value, {Color? color, bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(label, style: text.bodyMedium)),
              const SizedBox(width: 12),
              Flexible(
                child: Text(value,
                    textAlign: TextAlign.end,
                    style: text.bodyMedium?.copyWith(color: color, fontWeight: bold ? FontWeight.w700 : null)),
              ),
            ],
          ),
        );
    final q = widget.quote;
    final green = Colors.green.shade600, red = Colors.red.shade400;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Size this trade', style: text.titleLarge),
          Text('${widget.title}${widget.frame == null ? '' : ' · ${widget.frame}'}', style: text.bodyMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(flex: 3, child: field(_balance, 'Account balance', suffix: q)),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: field(_risk, 'Risk per trade', suffix: '%')),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: [
              for (final r in const [0.5, 1.0, 2.0])
                ChoiceChip(
                  label: Text('${_trim(r)}%'),
                  selected: _num(_risk) == r,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => setState(() => _risk.text = _trim(r)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: field(_entry, 'Entry')),
              const SizedBox(width: 10),
              Expanded(child: field(_stop, 'Stop loss')),
              const SizedBox(width: 10),
              SizedBox(width: 84, child: field(_fee, 'Fee', suffix: '%')),
            ],
          ),
          const SizedBox(height: 16),
          if (p == null)
            Text('Enter your balance and risk to see the size.', style: text.bodyMedium)
          else
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${p.side == Side.long ? 'BUY' : 'SELL'} ${formatSize(p.size)}',
                      style: text.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800, color: p.side == Side.long ? green : red),
                    ),
                    Text('≈ ${formatMoney(p.notional)} $q position', style: text.bodyMedium),
                    const Divider(height: 20),
                    row('At the stop (${widget.format(p.stop)})', '${formatMoney(p.pnlAt(p.stop))} $q · −1R',
                        color: red, bold: true),
                    if (p.tp1 != null)
                      row('At TP1 (${widget.format(p.tp1!)})',
                          '+${formatMoney(p.pnlAt(p.tp1!))} $q · +${p.rAt(p.tp1!).toStringAsFixed(2)}R', color: green),
                    if (p.tp2 != null)
                      row('At TP2 (${widget.format(p.tp2!)})',
                          '+${formatMoney(p.pnlAt(p.tp2!))} $q · +${p.rAt(p.tp2!).toStringAsFixed(2)}R', color: green),
                    row('Fees (in and out at the stop)', '${formatMoney(p.feesAtStop)} $q'),
                    row('Stop distance', '${(p.stopFraction * 100).toStringAsFixed(2)}%'),
                    const Divider(height: 20),
                    if (p.fitsSpot)
                      row('Leverage', 'none needed: fits your balance')
                    else if (widget.leverageAllowed) ...[
                      row('Leverage needed', '${p.leverage}x', bold: true, color: p.leverageSafe ? null : red),
                      row('Margin at ${p.leverage}x', '${formatMoney(p.margin)} $q'),
                      if (p.liquidation != null) row('Liquidation ≈ (isolated)', widget.format(p.liquidation!)),
                      row('Safe maximum for this stop', '${p.maxSafeLeverage}x'),
                      row('On spot instead',
                          'buy ${formatSize(p.spotSize)} (risks ${p.spotRiskPct.toStringAsFixed(2)}%)'),
                    ] else
                      row('Your balance buys', '${formatSize(p.spotSize)} (risks ${p.spotRiskPct.toStringAsFixed(2)}%)'),
                    for (final w in p.warnings)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.warning_amber, size: 18, color: scheme.error),
                            const SizedBox(width: 6),
                            Expanded(child: Text(w, style: text.bodySmall?.copyWith(color: scheme.error))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'The size is what makes the stop cost exactly your risk. Leverage only changes the margin you put up '
            'and where you\'d be liquidated, so use the least that carries the position. Liquidation is an '
            'estimate (${(maintenanceMargin * 100).toStringAsFixed(1)}% maintenance margin); check it on the exchange.',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: p == null ? null : () => _log(p),
            icon: const Icon(Icons.edit_note),
            label: const Text('I took this trade: log it to my journal'),
          ),
        ],
      ),
    );
  }
}
