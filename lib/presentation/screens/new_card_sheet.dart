import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../widgets/card_face.dart';

/// Opens the card form.
///
/// Every route into the form goes through here, so the deck, the card detail
/// screen, and the dashboard strip all present it identically.
Future<void> showNewCardSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NewCardSheet(),
    );

/// Issue a card.
///
/// Nothing here is validated. This build is a user interface presentation, so
/// the form takes whatever is typed, blank fields fall back to the placeholder
/// beside them, and the card is always issued. The alternative, a form that
/// rejects a number for failing a scheme check, would be pretending to a
/// verification the build does not do.
///
/// Everything arrives prefilled for the same reason: the point of the screen is
/// to show what a new card looks like in the deck, so it is one tap from open to
/// issued, and every field is still there to be changed.
class NewCardSheet extends ConsumerStatefulWidget {
  const NewCardSheet({super.key});

  @override
  ConsumerState<NewCardSheet> createState() => _NewCardSheetState();
}

class _NewCardSheetState extends ConsumerState<NewCardSheet> {
  static const String _fallbackLabel = 'FrostBank Everyday';
  static const String _fallbackHolder = 'Ava Mercado';
  static const String _fallbackNumber = '4137 8947 1175 2043';
  static const String _fallbackExpiry = '08/31';
  static const String _fallbackCvc = '412';
  static const double _fallbackLimit = 2000;

  final _label = TextEditingController(text: _fallbackLabel);
  final _holder = TextEditingController(text: _fallbackHolder);
  final _number = TextEditingController(text: _fallbackNumber);
  final _expiry = TextEditingController(text: _fallbackExpiry);
  final _cvc = TextEditingController(text: _fallbackCvc);
  final _limit = TextEditingController(text: '2000');

  CardNetwork _network = CardNetwork.visa;
  CardKind _kind = CardKind.debit;
  String? _accountId;
  bool _working = false;

  @override
  void dispose() {
    _label.dispose();
    _holder.dispose();
    _number.dispose();
    _expiry.dispose();
    _cvc.dispose();
    _limit.dispose();
    super.dispose();
  }

  /// Trimmed text, or [fallback] when the field was left empty.
  String _valueOf(TextEditingController controller, String fallback) {
    final text = controller.text.trim();
    return text.isEmpty ? fallback : text;
  }

