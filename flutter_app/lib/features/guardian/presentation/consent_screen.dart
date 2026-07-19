import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _accepted = false;
  bool _busy = false;
  String _verificationMode = 'email';
  String? _statusMessage;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_accepted) return;
    final client = Supabase.instance.client;
    setState(() {
      _busy = true;
      _statusMessage = null;
    });
    try {
      if (_verificationMode == 'email') {
        await client.auth.signInWithOtp(email: _emailController.text.trim());
      } else {
        await client.auth.signInWithOtp(phone: _phoneController.text.trim());
      }
      setState(() {
        _statusMessage = 'Verification code sent.';
      });
    } on AuthException catch (error) {
      setState(() {
        _statusMessage = error.message;
      });
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _verifyOtp() async {
    final client = Supabase.instance.client;
    setState(() {
      _busy = true;
      _statusMessage = null;
    });
    try {
      if (_verificationMode == 'email') {
        await client.auth.verifyOTP(
          email: _emailController.text.trim(),
          token: _otpController.text.trim(),
          type: OtpType.email,
        );
      } else {
        await client.auth.verifyOTP(
          phone: _phoneController.text.trim(),
          token: _otpController.text.trim(),
          type: OtpType.sms,
        );
      }
      final user = client.auth.currentUser;
      if (user != null) {
        await client.from('parent_verifications').upsert(<String, Object?>{
          'guardian_id': user.id,
          'method': _verificationMode == 'email' ? 'email_otp' : 'phone_otp',
          'status': 'verified',
          'verified_at': DateTime.now().toIso8601String(),
          'metadata': <String, Object?>{'source': 'flutter_app'},
        });
      }
      if (!mounted) return;
      context.go('/guardian/home');
    } on AuthException catch (error) {
      setState(() {
        _statusMessage = error.message;
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guardian consent')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const Text(
            'A calm, guardian-led play experience',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          const Text(
            'MindBridge uses guardian-approved settings to make two play activities more comfortable. '
            'It is not a medical or educational assessment.',
          ),
          const SizedBox(height: 16),
          const Text(
            'You can review each suggested setting, request an export, or ask us to delete your family data. '
            'Your child may pause or stop at any time.',
          ),
          const SizedBox(height: 24),
          CheckboxListTile(
            value: _accepted,
            onChanged: (value) => setState(() => _accepted = value ?? false),
            title: const Text('I am the child’s parent or legal guardian and agree to this version of the consent notice.'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const <ButtonSegment<String>>[
              ButtonSegment<String>(value: 'email', label: Text('Email OTP')),
              ButtonSegment<String>(value: 'phone', label: Text('Phone OTP')),
            ],
            selected: <String>{_verificationMode},
            onSelectionChanged: (selection) => setState(() => _verificationMode = selection.first),
          ),
          const SizedBox(height: 16),
          if (_verificationMode == 'email')
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email address'),
            )
          else
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number'),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Verification code'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              FilledButton(
                onPressed: _busy || !_accepted ? null : _sendOtp,
                child: const Text('Send code'),
              ),
              OutlinedButton(
                onPressed: _busy ? null : _verifyOtp,
                child: const Text('Verify and continue'),
              ),
            ],
          ),
          if (_statusMessage != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(_statusMessage!),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : () => context.go('/guardian/review'),
            child: const Text('Skip to settings review'),
          ),
        ],
      ),
    );
  }
}
