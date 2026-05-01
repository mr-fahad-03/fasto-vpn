import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/premium_surface.dart';
import '../../auth/state/auth_controller.dart';
import '../../subscription/state/entitlement_controller.dart';
import '../../subscription/state/purchase_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final entitlement = ref.watch(entitlementControllerProvider).valueOrNull;
    final purchase = ref.watch(purchaseControllerProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF3555D9),
        foregroundColor: Colors.white,
      ),
      body: PremiumPageBackground(
        child: auth.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
          error: (error, _) => Center(
            child: Text(error.toString(), style: const TextStyle(color: Colors.white)),
          ),
          data: (authState) {
            final session = authState.session;
            final isGuest = session?.isGuest ?? true;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                PremiumGlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text('Mode: ${isGuest ? 'Guest' : 'Google'}', style: const TextStyle(color: Color(0xFFE2E8F0))),
                        if (!isGuest) ...[
                          Text('Email: ${session?.email ?? '-'}', style: const TextStyle(color: Color(0xFFE2E8F0))),
                          Text('Name: ${session?.displayName ?? '-'}', style: const TextStyle(color: Color(0xFFE2E8F0))),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          'Subscription: ${entitlement?.hasPremium == true ? 'Premium' : 'Free'}',
                          style: const TextStyle(color: Color(0xFFE2E8F0)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (isGuest)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B1021)),
                    onPressed: () => context.go(AppRoutes.authChoice),
                    icon: const Icon(Icons.login),
                    label: const Text('Sign in with Google'),
                  )
                else
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ),
                    onPressed: authState.busy
                        ? null
                        : () async {
                            await ref.read(authControllerProvider.notifier).signOut();
                            if (!context.mounted) return;
                            context.go(AppRoutes.authChoice);
                          },
                    icon: const Icon(Icons.logout),
                    label: Text(authState.busy ? 'Signing out...' : 'Sign out'),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                  ),
                  onPressed: purchase == null
                      ? null
                      : () => ref.read(purchaseControllerProvider.notifier).restorePurchases(),
                  icon: const Icon(Icons.restore),
                  label: const Text('Restore purchases'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: () => context.push(AppRoutes.subscriptionStatus),
                  child: const Text('View subscription status details'),
                ),
                const SizedBox(height: 90),
              ],
            );
          },
        ),
      ),
    );
  }
}
