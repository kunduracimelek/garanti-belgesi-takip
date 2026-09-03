import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../theme/app_theme.dart';

/// Ayarlar > Güvenlik > Biyometrik Kilit açıksa uygulama açılışında
/// gösterilen kilit ekranı.
class BiometricGate extends StatefulWidget {
  final Widget child;
  const BiometricGate({super.key, required this.child});

  @override
  State<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends State<BiometricGate> {
  bool _unlocked = false;
  bool _checking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tryAuthenticate();
  }

  Future<void> _tryAuthenticate() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final auth = LocalAuthentication();
      final ok = await auth.authenticate(
        localizedReason: 'Vaultify verilerinize erişmek için kimliğinizi doğrulayın',
        options: const AuthenticationOptions(biometricOnly: false),
      );
      setState(() {
        _unlocked = ok;
        _checking = false;
      });
    } catch (e) {
      setState(() {
        _checking = false;
        _error = 'Kimlik doğrulama kullanılamadı.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return widget.child;

    return Scaffold(
      backgroundColor: AppColors.darkBgMain,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fingerprint_rounded, size: 72, color: AppColors.neonPurple),
              const SizedBox(height: 16),
              const Text('Vaultify Kilitli', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _checking ? null : _tryAuthenticate,
                icon: const Icon(Icons.lock_open_rounded),
                label: Text(_checking ? 'Doğrulanıyor...' : 'Kilidi Aç'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
