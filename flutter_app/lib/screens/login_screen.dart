import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/auth/auth_session_sync.dart';
import '../core/auth/supabase_auth_repository.dart';
import '../core/config/demo_config.dart';
import '../core/config/pilot_test_config.dart';
import '../core/config/supabase_config.dart';
import '../features/demo/presentation/demo_methodology_sheet.dart';
import '../features/demo/providers/demo_mode_provider.dart';
import '../features/demo/services/demo_launch_service.dart';
import '../core/router/app_router.dart';
import '../services/guardian_bootstrap_service.dart';

/// Guardian sign-in for local Supabase or hosted projects.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _auth = SupabaseAuthRepository();

  bool _isSignUp = false;
  bool _busy = false;
  bool _awaitingOtp = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _exitDemoMode() {
    ref.read(demoModeProvider.notifier).state = false;
    DemoConfig.runtimeActive = false;
    DemoConfig.guidedFullFlow = false;
  }

  String _mapAuthError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'Sign-in failed. If you just created an account, confirm your email first, '
          'or tap Field test sign-in for the ready-made pilot account.';
    }
    if (msg.contains('rate limit') || msg.contains('email rate')) {
      return 'Too many emails were sent. Wait 10–15 minutes, then use '
          'Field test sign-in (no email needed).';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please confirm your email from the inbox link, then sign in again.';
    }
    return e.message;
  }

  Future<void> _afterAuthenticated({bool fieldTestLaunch = false}) async {
    _exitDemoMode();
    await ref.read(guardianBootstrapServiceProvider).ensureReady();
    await syncAuthSessionRef(ref);
    if (!mounted) return;

    final auth = ref.read(authStatusProvider);
    if (!auth.hasCompletedIntake) {
      context.go('/consent');
      return;
    }

    if (fieldTestLaunch) {
      await restartStrengthFunnelExploration(ref, context);
      return;
    }

    if (!auth.hasCompletedStrengthFunnel) {
      context.go('/strength-funnel');
      return;
    }

    context.go('/dashboard');
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.length < 8) {
      setState(() => _error = 'Use a valid email and password (8+ characters).');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      if (_isSignUp) {
        final response = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );
        if (response.session != null) {
          await _afterAuthenticated();
          return;
        }
        // Hosted projects may require email confirmation — try immediate sign-in anyway.
        try {
          await Supabase.instance.client.auth.signInWithPassword(
            email: email,
            password: password,
          );
          await _afterAuthenticated();
          return;
        } on AuthException {
          setState(() {
            _isSignUp = false;
            _error =
                'Account created. Check your email to confirm, then sign in with the same password.';
          });
          return;
        }
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        await _afterAuthenticated();
      }
    } on AuthException catch (e) {
      setState(() => _error = _mapAuthError(e));
    } catch (e) {
      setState(() => _error = 'Could not reach MindBridge. Check your internet connection.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pilotSignIn() async {
    if (!PilotTestConfig.enabled) return;
    setState(() {
      _busy = true;
      _error = null;
      _emailController.text = PilotTestConfig.email;
      _passwordController.text = PilotTestConfig.password;
    });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: PilotTestConfig.email,
        password: PilotTestConfig.password,
      );
      await _afterAuthenticated(fieldTestLaunch: true);
    } on AuthException catch (e) {
      setState(() => _error = _mapAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendEmailOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email first.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _auth.sendEmailOtp(email);
      setState(() => _awaitingOtp = true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            SupabaseConfig.isLocalDev
                ? 'Check Inbucket at http://127.0.0.1:64324 for the code.'
                : 'Check your email for the 6-digit sign-in code.',
          ),
        ),
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyEmailOtp() async {
    final email = _emailController.text.trim();
    final token = _otpController.text.trim();
    if (email.isEmpty || token.length < 6) {
      setState(() => _error = 'Enter your email and the 6-digit code.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _auth.verifyEmailOtp(email, token);
      await _afterAuthenticated();
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email to reset password.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent. Check your inbox.')),
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guardian sign in')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'MindBridge helps guardians explore a child\'s present-moment play strengths. '
                      'Sign in to run intake, the interest funnel, and child play.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Not a diagnostic or clinical screening tool.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                    const SizedBox(height: 20),
                    if (PilotTestConfig.enabled) ...[
                      Card(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Field testing (real app)',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'One-tap sign-in with a confirmed pilot guardian account — '
                                'full 10-layer strength funnel (30 play themes, then narrows to top interests), '
                                'then child play on the cloud backend.',
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: _busy ? null : _pilotSignIn,
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('Field test sign-in'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                    ],
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _busy ? null : _submit(),
                    ),
                    if (_awaitingOtp) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Email sign-in code (6 digits)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _busy ? null : _verifyEmailOtp,
                        child: const Text('Verify code & sign in'),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isSignUp ? 'Create account' : 'Sign in'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() => _isSignUp = !_isSignUp),
                      child: Text(
                        _isSignUp
                            ? 'Already have an account? Sign in'
                            : 'Need an account? Create one',
                      ),
                    ),
                    TextButton(
                      onPressed: _busy ? null : _resetPassword,
                      child: const Text('Forgot password?'),
                    ),
                    OutlinedButton(
                      onPressed: _busy ? null : _sendEmailOtp,
                      child: const Text('Sign in with email code instead'),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () async {
                              await DemoMethodologySheet.show(context);
                              if (!context.mounted) return;
                              await launchHospitalDemoGuided(ref, context);
                            },
                      icon: const Icon(Icons.local_hospital_outlined),
                      label: const Text('Hospital demo (pre-filled answers)'),
                    ),
                    Text(
                      'Hospital demos stop at layer 3 for a short walkthrough. '
                      'For kid field testing, use Field test sign-in above (all 10 layers).',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () async {
                              await launchHospitalDemoQuick(ref, context);
                            },
                      child: const Text('Quick demo (skip intake)'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
