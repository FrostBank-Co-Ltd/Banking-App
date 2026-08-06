import 'package:flutter/foundation.dart';

@immutable
class NetkeibaRunner {
  const NetkeibaRunner({
    required this.horseNumber,
    required this.bracketNumber,
    required this.horseName,
    required this.ageSex,
    required this.jockey,
    required this.impostKg,
    this.winOdds,
    this.popularity,
    this.finishPosition,
    this.finishTime,
    this.margin,
    this.trainer,
    this.trainerBarn,
    this.bodyWeightKg,
    this.bodyWeightDiffKg,
  });

  final int horseNumber;
  final int bracketNumber;
  final String horseName;
  final String ageSex;
  final String jockey;
  final double impostKg;
  final double? winOdds;
  final int? popularity;
  final String? finishPosition;
  final String? finishTime;
  final String? margin;
  final String? trainer;
  final String? trainerBarn;
  final double? bodyWeightKg;
  final double? bodyWeightDiffKg;

  // Legacy accessor for compatibility
  double get odds => winOdds ?? 1.0;

  factory NetkeibaRunner.fromMap(Map<String, dynamic> map) {
    final posRaw = map['finishPosition'] ?? map['finish_position'] ?? map['rank'];
    return NetkeibaRunner(
      horseNumber: (map['horseNumber'] ?? map['horse_number'] ?? map['umaban'] ?? 0) as int,
      bracketNumber: (map['bracket'] ?? map['bracket_number'] ?? map['wakuban'] ?? 1) as int,
      horseName: (map['horseName'] ?? map['horse_name'] ?? 'Unknown Horse') as String,
      ageSex: (map['sexAge'] ?? map['age_sex'] ?? 'H4') as String,
      jockey: (map['jockey'] ?? 'TBD') as String,
      impostKg: ((map['weightCarriedKg'] ?? map['impost_kg'] ?? map['weight'] ?? 56.0) as num).toDouble(),
      winOdds: map['winOdds'] != null ? (map['winOdds'] as num).toDouble() : (map['odds'] != null ? (map['odds'] as num).toDouble() : null),
      popularity: map['popularity'] != null ? (map['popularity'] as num).toInt() : (map['ninki'] != null ? (map['ninki'] as num).toInt() : null),
      finishPosition: posRaw?.toString(),
      finishTime: map['time'] as String? ?? map['finish_time'] as String?,
      margin: map['margin'] as String?,
      trainer: map['trainer'] as String?,
      trainerBarn: map['trainerBarn'] as String?,
      bodyWeightKg: map['bodyWeightKg'] != null ? (map['bodyWeightKg'] as num).toDouble() : null,
      bodyWeightDiffKg: map['bodyWeightDiffKg'] != null ? (map['bodyWeightDiffKg'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'horseNumber': horseNumber,
        'bracket': bracketNumber,
        'horseName': horseName,
        'sexAge': ageSex,
        'jockey': jockey,
        'weightCarriedKg': impostKg,
        'winOdds': winOdds,
        'popularity': popularity,
        'finishPosition': finishPosition,
        'time': finishTime,
        'margin': margin,
        'trainer': trainer,
        'trainerBarn': trainerBarn,
        'bodyWeightKg': bodyWeightKg,
        'bodyWeightDiffKg': bodyWeightDiffKg,
      };
}

@immutable
class NetkeibaPayoutItem {
  const NetkeibaPayoutItem({
    required this.betType,
    required this.numbers,
    required this.payoutsJpy,
  });

  final String betType;
  final List<String> numbers;
  final List<int> payoutsJpy;

  factory NetkeibaPayoutItem.fromMap(Map<String, dynamic> map) {
    final numsRaw = map['numbers'] as List? ?? [];
    final jpyRaw = map['payoutsJpy'] as List? ?? [];

    return NetkeibaPayoutItem(
      betType: (map['betType'] ?? map['bet_type'] ?? 'win') as String,
      numbers: numsRaw.map((e) => e.toString()).toList(),
      payoutsJpy: jpyRaw.map((e) => (e as num).toInt()).toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'betType': betType,
        'numbers': numbers,
        'payoutsJpy': payoutsJpy,
      };
}

@immutable
class NetkeibaPayout {
  const NetkeibaPayout({
    required this.win,
    required this.place,
    required this.quinella,
    required this.trifecta,
  });

  final Map<String, int> win;
  final Map<String, int> place;
  final Map<String, int> quinella;
  final Map<String, int> trifecta;

  factory NetkeibaPayout.fromMap(Map<String, dynamic> map) {
    Map<String, int> parseMap(dynamic source) {
      if (source is! Map) return {};
      return source.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    }

    return NetkeibaPayout(
      win: parseMap(map['win']),
      place: parseMap(map['place']),
      quinella: parseMap(map['quinella']),
      trifecta: parseMap(map['trifecta']),
    );
  }

  Map<String, dynamic> toMap() => {
        'win': win,
        'place': place,
        'quinella': quinella,
        'trifecta': trifecta,
      };
}

@immutable
class NetkeibaRace {
  const NetkeibaRace({
    required this.raceId,
    required this.raceName,
    required this.course,
    required this.distanceMeters,
    required this.surface,
    required this.grade,
    required this.date,
    required this.weather,
    required this.trackCondition,
    required this.status,
    required this.runners,
    this.raceNumber,
    this.payoutItems,
    this.legacyPayout,
    this.checkedAt,
  });

  final String raceId;
  final String raceName;
  final String course;
  final int distanceMeters;
  final String surface;
  final String grade;
  final DateTime date;
  final String weather;
  final String trackCondition;
  final String status;
  final int? raceNumber;
  final List<NetkeibaRunner> runners;
  final List<NetkeibaPayoutItem>? payoutItems;
  final NetkeibaPayout? legacyPayout;
  final String? checkedAt;

  NetkeibaPayout? get payout {
    if (legacyPayout != null) return legacyPayout;
    if (payoutItems == null || payoutItems!.isEmpty) return null;

    final winMap = <String, int>{};
    final placeMap = <String, int>{};
    final quinellaMap = <String, int>{};
    final trifectaMap = <String, int>{};

    for (final item in payoutItems!) {
      final key = item.numbers.join('-');
      final val = item.payoutsJpy.isNotEmpty ? item.payoutsJpy.first : 0;
      if (item.betType.contains('win')) winMap[key] = val;
      if (item.betType.contains('place')) placeMap[key] = val;
      if (item.betType.contains('quinella')) quinellaMap[key] = val;
      if (item.betType.contains('trifecta')) trifectaMap[key] = val;
    }

    return NetkeibaPayout(
      win: winMap,
      place: placeMap,
      quinella: quinellaMap,
      trifecta: trifectaMap,
    );
  }

  factory NetkeibaRace.fromMap(Map<String, dynamic> map) {
    final resultsList = (map['results'] ?? map['runners'] ?? []) as List;
    final parsedRunners = resultsList
        .map((r) => NetkeibaRunner.fromMap(r as Map<String, dynamic>))
        .toList();

    final payoutsList = (map['payouts'] as List? ?? [])
        .map((p) => NetkeibaPayoutItem.fromMap(p as Map<String, dynamic>))
        .toList();

    final legacyPay = map['payout'] != null
        ? NetkeibaPayout.fromMap(map['payout'] as Map<String, dynamic>)
        : null;

    return NetkeibaRace(
      raceId: (map['raceId'] ?? map['race_id'] ?? '') as String,
      raceName: (map['raceName'] ?? map['race_name'] ?? 'JRA Race') as String,
      course: (map['venue'] ?? map['course'] ?? 'Hanshin') as String,
      raceNumber: map['raceNumber'] != null ? (map['raceNumber'] as num).toInt() : null,
      distanceMeters: ((map['distanceM'] ?? map['distance_meters'] ?? map['distance'] ?? 2000) as num).toInt(),
      surface: (map['surface'] ?? 'turf') as String,
      grade: (map['grade'] ?? 'G1') as String,
      date: DateTime.tryParse(map['checkedAt'] as String? ?? map['date'] as String? ?? '') ?? DateTime.now(),
      weather: (map['weather'] ?? 'Fine') as String,
      trackCondition: (map['going'] ?? map['track_condition'] ?? 'Sft') as String,
      status: (map['status'] ?? 'finished') as String,
      runners: parsedRunners,
      payoutItems: payoutsList.isNotEmpty ? payoutsList : null,
      legacyPayout: legacyPay,
      checkedAt: map['checkedAt'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'raceId': raceId,
        'raceName': raceName,
        'venue': course,
        'raceNumber': raceNumber,
        'distanceM': distanceMeters,
        'surface': surface,
        'grade': grade,
        'date': date.toIso8601String(),
        'weather': weather,
        'going': trackCondition,
        'status': status,
        'results': runners.map((r) => r.toMap()).toList(),
        'payouts': payoutItems?.map((p) => p.toMap()).toList(),
        'checkedAt': checkedAt,
      };
}
