import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/business.dart';
import '../data/business_repository.dart';

final businessRepositoryProvider =
    Provider<BusinessRepository>((ref) => const BusinessRepository());

/// Drives BusinessRegistrationPage's submit button: idle (null, not loading)
/// → loading → data (the newly-created Business) or error.
class BusinessRegistrationController extends AsyncNotifier<Business?> {
  @override
  Future<Business?> build() async => null; // nothing submitted yet this session

  Future<void> submit(BusinessRegistrationDraft draft) async {
    state = const AsyncLoading();
    final repo = ref.read(businessRepositoryProvider);
    state = await AsyncValue.guard(() => repo.register(draft));
  }
}

final businessRegistrationControllerProvider =
    AsyncNotifierProvider<BusinessRegistrationController, Business?>(
  BusinessRegistrationController.new,
);

/// The logged-in business's own profile. Watch `.canPostOpportunities` on
//final businessRegistrationControllerProvider AsyncNotifierProvider<BusinessRegistrationContriller,Business
/// the result to gate the "Post Opportunity" action anywhere in the app —
/// e.g. `ref.watch(myBusinessProvider).valueOrNull?.canPostOpportunities`.
final myBusinessProvider = FutureProvider<Business>((ref) {
  return ref.watch(businessRepositoryProvider).getMyBusiness();
});