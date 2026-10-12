import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tantya/journal.dart';
import 'package:tantya/screens/journal_screen.dart';
import 'package:tantya/screens/position_size_sheet.dart';

Future<void> openSheet(WidgetTester tester, Widget sheet) async {
  await tester.binding.setSurfaceSize(const Size(420, 1400));
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            builder: (_) => sheet,
          ),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('size a trade, log it, close it in the journal', (tester) async {
    await openSheet(
      tester,
      PositionSizeSheet(
        title: 'BTC/USDT', frame: '1h', count: 'Impulse ↑ · wave 3', sourceId: 'binance:BTCUSDT',
        entry: 100, stop: 95, tp1: 110, format: (p) => p.toStringAsFixed(2),
      ),
    );
    expect(find.textContaining('Enter your balance'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Account balance'), '1000');
    await tester.pumpAndSettle();
    expect(find.text('BUY ${formatSize(10 / 5.195)}'), findsOneWidget);
    expect(find.textContaining('−10.00 USDT'), findsOneWidget);

    await tester.tap(find.textContaining('log it to my journal'));
    await tester.pumpAndSettle();
    final logged = (await JournalStore.load()).single;
    expect(logged.title, 'BTC/USDT');
    expect(logged.riskAmount, closeTo(10, 1e-9));
    expect((await SizingDefaults.load()).balance, 1000);

    // Close it at TP1 with the journal sheet.
    await openSheet(tester, JournalEntrySheet(entry: logged));
    await tester.tap(find.text('Closed'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Exit price'), '110');
    await tester.tap(find.text('Yes'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final closed = (await JournalStore.load()).single;
    expect(closed.status, JournalStatus.closed);
    expect(closed.r, greaterThan(1.8));
    expect(closed.followedPlan, isTrue);
  });

  testWidgets('a hand-added trade is validated', (tester) async {
    await openSheet(tester, const JournalEntrySheet());
    await tester.enterText(find.widgetWithText(TextField, 'Pair'), 'SOL/USDT');
    await tester.enterText(find.widgetWithText(TextField, 'Entry'), '100');
    await tester.enterText(find.widgetWithText(TextField, 'Original stop'), '105');
    await tester.enterText(find.widgetWithText(TextField, 'Size (units)'), '2');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('stop must be below'), findsOneWidget);
    await tester.tap(find.text('Short'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final e = (await JournalStore.load()).single;
    expect(e.riskAmount, closeTo(2 * (5 + 0.001 * 205), 1e-9));
  });
}
