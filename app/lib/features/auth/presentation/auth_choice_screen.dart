import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/env.dart';
import '../../../core/widgets/premium_surface.dart';
import '../state/auth_controller.dart';

class AuthChoiceScreen extends ConsumerWidget {
  const AuthChoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Fasto VPN'),
        backgroundColor: const Color(0xFF5D39FF),
        foregroundColor: Colors.white,
      ),
      body: PremiumPageBackground(
        child: SafeArea(
          child: auth.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: PremiumGlassCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFFFCDD2), size: 42),
                      const SizedBox(height: 10),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(authControllerProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            data: (state) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: PremiumGlassCard(
                    borderRadius: BorderRadius.circular(28),
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xCC090F30),
                        Color(0xAA233CC5),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Choose how you want to continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 30,
                            height: 1.08,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Guest mode gives free servers only. Google sign-in enables premium upgrades.',
                          style: TextStyle(
                            color: Color(0xFFE2E8F0),
                            height: 1.35,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 22),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B1021),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: state.busy
                              ? null
                              : () => ref.read(authControllerProvider.notifier).continueAsGuest(),
                          child: state.busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Continue as Guest'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: state.busy || !Env.firebaseEnabled
                              ? null
                              : () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
                          icon: const Icon(Icons.login),
                          label: Text(
                            Env.firebaseEnabled ? 'Sign in with Google' : 'Google Sign-in Disabled',
                          ),
                        ),
                        if (state.error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            state.error!,
                            style: const TextStyle(color: Color(0xFFFFCDD2)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
