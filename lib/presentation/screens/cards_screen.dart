import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'new_card_sheet.dart';

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
                    onAction: () => showNewCardSheet(context),
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

class _Deck extends ConsumerStatefulWidget {
  const _Deck({
    required this.cards,
    required this.index,
    required this.onPageChanged,
  });

  final List<BankCard> cards;
  final int index;
  final ValueChanged<int> onPageChanged;

  @override
  ConsumerState<_Deck> createState() => _DeckState();
}

class _DeckState extends ConsumerState<_Deck> {
  /// The card whose freeze is out with the bank, and the state it was asked to
  /// take. Held here rather than read from [cardsControllerProvider], which is
  /// shared with issuing a card and would put frost on the wrong face.
  String? _requestedId;
  CardStatus? _requestedStatus;

  /// The card whose face should be showing a freeze in flight: the one that was
  /// asked to change and has not yet come back changed. Testing the status as
  /// well as the id means it does not matter whether the refreshed deck or the
  /// write's own callback lands first, so the face goes from taking hold to
  /// locked in one movement either way.
  String? get _pendingCardId {
    final id = _requestedId;
    if (id == null) return null;
    for (final card in widget.cards) {
      if (card.id != id) continue;
      return card.status == _requestedStatus ? null : id;
    }
    return id;
  }

  Future<void> _toggleFreeze(BankCard card) async {
    if (_requestedId != null) return;

    final wanted = card.status == CardStatus.frozen
        ? CardStatus.active
        : CardStatus.frozen;
    setState(() {
      _requestedId = card.id;
      _requestedStatus = wanted;
    });

    final ok = await ref
        .read(cardsControllerProvider.notifier)
        .toggleFreeze(card.id);

    // The write invalidates the read providers, so the deck is refetching by
    // the time it returns. Waiting for that means the frost goes from taking
    // hold straight through to locked, instead of falling back to nothing for
    // the length of the refetch and starting again.
    if (ok) {
      try {
        await ref.read(cardsProvider.future);
      } on Object {
        // The section below handles a failed read. Nothing to add here beyond
        // releasing the pending face, which happens either way.
      }
    }
    if (!mounted) return;

    final state = ref.read(cardsControllerProvider);
    setState(() {
      _requestedId = null;
      _requestedStatus = null;
    });

    if (ok) {
      // Feedback: the write has landed and the ice is going in, confirmed in the
      // hand. A freeze lands heavier than a thaw, so the two are told apart
      // without looking.
      if (wanted == CardStatus.frozen) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    }

    final message = switch (state) {
      CardSuccess(:final card) =>
        card.status == CardStatus.frozen
            ? '${card.label} is now frozen.'
            : '${card.label} is now active.',
      CardError(:final message) => message,
      _ => 'Something went wrong.',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        // The frost takes a beat to settle, so the confirmation waits rather
        // than covering it.
        duration: ok ? const Duration(seconds: 2) : const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final cards = widget.cards;
    final index = widget.index;
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
            onPageChanged: widget.onPageChanged,
            onCardTap: (tapped) => context.push('/card/${tapped.id}'),
            pendingCardId: _pendingCardId,
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
                        // Any freeze in flight, not just this card's: swiping to
                        // a neighbour mid write must not leave a live looking
                        // control that does nothing.
                        pending: _requestedId != null,
                        onTap: () => _toggleFreeze(card),
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
                  onTap: () => showNewCardSheet(context),
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
    this.pending = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// True while this action's write is out. The tile goes quiet and stops taking
  /// taps, so a second one cannot queue behind the first. The card itself is
  /// carrying the pending state, which is why there is no spinner here.
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return AnimatedOpacity(
      opacity: pending ? 0.55 : 1,
      duration: Motion.resolve(context, Motion.short),
      curve: Motion.standard,
      child: Pressable(
        onTap: pending ? null : onTap,
        semanticLabel: label,
        borderRadius: AppRadius.lg,
        child: SoftCard(
          padding: const EdgeInsets.symmetric(vertical: Space.x4),
          child: Column(
            children: [
              // State transition: an action that has just changed what it does
              // turns over. Keyed on what is shown, so the two tiles whose icon
              // and label never change never run a transition.
              _ActionTurn(
                child: Icon(
                  icon,
                  key: ValueKey(icon),
                  size: 20,
                  color: tokens.accent,
                ),
              ),
              const SizedBox(height: Space.x2),
              _ActionTurn(
                child: Text(
                  label,
                  key: ValueKey(label),
                  style: AppType.labelSmall.copyWith(color: tokens.textPrimary),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Swaps one piece of an action tile for another.
///
/// The outgoing piece drops and fades while the incoming one rises into its
/// place, so a control that has just changed what it does says so instead of
/// cutting to its new label between frames. Both are in the tree mid swap and the
/// stack takes the larger, which changes nothing here: an icon is swapped for one
/// the same size, and a single line label for another inside a tile whose width
/// its own flex already fixed.
class _ActionTurn extends StatelessWidget {
  const _ActionTurn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: Motion.resolve(context, Motion.short),
    switchInCurve: Motion.standard,
    switchOutCurve: Motion.standard,
    layoutBuilder: (currentChild, previousChildren) => Stack(
      alignment: Alignment.center,
      children: [...previousChildren, ?currentChild],
    ),
    transitionBuilder: (child, animation) => FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.35),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    ),
    child: child,
  );
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
