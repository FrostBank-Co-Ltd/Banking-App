import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/format/dates.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../widgets/pressable.dart';
import '../widgets/states.dart';
import '../widgets/surfaces.dart';

/// Profile, settings, security, and logout.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final profile = ref.watch(profileProvider);
    final preferences = ref.watch(preferencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ResponsiveShell(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.x5,
            Space.x2,
            Space.x5,
            Space.x16 + Space.x16,
          ),
          children: [
            AsyncSection<UserProfile>(
              value: profile,
              onRetry: () => ref.invalidate(profileProvider),
              skeleton: Row(
                children: const [
                  SkeletonBlock(width: 64, height: 64, radius: AppRadius.pill),
                  SizedBox(width: Space.x4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBlock(width: 140, height: 18),
                        SizedBox(height: Space.x2),
                        SkeletonBlock(width: 180, height: 13),
                      ],
                    ),
                  ),
                ],
              ),
              builder: (data) => Row(
                children: [
                  Monogram(
                    initials: data.initials,
                    size: 64,
                    background: tokens.interactiveSecondary,
                  ),
                  const SizedBox(width: Space.x4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.fullName,
                          style: AppType.headlineMedium.copyWith(
                            color: tokens.textPrimary,
                          ),
                        ),
                        const SizedBox(height: Space.x1),
                        Text(
                          data.maskedEmail,
                          style: AppType.bodySmall.copyWith(
                            color: tokens.textSecondary,
                          ),
                        ),
                        Text(
                          data.maskedMobile,
                          style: AppType.bodySmall.copyWith(
                            color: tokens.textSecondary,
                          ),
                        ),
                        Text(
                          'Member since ${Dates.monthYear(data.memberSince)}',
                          style: AppType.bodySmall.copyWith(
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.x6),
            OutlinedButton.icon(
              onPressed: profile.value == null
                  ? null
                  : () => _showEditProfileModal(context, ref, profile.value!),
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Edit details'),
            ),
            const SizedBox(height: Space.x8),
            const SectionHeader(title: 'Settings'),
            _SettingsCard(
              children: [
                _ThemeRow(mode: preferences.themeMode),
                _Divider(),
                _NavRow(
                  icon: Icons.language_rounded,
                  label: 'Language',
                  value: 'English',
                  route: '/soon/language',
                ),
                _Divider(),
                _NavRow(
                  icon: Icons.attach_money_rounded,
                  label: 'Currency display',
                  value: preferences.activeCurrency.displayName,
                  route: '/currency',
                ),
              ],
            ),
            const SizedBox(height: Space.x6),
            const SectionHeader(title: 'Security'),
            _SettingsCard(
              children: [
                _ToggleRow(
                  icon: Icons.visibility_off_rounded,
                  label: 'Hide balances',
                  value: preferences.balancesHidden,
                  onChanged: (_) => ref
                      .read(preferencesProvider.notifier)
                      .toggleBalanceVisibility(),
                ),
                _Divider(),
                _NavRow(
                  icon: Icons.pin_rounded,
                  label: 'Change PIN',
                  route: '/soon/change-pin',
                ),
                _Divider(),
                _NavRow(
                  icon: Icons.fingerprint_rounded,
                  label: 'Biometric unlock',
                  value: 'Not set up',
                  route: '/soon/biometrics',
                ),
                _Divider(),
                _NavRow(
                  icon: Icons.timer_outlined,
                  label: 'Session timeout',
                  value: '2 minutes',
                  route: '/soon/session-timeout',
                ),
              ],
            ),
            const SizedBox(height: Space.x6),
            const SectionHeader(title: 'About'),
            _SettingsCard(
              children: [
                _NavRow(
                  icon: Icons.info_outline_rounded,
                  label: 'About this build',
                  route: '/soon/about',
                ),
              ],
            ),
            const SizedBox(height: Space.x4),
            Text(
              'Every balance, card, rate, and transaction in this application is mock data.',
              style: AppType.bodySmall.copyWith(color: tokens.textSecondary),
            ),
            const SizedBox(height: Space.x8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () => _confirmLogout(context, ref),
                style: FilledButton.styleFrom(
                  backgroundColor: tokens.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.all(AppRadius.pill),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Log out'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final tokens = context.tokens;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(Space.x2),
              decoration: BoxDecoration(
                color: tokens.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.logout_rounded, color: tokens.error, size: 22),
            ),
            const SizedBox(width: Space.x3),
            Expanded(
              child: Text(
                'Log out',
                style: AppType.titleMedium.copyWith(color: tokens.textPrimary),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to log out? You will need to sign in again to access your accounts.',
          style: AppType.bodyMedium.copyWith(color: tokens.textSecondary),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          Space.x4,
          0,
          Space.x4,
          Space.x4,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: tokens.textPrimary,
                    side: BorderSide(color: tokens.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: Space.x3),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: Space.x3),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: Space.x3),
                  ),
                  child: const Text('Log Out'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(sessionProvider.notifier).signOut();
    }
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        borderRadius: AppRadius.all(AppRadius.lg),
        border: Border.all(color: tokens.border),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    color: context.tokens.border,
    indent: Space.x4,
    endIndent: Space.x4,
  );
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.label,
    required this.route,
    this.value,
  });

  final IconData icon;
  final String label;
  final String route;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Pressable(
      onTap: () => context.push(route),
      semanticLabel: value == null ? label : '$label, $value',
      borderRadius: AppRadius.lg,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.x4,
          vertical: Space.x4,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: tokens.textSecondary),
            const SizedBox(width: Space.x3),
            Expanded(
              child: Text(
                label,
                style: AppType.titleSmall.copyWith(color: tokens.textPrimary),
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: AppType.bodyMedium.copyWith(color: tokens.textSecondary),
              ),
            const SizedBox(width: Space.x1),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: tokens.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.x4,
        vertical: Space.x2,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: tokens.textSecondary),
          const SizedBox(width: Space.x3),
          Expanded(
            child: Text(
              label,
              style: AppType.titleSmall.copyWith(color: tokens.textPrimary),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: tokens.accent,
          ),
        ],
      ),
    );
  }
}

