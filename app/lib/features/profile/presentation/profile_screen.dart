import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
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
      appBar: AppBar(title: const Text('Profile')),
      body: auth.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (authState) {
          final session = authState.session;
          final isGuest = session?.isGuest ?? true;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Account', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Mode: ${isGuest ? 'Guest' : 'Google'}'),
                      if (!isGuest) ...[
                        Text('Email: ${session?.email ?? '-'}'),
                        Text('Name: ${session?.displayName ?? '-'}'),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Subscription: ${entitlement?.hasPremium == true ? 'Premium' : 'Free'}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (isGuest)
                ElevatedButton.icon(
                  onPressed: () => context.go(AppRoutes.authChoice),
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in with Google'),
                )
              else
                OutlinedButton.icon(
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
                onPressed: purchase == null
                    ? null
                    : () => ref.read(purchaseControllerProvider.notifier).restorePurchases(),
                icon: const Icon(Icons.restore),
                label: const Text('Restore purchases'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.push(AppRoutes.subscriptionStatus),
                child: const Text('View subscription status details'),
              ),
            ],
          );
        },
      ),
    );
  }
}
