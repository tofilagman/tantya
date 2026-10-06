import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../alerts.dart';
import '../candles.dart';
import '../mtf.dart';
import '../scan_alerts.dart';
import '../scanner.dart';
import '../setup.dart';
import '../sources/binance.dart';
import 'ew_panel.dart' show HtfBadge;
import 'instrument_screen.dart';

/// Scans the top Binance pairs on one timeframe and ranks their Elliott Wave setups.
class ScannerView extends StatefulWidget {
  const ScannerView({super.key, required this.tickers});

  /// All tickers, sorted by 24h quote volume (from the Crypto tab).
  final List<Ticker> tickers;

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> {
  static const _frames = [Timeframe.m5, Timeframe.m15, Timeframe.h1, Timeframe.h4, Timeframe.d1];
  static const _universes = [30, 50, 100];

  Timeframe _frame = Timeframe.h1;
  int _universe = 50;

  List<ScanResult>? _results;
  (Timeframe, int, DateTime)? _scannedWith;
  (int, int)? _progress;
  int _run = 0;

  Bias _bias = Bias.all;
  bool _minRR = true;
  bool _agreeOnly = false;

  /// Only setups the next timeframe up agrees with. Also the background-alert criterion.
  bool _htfOnly = true;

  ScanAlertSettings? _alerts;

  bool get _scanning => _progress != null;

  @override
  void initState() {
    super.initState();
    ScanAlertStore.settings().then((s) {
      if (mounted) setState(() => _alerts = s);
    });
  }

  ScanAlertSettings get _current => ScanAlertSettings(
        frame: _frame,
        universe: _universe,
        bias: _bias,
        minRR: _minRR ? 1.5 : 0,
        agreeOnly: _agreeOnly,
        htfAgreeOnly: _htfOnly,
      );

  Future<void> _enableAlerts() async {
    final granted = await requestNotificationPermission();
    final s = _current;
    await ScanAlertStore.enable(s);
    if (!mounted) return;
    setState(() => _alerts = s);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(granted
          ? 'Background alerts on. You\'ll be notified of new ${s.frame.label} setups.'
          : 'Saved, but notifications are blocked. Allow them in system settings.'),
    ));
  }

  Future<void> _disableAlerts() async {
    await ScanAlertStore.disable();
    if (mounted) setState(() => _alerts = null);
  }

  Future<void> _scan() async {
    final run = ++_run;
    final pairs = widget.tickers.where((t) => t.mainstream).take(_universe).toList();
    final frame = _frame;
    setState(() => _progress = (0, pairs.length));
    try {
      final results = await scan(
        pairs,
        frame,
        onProgress: (d, n) {
          if (mounted && run == _run) setState(() => _progress = (d, n));
        },
        // A newer scan (or leaving the screen) abandons this one.
        cancelled: () => !mounted || run != _run,
      );
      if (!mounted || run != _run) return;
      setState(() {
        _results = results;
        _scannedWith = (frame, pairs.length, DateTime.now());
        _progress = null;
      });
    } on ScanCancelled {
      return;
    } catch (e) {
      if (!mounted || run != _run) return;
      setState(() => _progress = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Scan failed: $e')));
    }
  }

  List<ScanResult> get _filtered => (_results ?? const <ScanResult>[]).where((r) {
        if (_bias == Bias.long && r.setup.side != Side.long) return false;
        if (_bias == Bias.short && r.setup.side != Side.short) return false;
        if (_minRR && r.setup.rr1 < 1.5) return false;
        if (_agreeOnly && !r.analysis.consensus) return false;
        if (_htfOnly && r.htf != null && r.htf!.verdict != HtfVerdict.agree) return false;
        return true;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final results = _results;
    final shown = _filtered;
    return RefreshIndicator(
      onRefresh: _scan,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
        children: [
          _controls(text),
          _alertsCard(text),
          const SizedBox(height: 8),
          if (_scanning) _progressBar(text),
          if (results != null && !_scanning) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text(
                '${shown.length} of ${results.length} setups shown · '
                '${_scannedWith!.$2} pairs on ${_scannedWith!.$1.label} · '
                'scanned ${DateFormat.Hm().format(_scannedWith!.$3)}',
                style: text.labelMedium,
              ),
            ),
            if (_scannedWith!.$1 != _frame || _scannedWith!.$2 != _universe)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('Settings changed. Tap Scan to update.',
                    style: text.labelMedium?.copyWith(color: Colors.orange.shade800)),
              ),
            if (shown.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text('No setups pass these filters. Loosen them or try another timeframe.',
                    textAlign: TextAlign.center),
              ),
            for (var i = 0; i < shown.length; i++) _ResultCard(rank: i + 1, result: shown[i], frame: _scannedWith!.$1),
          ],
          if (results == null && !_scanning)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Runs the Elliott Wave engine on the most traded pairs and lists the strongest setups: '
                'a textbook-looking count, worthwhile reward:risk, and most of the move still ahead.',
                textAlign: TextAlign.center,
                style: text.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }

  Widget _controls(TextTheme text) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final f in _frames)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(f.label),
                        selected: f == _frame,
                        visualDensity: VisualDensity.compact,
                        onSelected: _scanning ? null : (_) => setState(() => _frame = f),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('Top', style: text.bodyMedium),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _universe,
                  underline: const SizedBox.shrink(),
                  items: [for (final u in _universes) DropdownMenuItem(value: u, child: Text('$u pairs'))],
                  onChanged: _scanning ? null : (u) => setState(() => _universe = u!),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _scanning || widget.tickers.isEmpty ? null : _scan,
                  icon: const Icon(Icons.radar),
                  label: Text(_results == null ? 'Scan' : 'Rescan'),
                ),
              ],
            ),
            const Divider(height: 16),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                SegmentedButton<Bias>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(visualDensity: VisualDensity.compact),
                  segments: const [
                    ButtonSegment(value: Bias.all, label: Text('All')),
                    ButtonSegment(value: Bias.long, label: Text('Long')),
                    ButtonSegment(value: Bias.short, label: Text('Short')),
                  ],
                  selected: {_bias},
                  onSelectionChanged: (s) => setState(() => _bias = s.first),
                ),
                FilterChip(
                  label: const Text('R:R ≥ 1.5'),
                  selected: _minRR,
                  visualDensity: VisualDensity.compact,
                  onSelected: (v) => setState(() => _minRR = v),
                ),
                FilterChip(
                  label: const Text('Counts agree'),
                  selected: _agreeOnly,
                  visualDensity: VisualDensity.compact,
                  onSelected: (v) => setState(() => _agreeOnly = v),
                ),
                if (_frame.higher != null)
                  FilterChip(
                    label: Text('${_frame.higher!.label} agrees'),
                    selected: _htfOnly,
                    visualDensity: VisualDensity.compact,
                    onSelected: (v) => setState(() => _htfOnly = v),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _alertsCard(TextTheme text) {
    final a = _alerts;
    final canAlert = ScanAlertSettings.frames.contains(_frame);
    String describe(ScanAlertSettings s) => [
          s.frame.label,
          'top ${s.universe}',
          if (s.bias != Bias.all) s.bias == Bias.long ? 'longs' : 'shorts',
          if (s.minRR > 0) 'R:R ≥ ${s.minRR}',
          if (s.agreeOnly) 'counts agree',
          if (s.htfAgreeOnly && s.frame.higher != null) '${s.frame.higher!.label} agrees',
          'score ≥ ${(s.minFit * 100).round()}',
          '< ${(s.maxProgress * 100).round()}% of move done',
        ].join(' · ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(a == null ? Icons.notifications_off_outlined : Icons.notifications_active,
                    size: 20, color: a == null ? null : Colors.green.shade600),
                const SizedBox(width: 8),
                Expanded(child: Text(a == null ? 'Background alerts' : 'Background alerts on', style: text.titleSmall)),
                if (a != null) TextButton(onPressed: _disableAlerts, child: const Text('Turn off')),
              ],
            ),
            const SizedBox(height: 4),
            if (a != null) ...[
              Text(describe(a), style: text.bodySmall),
              const SizedBox(height: 4),
              Text(
                'Scans once per new ${a.frame.label} candle (checked every ~15 min) and notifies only setups '
                'it hasn\'t reported before. About ${a.megabytesPerDay.toStringAsFixed(0)} MB of data a day.',
                style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              if (describe(a) != describe(_current) && canAlert)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _enableAlerts,
                    icon: const Icon(Icons.sync, size: 18),
                    label: const Text('Use the settings above instead'),
                  ),
                ),
            ] else ...[
              Text(
                canAlert
                    ? 'Get notified when the scanner finds a fresh setup matching the settings above '
                        '(plus score ≥ 60 and under half the move done), even with the app closed. '
                        'About ${_current.megabytesPerDay.toStringAsFixed(0)} MB of data a day.'
                    : '5m is too fast for the background check, which runs every ~15 min. '
                        'Pick 15m or higher to set up alerts.',
                style: text.bodySmall,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: canAlert ? _enableAlerts : null,
                  icon: const Icon(Icons.notifications_active_outlined, size: 18),
                  label: const Text('Alert me about new setups like these'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _progressBar(TextTheme text) {
    final (done, total) = _progress!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: total == 0 ? null : done / total),
          const SizedBox(height: 6),
          Text(
            'Counting waves… $done / $total pairs'
            '${_frame.higher == null ? '' : ' (checking ${_frame.higher!.label} too)'}',
            style: text.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.rank, required this.result, required this.frame});

  final int rank;
  final ScanResult result;
  final Timeframe frame;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final r = result;
    final s = r.setup;
    final long = s.side == Side.long;
    final color = long ? Colors.green.shade600 : Colors.red.shade400;
    final pair = r.ticker.pair;
    String fmt(double p) => p.toStringAsFixed(decimalsFor(p));
    String pctFrom(double level) => '${((level - s.entry) / s.entry * 100).abs().toStringAsFixed(2)}%';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => InstrumentScreen(
            source: BinanceSource(r.ticker.symbol, base: pair?.$1, quote: pair?.$2),
            initialFrame: frame,
          ),
        )),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('#$rank', style: text.labelLarge?.copyWith(color: Theme.of(context).colorScheme.outline)),
                  const SizedBox(width: 8),
                  Text(pair == null ? r.ticker.symbol : '${pair.$1}/${pair.$2}',
                      style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                    child: Text(long ? 'LONG' : 'SHORT',
                        style: text.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                  const Spacer(),
                  if (r.analysis.consensus)
                    Tooltip(
                      message: 'Top counts agree on direction',
                      child: Icon(Icons.verified, size: 18, color: Colors.green.shade600),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(r.scenario.title, style: text.bodyMedium),
              const SizedBox(height: 10),
              Row(
                children: [
                  _metric(text, 'Score', '${(r.scenario.score * 100).round()}'),
                  _metric(text, 'R:R', s.rr1.toStringAsFixed(2)),
                  _metric(text, 'Stop', pctFrom(s.stop), color: Colors.red.shade400),
                  _metric(text, 'TP1', pctFrom(s.tp1), color: Colors.green.shade600),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('Move done', style: text.labelSmall),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: r.progress,
                        minHeight: 5,
                        color: r.progress < 0.5 ? Colors.green.shade600 : Colors.orange.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${(r.progress * 100).round()}%', style: text.labelSmall),
                ],
              ),
              if (r.htf != null) ...[
                const SizedBox(height: 8),
                HtfBadge(frame: r.htf!.frame, check: r.htf, compact: true),
              ],
              const SizedBox(height: 6),
              Text('Entry ${fmt(s.entry)} · SL ${fmt(s.stop)} · TP1 ${fmt(s.tp1)} · TP2 ${fmt(s.tp2)}',
                  style: text.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metric(TextTheme text, String label, String value, {Color? color}) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: text.labelSmall),
            Text(value, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      );
}
