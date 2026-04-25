import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../auth/state/auth_controller.dart';
import '../state/entitlement_controller.dart';
import '../state/purchase_controller.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseAsync = ref.watch(purchaseControllerProvider);
    final entitlement = ref.watch(entitlementControllerProvider).valueOrNull;
    final authState = ref.watch(authControllerProvider).valueOrNull;

    final isGuest = authState?.session?.isGuest ?? true;

    return Scaffold(
      appBar: AppBar(title: const Text('Premium')),
      body: purchaseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (state) {
          final package = state.selectedPackage;
          final price = package?.storeProduct.priceString ?? 'US\$9.99/month';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fasto Premium', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      const Text('Unlock all active proxy countries and remove all ads.'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.workspace_premium),
                          const SizedBox(width: 8),
                          Text(
                            price,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text('Plan target: US\$9.99/month'),
                      const SizedBox(height: 16),
                      if (entitlement?.hasPremium == true)
                        const ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.verified, color: Colors.green),
                          title: Text('Premium is already active on your account'),
                        )
                      else ...[
                        if (isGuest)
                          Card(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: ListTile(
                              leading: const Icon(Icons.info_outline),
                              title: const Text('Sign in with Google to buy premium'),
                              subtitle: const Text(
                                'Guest mode cannot attach purchases to your backend account.',
                              ),
                              trailing: TextButton(
                                onPressed: () => context.go(AppRoutes.authChoice),
                                child: const Text('Sign In'),
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isGuest || state.purchasing || package == null
                                ? null
                                : () => ref.read(purchaseControllerProvider.notifier).purchaseSelected(),
                            icon: state.purchasing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.shopping_bag_outlined),
                            label: Text(state.purchasing ? 'Processing...' : 'Subscribe Now'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: state.restoring
                              ? null
                              : () => ref.read(purchaseControllerProvider.notifier).restorePurchases(),
                          child: Text(state.restoring ? 'Restoring...' : 'Restore Purchases'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => ref.read(purchaseControllerProvider.notifier).refreshOfferings(),
                          child: const Text('Reload Offerings'),
                        ),
                      ),
                      if (state.error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          state.error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
