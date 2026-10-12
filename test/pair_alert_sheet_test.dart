import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tantya/candles.dart';
import 'package:tantya/pair_watch.dart';
import 'package:tantya/screens/pair_alert_sheet.dart';

void main() {
  testWidgets('typing a level keeps the sheet open and saves it', (tester) async {
    PairAlertResult? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => result = await showModalBottomSheet<PairAlertResult>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => PairAlertSheet(
                watch: PairWatch(symbol: 'BTCUSDT', title: 'BTC/USDT', frame: Timeframe.h1, lastPrice: 100, baseline: 100),
                isNew: true,
                price: 100,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextField, 'Rises above'));
    await tester.pumpAndSettle();
    expect(find.text('Alerts: BTC/USDT'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Rises above'), '105');
    await tester.tap(find.text('4h'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Watch'));
    await tester.tap(find.text('Watch'));
    await tester.pumpAndSettle();
    expect(result?.watch?.above, 105);
    expect(result?.watch?.frame, Timeframe.h4);
  });
}
