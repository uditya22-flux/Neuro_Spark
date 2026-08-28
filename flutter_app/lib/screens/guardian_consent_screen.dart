import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session_sync.dart';
import '../../services/guardian_bootstrap_service.dart';
import '../features/guardian/providers/consent_providers.dart';
import '../features/guardian/data/consent_repository.dart';

/// Guardian must accept active consent before intake (hospital / gov beta requirement).
class GuardianConsentScreen extends ConsumerStatefulWidget {
  const GuardianConsentScreen({super.key});

  @override
  ConsumerState<GuardianConsentScreen> createState() => _GuardianConsentScreenState();
}

class _GuardianConsentScreenState extends ConsumerState<GuardianConsentScreen> {
  bool _accepted = false;
  bool _busy = false;
  String? _error;

  Future<void> _submit(String consentVersionId) async {
    if (!_accepted) {
      setState(() => _error = 'Please confirm you have read and accept the consent terms.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(consentRepositoryProvider).acceptConsent(consentVersionId);
      await ref.read(guardianBootstrapServiceProvider).ensureReady();
      await syncAuthSessionRef(ref);
      if (!mounted) return;
      context.go('/intake');
    } catch (e) {
      setState(() => _error = 'Could not record consent. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final consentAsync = ref.watch(activeConsentVersionProvider);
    final hasConsentAsync = ref.watch(hasActiveConsentProvider);

    return hasConsentAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => _buildScaffold(context, null),
      data: (hasConsent) {
        if (hasConsent) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/intake');
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return consentAsync.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, __) => _buildScaffold(context, null),
          data: (version) => _buildScaffold(context, version),
        );
      },
    );
  }

  Widget _buildScaffold(BuildContext context, ConsentVersion? version) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Guardian consent')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(Icons.verified_user_outlined, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Guardian-led strengths exploration',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'MindBridge helps guardians explore a child\'s present-moment play interests. '
              'It is not a diagnostic tool, employment predictor, or clinical screening device.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('You agree that:', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    const _ConsentBullet(
                      'You are the parent or legal guardian and will supervise all sessions.',
                    ),
                    const _ConsentBullet(
                      'Activities measure present enjoyment only — never future career intent.',
                    ),
                    const _ConsentBullet(
                      'Child data is stored securely and can be exported or purged on request.',
                    ),
                    const _ConsentBullet(
                      'This beta is for strengths exploration, not medical diagnosis or treatment.',
                    ),
                    if (version != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Consent version: ${version.version} (${version.jurisdiction})',
                        style: theme.textTheme.labelMedium,
                      ),
                      if (version.documentUrl.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SelectableText(
                          'Policy document: ${version.documentUrl}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _accepted,
              onChanged: _busy ? null : (v) => setState(() => _accepted = v ?? false),
              title: const Text('I have read and accept these terms on behalf of my child.'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy || version == null ? null : () => _submit(version.id),
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Accept and continue'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsentBullet extends StatelessWidget {
  const _ConsentBullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
