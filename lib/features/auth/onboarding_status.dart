import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';

/// Key that stores the onboarding status **inside the signed-in account's
/// Supabase auth user metadata** (`auth.users.raw_user_meta_data`).
///
/// This is the account-wide source of truth the router reads. Onboarding used
/// to be a single SharedPreferences boolean — a *device* flag: one
/// installation shared one boolean across every account that ever signed in
/// on it, so onboarding appeared on the first login only and a second account
/// (or the same account on another device) never saw it again. Auth user
/// metadata travels with the account, so the same status shows up on a fresh
/// install once the session is restored, without any new table, migration, or
/// RPC.
///
/// The value stored is just a `true` boolean — never a token or any
/// credential-bearing payload. The literal is the same historical
/// `netlearn_onboarding_complete` string so no other key collides with what
/// earlier app versions wrote locally.
const String onboardingCompleteMetadataKey = 'netlearn_onboarding_complete';

/// The device-local flag the flow used to write. The router no longer treats
/// it as authoritative, but the flow still writes it and this module still
/// reads it in one narrow case: when Supabase is not reachable from Dart at
/// all (unit/widget tests offline), so the decision stays decidable without a
/// backend and the pre-account-scoped tests keep their deterministic shape.
const String onboardingLegacyLocalKey = 'netlearn_onboarding_complete';

/// Whether the signed-in account has completed onboarding.
///
/// Reads the current user's auth metadata straight from the restored session,
/// so no extra network round-trip happens in the router redirect. Must only be
/// called when a session exists (the router already guarantees that before the
/// onboarding gate).
///
/// Existing users who completed onboarding before this flag moved to the
/// account deliberately see the flow one more time: migrating the old
/// device-local flag would wrongly "complete" onboarding for any account that
/// signs in on a device where *anyone* once finished it. One extra run of the
/// flow, and from then on the status lives on the account itself.
Future<bool> isOnboardingCompleteForCurrentUser() async {
  try {
    final user = supabase.auth.currentUser;
    final metadata = user?.userMetadata;
    return metadata?[onboardingCompleteMetadataKey] == true;
  } catch (_) {
    // Supabase is not initialized (tests run offline). Fall back to the
    // device-local flag so a test can arrange a known onboarding state without
    // a backend; in production this branch does not run because the router
    // only asks this question behind an active session.
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(onboardingLegacyLocalKey) ?? false;
  }
}

/// Records onboarding completion on the signed-in account.
///
/// Writes both places: the account's auth metadata (the status every device
/// reads) and the legacy device-local flag (the offline fallback above).
///
/// Returns `true` only when the account-wide write actually succeeded. A
/// `false` return means Supabase is unreachable or no user is signed in — the
/// caller must not claim the status was saved. The worst case is the flow
/// repeating on the next sign-in; nothing gets corrupted.
Future<bool> markOnboardingCompleteForCurrentUser() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(onboardingLegacyLocalKey, true);

  try {
    final auth = supabase.auth;
    final user = auth.currentUser;
    if (user == null) {
      return false;
    }

    final metadata = user.userMetadata;
    if (metadata?[onboardingCompleteMetadataKey] == true) {
      return true;
    }

    final response = await auth.updateUser(
      UserAttributes(data: {onboardingCompleteMetadataKey: true}),
    );
    final updatedMetadata = response.user?.userMetadata;
    return updatedMetadata?[onboardingCompleteMetadataKey] == true;
  } catch (_) {
    return false;
  }
}
