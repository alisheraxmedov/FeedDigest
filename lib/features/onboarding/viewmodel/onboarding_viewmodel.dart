/*
Tracks whether the first-run onboarding has been shown. The flag lives in the
Hive `meta` box (same store as the other app preferences) so it survives
restarts; once seen, onboarding never appears again.
*/
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';

final onboardingSeenProvider = NotifierProvider<OnboardingController, bool>(
  OnboardingController.new,
);

class OnboardingController extends Notifier<bool> {
  static const String _key = 'onboarding_seen';

  @override
  bool build() => ref.read(metaBoxProvider).get(_key) as bool? ?? false;

  Future<void> markSeen() async {
    if (state) return;
    state = true;
    final box = ref.read(metaBoxProvider);
    await box.put(_key, true);
    await box.flush();
  }
}
