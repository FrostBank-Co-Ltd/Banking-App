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
import '../widgets/money_text.dart';
import '../widgets/states.dart';
import '../widgets/surfaces.dart';

/// Card detail with a tall card face showing the brand mark, a page dot
/// indicator, the card balance, and the card info section.
class CardDetailScreen extends ConsumerStatefulWidget {
  const CardDetailScreen({required this.cardId, super.key});

  final String cardId;

  @override
  ConsumerState<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends ConsumerState<CardDetailScreen> {
  PageController? _pages;
  int? _index;

  @override
  void dispose() {
    _pages?.dispose();
    super.dispose();
  }

  Future<void> _copy(BankCard card) async {
    await Clipboard.setData(
      ClipboardData(text: card.number.replaceAll(' ', '')),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Card number copied'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(cardsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Card')),
      body: ResponsiveShell(
        child: AsyncSection<List<BankCard>>(
          value: cards,
          onRetry: () => ref.invalidate(cardsProvider),
          skeleton: const Padding(
            padding: EdgeInsets.all(Space.x5),
            child: Column(
              children: [
                SkeletonBlock(height: 260, radius: AppRadius.xl),
                SizedBox(height: Space.x6),
                SkeletonBlock(width: 200, height: 34),
                SizedBox(height: Space.x6),
                SkeletonRows(count: 4),
              ],
            ),
          ),
          isEmpty: (rows) => rows.isEmpty,
          empty: EmptyStateView(
            heading: 'No cards yet',
            message: 'Add a card to see its details here.',
            actionLabel: 'Add card',
            icon: Icons.credit_card_rounded,
            onAction: () => context.push('/soon/new-card'),
          ),
          builder: (rows) {
            final startIndex = rows.indexWhere(
              (card) => card.id == widget.cardId,
            );
            final initial = startIndex < 0 ? 0 : startIndex;
            final controller = _pages ??= PageController(
              initialPage: initial,
              viewportFraction: 0.82,
            );
            final activeIndex = (_index ?? initial).clamp(0, rows.length - 1);
            final card = rows[activeIndex];

            return ListView(
              padding: const EdgeInsets.only(bottom: Space.x10),
              children: [
                SizedBox(
                  height: 260,
                  child: PageView.builder(
                    controller: controller,
                    itemCount: rows.length,
                    onPageChanged: (value) => setState(() => _index = value),
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Space.x2),
                      child: _CardFace(
                        card: rows[index],
                        isActive: index == activeIndex,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Space.x4),
                _PageDots(count: rows.length, active: activeIndex),
                const SizedBox(height: Space.x6),
                Center(
                  child: MoneyText(
                    card.balance,
                    style: AppType.numericLarge.copyWith(fontSize: 36),
                    currencyCode: card.currencyCode,
                    label: '${card.label} balance',
                  ),
                ),
                const SizedBox(height: Space.x6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.x5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'Card info'),
                      DetailRow(
                        label: 'Card number',
                        value: NumericText(
                          card.maskedNumber,
                          style: AppType.numericMedium,
                          label: 'Card number ending ${card.last4}',
                        ),
                        trailing: IconButton(
                          onPressed: () => _copy(card),
                          tooltip: 'Copy card number',
                          icon: const Icon(Icons.copy_rounded, size: 18),
                        ),
                      ),
                      DetailRow(
                        label: 'CVC',
                        value: NumericText(
                          card.cvc,
                          style: AppType.numericMedium,
                          label: 'CVC ${card.cvc}',
                        ),
                      ),
                      DetailRow(
                        label: 'Expiry date',
                        value: NumericText(
                          card.expiry,
                          style: AppType.numericMedium,
                          label: 'Expires ${card.expiry}',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Tall vertical card face with brand mark centred, masked last-4 at top left,
/// and card type label at bottom right. Matches the reference design.
class _CardFace extends StatelessWidget {
  const _CardFace({required this.card, required this.isActive});

  final BankCard card;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return FrostCardSurface(
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(Space.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: masked last-4
          Text(
            '\u2022\u2022\u2022\u2022 ${card.last4}',
            style: AppType.labelMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              letterSpacing: 1.2,
            ),
          ),
          // Centre: brand mark
          Expanded(
            child: Center(
              child: FrostMark(size: 80),
            ),
          ),
          // Bottom row: network logo + card type
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _NetworkLogo(network: card.network),
              Text(
                'Debit',
                style: AppType.titleSmall.copyWith(
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Renders the card network logo. For Mastercard it draws the two overlapping
/// circles; for Visa it shows the word mark.
class _NetworkLogo extends StatelessWidget {
  const _NetworkLogo({required this.network});

  final CardNetwork network;

  @override
  Widget build(BuildContext context) {
    if (network == CardNetwork.mastercard) {
      return SizedBox(
        width: 38,
        height: 24,
        child: CustomPaint(painter: _MastercardPainter()),
      );
    }
    return Text(
      'VISA',
      style: AppType.titleSmall.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    );
  }
}

class _MastercardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height / 2;

    final leftCenter = Offset(r, r);
    final rightCenter = Offset(size.width - r, r);

    // Left circle (red/warm)
    canvas.drawCircle(
      leftCenter,
      r,
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
    // Right circle (orange/warm)
    canvas.drawCircle(
      rightCenter,
      r,
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      label: 'Card ${active + 1} of $count',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < count; index++)
              AnimatedContainer(
                duration: Motion.resolve(context, Motion.short),
                curve: Motion.standard,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: index == active ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: index == active ? tokens.accent : tokens.border,
                  borderRadius: AppRadius.all(AppRadius.pill),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
