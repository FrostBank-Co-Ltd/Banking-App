import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_bank_app/core/design/theme.dart';
import 'package:mobile_bank_app/data/netkeiba_repository_impl.dart';
import 'package:mobile_bank_app/domain/netkeiba_models.dart';
import 'package:mobile_bank_app/presentation/screens/netkeiba_race_screen.dart';
import 'package:mobile_bank_app/state/netkeiba_providers.dart';

void main() {
  group('Netkeiba Domain Models', () {
    test('NetkeibaRace.fromMap parses JRA JSON data correctly', () {
      final map = {
        'raceId': '20260614',
        'raceName': 'TAKARAZUKA KINEN',
        'venue': 'Hanshin Racecourse',
        'raceNumber': 11,
        'distanceM': 2200,
        'surface': 'turf',
        'grade': 'G1',
        'going': 'Sft',
        'status': 'finished',
        'results': [
          {
            'horseNumber': 16,
            'bracket': 8,
            'horseName': 'Meisho Tabaru',
            'sexAge': '5H',
            'jockey': 'Y.Take',
            'weightCarriedKg': 58.0,
            'winOdds': 3.9,
            'popularity': 1,
            'finishPosition': '1',
            'time': '2:12.1',
            'trainer': 'M.Ishibashi',
          }
        ],
        'payouts': [
          {
            'betType': 'win',
            'numbers': [16],
            'payoutsJpy': [390],
          }
        ],
      };

      final race = NetkeibaRace.fromMap(map);
      expect(race.raceId, equals('20260614'));
      expect(race.raceName, equals('TAKARAZUKA KINEN'));
      expect(race.runners.length, equals(1));
      expect(race.runners.first.horseName, equals('Meisho Tabaru'));
      expect(race.payoutItems?.first.payoutsJpy.first, equals(390));
    });
  });

  group('ApifyNetkeibaRaceRepository G1 Race Dates', () {
    test('fetchRecentRaces returns seeded G1 races when token empty', () async {
      final repo = ApifyNetkeibaRaceRepository(apifyApiToken: '');
      final list = await repo.fetchRecentRaces();
      expect(list.isNotEmpty, isTrue);
      final raceIds = list.map((r) => r.raceId).toList();
      expect(raceIds, containsAll(['20260524', '20260531', '20260607', '20260614']));
    });

    test('fetchRaceDetails fetches Japanese Derby 20260531 correctly', () async {
      final repo = ApifyNetkeibaRaceRepository(apifyApiToken: '');
      final race = await repo.fetchRaceDetails('20260531');
      expect(race.raceId, equals('20260531'));
      expect(race.raceName, contains('TOKYO YUSHUN'));
      expect(race.runners.first.horseName, equals('Danon Decile'));
    });
  });

  group('NetkeibaRaceScreen UI & Calendar Test', () {
    Widget harness() => ProviderScope(
          overrides: [
            apifyTokenProvider.overrideWith(() => _OfflineApifyTokenController()),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const NetkeibaRaceScreen(),
          ),
        );

    testWidgets('Renders JRA G1 Race Calendar & Hub screen', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      expect(find.text('JRA G1 Race Calendar & Hub'), findsOneWidget);
      expect(find.text('JRA G1 Season Calendar'), findsOneWidget);
      expect(find.text('Danon Decile'), findsWidgets);
      expect(find.text('N.Yokoyama'), findsOneWidget);
    });

    testWidgets('Tapping Jun 07 Yasuda Kinen calendar chip switches selected race', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      final yasudaChip = find.text('Yasuda');
      expect(yasudaChip, findsOneWidget);

      await tester.tap(yasudaChip);
      await tester.pumpAndSettle();

      expect(find.text('Romantic Warrior'), findsWidgets);
      expect(find.text('J.McDonald'), findsOneWidget);
    });

    testWidgets('Race Simulator tab calculates simulation correctly', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      final simTab = find.text('Race Simulator 🏇');
      expect(simTab, findsOneWidget);

      await tester.tap(simTab);
      await tester.pumpAndSettle();

      expect(find.text('Run Race Simulation 🏇'), findsOneWidget);

      await tester.tap(find.text('Run Race Simulation 🏇'));
      await tester.pumpAndSettle();

      expect(find.textContaining('WINNER!'), findsOneWidget);
    });
  });
}

class _OfflineApifyTokenController extends ApifyTokenController {
  @override
  String build() => '';
}
