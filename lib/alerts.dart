import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

import 'api.dart';
import 'mtf.dart';
import 'scan_alerts.dart';
import 'scanner.dart';
import 'setup.dart';
import 'sources/binance.dart';
import 'watchlist.dart';

const _taskName = 'tantya.checkWatchlist';
final _notifications = FlutterLocalNotificationsPlugin();

const _channel = AndroidNotificationDetails(
  'price_alerts',
  'Price alerts',
  channelDescription: 'Watched markets moving or crossing your levels',
  importance: Importance.high,
  priority: Priority.high,
);

/// iOS/macOS: show the banner and play the sound even when the app is in the foreground.
const _ios = DarwinNotificationDetails(presentAlert: true, presentBanner: true, presentSound: true);

/// Windows, macOS and Linux have no WorkManager-style scheduler for Flutter, so the
/// checks run on a timer inside the app instead: only while it is open.
bool get isDesktop => Platform.isWindows || Platform.isMacOS || Platform.isLinux;

/// Entry point for the WorkManager background isolate.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, _) async {
    WidgetsFlutterBinding.ensureInitialized();
    await initNotifications();
    return runChecks(); // false lets WorkManager retry sooner
  });
}

/// Watchlist alerts, setup results and the background scan. Independent: one failing
/// (network blip) doesn't skip the others. Returns false if any failed.
Future<bool> runChecks() async {
  var ok = true;
  for (final check in [checkWatchlist, checkSetups, checkScan]) {
    try {
      await check();
    } catch (_) {
      ok = false;
    }
  }
  return ok;
}

/// How often background checks run, for user-facing text. Android's WorkManager honours
/// the 15-minute period; iOS runs background refresh when it sees fit, typically far less
/// often (and less still for apps that are rarely opened); desktop runs them in-app.
String get backgroundCadence => Platform.isIOS
    ? 'when iOS allows, often hourly'
    : isDesktop
        ? 'every 15 min while Tantya is open'
        : 'about every 15 min';

/// Where a tapped notification should take the user, carried in its payload:
/// `pair|SOLUSDT|h1`, `scanner` or `setups`.
typedef NotificationTap = void Function(String payload);

Future<void> initNotifications({NotificationTap? onTap}) async {
  await _notifications.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_notification'),
      // Don't prompt at launch (this also runs in the background isolate, which can't
      // prompt); [requestNotificationPermission] asks when the user turns an alert on.
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      windows: WindowsInitializationSettings(
        appName: 'Tantya',
        appUserModelId: 'org.r3al.tantya',
        // Fixed for the app's lifetime: Windows uses it to route notification clicks back.
        guid: 'b5beee93-461b-41a0-a2c9-b6b9b76d99b6',
      ),
    ),
    onDidReceiveNotificationResponse: onTap == null
        ? null
        : (r) {
            final p = r.payload;
            if (p != null) onTap(p);
          },
  );
}

/// Payload of the notification that launched the app from scratch, if any.
Future<String?> launchPayload() async {
  final d = await _notifications.getNotificationAppLaunchDetails();
  return d?.didNotificationLaunchApp == true ? d!.notificationResponse?.payload : null;
}

Future<bool> requestNotificationPermission() async {
  final android = _notifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  // Null below Android 13, where no runtime permission exists.
  if (android != null) return await android.requestNotificationsPermission() ?? true;
  final ios = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
  if (ios != null) return await ios.requestPermissions(alert: true, sound: true) ?? false;
  final mac = _notifications.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
  if (mac != null) return await mac.requestPermissions(alert: true, sound: true) ?? false;
  return true; // Windows: no runtime permission
}

Timer? _desktopTimer;

/// Desktop: run the checks every 15 minutes while the app is open, starting a minute
/// after launch so the first screen loads undisturbed.
void _startDesktopChecks() {
  _desktopTimer?.cancel();
  Timer(const Duration(minutes: 1), runChecks);
  _desktopTimer = Timer.periodic(const Duration(minutes: 15), (_) => runChecks());
}

/// Starts the 15-minute background check (Android's minimum periodic interval; iOS treats
/// it as the earliest allowed). Desktop runs the same checks on an in-app timer.
Future<void> scheduleBackgroundChecks() async {
  if (isDesktop) {
    _startDesktopChecks();
    return;
  }
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    _taskName,
    _taskName,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}

/// Settles open setups and notifies for each one that hit its target or stop.
Future<void> checkSetups() async {
  for (final s in await SetupStore.resolveOpen()) {
    final r = s.resultR ?? 0;
    final what = switch (s.status) {
      SetupStatus.target => 'hit TP1',
      SetupStatus.stopped => 'stopped out',
      _ => 'expired',
    };
    await _notifications.show(
      id: s.id.hashCode & 0x7fffffff,
      title: '${s.side == Side.long ? 'Long' : 'Short'} ${s.source.title} $what',
      body: '${r >= 0 ? '+' : ''}${r.toStringAsFixed(2)} R · ${s.count}',
      notificationDetails: const NotificationDetails(android: _setupChannel, iOS: _ios, macOS: _ios),
      payload: 'setups',
    );
  }
}

