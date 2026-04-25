import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/entitlement_controller.dart';
import '../state/purchase_controller.dart';

class SubscriptionStatusScreen extends ConsumerWidget {
  const SubscriptionStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlementAsync = ref.watch(entitlementControllerProvider);
    final purchaseAsync = ref.watch(purchaseControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription Status')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: entitlementAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('Failed to load entitlement: $error'),
                data: (entitlement) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Backend Entitlement', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Plan: ${entitlement.plan}'),
                    Text('Premium: ${entitlement.hasPremium ? 'Yes' : 'No'}'),
                    Text('Ads Enabled: ${entitlement.adsEnabled ? 'Yes' : 'No'}'),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.read(entitlementControllerProvider.notifier).refresh(),
                      child: const Text('Refresh entitlement'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: purchaseAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('RevenueCat state unavailable: $error'),
                data: (purchase) {
                  final info = purchase.customerInfo;
                  final activeEntitlements = info?.entitlements.active.keys.join(', ') ?? 'none';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RevenueCat', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Active entitlements: $activeEntitlements'),
                      Text('Offerings loaded: ${purchase.offerings != null ? 'Yes' : 'No'}'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => ref.read(purchaseControllerProvider.notifier).refreshOfferings(),
                              child: const Text('Reload offerings'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => ref.read(purchaseControllerProvider.notifier).restorePurchases(),
                              child: const Text('Restore purchases'),
                            ),
                          ),
                        ],
                      ),
                      if (purchase.error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          purchase.error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