  Future<void> _submit(List<Account> accounts) async {
    if (accounts.isEmpty) return;
    final accountId = _accountId ?? accounts.first.id;
    final label = _valueOf(_label, _fallbackLabel);

    setState(() => _working = true);

    final ok = await ref
        .read(cardsControllerProvider.notifier)
        .createCard(
          accountId: accountId,
          label: label,
          holderName: _valueOf(_holder, _fallbackHolder),
          number: _valueOf(_number, _fallbackNumber),
          cvc: _valueOf(_cvc, _fallbackCvc),
          expiry: _valueOf(_expiry, _fallbackExpiry),
          network: _network,
          kind: _kind,
          spendingLimit:
              double.tryParse(_limit.text.trim().replaceAll(',', '')) ??
              _fallbackLimit,
        );

    if (!mounted) return;
    setState(() => _working = false);

    final messenger = ScaffoldMessenger.of(context);
    if (ok) {
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text('$label added.')));
      return;
    }

    final state = ref.read(cardsControllerProvider);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          state is CardError ? state.message : 'Something went wrong.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final accounts = ref.watch(accountsProvider);
    final rows = accounts.hasValue
        ? accounts.requireValue
        : const <Account>[];
    final selected = _accountId ?? (rows.isEmpty ? null : rows.first.id);

    return Container(
      decoration: BoxDecoration(
        color: tokens.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Space.x5,
            Space.x5,
            Space.x5,
            Space.x3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: Space.x4),
                  decoration: BoxDecoration(
                    color: tokens.border,
                    borderRadius: AppRadius.all(AppRadius.pill),
                  ),
                ),
              ),

              Text(
                'Add a card',
                style: AppType.headlineMedium.copyWith(
                  color: tokens.textPrimary,
                ),
              ),
              const SizedBox(height: Space.x1),
              Text(
                'Nothing is checked in this build. Any details will do.',
                style: AppType.bodySmall.copyWith(color: tokens.textSecondary),
              ),

              const SizedBox(height: Space.x5),

              _Field(
                controller: _label,
                label: 'Card name',
                hint: _fallbackLabel,
                capitalization: TextCapitalization.words,
              ),
              const SizedBox(height: Space.x4),

              _Choices<CardNetwork>(
                label: 'Network',
                values: CardNetwork.values,
                selected: _network,
                labelOf: (value) => value.label,
                leadingOf: (value) => NetworkMark(network: value, width: 26),
                onChanged: (value) => setState(() => _network = value),
              ),
              const SizedBox(height: Space.x4),

              _Choices<CardKind>(
                label: 'Type',
                values: CardKind.values,
                selected: _kind,
                labelOf: (value) => value.label,
                onChanged: (value) => setState(() => _kind = value),
              ),
              const SizedBox(height: Space.x4),

              _AccountPicker(
                accounts: rows,
                loading: accounts.isLoading && rows.isEmpty,
                selectedId: selected,
                onChanged: (id) => setState(() => _accountId = id),
              ),
              const SizedBox(height: Space.x4),

              _Field(
                controller: _holder,
                label: 'Card holder',
                hint: _fallbackHolder,
                capitalization: TextCapitalization.words,
              ),
              const SizedBox(height: Space.x4),

              _Field(
                controller: _number,
                label: 'Card number',
                hint: _fallbackNumber,
                keyboardType: TextInputType.number,
                mono: true,
                // Grouping only, never rejection: any run of digits is accepted
                // at any length.
                formatters: const [_GroupedDigits(groupSize: 4, maxDigits: 19)],
              ),
              const SizedBox(height: Space.x4),

              Row(
                children: [
                  Expanded(
                    child: _Field(
                      controller: _expiry,
                      label: 'Expiry',
                      hint: _fallbackExpiry,
                      keyboardType: TextInputType.number,
                      mono: true,
                      formatters: const [_ExpiryMask()],
                    ),
                  ),
                  const SizedBox(width: Space.x3),
                  Expanded(
                    child: _Field(
                      controller: _cvc,
                      label: 'CVC',
                      hint: _fallbackCvc,
                      keyboardType: TextInputType.number,
                      mono: true,
                      formatters: const [_GroupedDigits(maxDigits: 4)],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.x4),

              _Field(
                controller: _limit,
                label: 'Daily spending limit',
                hint: '2000',
                keyboardType: TextInputType.number,
                mono: true,
                prefix: '\$',
                formatters: const [_GroupedDigits(maxDigits: 9)],
              ),

              const SizedBox(height: Space.x5),

              FilledButton(
                onPressed: _working || rows.isEmpty
                    ? null
                    : () => _submit(rows),
                child: _working
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Add card'),
              ),

              const SizedBox(height: Space.x2),
            ],
          ),
        ),
      ),
    );
  }
}

/// One labelled text field, styled from the shared input theme.
class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.capitalization = TextCapitalization.none,
    this.formatters,
    this.mono = false,
    this.prefix,
  });

  final TextEditingController controller;
  final String label;

  /// Doubles as the value used when the field is left empty, so the placeholder
  /// is a promise rather than a suggestion.
  final String hint;

  final TextInputType? keyboardType;
  final TextCapitalization capitalization;
  final List<TextInputFormatter>? formatters;

  /// Figures are set in the monospace face, the way they are everywhere else.
  final bool mono;

  final String? prefix;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    textCapitalization: capitalization,
    inputFormatters: formatters,
    style: mono
        ? AppType.numericMedium.copyWith(color: context.tokens.textPrimary)
        : null,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefix,
    ),
  );
}

