import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/proxy_node.dart';
import '../../../core/networking/dio_client.dart';
import '../../../core/services/service_providers.dart';
import '../../auth/state/auth_controller.dart';
import 'proxy_list_controller.dart';

class VpnConnectionState {
  final String? selectedProxyId;
  final String? connectedProxyId;
  final DateTime? connectedAt;
  final bool connecting;
  final String? error;

  const VpnConnectionState({
    this.selectedProxyId,
    this.connectedProxyId,
    this.connectedAt,
    this.connecting = false,
    this.error,
  });

  bool get isConnected => connectedProxyId != null && connectedProxyId!.isNotEmpty;

  VpnConnectionState copyWith({
    String? selectedProxyId,
    bool clearSelectedProxyId = false,
    String? connectedProxyId,
    bool clearConnectedProxyId = false,
    DateTime? connectedAt,
    bool clearConnectedAt = false,
    bool? connecting,
    String? error,
    bool clearError = false,
  }) {
    return VpnConnectionState(
      selectedProxyId: clearSelectedProxyId ? null : (selectedProxyId ?? this.selectedProxyId),
      connectedProxyId: clearConnectedProxyId ? null : (connectedProxyId ?? this.connectedProxyId),
      connectedAt: clearConnectedAt ? null : (connectedAt ?? this.connectedAt),
      connecting: connecting ?? this.connecting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class VpnConnectionController extends AsyncNotifier<VpnConnectionState> {
  @override
  Future<VpnConnectionState> build() async {
    final storage = ref.read(appStorageProvider);
    final connectedProxyId = await storage.readConnectedProxyId();
    final connectedProxyConfig = await storage.readConnectedProxyConfig();

    if (connectedProxyConfig != null) {
      ref.read(appTrafficProxyManagerProvider).activate(connectedProxyConfig);
    }

    return VpnConnectionState(
      selectedProxyId: connectedProxyId,
      connectedProxyId: connectedProxyId,
      connectedAt: connectedProxyId == null ? null : DateTime.now(),
    );
  }

  void setSelectedProxy(String proxyId) {
    final current = state.valueOrNull ?? const VpnConnectionState();
    state = AsyncData(current.copyWith(selectedProxyId: proxyId, clearError: true));
  }

  Future<bool> connect(ProxyNode proxy, {required bool hasPremium}) async {
    final current = state.valueOrNull ?? const VpnConnectionState();

    if (proxy.isPremium && !hasPremium) {
      state = AsyncData(current.copyWith(
        connecting: false,
        error: 'This is a premium server. Upgrade your plan to connect.',
      ));
      return false;
    }

    state = AsyncData(current.copyWith(connecting: true, clearError: true));

    try {
      final session = ref.read(authControllerProvider).valueOrNull?.session;
      final result = await ref.read(proxyRepositoryProvider).connectToProxy(
            session,
            proxyId: proxy.id,
          );

      final guestSessionId = result.guestSessionId;
      if (guestSessionId != null && guestSessionId.isNotEmpty) {
        await ref.read(authControllerProvider.notifier).setGuestSessionId(guestSessionId);
      }

      ref.read(appTrafficProxyManagerProvider).activate(result.data.connect);
      await ref.read(appStorageProvider).saveConnectedProxyId(proxy.id);
      await ref.read(appStorageProvider).saveConnectedProxyConfig(result.data.connect);

      final connectedAt = DateTime.tryParse(result.data.connectedAt) ?? DateTime.now();
      state = AsyncData(current.copyWith(
        connecting: false,
        selectedProxyId: proxy.id,
        connectedProxyId: proxy.id,
        connectedAt: connectedAt,
        clearError: true,
      ));
      return true;
    } catch (error) {
      state = AsyncData(current.copyWith(
        connecting: false,
        error: error.toString(),
      ));
      return false;
    }
  }

  Future<void> disconnect() async {
    final current = state.valueOrNull ?? const VpnConnectionState();
    ref.read(appTrafficProxyManagerProvider).clear();
    await ref.read(appStorageProvider).clearConnectedProxyState();
    state = AsyncData(current.copyWith(
      connecting: false,
      clearConnectedProxyId: true,
      clearConnectedAt: true,
      clearError: true,
    ));
  }

  Future<void> syncWithAvailableProxies(List<ProxyNode> items) async {
    final current = state.valueOrNull ?? const VpnConnectionState();
    final proxyManager = ref.read(appTrafficProxyManagerProvider);
    final storage = ref.read(appStorageProvider);

    if (items.isEmpty) {
      if (current.connectedProxyId != null) {
        final persisted = await storage.readConnectedProxyConfig();
        if (persisted != null) {
          proxyManager.activate(persisted);
        }
      }
      return;
    }

    final hasConnected = current.connectedProxyId != null &&
        items.any((proxy) => proxy.id == current.connectedProxyId);
    final hasSelected = current.selectedProxyId != null &&
        items.any((proxy) => proxy.id == current.selectedProxyId);

    var next = current;

    if (hasConnected && current.connectedProxyId != null) {
      ProxyNode? connectedProxy;
      for (final item in items) {
        if (item.id == current.connectedProxyId) {
          connectedProxy = item;
          break;
        }
      }
      if (connectedProxy != null) {
        proxyManager.activate(connectedProxy.connect);
        await storage.saveConnectedProxyConfig(connectedProxy.connect);
      }
    } else if (current.connectedProxyId != null) {
      final persisted = await storage.readConnectedProxyConfig();
      if (persisted != null) {
        proxyManager.activate(persisted);
      }
    } else if (next.connectedProxyId == null) {
      proxyManager.clear();
    }

    if (!hasSelected) {
      next = next.copyWith(selectedProxyId: next.connectedProxyId ?? items.first.id);
    }

    if (next != current) {
      state = AsyncData(next);
    }
  }
}

final vpnConnectionControllerProvider =
    AsyncNotifierProvider<VpnConnectionController, VpnConnectionState>(VpnConnectionController.new);
