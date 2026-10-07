import 'dart:async';

import 'package:flutter/material.dart';

import 'alerts.dart';
import 'candles.dart';
import 'screens/about_screen.dart';
import 'screens/crypto_screen.dart';
import 'screens/instrument_screen.dart';
import 'screens/markets_screen.dart';
import 'screens/setups_screen.dart';
import 'screens/watchlist_screen.dart';
import 'sources/binance.dart';

/// Payloads of notifications tapped while the app is running.
final _taps = StreamController<String>.broadcast();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Alerts are an extra; never let their setup keep the app from opening.
  try {
    await initNotifications(onTap: _taps.add);
    await scheduleBackgroundChecks();
  } catch (e, st) {
    debugPrint('Alert setup failed: $e\n$st');
  }
  runApp(const TantyaApp());
}

class TantyaApp extends StatelessWidget {
  const TantyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF2D6BEA);
    return MaterialApp(
      title: 'Tantya',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.light),
      darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  final _cryptoKey = GlobalKey<CryptoScreenState>();
  final _setupsKey = GlobalKey<SetupsScreenState>();
  final _watchlistKey = GlobalKey<WatchlistScreenState>();
  StreamSubscription<String>? _tapSub;

  @override
  void initState() {
    super.initState();
    _tapSub = _taps.stream.listen(_openFromNotification);
    // A tap that launched the app from scratch arrives here instead of the stream.
    launchPayload().then((p) {
      if (p != null && mounted) _openFromNotification(p);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _tapSub?.cancel();
    super.dispose();
  }

  void _select(int i) {
    setState(() => _tab = i);
    if (i == 2) _setupsKey.currentState?.refresh();
    if (i == 3) _watchlistKey.currentState?.refresh();
  }

  void _openFromNotification(String payload) {
    final parts = payload.split('|');
    switch (parts.first) {
      case 'setups':
        _select(2);
      case 'scanner':
        _select(0);
        _cryptoKey.currentState?.showScanner();
      case 'pair' when parts.length == 3:
        _select(0);
        final pair = Ticker.bare(parts[1]).pair;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => InstrumentScreen(
            source: BinanceSource(parts[1], base: pair?.$1, quote: pair?.$2),
            initialFrame: Timeframe.values.asNameMap()[parts[2]],
          ),
        ));
    }
  }

  static const _tabs = [
    (Icons.candlestick_chart_outlined, Icons.candlestick_chart, 'Crypto'),
    (Icons.how_to_vote_outlined, Icons.how_to_vote, 'Polymarket'),
    (Icons.fact_check_outlined, Icons.fact_check, 'Setups'),
    (Icons.notifications_none, Icons.notifications, 'Watchlist'),
    (Icons.info_outline, Icons.info, 'About'),
  ];

  @override
  Widget build(BuildContext context) {
    final body = IndexedStack(
      index: _tab,
      children: [
        CryptoScreen(key: _cryptoKey),
        const MarketsScreen(),
        SetupsScreen(key: _setupsKey),
        WatchlistScreen(key: _watchlistKey),
        const AboutScreen(),
      ],
    );

    // Desktop / tablet: a side rail, and lists kept to a readable width.
    if (MediaQuery.sizeOf(context).width >= 900) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _tab,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final (icon, selected, label) in _tabs)
                  NavigationRailDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: Text(label)),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: body),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _select,
        destinations: [
          for (final (icon, selected, label) in _tabs)
            NavigationDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: label),
        ],
      ),
    );
  }
}
