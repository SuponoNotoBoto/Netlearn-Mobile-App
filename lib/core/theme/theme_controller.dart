import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../supabase/supabase_client.dart';

/// Whether the app renders in light or dark colours.
///
/// The choice is cached locally so the very first frame after launch already
/// uses the right brightness, and mirrored to `profiles.dark_mode` so the
/// setting follows the student to another device.
class ThemeController extends Notifier<ThemeMode> {
  static const String _darkModeKey = 'netlearn_dark_mode';

  @override
  ThemeMode build() {
    return ThemeMode.light;
  }

  bool get isDark => state == ThemeMode.dark;

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();

    state = preferences.getBool(_darkModeKey) == true
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  /// Flips the theme and persists the result.
  Future<void> toggle() async {
    await setDarkMode(!isDark);
  }

  Future<void> setDarkMode(bool enabled) async {
    if (isDark == enabled) {
      return;
    }

    state = enabled ? ThemeMode.dark : ThemeMode.light;

    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_darkModeKey, enabled);

    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        return;
      }

      await supabase
          .from('profiles')
          .update({'dark_mode': enabled})
          .eq('id', user.id);
    } catch (_) {
      // The preference stays cached locally, so a failed profile write only
      // means the choice does not follow the student to another device.
    }
  }

  Future<void> syncFromProfile() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        return;
      }

      final profile = await supabase
          .from('profiles')
          .select('dark_mode')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        return;
      }

      final enabled = profile['dark_mode'] == true;

      state = enabled ? ThemeMode.dark : ThemeMode.light;

      final preferences = await SharedPreferences.getInstance();

      await preferences.setBool(_darkModeKey, enabled);
    } catch (_) {
      // Keep the locally cached choice if the profile cannot be read.
    }
  }
}

final themeModeProvider =
    NotifierProvider<ThemeController, ThemeMode>(
      ThemeController.new,
    );