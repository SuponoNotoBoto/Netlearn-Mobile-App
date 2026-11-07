import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../supabase/supabase_client.dart';

class LanguageController extends Notifier<Locale> {
  static const String _languageKey = 'netlearn_language';

  @override
  Locale build() {
    return const Locale('en');
  }

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();

    final String? savedLanguage =
    preferences.getString(_languageKey);

    if (savedLanguage == 'id') {
      state = const Locale('id');
      return;
    }

    if (savedLanguage == 'en') {
      state = const Locale('en');
      return;
    }

    state = const Locale('en');

    await preferences.setString(
      _languageKey,
      'en',
    );
  }

  Future<void> setLanguage(String languageCode) async {
    if (languageCode != 'en' && languageCode != 'id') {
      return;
    }

    state = Locale(languageCode);

    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _languageKey,
      languageCode,
    );

    final user = supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      await supabase
          .from('profiles')
          .update({
        'language': languageCode,
      })
          .eq('id', user.id);
    } catch (_) {
      // Bahasa lokal tetap tersimpan
      // walaupun update profile gagal.
    }
  }

  Future<void> syncFromProfile() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      final profile = await supabase
          .from('profiles')
          .select('language')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        return;
      }

      final dynamic rawLanguage = profile['language'];

      final String language =
          rawLanguage?.toString() ?? '';

      if (language != 'en' && language != 'id') {
        return;
      }

      state = Locale(language);

      final preferences = await SharedPreferences.getInstance();

      await preferences.setString(
        _languageKey,
        language,
      );
    } catch (_) {
      // Jika gagal mengambil profile,
      // gunakan bahasa yang tersimpan secara lokal.
    }
  }
}

final languageProvider =
NotifierProvider<LanguageController, Locale>(
  LanguageController.new,
);