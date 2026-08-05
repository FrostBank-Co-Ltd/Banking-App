import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../widgets/brand.dart';
import '../widgets/card_carousel.dart';
import '../widgets/card_face.dart';
import '../widgets/money_text.dart';
import '../widgets/motion_effects.dart';
import '../widgets/pressable.dart';
import '../widgets/states.dart';
import '../widgets/surfaces.dart';

/// Every card on the profile, reached from the brand mark in the centre of the
/// navigation pill.
///
/// The deck is the subject of the screen: one card in front, its neighbours
/// turned away at the edges, and the figures below always describing whichever
/// card is facing the holder.
class CardsScreen extends ConsumerStatefulWidget {
  const CardsScreen({super.key});

  @override
  ConsumerState<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends ConsumerState<CardsScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
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
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              0,
              Space.x2,
              0,
              Space.x16 + Space.x8,
            ),
            children: [
              AsyncSection<List<BankCard>>(
                value: cards,
                onRetry: () => ref.invalidate(cardsProvider),
                skeleton: const _DeckSkeleton(),
                isEmpty: (rows) => rows.isEmpty,
                empty: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.x5),
                  child: EmptyStateView(
                    heading: 'No cards yet',
                    message: 'Add your first card to manage it here.',
                    actionLabel: 'Add card',
                    icon: Icons.credit_card_rounded,
                    onAction: () => context.push('/soon/new-card'),
                  ),
                ),
                builder: (rows) => _Deck(
                  cards: rows,
                  index: _index.clamp(0, rows.length - 1),
                  onPageChanged: (value) => setState(() => _index = value),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Deck extends StatelessWidget {
  const _Deck({
    required this.cards,
    required this.index,
    required this.onPageChanged,
  });

  final List<BankCard> cards;
  final int index;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final card = cards[index];

    return Column(
      children: [
        FadeSlideIn(
          duration: Motion.long,
          offset: const Offset(0, 28),
          scaleFrom: 0.9,
          child: CardCarousel(
            cards: cards,
            initialIndex: index,
            onPageChanged: onPageChanged,
            onCardTap: (tapped) => context.push('/card/${tapped.id}'),
          ),
        ),
        const SizedBox(height: Space.x6),

        // Everything below belongs to the card in front, so it swaps as one
        // block rather than field by field.
        CardValueSwap(
          child: Column(
            key: ValueKey(card.id),
            children: [
              Text(
                card.label,
                style: AppType.labelMedium.copyWith(
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(height: Space.x2),
              MoneyText(
                card.balance,
                style: AppType.numericHero.copyWith(fontSize: 36),
                currencyCode: card.currencyCode,
                label: '${card.label} balance',
              ),
              const SizedBox(height: Space.x3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  NumericText(
                    card.maskedNumber,
                    style: AppType.numericSmall,
                    color: tokens.textSecondary,
                    label: 'Card ending ${card.last4}',
                  ),
                  const SizedBox(width: Space.x3),
                  StatusPill(
                    label: card.status.label,
                    color: card.status == CardStatus.frozen
                        ? tokens.info
                        : tokens.success,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.x6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.x5),
          child: Column(
            children: [
              // FadeSlideIn sits inside each Expanded, because Expanded has to
              // stay a direct child of the Row for the flex to resolve.
              Row(
                children: [
                  Expanded(
                    child: FadeSlideIn(
                      index: 2,
                      child: _CardAction(
                        icon: Icons.tune_rounded,
                        label: 'Details',
                        onTap: () => context.push('/card/${card.id}'),
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.x3),
                  Expanded(
                    child: FadeSlideIn(
                      index: 3,
                      child: _CardAction(
                        icon: card.status == CardStatus.frozen
                            ? Icons.lock_open_rounded
                            : Icons.ac_unit_rounded,
                        label: card.status == CardStatus.frozen
                            ? 'Unfreeze'
                            : 'Freeze',
                        onTap: () => context.push('/soon/freeze-card'),
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.x3),
                  Expanded(
                    child: FadeSlideIn(
                      index: 4,
                      child: _CardAction(
                        icon: Icons.speed_rounded,
                        label: 'Limits',
                        onTap: () => context.push('/soon/card-limits'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.x4),
              FadeSlideIn(
                index: 6,
                child: Pressable(
                  onTap: () => context.push('/soon/new-card'),
                  semanticLabel: 'Add card',
                  borderRadius: AppRadius.lg,
                  child: Container(
                    height: 64,
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
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      borderRadius: AppRadius.lg,
      child: SoftCard(
        padding: const EdgeInsets.symmetric(vertical: Space.x4),
        child: Column(
          children: [
            Icon(icon, size: 20, color: tokens.accent),
            const SizedBox(height: Space.x2),
            Text(
              label,
              style: AppType.labelSmall.copyWith(color: tokens.textPrimary),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shape matched placeholder, so nothing moves when the deck arrives.
class _DeckSkeleton extends StatelessWidget {
  const _DeckSkeleton();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Column(
      children: [
        SizedBox(
          height: CardCarousel.heightFor(constraints.maxWidth),
          child: Center(
            child: CardFaceSkeleton(
              width: CardCarousel.cardWidthFor(constraints.maxWidth),
            ),
          ),
        ),
        const SizedBox(height: Space.x2),
        const SkeletonBlock(width: 60, height: 7, radius: AppRadius.pill),
        const SizedBox(height: Space.x6),
        const SkeletonBlock(width: 96, height: 12),
        const SizedBox(height: Space.x3),
        const SkeletonBlock(width: 190, height: 34),
        const SizedBox(height: Space.x4),
        const SkeletonBlock(width: 210, height: 14),
        const SizedBox(height: Space.x6),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: Space.x5),
          child: Row(
            children: [
              Expanded(child: SkeletonBlock(height: 76, radius: AppRadius.lg)),
              SizedBox(width: Space.x3),
              Expanded(child: SkeletonBlock(height: 76, radius: AppRadius.lg)),
              SizedBox(width: Space.x3),
              Expanded(child: SkeletonBlock(height: 76, radius: AppRadius.lg)),
            ],
          ),
        ),
      ],
    ),
  );
}
