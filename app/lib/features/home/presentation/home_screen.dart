import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/models/proxy_node.dart';
import '../../../core/widgets/ad_banner.dart';
import '../../auth/state/auth_controller.dart';
import '../../proxies/state/proxy_list_controller.dart';
import '../../proxies/state/vpn_connection_controller.dart';
import '../../subscription/state/ad_visibility_provider.dart';
import '../../subscription/state/entitlement_controller.dart';
import '../../subscription/state/purchase_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final int initialTab;

  const HomeScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late int _tabIndex;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTab.clamp(0, 2);
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Fasto VPN', 'Plans', 'Profile'];

    final tabs = [
      _HomeTab(
        onOpenServers: () => context.push(AppRoutes.proxies),
        onOpenPlans: () => setState(() => _tabIndex = 1),
      ),
      _PlansTab(
        onOpenAuth: () => context.go(AppRoutes.authChoice),
        onOpenSubscriptionStatus: () => context.push(AppRoutes.subscriptionStatus),
      ),
      _ProfileTab(
        onOpenAuth: () => context.go(AppRoutes.authChoice),
        onOpenSettings: () => context.push(AppRoutes.settings),
        onOpenSubscriptionStatus: () => context.push(AppRoutes.subscriptionStatus),
        onOpenPlans: () => setState(() => _tabIndex = 1),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tabIndex]),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push(AppRoutes.settings),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.workspace_premium_outlined),
            selectedIcon: Icon(Icons.workspace_premium),
            label: 'Plans',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

enum _ConnectFlightUiState { idle, animating, success, failed }

class _HomeTab extends ConsumerStatefulWidget {
  final VoidCallback onOpenServers;
  final VoidCallback onOpenPlans;