/// Expandable notification on the scanner channel showing all of [body].
NotificationDetails _scanDetails(String body) => NotificationDetails(
      android: AndroidNotificationDetails(
        'scan_setups',
        'New scanner setups',
        channelDescription: 'Fresh Elliott Wave setups found by the background scan',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(body),
        groupKey: 'tantya.scan',
      ),
      iOS: const DarwinNotificationDetails(threadIdentifier: 'tantya.scan'),
      macOS: const DarwinNotificationDetails(threadIdentifier: 'tantya.scan'),
    );

/// Runs the background scan when due and notifies new setups: one notification each
/// for the best three, plus a summary when there are more.
Future<void> checkScan() async {
  final fresh = await ScanAlertStore.runDue();
  if (fresh.isEmpty) return;
  final settings = await ScanAlertStore.settings();
  final frame = settings?.frame;
  for (final r in fresh.take(3)) {
    await _notifications.show(
      id: 'scan|${r.ticker.symbol}'.hashCode & 0x7fffffff,
      title: scanTitle(r, frame?.label),
      body: scanBody(r),
      notificationDetails: _scanDetails(scanBody(r)),
      payload: 'pair|${r.ticker.symbol}|${frame?.name ?? 'h1'}',
    );
  }
  if (fresh.length > 3) {
    await _notifications.show(
      id: 'scan|summary'.hashCode & 0x7fffffff,
      title: '${fresh.length} new Elliott Wave setups${frame == null ? '' : ' on ${frame.label}'}',
      body: fresh.skip(3).map((r) => scanTitle(r, null)).join('\n'),
      notificationDetails: _scanDetails(fresh.skip(3).map((r) => scanTitle(r, null)).join('\n')),
      payload: 'scanner',
    );
  }
}

String scanTitle(ScanResult r, String? frame) {
  final pair = r.ticker.pair;
  final name = pair == null ? r.ticker.symbol : '${pair.$1}/${pair.$2}';
  return '${r.setup.side == Side.long ? 'LONG' : 'SHORT'} $name${frame == null ? '' : ' · $frame'}';
}

String scanBody(ScanResult r) {
  final s = r.setup;
  String f(double p) => p.toStringAsFixed(decimalsFor(p));
  final htf = r.htf;
  final agree = htf == null
      ? ''
      : switch (htf.verdict) {
          HtfVerdict.agree => ' · ${htf.frame.label} agrees',
          HtfVerdict.conflict => ' · ${htf.frame.label} disagrees',
          HtfVerdict.unknown => '',
        };
  return '${r.scenario.title} · score ${(r.scenario.score * 100).round()} · R:R ${s.rr1.toStringAsFixed(2)}$agree\n'
      'Entry ${f(s.entry)} · SL ${f(s.stop)} · TP1 ${f(s.tp1)}';
}

const _setupChannel = AndroidNotificationDetails(
  'setup_results',
  'Setup results',
  channelDescription: 'Tracked Elliott Wave setups reaching their target or stop',
  importance: Importance.high,
  priority: Priority.high,
);

/// Refreshes every watched market, fires notifications for triggered alerts,
/// and returns the fresh markets keyed by market id.
Future<Map<String, Market>> checkWatchlist({PolymarketApi? api}) async {
  api ??= PolymarketApi();
  final items = await WatchStore.load();
  if (items.isEmpty) return {};

  final ids = items.map((i) => i.marketId).toSet();
  final markets = <String, Market>{};
  await Future.wait(ids.map((id) async {
    try {
      markets[id] = await api!.market(id);
    } catch (_) {
      // Skip this one; the rest still get checked.
    }
  }));

  for (final item in items) {
    final m = markets[item.marketId];
    if (m == null || item.outcomeIndex >= m.prices.length) continue;
    final lines = evaluate(item, m.prices[item.outcomeIndex], closed: m.closed);
    if (lines.isNotEmpty) {
      await _notifications.show(
        id: item.key.hashCode & 0x7fffffff,
        title: item.question,
        body: lines.join('\n'),
        notificationDetails: const NotificationDetails(android: _channel, iOS: _ios, macOS: _ios),
      );
    }
  }
  // Re-read before saving so edits made while we were fetching aren't lost.
  final latest = {for (final i in await WatchStore.load()) i.key: i};
  for (final item in items) {
    final current = latest[item.key];
    if (current == null) continue; // removed meanwhile
    current
      ..baseline = item.baseline
      ..lastPrice = item.lastPrice
      ..resolved = item.resolved;
  }
  await WatchStore.save(latest.values.toList());
  return markets;
}
