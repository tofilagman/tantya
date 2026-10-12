import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's light / dark / follow-the-system choice, remembered across restarts.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController._(super.mode);

  static const _key = 'theme.mode.v1';

  /// Loads the saved choice; System if none (or prefs are unavailable).
  static Future<ThemeController> load() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getString(_key);
      return ThemeController._(ThemeMode.values.asNameMap()[saved] ?? ThemeMode.system);
    } catch (_) {
      return ThemeController._(ThemeMode.system);
    }
  }

  Future<void> set(ThemeMode mode) async {
    value = mode;
    try {
      await (await SharedPreferences.getInstance()).setString(_key, mode.name);
    } catch (_) {
      // Not saved; still applies for this session.
    }
  }

  /// System → Light → Dark → System, for a one-tap button.
  Future<void> cycle() => set(ThemeMode.values[(value.index + 1) % ThemeMode.values.length]);
}

/// Set in main(); read by the screens that offer the toggle.
late final ThemeController themeController;

IconData themeIcon(ThemeMode m) => switch (m) {
      ThemeMode.system => Icons.brightness_auto,
      ThemeMode.light => Icons.light_mode,
      ThemeMode.dark => Icons.dark_mode,
    };

String themeLabel(ThemeMode m) => switch (m) {
      ThemeMode.system => 'System',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };
