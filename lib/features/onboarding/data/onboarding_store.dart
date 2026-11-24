import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final onboardingStoreProvider = Provider((ref) => OnboardingStore());
final onboardingCompletedProvider = FutureProvider<bool>(
  (ref) => ref.watch(onboardingStoreProvider).isCompleted(),
);

class OnboardingStore {
  static const profileKey = 'onboarding_profile_v1';

  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(profileKey);
    if (raw == null) return false;
    final profile = jsonDecode(raw) as Map<String, dynamic>;
    return profile['has_completed_onboarding'] == true;
  }

  Future<void> complete() async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(
      profileKey,
      jsonEncode({'has_seen_intro': true, 'has_completed_onboarding': true}),
    )) {
      throw StateError('Không lưu được trạng thái giới thiệu.');
    }
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(profileKey);
  }
}
