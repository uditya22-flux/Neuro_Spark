import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_auth_repository.dart';

/// Lightweight guardian sign-in. Verification and consent are still enforced
/// by Supabase before a child profile or preferences can be created.
class GuardianLoginScreen extends StatefulWidget {
  const GuardianLoginScreen({super.key, required this.onAuthenticated});

  final ValueChanged<String> onAuthenticated;

  @override
  State<GuardianLoginScreen> createState() => _GuardianLoginScreenState();
}

class _GuardianLoginScreenState extends State<GuardianLoginScreen> {
  final _email = TextEditingController();
  final _auth = SupabaseAuthRepository();
  StreamSubscription<AuthState>? _authSubscription;
  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _authSubscription = _auth.authChanges.listen((state) {
      if (state.event == AuthChangeEvent.signedIn && state.session?.user != null) {
        _completeAuthentication(state.session!.user);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Enter a valid guardian email address.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _auth.sendEmailOtp(email);
      if (mounted) setState(() => _codeSent = true);
    } on AuthException catch (error) {
      if (mounted) {
        setState(
          () => _error = 'Could not send sign-in link: ${error.message}',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'We could not send a sign-in link. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _completeAuthentication(User user) {
    if (!mounted) return;
    widget.onAuthenticated(user.id);
    context.go('/intake');
  }

  void _changeEmail() {
    setState(() {
      _codeSent = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Guardian sign in')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Sign in before setting up a child’s exploration space.', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _email,
                      enabled: !_busy && !_codeSent,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Guardian email'),
                    ),
                    if (_codeSent) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Open the sign-in link in your email. MindBridge will reopen automatically.',
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _busy ? null : _changeEmail,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Change email'),
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _sendCode,
                      child: Text(_busy
                          ? 'Please wait...'
                          : _codeSent
                              ? 'Resend sign-in link'
                              : 'Send sign-in link'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