/// A row of chips over one enum. Selection cannot be invalid, so there is
/// nothing to validate.
class _Choices<T> extends StatelessWidget {
  const _Choices({
    required this.label,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.leadingOf,
  });

  final String label;
  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final Widget Function(T value)? leadingOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppType.labelMedium.copyWith(color: tokens.textSecondary),
        ),
        const SizedBox(height: Space.x2),
        Row(
          children: [
            for (final value in values) ...[
              Expanded(
                child: _Chip(
                  label: labelOf(value),
                  leading: leadingOf?.call(value),
                  selected: value == selected,
                  onTap: () => onChanged(value),
                ),
              ),
              if (value != values.last) const SizedBox(width: Space.x3),
            ],
          ],
        ),
      ],
    );
  }
}

/// One selectable chip.
///
/// Requires a bounded width from its parent, because the label is flexible so it
/// can ellipsize. Callers place it inside an [Expanded] or a [SizedBox]; dropping
/// it straight into a horizontally scrolling row will fail to lay out.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
    this.sublabel,
  });

  final String label;
  final String? sublabel;
  final Widget? leading;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: Layout.minTapTarget),
            padding: const EdgeInsets.symmetric(
              horizontal: Space.x3,
              vertical: Space.x3,
            ),
            decoration: BoxDecoration(
              color: selected ? tokens.interactiveSecondary : tokens.surface,
              borderRadius: AppRadius.all(AppRadius.md),
              border: Border.all(
                color: selected ? tokens.accent : tokens.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: Space.x2),
                ],
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: AppType.labelLarge.copyWith(
                          color: selected
                              ? tokens.interactivePrimary
                              : tokens.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (sublabel != null)
                        Text(
                          sublabel!,
                          style: AppType.bodySmall.copyWith(
                            color: tokens.textSecondary,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The account the card settles against.
class _AccountPicker extends StatelessWidget {
  const _AccountPicker({
    required this.accounts,
    required this.loading,
    required this.selectedId,
    required this.onChanged,
  });

  final List<Account> accounts;
  final bool loading;
  final String? selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Linked account',
          style: AppType.labelMedium.copyWith(color: tokens.textSecondary),
        ),
        const SizedBox(height: Space.x2),
        if (loading)
          Text(
            'Loading accounts\u2026',
            style: AppType.bodySmall.copyWith(color: tokens.textSecondary),
          )
        else if (accounts.isEmpty)
          Text(
            'No account to link a card to.',
            style: AppType.bodySmall.copyWith(color: tokens.error),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final account in accounts)
                  Padding(
                    padding: const EdgeInsets.only(right: Space.x3),
                    // A fixed width, not a minimum. This row scrolls
                    // horizontally, so it hands its children an unbounded width,
                    // and the flex inside _Chip cannot lay out against that.
                    child: SizedBox(
                      width: 168,
                      child: _Chip(
                        label: account.name,
                        sublabel: account.shortCode,
                        selected: account.id == selectedId,
                        onTap: () => onChanged(account.id),
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

/// Keeps digits only and groups them, so a typed number reads the way it is
/// printed on a card. Never rejects a value for being short or implausible.
class _GroupedDigits extends TextInputFormatter {
  const _GroupedDigits({this.groupSize, required this.maxDigits});

  /// Null leaves the digits unbroken.
  final int? groupSize;

  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > maxDigits) digits = digits.substring(0, maxDigits);

    final size = groupSize;
    final text = size == null
        ? digits
        : [
            for (var i = 0; i < digits.length; i += size)
              digits.substring(i, (i + size).clamp(0, digits.length)),
          ].join(' ');

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Formats an expiry as `MM/YY` while typing. Accepts any month and any year,
/// including ones already past.
class _ExpiryMask extends TextInputFormatter {
  const _ExpiryMask();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 4) digits = digits.substring(0, 4);

    final text = digits.length <= 2
        ? digits
        : '${digits.substring(0, 2)}/${digits.substring(2)}';

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
