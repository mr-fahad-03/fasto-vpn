import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/models/proxy_node.dart';
import '../../../core/widgets/ad_banner.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/native_ad_placeholder.dart';
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
        actions: [
          IconButton(
            onPressed: () => ref.read(proxyListControllerProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: proxyAsync.when(
        loading: () => const LoadingView(label: 'Loading servers...'),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(proxyListControllerProvider),
        ),
        data: (state) {
          if (state.loading) {
            return const LoadingView(label: 'Loading servers...');
          }

          if (state.error != null && state.items.isEmpty) {
            return ErrorView(
              message: state.error!,
              onRetry: () => ref.read(proxyListControllerProvider.notifier).refresh(),
            );
          }

          return Column(
            children: [
              if (connectedProxy != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text(connectedProxy.flag)),
                      title: Text('Connected: ${connectedProxy.country}'),
                      subtitle: const Text('Your secure server is active.'),
                      trailing: const Icon(Icons.verified, color: Colors.green),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search country',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => ref.read(proxyFilterControllerProvider.notifier).setSearch(value),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Choose a country, then tap Connect.'),
                ),
              ),
              if (entitlement?.hasPremium != true)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.workspace_premium_outlined),
                      title: const Text('Unlock all countries and no ads'),
                      subtitle: const Text('Upgrade to Premium for full server access.'),
                      trailing: TextButton(
                        onPressed: () => context.push(AppRoutes.premium),
                        child: const Text('Upgrade'),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: countryServers.isEmpty
                    ? const EmptyView(
                        title: 'No servers found',
                        subtitle: 'Try changing your search text.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemBuilder: (context, index) {
                          final item = countryServers[index];
                          final isSelected = connection.selectedProxyId == item.id;
                          final isConnected = connection.connectedProxyId == item.id;

                          return Card(
                            child: ListTile(
                              onTap: () => ref.read(vpnConnectionControllerProvider.notifier).setSelectedProxy(item.id),
                              leading: CircleAvatar(child: Text(item.flag)),
                              title: Text(item.country),
                              subtitle: Text(
                                isConnected
                                    ? 'Connected'
                                    : item.isPremium && !hasPremium
                                        ? 'Premium server'
                                        : 'Tap to select',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (item.isPremium)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: Icon(Icons.lock_outline, size: 18),
                                    ),
                                  Icon(
                                    isConnected
                                        ? Icons.verified
                                        : isSelected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
                                    color: isConnected ? Colors.green : null,
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
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
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
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Center(child: AdBannerWidget(show: showAds)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: NativeAdPlaceholder(show: showAds),
              ),
            ],
          );
        },
      ),
    );
  }
}
