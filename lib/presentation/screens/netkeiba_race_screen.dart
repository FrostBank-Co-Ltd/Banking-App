import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/netkeiba_models.dart';
import '../../state/netkeiba_providers.dart';
import '../widgets/pressable.dart';
import '../widgets/surfaces.dart';

class NetkeibaRaceScreen extends ConsumerStatefulWidget {
  const NetkeibaRaceScreen({super.key});

  @override
  ConsumerState<NetkeibaRaceScreen> createState() => _NetkeibaRaceScreenState();
}

class _NetkeibaRaceScreenState extends ConsumerState<NetkeibaRaceScreen>
    with SingleTickerProviderStateMixin {
  final _tokenController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _searchRace(String id) {
    final clean = id.trim();
    if (clean.isNotEmpty) {
      ref.read(selectedRaceIdProvider.notifier).select(clean);
    }
  }

  void _saveToken() {
    final token = _tokenController.text.trim();
    ref.read(apifyTokenProvider.notifier).setToken(token);
    final selectedId = ref.read(selectedRaceIdProvider);
    ref.invalidate(netkeibaRaceDetailsProvider(selectedId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          token.isNotEmpty
              ? 'Apify API Token saved! Live API active.'
              : 'Apify API Token cleared.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final apifyToken = ref.watch(apifyTokenProvider);
    final selectedId = ref.watch(selectedRaceIdProvider);
    final raceAsync = ref.watch(netkeibaRaceDetailsProvider(selectedId));

    if (_tokenController.text.isEmpty && apifyToken.isNotEmpty) {
      _tokenController.text = apifyToken;
    }

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: Text(
          'JRA G1 Race Calendar & Hub',
          style: AppType.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: tokens.textPrimary,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: tokens.textPrimary),
            onPressed: () {
              ref.invalidate(netkeibaRaceDetailsProvider(selectedId));
              ref.invalidate(netkeibaRecentRacesProvider);
            },
            tooltip: 'Refresh Race Data',
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveShell(
          child: Column(
            children: [
              // Top Apify API Token Settings Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.x4, Space.x2, Space.x4, 0),
                child: Container(
                  padding: const EdgeInsets.all(Space.x3),
                  decoration: BoxDecoration(
                    color: tokens.surfaceRaised,
                    borderRadius: AppRadius.all(AppRadius.md),
                    border: Border.all(
                      color: apifyToken.isNotEmpty
                          ? tokens.success.withValues(alpha: 0.5)
                          : tokens.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.key_rounded,
                        size: 18,
                        color: apifyToken.isNotEmpty ? tokens.success : tokens.warning,
                      ),
                      const SizedBox(width: Space.x2),
                      Expanded(
                        child: TextField(
                          controller: _tokenController,
                          obscureText: true,
                          style: AppType.bodyMedium.copyWith(color: tokens.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Paste Apify Token (apify_api_...)',
                            isDense: true,
                            border: InputBorder.none,
                            hintStyle: AppType.bodySmall.copyWith(color: tokens.textSecondary),
                          ),
                          onSubmitted: (_) => _saveToken(),
                        ),
                      ),
                      const SizedBox(width: Space.x2),
                      Pressable(
                        onTap: _saveToken,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Space.x3,
                            vertical: Space.x1 + 2,
                          ),
                          decoration: BoxDecoration(
                            color: apifyToken.isNotEmpty ? tokens.success : tokens.interactivePrimary,
                            borderRadius: AppRadius.all(AppRadius.pill),
                          ),
                          child: Text(
                            apifyToken.isNotEmpty ? 'Active Token' : 'Set Token',
                            style: AppType.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: Space.x3),

              // G1 Race Calendar Quick Selector
              _G1RaceCalendarHeader(
                selectedRaceId: selectedId,
                onRaceSelected: (id) => _searchRace(id),
              ),

              const SizedBox(height: Space.x2),

              // Tab Navigation Bar
              TabBar(
                controller: _tabController,
                labelColor: tokens.accent,
                unselectedLabelColor: tokens.textSecondary,
                indicatorColor: tokens.accent,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Contestants & Winners'),
                  Tab(text: 'Race Simulator 🏇'),
                  Tab(text: 'Payouts'),
                  Tab(text: 'Apify API'),
                ],
              ),

              // Main Tab Content Area
              Expanded(
                child: raceAsync.when(
                  data: (race) {
                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _ContestantsTab(race: race),
                        _RaceSimulatorTab(race: race),
                        _PayoutsTab(payout: race.payout, payoutItems: race.payoutItems),
                        _ApifyInfoTab(raceId: race.raceId),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(Space.x4),
                      child: Text(
                        'Failed to load race data: $err',
                        style: TextStyle(color: tokens.error),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _G1RaceCalendarHeader extends ConsumerWidget {
  const _G1RaceCalendarHeader({
    required this.selectedRaceId,
    required this.onRaceSelected,
  });

  final String selectedRaceId;
  final ValueChanged<String> onRaceSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;

    final calendarRaces = [
      {'date': 'MAY 24', 'name': 'Oaks', 'id': '20260524'},
      {'date': 'MAY 31', 'name': 'Derby', 'id': '20260531'},
      {'date': 'JUN 07', 'name': 'Yasuda', 'id': '20260607'},
      {'date': 'JUN 14', 'name': 'Takarazuka', 'id': '20260614'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_rounded, size: 18, color: tokens.accent),
              const SizedBox(width: 6),
              Text(
                'JRA G1 Season Calendar',
                style: AppType.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.x2),
          Row(
            children: calendarRaces.map((item) {
              final isSelected = selectedRaceId == item['id'];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Pressable(
                    onTap: () => onRaceSelected(item['id']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: Space.x2),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [tokens.interactivePrimary, tokens.accent],
                              )
                            : null,
                        color: isSelected ? null : tokens.surfaceRaised,
                        borderRadius: AppRadius.all(AppRadius.md),
                        border: Border.all(
                          color: isSelected ? tokens.accent : tokens.border,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            item['date']!,
                            style: AppType.labelSmall.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white70 : tokens.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['name']!,
                            style: AppType.titleSmall.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : tokens.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ContestantsTab extends StatelessWidget {
  const _ContestantsTab({required this.race});

  final NetkeibaRace race;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final winner = race.runners
        .where((r) => r.finishPosition == '1' || r.finishPosition == '1.0')
        .firstOrNull;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Space.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Race Overview Header Card
          Container(
            padding: const EdgeInsets.all(Space.x4),
            decoration: BoxDecoration(
              color: tokens.surfaceRaised,
              borderRadius: AppRadius.all(AppRadius.lg),
              border: Border.all(color: tokens.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusPill(
                      label: race.grade,
                      color: tokens.accent,
                    ),
                    const SizedBox(width: Space.x2),
                    Expanded(
                      child: Text(
                        race.raceName,
                        style: AppType.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                    StatusPill(
                      label: race.status,
                      color: tokens.success,
                    ),
                  ],
                ),
                const SizedBox(height: Space.x3),
                Wrap(
                  spacing: Space.x4,
                  runSpacing: Space.x2,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: tokens.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${race.course} (${race.surface} ${race.distanceMeters}m)',
                          style: AppType.bodyMedium.copyWith(color: tokens.textSecondary),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wb_sunny_outlined, size: 16, color: tokens.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${race.weather} / ${race.trackCondition}',
                          style: AppType.bodyMedium.copyWith(color: tokens.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: Space.x2),
                Text(
                  'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(race.date)} | ID: ${race.raceId}',
                  style: AppType.labelMedium.copyWith(color: tokens.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(height: Space.x4),

          // Winner Spotlight Card
          if (winner != null) ...[
            Container(
              padding: const EdgeInsets.all(Space.x4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: tokens.isDark
                      ? const [Color(0xFF332000), Color(0xFF1F1200)]
                      : const [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                ),
                borderRadius: AppRadius.all(AppRadius.lg),
                border: Border.all(color: Colors.amber.shade600, width: 1.5),
              ),
              child: Row(
                children: [
                  const Text('🥇', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: Space.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'G1 CHAMPION WINNER',
                          style: AppType.labelSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade600,
                          ),
                        ),
                        Text(
                          winner.horseName,
                          style: AppType.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: tokens.isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          'Jockey: ${winner.jockey} | Time: ${winner.finishTime ?? "-"}',
                          style: AppType.bodySmall.copyWith(
                            color: tokens.isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (winner.winOdds != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        borderRadius: AppRadius.all(AppRadius.pill),
                      ),
                      child: Text(
                        '${winner.winOdds!.toStringAsFixed(1)}x Odds',
                        style: AppType.labelMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: Space.x4),
          ],

          Text(
            'Contestant Runners & Standings',
            style: AppType.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: Space.x2),

          // Runners Table Card
          Container(
            decoration: BoxDecoration(
              color: tokens.surfaceRaised,
              borderRadius: AppRadius.all(AppRadius.lg),
              border: Border.all(color: tokens.border),
            ),
            child: ClipRRect(
              borderRadius: AppRadius.all(AppRadius.lg),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  headingRowColor: WidgetStateProperty.all(tokens.surface),
                  columns: [
                    DataColumn(label: Text('Pos', style: AppType.labelMedium.copyWith(color: tokens.textSecondary))),
                    DataColumn(label: Text('No', style: AppType.labelMedium.copyWith(color: tokens.textSecondary))),
                    DataColumn(label: Text('Horse Name', style: AppType.labelMedium.copyWith(color: tokens.textSecondary))),
                    DataColumn(label: Text('Jockey', style: AppType.labelMedium.copyWith(color: tokens.textSecondary))),
                    DataColumn(label: Text('Odds', style: AppType.labelMedium.copyWith(color: tokens.textSecondary))),
                    DataColumn(label: Text('Time', style: AppType.labelMedium.copyWith(color: tokens.textSecondary))),
                    DataColumn(label: Text('Margin', style: AppType.labelMedium.copyWith(color: tokens.textSecondary))),
                    DataColumn(label: Text('Trainer', style: AppType.labelMedium.copyWith(color: tokens.textSecondary))),
                  ],
                  rows: race.runners.map((runner) {
                    final isWinner = runner.finishPosition == '1' || runner.finishPosition == '1.0';
                    return DataRow(
                      color: isWinner
                          ? WidgetStateProperty.all(
                              tokens.accent.withValues(alpha: 0.15),
                            )
                          : null,
                      cells: [
                        DataCell(
                          Text(
                            runner.finishPosition != null
                                ? '#${runner.finishPosition}'
                                : '-',
                            style: AppType.bodyMedium.copyWith(
                              fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                              color: isWinner ? tokens.accent : tokens.textPrimary,
                            ),
                          ),
                        ),
                        DataCell(Text('${runner.horseNumber}', style: AppType.bodyMedium.copyWith(color: tokens.textPrimary))),
                        DataCell(
                          Row(
                            children: [
                              Text(
                                runner.horseName,
                                style: AppType.bodyMedium.copyWith(
                                  fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                                  color: tokens.textPrimary,
                                ),
                              ),
                              if (isWinner) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.emoji_events_rounded,
                                    size: 16, color: Colors.amber),
                              ],
                            ],
                          ),
                        ),
                        DataCell(Text(runner.jockey, style: AppType.bodyMedium.copyWith(color: tokens.textPrimary))),
                        DataCell(Text(runner.winOdds != null ? '${runner.winOdds!.toStringAsFixed(1)}x' : '-', style: AppType.numericMedium.copyWith(color: tokens.textPrimary))),
                        DataCell(Text(runner.finishTime ?? '-', style: AppType.bodyMedium.copyWith(color: tokens.textPrimary))),
                        DataCell(Text(runner.margin ?? '-', style: AppType.bodyMedium.copyWith(color: tokens.textSecondary))),
                        DataCell(Text(runner.trainer ?? '-', style: AppType.bodyMedium.copyWith(color: tokens.textSecondary))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RaceSimulatorTab extends StatefulWidget {
  const _RaceSimulatorTab({required this.race});

  final NetkeibaRace race;

  @override
  State<_RaceSimulatorTab> createState() => _RaceSimulatorTabState();
}

class _RaceSimulatorTabState extends State<_RaceSimulatorTab> {
  final _stakeController = TextEditingController(text: '100');
  NetkeibaRunner? _selectedRunner;
  String? _simulationResult;

  @override
  void initState() {
    super.initState();
    if (widget.race.runners.isNotEmpty) {
      _selectedRunner = widget.race.runners.first;
    }
  }

  void _runSimulation() {
    if (_selectedRunner == null) return;
    final stake = double.tryParse(_stakeController.text.trim()) ?? 100.0;
    final odds = _selectedRunner!.winOdds ?? 2.5;
    final isWinner = _selectedRunner!.finishPosition == '1' || _selectedRunner!.finishPosition == '1.0';

    if (isWinner) {
      final payout = stake * odds;
      setState(() {
        _simulationResult = '🎉 WINNER! Your horse ${_selectedRunner!.horseName} won 1st place! Payout: \$${payout.toStringAsFixed(2)}';
      });
    } else {
      setState(() {
        _simulationResult = '❌ ${_selectedRunner!.horseName} placed #${_selectedRunner!.finishPosition ?? "runner-up"}. Better luck next race!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Space.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Race Simulator: ${widget.race.raceName}',
            style: AppType.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: Space.x2),
          Text(
            'Simulate placing a Win ticket on your chosen G1 contestant.',
            style: AppType.bodySmall.copyWith(color: tokens.textSecondary),
          ),
          const SizedBox(height: Space.x4),

          // Horse Selection Dropdown
          DropdownButtonFormField<NetkeibaRunner>(
            initialValue: _selectedRunner,
            isExpanded: true,
            dropdownColor: tokens.surfaceRaised,
            style: AppType.bodyMedium.copyWith(color: tokens.textPrimary),
            decoration: InputDecoration(
              labelText: 'Select Contestant Horse',
              labelStyle: AppType.labelMedium.copyWith(color: tokens.textSecondary),
              filled: true,
              fillColor: tokens.surfaceRaised,
              border: OutlineInputBorder(
                borderRadius: AppRadius.all(AppRadius.md),
                borderSide: BorderSide(color: tokens.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.all(AppRadius.md),
                borderSide: BorderSide(color: tokens.border),
              ),
            ),
            items: widget.race.runners.map((r) {
              return DropdownMenuItem(
                value: r,
                child: Text(
                  '#${r.horseNumber} ${r.horseName} (${r.jockey}) - ${r.winOdds != null ? r.winOdds!.toStringAsFixed(1) : "2.5"}x',
                  style: TextStyle(color: tokens.textPrimary),
                ),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedRunner = val),
          ),

          const SizedBox(height: Space.x3),

          // Stake input
          TextField(
            controller: _stakeController,
            keyboardType: TextInputType.number,
            style: AppType.bodyMedium.copyWith(color: tokens.textPrimary),
            decoration: InputDecoration(
              labelText: 'Simulated Stake Amount (\$)',
              labelStyle: AppType.labelMedium.copyWith(color: tokens.textSecondary),
              prefixText: '\$ ',
              prefixStyle: TextStyle(color: tokens.textPrimary),
              filled: true,
              fillColor: tokens.surfaceRaised,
              border: OutlineInputBorder(
                borderRadius: AppRadius.all(AppRadius.md),
                borderSide: BorderSide(color: tokens.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.all(AppRadius.md),
                borderSide: BorderSide(color: tokens.border),
              ),
            ),
          ),

          const SizedBox(height: Space.x4),

          // Simulate Button
          Pressable(
            onTap: _runSimulation,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [tokens.interactivePrimary, tokens.accent],
                ),
                borderRadius: AppRadius.all(AppRadius.pill),
              ),
              child: const Center(
                child: Text(
                  'Run Race Simulation 🏇',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),

          if (_simulationResult != null) ...[
            const SizedBox(height: Space.x4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Space.x4),
              decoration: BoxDecoration(
                color: _simulationResult!.startsWith('🎉')
                    ? tokens.success.withValues(alpha: 0.15)
                    : tokens.error.withValues(alpha: 0.15),
                borderRadius: AppRadius.all(AppRadius.md),
                border: Border.all(
                  color: _simulationResult!.startsWith('🎉') ? tokens.success : tokens.error,
                ),
              ),
              child: Text(
                _simulationResult!,
                style: AppType.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _simulationResult!.startsWith('🎉') ? tokens.success : tokens.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PayoutsTab extends StatelessWidget {
  const _PayoutsTab({this.payout, this.payoutItems});

  final NetkeibaPayout? payout;
  final List<NetkeibaPayoutItem>? payoutItems;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    if (payout == null && (payoutItems == null || payoutItems!.isEmpty)) {
      return Center(
        child: Text(
          'Payout data not available for this race.',
          style: AppType.bodyMedium.copyWith(color: tokens.textSecondary),
        ),
      );
    }

    if (payoutItems != null && payoutItems!.isNotEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(Space.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: payoutItems!.map((item) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bet Type: ${item.betType.toUpperCase()}',
                  style: AppType.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: Space.x2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Combination: ${item.numbers.join(" - ")}',
                      style: AppType.bodyMedium.copyWith(color: tokens.textSecondary),
                    ),
                    Text(
                      item.payoutsJpy.isNotEmpty ? '¥${item.payoutsJpy.join(" / ¥")}' : '-',
                      style: AppType.numericMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: tokens.success,
                      ),
                    ),
                  ],
                ),
                SoftDivider(inset: 0),
              ],
            );
          }).toList(),
        ),
      );
    }

    Widget buildSection(String title, Map<String, int> data) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppType.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: Space.x2),
          ...data.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Combination: ${e.key}',
                    style: AppType.bodyMedium.copyWith(color: tokens.textSecondary),
                  ),
                  Text(
                    '¥${e.value}',
                    style: AppType.numericMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: tokens.success,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SoftDivider(inset: 0),
        ],
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Space.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSection('Win (単勝 - Tansho)', payout!.win),
          buildSection('Place (複勝 - Fukuso)', payout!.place),
          buildSection('Quinella (馬連 - Umaren)', payout!.quinella),
          buildSection('Trifecta (3連単 - Sanrentan)', payout!.trifecta),
        ],
      ),
    );
  }
}

class _ApifyInfoTab extends StatelessWidget {
  const _ApifyInfoTab({required this.raceId});

  final String raceId;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Space.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Apify Actor Integration',
            style: AppType.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: Space.x2),
          Text(
            'Actor: jpmarketdata/netkeiba-race-checker\n'
            'Dataset Endpoint: https://api.apify.com/v2/datasets/BSBaX0BfLbP3C3vpC/items',
            style: AppType.bodyMedium.copyWith(color: tokens.textSecondary),
          ),
          const SizedBox(height: Space.x4),
          Text(
            'POST Request Payload Sample:',
            style: AppType.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: Space.x2),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Space.x3),
            decoration: BoxDecoration(
              color: tokens.isDark ? Colors.black87 : const Color(0xFF1E293B),
              borderRadius: AppRadius.all(AppRadius.md),
            ),
            child: Text(
              '{\n  "includeIndividualEntries": false,\n  "raceIds": ["$raceId"],\n  "maxRaces": 12\n}',
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Colors.greenAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
