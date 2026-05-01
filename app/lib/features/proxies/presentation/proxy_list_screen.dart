import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/models/proxy_node.dart';
import '../../../core/widgets/ad_banner.dart';
import '../../../core/widgets/native_ad_placeholder.dart';
import '../../../core/widgets/premium_surface.dart';
import '../../subscription/state/ad_visibility_provider.dart';
import '../../subscription/state/entitlement_controller.dart';
import '../state/proxy_list_controller.dart';
import '../state/vpn_connection_controller.dart';

class ProxyListScreen extends ConsumerStatefulWidget {
  const ProxyListScreen({super.key});

  @override
  ConsumerState<ProxyListScreen> createState() => _ProxyListScreenState();
}

class _ProxyListScreenState extends ConsumerState<ProxyListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(proxyFilterControllerProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final proxyAsync = ref.watch(proxyListControllerProvider);
    final filtered = ref.watch(filteredProxiesProvider);
    final entitlement = ref.watch(entitlementControllerProvider).valueOrNull;
    final connectionAsync = ref.watch(vpnConnectionControllerProvider);
    final connection = connectionAsync.valueOrNull ?? const VpnConnectionState();
    final countryServers = _distinctCountries(filtered);
    final selectedProxy = _findById(countryServers, connection.selectedProxyId);
    final connectedProxy = _findById(countryServers, connection.connectedProxyId);
    final hasPremium = entitlement?.hasPremium == true;
    final selectedNeedsUpgrade = selectedProxy != null && selectedProxy.isPremium && !hasPremium;

    final showAds = ref.watch(adVisibilityProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vpnConnectionControllerProvider.notifier).syncWithAvailableProxies(countryServers);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Server'),
        backgroundColor: const Color(0xFF3555D9),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => ref.read(proxyListControllerProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: PremiumPageBackground(
        child: proxyAsync.when(
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
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(proxyListControllerProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
        data: (state) {
          if (state.loading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (state.error != null && state.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: PremiumGlassCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFFFCDD2), size: 42),
                      const SizedBox(height: 10),
                      Text(
                        state.error!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.read(proxyListControllerProvider.notifier).refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Column(
            children: [
              if (connectedProxy != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: PremiumGlassCard(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(connectedProxy.flag),
                      ),
                      title: Text(
                        'Connected: ${connectedProxy.country}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text(
                        'Your secure server is active.',
                        style: TextStyle(color: Color(0xFFE2E8F0)),
                      ),
                      trailing: const Icon(Icons.verified, color: Color(0xFF86EFAC)),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search country',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.78)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.34)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                  ),
                  onChanged: (value) => ref.read(proxyFilterControllerProvider.notifier).setSearch(value),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose a country, then tap Connect.',
                    style: TextStyle(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              if (entitlement?.hasPremium != true)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: PremiumGlassCard(
                    child: ListTile(
                      leading: const Icon(Icons.workspace_premium_outlined, color: Colors.amberAccent),
                      title: const Text(
                        'Unlock all countries and no ads',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text(
                        'Upgrade to Premium for full server access.',
                        style: TextStyle(color: Color(0xFFE2E8F0)),
                      ),
                      trailing: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.14),
                        ),
                        onPressed: () => context.push(AppRoutes.premium),
                        child: const Text('Upgrade'),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: countryServers.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No servers found. Try changing your search text.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemBuilder: (context, index) {
                          final item = countryServers[index];
                          final isSelected = connection.selectedProxyId == item.id;
                          final isConnected = connection.connectedProxyId == item.id;

                          return PremiumGlassCard(
                            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                            child: ListTile(
                              onTap: () => ref.read(vpnConnectionControllerProvider.notifier).setSelectedProxy(item.id),
                              leading: CircleAvatar(
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                child: Text(item.flag),
                              ),
                              title: Text(
                                item.country,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                isConnected
                                    ? 'Connected'
                                    : item.isPremium && !hasPremium
                                        ? 'Premium server'
                                        : 'Tap to select',
                                style: const TextStyle(color: Color(0xFFE2E8F0)),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (item.isPremium)
                                    Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: Icon(
                                        Icons.lock_outline,
                                        size: 18,
                                        color: item.isPremium && !hasPremium ? Colors.amberAccent : Colors.white,
                                      ),
                                    ),
                                  Icon(
                                    isConnected
                                        ? Icons.verified
                                        : isSelected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
                                    color: isConnected ? const Color(0xFF86EFAC) : Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemCount: countryServers.length,
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  'App traffic only mode: browser/device IP remains unchanged.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B1021),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: selectedProxy == null || connection.connecting
                        ? null
                        : () async {
                            if (selectedNeedsUpgrade) {
                              context.push(AppRoutes.premium);
                              return;
                            }
                            final notifier = ref.read(vpnConnectionControllerProvider.notifier);
                            if (connection.connectedProxyId == selectedProxy.id) {
                              await notifier.disconnect();
                            } else {
                              await notifier.connect(
                                selectedProxy,
                                hasPremium: hasPremium,
                              );
                            }
                          },
                    child: Text(
                      connection.connecting
                          ? 'Connecting...'
                          : selectedProxy == null
                              ? 'Select a Country'
                              : selectedNeedsUpgrade
                                  ? 'Upgrade to Connect'
                              : connection.connectedProxyId == selectedProxy.id
                                  ? 'Disconnect'
                                  : 'Connect',
                    ),
                  ),
                ),
              ),
              if (connection.error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    connection.error!,
                    style: const TextStyle(color: Color(0xFFFFCDD2)),
                    textAlign: TextAlign.center,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Center(child: AdBannerWidget(show: showAds)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    cardTheme: CardThemeData(
                      color: Colors.white.withValues(alpha: 0.12),
                      surfaceTintColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    iconTheme: const IconThemeData(color: Colors.white),
                    textTheme: Theme.of(context).textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
                  ),
                  child: NativeAdPlaceholder(show: showAds),
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
