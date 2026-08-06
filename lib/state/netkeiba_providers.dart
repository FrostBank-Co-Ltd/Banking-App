import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/netkeiba_repository_impl.dart';
import '../domain/netkeiba_models.dart';
import '../domain/netkeiba_repository.dart';

class ApifyTokenController extends Notifier<String> {
  @override
  String build() => const String.fromEnvironment('APIFY_API_TOKEN', defaultValue: '');

  void setToken(String newToken) => state = newToken.trim();
}

/// Provider for user's Apify API Token.
final apifyTokenProvider = NotifierProvider<ApifyTokenController, String>(
  ApifyTokenController.new,
);

/// Provider for the Netkeiba Race Checker repository.
final netkeibaRepositoryProvider = Provider<NetkeibaRaceRepository>((ref) {
  final token = ref.watch(apifyTokenProvider);
  return ApifyNetkeibaRaceRepository(apifyApiToken: token);
});

/// Provider for loading the list of recent / featured JRA races.
final netkeibaRecentRacesProvider = FutureProvider<List<NetkeibaRace>>((ref) async {
  final repo = ref.watch(netkeibaRepositoryProvider);
  return repo.fetchRecentRaces();
});

class SelectedRaceIdController extends Notifier<String> {
  @override
  String build() => '20260531';

  void select(String raceId) => state = raceId;
}

/// Currently selected JRA Race ID in the Netkeiba Race Checker UI.
final selectedRaceIdProvider = NotifierProvider<SelectedRaceIdController, String>(
  SelectedRaceIdController.new,
);

/// Provider for fetching race details by ID.
final netkeibaRaceDetailsProvider =
    FutureProvider.family<NetkeibaRace, String>((ref, raceId) async {
  final repo = ref.watch(netkeibaRepositoryProvider);
  return repo.fetchRaceDetails(raceId);
});