class _ThemeRow extends ConsumerWidget {
  const _ThemeRow({required this.mode});

  final ThemeMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.all(Space.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.brightness_6_rounded,
                size: 20,
                color: tokens.textSecondary,
              ),
              const SizedBox(width: Space.x3),
              Text(
                'Theme',
                style: AppType.titleSmall.copyWith(color: tokens.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: Space.x3),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
              ButtonSegment(value: ThemeMode.light, label: Text('Light')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
            ],
            selected: {mode},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => ref
                .read(preferencesProvider.notifier)
                .setThemeMode(selection.first),
            style: SegmentedButton.styleFrom(
              backgroundColor: tokens.surface,
              foregroundColor: tokens.textSecondary,
              selectedBackgroundColor: tokens.interactiveSecondary,
              selectedForegroundColor: tokens.interactivePrimary,
              side: BorderSide(color: tokens.border),
              textStyle: AppType.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}

void _showEditProfileModal(
  BuildContext context,
  WidgetRef ref,
  UserProfile profile,
) {
  final nameCtrl = TextEditingController(text: profile.fullName);
  final emailCtrl = TextEditingController(text: profile.email);
  final mobileCtrl = TextEditingController(text: profile.mobile);

  showDialog<void>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Edit Profile'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Full Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: emailCtrl,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: mobileCtrl,
            decoration: const InputDecoration(labelText: 'Mobile'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final updated = UserProfile(
              id: profile.id,
              fullName: nameCtrl.text.trim(),
              email: emailCtrl.text.trim(),
              mobile: mobileCtrl.text.trim(),
              memberSince: profile.memberSince,
            );

            try {
              await ref.read(profileRepositoryProvider).updateProfile(updated);
              ref.invalidate(profileProvider);
              if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully!')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not update profile: $e')),
                );
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
