import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/premium_surface.dart';

import '../state/entitlement_controller.dart';
import '../state/purchase_controller.dart';

class SubscriptionStatusScreen extends ConsumerWidget {
  const SubscriptionStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlementAsync = ref.watch(entitlementControllerProvider);
    final purchaseAsync = ref.watch(purchaseControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Status'),
        backgroundColor: const Color(0xFF4B42D4),
        foregroundColor: Colors.white,
      ),
      body: PremiumPageBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PremiumGlassCard(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: entitlementAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                  error: (error, _) => Text(
                    'Failed to load entitlement: $error',
                    style: const TextStyle(color: Color(0xFFFFCDD2)),
                  ),
                  data: (entitlement) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Backend Entitlement',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text('Plan: ${entitlement.plan}', style: const TextStyle(color: Color(0xFFE2E8F0))),
                      Text(
                        'Premium: ${entitlement.hasPremium ? 'Yes' : 'No'}',
                        style: const TextStyle(color: Color(0xFFE2E8F0)),
                      ),
                      Text(
                        'Ads Enabled: ${entitlement.adsEnabled ? 'Yes' : 'No'}',
                        style: const TextStyle(color: Color(0xFFE2E8F0)),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                        ),
                        onPressed: () => ref.read(entitlementControllerProvider.notifier).refresh(),
                        child: const Text('Refresh entitlement'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            PremiumGlassCard(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: purchaseAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                  error: (error, _) => Text(
                    'RevenueCat state unavailable: $error',
                    style: const TextStyle(color: Color(0xFFFFCDD2)),
                  ),
                  data: (purchase) {
                    final info = purchase.customerInfo;
                    final activeEntitlements = info?.entitlements.active.keys.join(', ') ?? 'none';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RevenueCat',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Active entitlements: $activeEntitlements',
                          style: const TextStyle(color: Color(0xFFE2E8F0)),
                        ),
                        Text(
                          'Offerings loaded: ${purchase.offerings != null ? 'Yes' : 'No'}',
                          style: const TextStyle(color: Color(0xFFE2E8F0)),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
                                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                                ),
                                onPressed: () => ref.read(purchaseControllerProvider.notifier).refreshOfferings(),
                                child: const Text('Reload offerings'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
                                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                                ),
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
                            style: const TextStyle(color: Color(0xFFFFCDD2)),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}