  const _HomeTab({
    required this.onOpenServers,
    required this.onOpenPlans,
  });

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> with SingleTickerProviderStateMixin {
  late final AnimationController _flightController;
  late final Animation<double> _flightProgress;
  _ConnectFlightUiState _flightState = _ConnectFlightUiState.idle;
  int _flightRunId = 0;

  @override
  void initState() {
    super.initState();
    _flightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _flightProgress = CurvedAnimation(
      parent: _flightController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _flightController.dispose();
    super.dispose();
  }

  List<ProxyNode> _distinctCountries(List<ProxyNode> items) {
    final byCountry = <String, ProxyNode>{};
    for (final item in items) {
      final key = item.countryCode.toUpperCase();
      final existing = byCountry[key];
      if (existing == null || (existing.isPremium && !item.isPremium)) {
        byCountry[key] = item;
      }
    }
    return byCountry.values.toList();
  }

  ProxyNode? _findById(List<ProxyNode> items, String? id) {
    if (id == null || id.isEmpty) {
      return null;
    }

    for (final item in items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  Future<void> _openSelectorSheet(
    BuildContext context, {
    required List<ProxyNode> topCountries,
    required bool hasPremium,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Top Countries',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 8),
                if (topCountries.isEmpty)
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.public_off),
                    title: Text('No servers available right now'),
                  )
                else
                  ...topCountries.map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        ref.read(vpnConnectionControllerProvider.notifier).setSelectedProxy(item.id);
                        Navigator.of(sheetContext).pop();
                      },
                      leading: CircleAvatar(child: Text(item.flag)),
                      title: Text(item.country),
                      subtitle: Text(item.isPremium ? 'Premium server' : 'Free server'),
                      trailing: item.isPremium && !hasPremium
                          ? const Icon(Icons.lock_outline)
                          : const Icon(Icons.chevron_right),
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      widget.onOpenServers();
                    },
                    icon: const Icon(Icons.public),
                    label: const Text('More Servers'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _setFlightState(_ConnectFlightUiState value) {
    if (!mounted) {
      return;
    }
    setState(() {
      _flightState = value;
    });
  }

  Future<void> _handleConnectAction({
    required ProxyNode selectedProxy,
    required bool hasPremium,
    required bool selectedNeedsUpgrade,
    required String? connectedProxyId,
  }) async {
    final notifier = ref.read(vpnConnectionControllerProvider.notifier);

    if (selectedNeedsUpgrade) {
      widget.onOpenPlans();
      return;
    }

    if (selectedProxy.id == connectedProxyId) {
      await notifier.disconnect();
      _flightController.value = 0;
      _setFlightState(_ConnectFlightUiState.idle);
      return;
    }

    if (_flightState == _ConnectFlightUiState.animating) {
      return;
    }

    final runId = ++_flightRunId;
    _setFlightState(_ConnectFlightUiState.animating);

    final animationFuture = _flightController.forward(from: 0);
    final connected = await notifier.connect(selectedProxy, hasPremium: hasPremium);

    if (!mounted || runId != _flightRunId) {
      return;
    }

    if (!connected) {
      if (_flightController.isAnimating) {
        _flightController.stop(canceled: true);
      }
      _flightController.value = 0;
      _setFlightState(_ConnectFlightUiState.failed);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted || runId != _flightRunId) {
        return;
      }
      _setFlightState(_ConnectFlightUiState.idle);
      return;
    }

    try {
      await animationFuture;
    } catch (_) {
      // Ignore canceled animation futures on widget lifecycle changes.
    }

    if (!mounted || runId != _flightRunId) {
      return;
    }

    _setFlightState(_ConnectFlightUiState.success);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted || runId != _flightRunId) {
      return;
    }
    _setFlightState(_ConnectFlightUiState.idle);
  }

  @override
  Widget build(BuildContext context) {
    final entitlement = ref.watch(entitlementControllerProvider).valueOrNull;
    final proxiesState = ref.watch(proxyListControllerProvider).valueOrNull;
    final auth = ref.watch(authControllerProvider).valueOrNull;
    final connectionState = ref.watch(vpnConnectionControllerProvider).valueOrNull ?? const VpnConnectionState();
    final showAds = ref.watch(adVisibilityProvider);

    final hasPremium = entitlement?.hasPremium == true;
    final allItems = proxiesState?.items ?? const <ProxyNode>[];
    final countries = _distinctCountries(allItems);
    final topCountries = countries.take(3).toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vpnConnectionControllerProvider.notifier).syncWithAvailableProxies(countries);
    });

    final selected = _findById(countries, connectionState.selectedProxyId);
    final connected = _findById(countries, connectionState.connectedProxyId);
    final selectedProxy = selected ?? (countries.isNotEmpty ? countries.first : null);
    final selectedNeedsUpgrade = selectedProxy != null && selectedProxy.isPremium && !hasPremium;
    final connectActionBusy = connectionState.connecting || _flightState == _ConnectFlightUiState.animating;

    final freeCount = countries.where((item) => !item.isPremium).length;
    final premiumCount = countries.where((item) => item.isPremium).length;
    final isGuest = auth?.session?.isGuest ?? true;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(entitlementControllerProvider.notifier).refresh();
        await ref.read(proxyListControllerProvider.notifier).refresh();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      connected == null
                          ? 'App Proxy: Disconnected'
                          : 'App Proxy: ${connected.country}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  hasPremium
                      ? 'All countries unlocked with premium speed.'
                      : 'Free plan active. Premium countries are visible but locked.',
                  style: const TextStyle(color: Color(0xFFE2E8F0)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'This mode routes Fasto app requests only. Browser/device IP does not change.',
                  style: TextStyle(color: Color(0xFFBFDBFE), fontSize: 12),
                ),
                const SizedBox(height: 12),
                AnimatedBuilder(
                  animation: _flightProgress,
                  builder: (context, _) {
                    return _ConnectFlightTrack(
                      progress: _flightProgress.value,
                      selectedCountry: selectedProxy?.country ?? 'Selected Country',
                      selectedFlag: selectedProxy?.flag ?? '🌐',
                      state: _flightState,
                    );
                  },
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _flightState == _ConnectFlightUiState.success
                      ? Container(
                          key: const ValueKey('connect_success_chip'),
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.55)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'You are connected',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _flightState == _ConnectFlightUiState.failed
                          ? Container(
                              key: const ValueKey('connect_failed_chip'),
                              margin: const EdgeInsets.only(top: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Connection failed',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                ),
                const SizedBox(height: 14),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _openSelectorSheet(
                    context,
                    topCountries: topCountries,
                    hasPremium: hasPremium,
                  ),
                  child: Ink(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: Text(selectedProxy?.flag ?? '🌐'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedProxy?.country ?? 'Select a Country',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                selectedProxy == null
                                    ? 'Tap to choose a server'
                                    : selectedProxy.isPremium
                                        ? 'Premium server'
                                        : 'Free server',
                                style: const TextStyle(color: Color(0xFFE2E8F0)),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.expand_more, color: Colors.white),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: selectedProxy == null || connectActionBusy
                        ? null
                        : () => _handleConnectAction(
                              selectedProxy: selectedProxy,
                              hasPremium: hasPremium,
                              selectedNeedsUpgrade: selectedNeedsUpgrade,
                              connectedProxyId: connectionState.connectedProxyId,
                            ),
                    icon: Icon(
                      selectedNeedsUpgrade
                          ? Icons.workspace_premium
                          : selectedProxy?.id == connectionState.connectedProxyId
                              ? Icons.link_off
                              : Icons.power_settings_new,
                    ),
                    label: Text(
                      connectActionBusy
                          ? 'Connecting...'
                          : selectedProxy == null
                              ? 'Select Country'
                              : selectedNeedsUpgrade
                                  ? 'Upgrade to Connect'
                                  : selectedProxy.id == connectionState.connectedProxyId
                                      ? 'Disconnect'
                                      : 'Connect Now',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Countries',
                  value: '${countries.length}',
                  icon: Icons.public,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'Free',
                  value: '$freeCount',
                  icon: Icons.lock_open,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'Premium',
                  value: '$premiumCount',
                  icon: Icons.lock,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Popular Countries',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...topCountries.map(
                        (item) => ActionChip(
                          avatar: Text(item.flag),
                          label: Text(item.country),
                          onPressed: () => ref.read(vpnConnectionControllerProvider.notifier).setSelectedProxy(item.id),
                        ),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.grid_view_rounded, size: 18),
                        label: const Text('More'),
                        onPressed: widget.onOpenServers,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isGuest) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Guest mode is active'),
                subtitle: const Text('Sign in with Google from Profile to unlock premium purchases.'),
                trailing: TextButton(
                  onPressed: () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
                  child: const Text('Sign In'),
                ),
              ),
            ),
          ],
          if (connectionState.error != null) ...[
            const SizedBox(height: 8),
            Text(
              connectionState.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 12),
          Center(child: AdBannerWidget(show: showAds)),
        ],
      ),
    );
  }
}

