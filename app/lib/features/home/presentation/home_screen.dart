import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

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
    final isHomeTab = _tabIndex == 0;
    final isPlansTab = _tabIndex == 1;
    final isProfileTab = _tabIndex == 2;
    final highlightAppBar = isHomeTab || isPlansTab || isProfileTab;

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
      extendBody: true,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Text(
          isHomeTab ? 'FASTO VPN' : titles[_tabIndex],
          style: highlightAppBar
              ? const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.6,
                )
              : null,
        ),
        backgroundColor: isHomeTab
            ? const Color(0xFF6A3EF0)
            : isPlansTab
                ? const Color(0xFF4B42D4)
                : isProfileTab
                    ? const Color(0xFF3555D9)
                    : null,
        foregroundColor: highlightAppBar ? Colors.white : null,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (highlightAppBar)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _FrostedIconButton(
                icon: Icons.settings_outlined,
                onTap: () => context.push(AppRoutes.settings),
              ),
            )
          else
            IconButton(
              tooltip: 'Settings',
              onPressed: () => context.push(AppRoutes.settings),
              icon: const Icon(Icons.settings_outlined),
            ),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: tabs,
      ),
      bottomNavigationBar: highlightAppBar
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xE6F5F8FF),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.62)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: NavigationBarTheme(
                        data: const NavigationBarThemeData(
                          backgroundColor: Colors.transparent,
                          surfaceTintColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          indicatorColor: Color(0xFFB8F1E2),
                        ),
                        child: NavigationBar(
                          height: 72,
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
                      ),
                    ),
                  ),
                ),
              ),
            )
          : NavigationBar(
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
    const topContentInset = 12.0;
    final isConnectedToSelected = selectedProxy?.id == connectionState.connectedProxyId;
    final connectButtonLabel = connectActionBusy
        ? 'Connecting...'
        : selectedProxy == null
            ? 'Select Country'
            : selectedNeedsUpgrade
                ? 'Upgrade to Connect'
                : isConnectedToSelected
                    ? 'Disconnect'
                    : 'Connect Now';
    final connectButtonIcon = selectedNeedsUpgrade
        ? Icons.workspace_premium
        : isConnectedToSelected
            ? Icons.link_off
            : Icons.power_settings_new;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD137FF),
            Color(0xFF5D39FF),
            Color(0xFF12A9FF),
          ],
          stops: [0, 0.52, 1],
        ),
      ),
      child: Stack(
        children: [
          RefreshIndicator(
            color: const Color(0xFF0F172A),
            onRefresh: () async {
              await ref.read(entitlementControllerProvider.notifier).refresh();
              await ref.read(proxyListControllerProvider.notifier).refresh();
            },
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, topContentInset, 16, 20),
              children: [
                _GlassPanel(
                  padding: const EdgeInsets.all(18),
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xCC090F30),
                      Color(0xAA233CC5),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: 0.42,
                            child: Transform.scale(
                              scale: 1.2,
                              child: Lottie.asset(
                                'assets/World.json',
                                fit: BoxFit.cover,
                                alignment: Alignment.centerRight,
                                repeat: true,
                                animate: true,
                                frameRate: FrameRate.max,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Color(0xBF080F2A),
                                  Color(0x660A1338),
                                  Color(0x1A0A1338),
                                ],
                                stops: [0, 0.52, 1],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.shield_rounded, color: Colors.white, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  connected == null
                                      ? 'App Proxy: Disconnected'
                                      : 'App Proxy: ${connected.country}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      const SizedBox(height: 10),
                      Text(
                        hasPremium
                            ? 'All countries unlocked with premium speed.'
                            : 'Free plan active. Premium countries are visible but locked.',
                        style: const TextStyle(color: Color(0xFFE2E8F0), height: 1.35),
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
                            selectedFlag: selectedProxy?.flag ?? '??',
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
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _openSelectorSheet(
                          context,
                          topCountries: topCountries,
                          hasPremium: hasPremium,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                child: Text(selectedProxy?.flag ?? '??'),
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
                      _GradientActionButton(
                        label: connectButtonLabel,
                        icon: connectButtonIcon,
                        onTap: selectedProxy == null || connectActionBusy
                            ? null
                            : () => _handleConnectAction(
                                  selectedProxy: selectedProxy,
                                  hasPremium: hasPremium,
                                  selectedNeedsUpgrade: selectedNeedsUpgrade,
                                  connectedProxyId: connectionState.connectedProxyId,
                                ),
                        kind: selectedNeedsUpgrade
                            ? _GradientActionKind.premium
                            : isConnectedToSelected
                                ? _GradientActionKind.disconnect
                                : _GradientActionKind.connect,
                      ),
                        ],
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
                _GlassPanel(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Popular Countries',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (topCountries.isEmpty)
                        const Text(
                          'No countries available right now.',
                          style: TextStyle(color: Color(0xFFE2E8F0)),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...topCountries.map(
                              (item) => ActionChip(
                                avatar: Text(item.flag),
                                backgroundColor: const Color(0x660B1021),
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
                                labelStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                label: Text(item.country),
                                onPressed: () =>
                                    ref.read(vpnConnectionControllerProvider.notifier).setSelectedProxy(item.id),
                              ),
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.grid_view_rounded, size: 18, color: Colors.white),
                              backgroundColor: const Color(0x660B1021),
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
                              labelStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              label: const Text('More'),
                              onPressed: widget.onOpenServers,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (isGuest) ...[
                  const SizedBox(height: 12),
                  _GlassPanel(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                          child: const Icon(Icons.info_outline, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Guest mode active. Sign in from Profile to unlock premium purchases.',
                            style: TextStyle(color: Colors.white, height: 1.3),
                          ),
                        ),
                        TextButton(
                          onPressed: () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white.withValues(alpha: 0.14),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          child: const Text('Sign In'),
                        ),
                      ],
                    ),
                  ),
                ],
                if (connectionState.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    connectionState.error!,
                    style: const TextStyle(color: Color(0xFFFFCDD2), fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 12),
                Center(child: AdBannerWidget(show: showAds)),
                const SizedBox(height: 94),
              ],
            ),
          ),
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

class _HomeBackgroundGlow extends StatelessWidget {
  final Alignment alignment;
  final double size;
  final Color color;

  const _HomeBackgroundGlow({
    required this.alignment,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final LinearGradient? gradient;

  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: gradient ??
                const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0x33FFFFFF),
                    Color(0x1DFFFFFF),
                  ],
                ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _FrostedIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FrostedIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Material(
          color: Colors.white.withValues(alpha: 0.18),
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
              ),
              child: Icon(icon, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

enum _GradientActionKind { connect, disconnect, premium }

class _GradientActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final _GradientActionKind kind;

  const _GradientActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.kind,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    late final LinearGradient gradient;
    if (disabled) {
      gradient = const LinearGradient(
        colors: [
          Color(0x3DFFFFFF),
          Color(0x3DFFFFFF),
        ],
      );
    } else if (kind == _GradientActionKind.disconnect) {
      gradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF7F1D1D),
          Color(0xFFB91C1C),
        ],
      );
    } else if (kind == _GradientActionKind.premium) {
      gradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF8A3D06),
          Color(0xFFEA580C),
        ],
      );
    } else {
      gradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0B1021),
          Color(0xFF0A1A3D),
        ],
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: gradient,
        boxShadow: disabled
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: Colors.white.withValues(alpha: disabled ? 0.55 : 1)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: disabled ? 0.55 : 1),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
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

        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFD137FF),
                Color(0xFF5D39FF),
                Color(0xFF12A9FF),
              ],
              stops: [0, 0.52, 1],
            ),
          ),
          child: Stack(
            children: [
              const _HomeBackgroundGlow(
                alignment: Alignment.topLeft,
                size: 240,
                color: Color(0x4DFFFFFF),
              ),
              const _HomeBackgroundGlow(
                alignment: Alignment.bottomRight,
                size: 300,
                color: Color(0x29000000),
              ),
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                children: [
                  _GlassPanel(
                    borderRadius: BorderRadius.circular(28),
                    padding: const EdgeInsets.all(18),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xAA0A1338),
                        Color(0x994A33C6),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fasto Premium',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Unlock all countries, connect instantly, and enjoy an ad-free experience.',
                          style: TextStyle(
                            color: Color(0xFFE2E8F0),
                            height: 1.35,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.amberAccent.withValues(alpha: 0.2),
                              ),
                              child: const Icon(Icons.workspace_premium, color: Colors.amberAccent, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                price,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _GlassPanel(
                    padding: const EdgeInsets.all(14),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BenefitRow(
                          label: 'Connect to premium countries',
                          textColor: Colors.white,
                          iconColor: Color(0xFF86EFAC),
                        ),
                        _BenefitRow(
                          label: 'No ad interruptions',
                          textColor: Colors.white,
                          iconColor: Color(0xFF86EFAC),
                        ),
                        _BenefitRow(
                          label: 'Priority server availability',
                          textColor: Colors.white,
                          iconColor: Color(0xFF86EFAC),
                        ),
                        _BenefitRow(
                          label: 'Faster premium routing',
                          textColor: Colors.white,
                          iconColor: Color(0xFF86EFAC),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (hasPremium)
                    _GlassPanel(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.green.withValues(alpha: 0.22),
                            ),
                            child: const Icon(Icons.verified, color: Color(0xFF86EFAC)),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Premium is active',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Your account currently has full access to all countries.',
                                  style: TextStyle(color: Color(0xFFE2E8F0)),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: onOpenSubscriptionStatus,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.white.withValues(alpha: 0.14),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            child: const Text('Details'),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    if (isGuest)
                      _GlassPanel(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                              child: const Icon(Icons.info_outline, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sign in required',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Sign in with Google to purchase premium and sync your plan.',
                                    style: TextStyle(color: Color(0xFFE2E8F0)),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: onOpenAuth,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.white.withValues(alpha: 0.14),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                              child: const Text('Sign In'),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    _GradientActionButton(
                      onTap: isGuest || state.purchasing || package == null
                          ? null
                          : () => ref.read(purchaseControllerProvider.notifier).purchaseSelected(),
                      kind: _GradientActionKind.premium,
                      icon: state.purchasing ? Icons.hourglass_top_rounded : Icons.shopping_bag_outlined,
                      label: state.purchasing ? 'Processing...' : 'Upgrade Now',
                    ),
                  ],
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: state.restoring
                          ? null
                          : () => ref.read(purchaseControllerProvider.notifier).restorePurchases(),
                      child: Text(
                        state.restoring ? 'Restoring...' : 'Restore Purchases',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => ref.read(purchaseControllerProvider.notifier).refreshOfferings(),
                    child: const Text(
                      'Reload Plans',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        state.error!,
                        style: const TextStyle(
                          color: Color(0xFFFFCDD2),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 94),
                ],
              ),
            ],
          ),
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

        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFD137FF),
                Color(0xFF5D39FF),
                Color(0xFF12A9FF),
              ],
              stops: [0, 0.52, 1],
            ),
          ),
          child: Stack(
            children: [
              const _HomeBackgroundGlow(
                alignment: Alignment.topLeft,
                size: 240,
                color: Color(0x4DFFFFFF),
              ),
              const _HomeBackgroundGlow(
                alignment: Alignment.bottomRight,
                size: 300,
                color: Color(0x29000000),
              ),
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                children: [
                  _GlassPanel(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.24),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.36)),
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isGuest ? 'Guest Account' : (session?.email ?? 'Google Account'),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: Colors.white.withValues(alpha: 0.16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                entitlement?.hasPremium == true ? Icons.workspace_premium : Icons.lock_open,
                                size: 16,
                                color: entitlement?.hasPremium == true ? Colors.amberAccent : Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                entitlement?.hasPremium == true ? 'PREMIUM' : 'FREE',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _GlassPanel(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _ProfileActionTile(
                          icon: Icons.workspace_premium_outlined,
                          title: 'Plan & Billing',
                          subtitle: 'Manage premium access and billing state',
                          onTap: onOpenPlans,
                        ),
                        Divider(height: 1, color: Colors.white.withValues(alpha: 0.2)),
                        _ProfileActionTile(
                          icon: Icons.receipt_long_outlined,
                          title: 'Subscription Status',
                          onTap: onOpenSubscriptionStatus,
                        ),
                        Divider(height: 1, color: Colors.white.withValues(alpha: 0.2)),
                        _ProfileActionTile(
                          icon: Icons.settings_outlined,
                          title: 'Settings',
                          onTap: onOpenSettings,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isGuest)
                    _GradientActionButton(
                      onTap: authState.busy ? null : onOpenAuth,
                      icon: Icons.login,
                      label: authState.busy ? 'Please wait...' : 'Sign in with Google',
                      kind: _GradientActionKind.connect,
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: purchase == null || purchase.restoring
                          ? null
                          : () => ref.read(purchaseControllerProvider.notifier).restorePurchases(),
                      icon: const Icon(Icons.restore),
                      label: Text(purchase?.restoring == true ? 'Restoring...' : 'Restore purchases'),
                    ),
                  ),
                  const SizedBox(height: 94),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ProfileActionTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: const TextStyle(color: Color(0xFFE2E8F0)),
            ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white),
      onTap: onTap,
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
    return _GlassPanel(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.86),
                ),
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String label;
  final Color? textColor;
  final Color? iconColor;

  const _BenefitRow({
    required this.label,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: iconColor ?? Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: textColor == null ? null : TextStyle(color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}

