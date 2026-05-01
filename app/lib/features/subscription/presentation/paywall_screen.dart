import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/premium_surface.dart';
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
      appBar: AppBar(
        title: const Text('Premium'),
        backgroundColor: const Color(0xFF4B42D4),
        foregroundColor: Colors.white,
      ),
      body: PremiumPageBackground(
        child: purchaseAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          ),
          data: (state) {
            final package = state.selectedPackage;
            final price = package?.storeProduct.priceString ?? 'US\$9.99/month';

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                PremiumGlassCard(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xCC090F30),
                      Color(0xAA233CC5),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fasto Premium',
                          style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Unlock all active proxy countries and remove all ads.',
                          style: TextStyle(color: Color(0xFFE2E8F0)),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.workspace_premium, color: Colors.amberAccent),
                            const SizedBox(width: 8),
                            Text(
                              price,
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text('Plan target: US\$9.99/month', style: TextStyle(color: Color(0xFFE2E8F0))),
                        const SizedBox(height: 16),
                        if (entitlement?.hasPremium == true)
                          const ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.verified, color: Color(0xFF86EFAC)),
                            title: Text(
                              'Premium is already active on your account',
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        else ...[
                          if (isGuest)
                            PremiumGlassCard(
                              padding: const EdgeInsets.all(10),
                              child: ListTile(
                                leading: const Icon(Icons.info_outline, color: Colors.white),
                                title: const Text(
                                  'Sign in with Google to buy premium',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                ),
                                subtitle: const Text(
                                  'Guest mode cannot attach purchases to your backend account.',
                                  style: TextStyle(color: Color(0xFFE2E8F0)),
                                ),
                                trailing: TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.white.withValues(alpha: 0.14),
                                  ),
                                  onPressed: () => context.go(AppRoutes.authChoice),
                                  child: const Text('Sign In'),
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0B1021),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
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
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                            ),
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
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => ref.read(purchaseControllerProvider.notifier).refreshOfferings(),
                            child: const Text('Reload Offerings'),
                          ),
                        ),
                        if (state.error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            state.error!,
                            style: const TextStyle(color: Color(0xFFFFCDD2)),
                          ),
                        ],
                      ],
                    ),
                  ),
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
