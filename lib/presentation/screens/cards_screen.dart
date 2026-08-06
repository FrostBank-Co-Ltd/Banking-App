import 'package:flutter/material.dart';

import 'card_detail_screen.dart';

/// Every card on the profile, displaying full card details, security PIN reveal,
/// CVC, expiry, status toggle with PIN prompt, and card controls.
class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CardDetailScreen(cardId: '');
  }
}