class _ConnectFlightTrack extends StatelessWidget {
  final double progress;
  final String selectedCountry;
  final String selectedFlag;
  final _ConnectFlightUiState state;

  const _ConnectFlightTrack({
    required this.progress,
    required this.selectedCountry,
    required this.selectedFlag,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final showPlane = state == _ConnectFlightUiState.animating || state == _ConnectFlightUiState.success;
    final lineColor = state == _ConnectFlightUiState.failed
        ? Colors.redAccent.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.45);

    return Container(
      height: 78,
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const startX = 20.0;
          final endX = constraints.maxWidth - 28;
          final deltaX = endX - startX;
          final planeX = startX + (deltaX * progress);
          final planeY = 34 - (math.sin(progress * math.pi) * 12);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: startX,
                right: 16,
                top: 35,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: lineColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const Positioned(
                left: 0,
                top: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8),
                    Icon(Icons.radio_button_checked, size: 14, color: Colors.white),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                top: 8,
                child: SizedBox(
                  width: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        selectedCountry,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedFlag,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              if (showPlane)
                Positioned(
                  left: planeX - 10,
                  top: planeY,
                  child: const Icon(
                    Icons.flight,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PlansTab extends ConsumerWidget {
  final VoidCallback onOpenAuth;
  final VoidCallback onOpenSubscriptionStatus;

  const _PlansTab({
    required this.onOpenAuth,
    required this.onOpenSubscriptionStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement = ref.watch(entitlementControllerProvider).valueOrNull;
    final purchaseAsync = ref.watch(purchaseControllerProvider);
    final auth = ref.watch(authControllerProvider).valueOrNull;
    final isGuest = auth?.session?.isGuest ?? true;

    return purchaseAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(error.toString(), textAlign: TextAlign.center),
        ),
      ),
      data: (state) {
        final hasPremium = entitlement?.hasPremium == true;
        final package = state.selectedPackage;
        final price = package?.storeProduct.priceString ?? 'US\$9.99 / month';

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B132B), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fasto Premium',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Unlock all countries, connect instantly, and enjoy an ad-free experience.',
                    style: TextStyle(color: Color(0xFFE2E8F0)),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.workspace_premium, color: Colors.amberAccent),
                      const SizedBox(width: 8),
                      Text(
                        price,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BenefitRow(label: 'Connect to premium countries'),
                    _BenefitRow(label: 'No ad interruptions'),
                    _BenefitRow(label: 'Priority server availability'),
                    _BenefitRow(label: 'Faster premium routing'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (hasPremium)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.verified, color: Colors.green),
                  title: const Text('Premium is active'),
                  subtitle: const Text('Your account currently has full access to all countries.'),
                  trailing: TextButton(
                    onPressed: onOpenSubscriptionStatus,
                    child: const Text('Details'),
                  ),
                ),
              )
            else ...[
              if (isGuest)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Sign in required'),
                    subtitle: const Text('Sign in with Google to purchase premium and sync your plan.'),
                    trailing: TextButton(
                      onPressed: onOpenAuth,
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
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.shopping_bag_outlined),
                  label: Text(state.purchasing ? 'Processing...' : 'Upgrade Now'),
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
            TextButton(
              onPressed: () => ref.read(purchaseControllerProvider.notifier).refreshOfferings(),
              child: const Text('Reload Plans'),
            ),
            if (state.error != null)
              Text(
                state.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        );
      },
    );
  }
}

class _ProfileTab extends ConsumerWidget {
  final VoidCallback onOpenAuth;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenSubscriptionStatus;
  final VoidCallback onOpenPlans;

  const _ProfileTab({
    required this.onOpenAuth,
    required this.onOpenSettings,
    required this.onOpenSubscriptionStatus,
    required this.onOpenPlans,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final entitlement = ref.watch(entitlementControllerProvider).valueOrNull;
    final purchase = ref.watch(purchaseControllerProvider).valueOrNull;

    return auth.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (authState) {
        final session = authState.session;
        final isGuest = session?.isGuest ?? true;
        final name = session?.displayName?.trim().isNotEmpty == true
            ? session!.displayName!
            : (session?.email ?? 'Guest User');

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            isGuest ? 'Guest Account' : (session?.email ?? 'Google Account'),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(entitlement?.hasPremium == true ? 'PREMIUM' : 'FREE'),
                      avatar: Icon(
                        entitlement?.hasPremium == true ? Icons.workspace_premium : Icons.lock_open,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.workspace_premium_outlined),
                    title: const Text('Plan & Billing'),
                    subtitle: const Text('Manage premium access and billing state'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: onOpenPlans,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: const Text('Subscription Status'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: onOpenSubscriptionStatus,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Settings'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: onOpenSettings,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (isGuest)
              ElevatedButton.icon(
                onPressed: authState.busy ? null : onOpenAuth,
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
              onPressed: purchase == null || purchase.restoring
                  ? null
                  : () => ref.read(purchaseControllerProvider.notifier).restorePurchases(),
              icon: const Icon(Icons.restore),
              label: Text(purchase?.restoring == true ? 'Restoring...' : 'Restore purchases'),
            ),
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String label;

  const _BenefitRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
