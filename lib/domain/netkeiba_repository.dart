import 'netkeiba_models.dart';

abstract class NetkeibaRaceRepository {
  /// Fetches a list of featured / recent JRA race cards.
  Future<List<NetkeibaRace>> fetchRecentRaces();

  /// Fetches detailed race results, entries, and payouts for a specific 12-digit race ID.
  Future<NetkeibaRace> fetchRaceDetails(String raceId);
}
