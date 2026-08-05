import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../widgets/brand.dart';
import '../widgets/money_text.dart';
import '../widgets/pressable.dart';
import '../widgets/states.dart';
import '../widgets/surfaces.dart';

/// Every card on the profile, reached from the brand mark in the centre of the
/// navigation pill.
class CardsScreen extends ConsumerWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(cardsProvider);
    final tokens = context.tokens;

    return Scaffold(
      appBar: AppBar(title: const Text('Cards')),
      body: ResponsiveShell(
        child: RefreshIndicator(
          color: tokens.accent,
          onRefresh: () async {
            ref.invalidate(cardsProvider);
            await ref.read(cardsProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Space.x5,
              Space.x2,
              Space.x5,
              Space.x16 + Space.x8,
            ),
            children: [
              AsyncSection<List<BankCard>>(
                value: cards,
                onRetry: () => ref.invalidate(cardsProvider),
                skeleton: const Column(
                  children: [
                    SkeletonBlock(height: 132, radius: AppRadius.lg),
                    SizedBox(height: Space.x4),
                    SkeletonBlock(height: 132, radius: AppRadius.lg),
                  ],
                ),
                isEmpty: (rows) => rows.isEmpty,
                empty: EmptyStateView(
                  heading: 'No cards yet',
                  message: 'Add your first card to manage it here.',
                  actionLabel: 'Add card',
                  icon: Icons.credit_card_rounded,
                  onAction: () => context.push('/soon/new-card'),
                ),
                builder: (rows) => Column(
                  children: [
                    for (final card in rows)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.x4),
                        child: Pressable(
                          onTap: () => context.push('/card/${card.id}'),
                          semanticLabel:
                              '${card.label}, ${card.network.label} ending ${card.last4}, ${card.status.label}',
                          borderRadius: AppRadius.lg,
                          child: FrostCardSurface(
                            radius: AppRadius.lg,
                            child: Padding(
                              padding: const EdgeInsets.all(Space.x5),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        card.label,
                                        style: AppType.titleMedium.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        card.network.label,
                                        style: AppType.labelMedium.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: Space.x5),
                                  NumericText(
                                    card.maskedNumber,
                                    style: AppType.numericMedium,
                                    color: Colors.white,
                                    label: 'Card ending ${card.last4}',
                                  ),
                                  const SizedBox(height: Space.x4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      MoneyText(
                                        card.balance,
                                        style: AppType.numericMedium,
                                        color: Colors.white,
                                        currencyCode: card.currencyCode,
                                        label: '${card.label} balance',
                                      ),
                                      StatusPill(
                                        label: card.status.label,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    Pressable(
                      onTap: () => context.push('/soon/new-card'),
                      semanticLabel: 'Add card',
                      borderRadius: AppRadius.lg,
                      child: Container(
                        height: 88,
                        decoration: BoxDecoration(
                          color: tokens.surface,
                          borderRadius: AppRadius.all(AppRadius.lg),
                          border: Border.all(color: tokens.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded, color: tokens.accent),
                            const SizedBox(width: Space.x2),
                            Text(
                              'Add card',
                              style: AppType.labelLarge.copyWith(
                                color: tokens.interactivePrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
