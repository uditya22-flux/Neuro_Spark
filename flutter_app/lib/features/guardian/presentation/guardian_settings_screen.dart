import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../providers/game_environment_provider.dart';
import '../../../services/intake_persistence_service.dart';
import '../data/guardian_repository.dart';

final guardianRepositoryProvider = Provider<GuardianRepository>((ref) {
  return SupabaseGuardianRepository();
});

/// Account, privacy, and data controls for hospital / guardian deployment.
class GuardianSettingsScreen extends ConsumerStatefulWidget {
  const GuardianSettingsScreen({super.key});

  @override
  ConsumerState<GuardianSettingsScreen> createState() => _GuardianSettingsScreenState();
}

class _GuardianSettingsScreenState extends ConsumerState<GuardianSettingsScreen> {
  bool _busy = false;
  String? _message;

  Future<void> _exportData() async {
    final childId = ref.read(gameEnvironmentProvider)?.childId;
    if (childId == null) {
      setState(() => _message = 'Complete intake first to link a child profile.');
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      await ref.read(guardianRepositoryProvider).requestPrivacyExport(childId: childId);
      setState(() => _message = 'Export requested. You will receive data per your institution policy.');
    } catch (e) {
      setState(() => _message = 'Export could not be started. Try again later.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestPurge() async {
    final childId = ref.read(gameEnvironmentProvider)?.childId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request data purge?'),
        content: const Text(
          'This requests deletion of your child\'s stored data per privacy policy. '
          'This action is processed asynchronously and cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Request purge'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      await ref.read(guardianRepositoryProvider).requestPurge(childId: childId);
      setState(() => _message = 'Purge requested. Processing may take up to 24 hours.');
    } catch (e) {
      setState(() => _message = 'Purge could not be started.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    await ref.read(intakePersistenceServiceProvider).clearAll(ref);
    ref.read(authStatusProvider.notifier).state = const AuthUserStatus(
      isLoggedIn: false,
      userId: '',
      hasCompletedIntake: false,
      hasCompletedStrengthFunnel: false,
      hasCompletedAssessment: false,
    );
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = Supabase.instance.client.auth.currentUser?.email ?? 'Signed in';

    return Scaffold(
      appBar: AppBar(title: const Text('Guardian account')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Signed in as'),
            subtitle: Text(email),
          ),
          const Divider(),
          Text('Data & privacy', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Export my data'),
            subtitle: const Text('Request a copy of stored guardian and child records.'),
            onTap: _busy ? null : _exportData,
          ),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: theme.colorScheme.error),
            title: const Text('Request data purge'),
            subtitle: const Text('Delete stored data per privacy policy.'),
            onTap: _busy ? null : _requestPurge,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Sign out'),
            onTap: _signOut,
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(_message!, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 24),
          Text(
            'MindBridge is guardian-led strengths exploration — not diagnostic or clinical screening.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
