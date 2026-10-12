import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tantya/theme_mode.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults to System, then remembers the choice', () async {
    final a = await ThemeController.load();
    expect(a.value, ThemeMode.system);
    await a.set(ThemeMode.dark);
    final b = await ThemeController.load();
    expect(b.value, ThemeMode.dark);
  });

  test('cycle goes System → Light → Dark → System', () async {
    final c = await ThemeController.load();
    final seen = <ThemeMode>[];
    for (var i = 0; i < 3; i++) {
      await c.cycle();
      seen.add(c.value);
    }
    expect(seen, [ThemeMode.light, ThemeMode.dark, ThemeMode.system]);
  });

  test('an unknown saved value falls back to System', () async {
    SharedPreferences.setMockInitialValues({'theme.mode.v1': 'sepia'});
    expect((await ThemeController.load()).value, ThemeMode.system);
  });
}
