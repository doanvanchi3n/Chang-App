import 'dart:convert';

import 'package:chang_app/features/onboarding/data/onboarding_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Đánh dấu intro đã xem và onboarding đã hoàn tất', () async {
    final store = OnboardingStore();

    expect(await store.isCompleted(), isFalse);
    await store.complete();

    final prefs = await SharedPreferences.getInstance();
    final profile = jsonDecode(
      prefs.getString(OnboardingStore.profileKey)!,
    ) as Map<String, dynamic>;
    expect(profile, {'has_seen_intro': true, 'has_completed_onboarding': true});
    expect(await OnboardingStore().isCompleted(), isTrue);
  });
}
