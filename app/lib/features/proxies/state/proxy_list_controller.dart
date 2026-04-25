import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/proxy_node.dart';
import '../../../core/models/session_data.dart';
import '../../../core/networking/backend_api.dart';
import '../../auth/state/auth_controller.dart';
import '../data/proxy_repository.dart';
import 'proxy_filter_state.dart';

class ProxyListState {
  final bool loading;
  final bool refreshing;
  final ProxyListPayload? payload;
  final String? error;

  const ProxyListState({
    required this.loading,
    required this.refreshing,
    this.payload,
    this.error,
  });

  List<ProxyNode> get items => payload?.items ?? const [];

  ProxyListState copyWith({
    bool? loading,
    bool? refreshing,
    ProxyListPayload? payload,
    bool clearPayload = false,
    String? error,
    bool clearError = false,
  }) {
    return ProxyListState(
      loading: loading ?? this.loading,
      refreshing: refreshing ?? this.refreshing,
      payload: clearPayload ? null : (payload ?? this.payload),
      error: clearError ? null : (error ?? this.error),
    );
  }

  factory ProxyListState.initial() {
    return const ProxyListState(
      loading: true,
      refreshing: false,
      payload: null,
      error: null,
    );
  }
}

final proxyRepositoryProvider = Provider<ProxyRepository>((ref) {
  return ProxyRepository(backendApi: ref.watch(backendApiProvider));
});

class ProxyFilterController extends Notifier<ProxyFilterState> {
  @override
  ProxyFilterState build() => ProxyFilterState.initial();

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setPremiumFilter(ProxyPremiumFilter filter) {
    state = state.copyWith(premiumFilter: filter);
  }

  void setCountryCode(String? countryCode) {
    if (countryCode == null || countryCode.isEmpty) {
      state = state.copyWith(clearCountryCode: true);
      return;
    }
    state = state.copyWith(countryCode: countryCode.toUpperCase());
  }

  void reset() {
    state = ProxyFilterState.initial();
  }
}

final proxyFilterControllerProvider =
    NotifierProvider<ProxyFilterController, ProxyFilterState>(ProxyFilterController.new);

class ProxyListController extends AsyncNotifier<ProxyListState> {
  @override
  Future<ProxyListState> build() async {
    final authState = ref.watch(authControllerProvider).valueOrNull;
    final session = authState?.session;
    return _fetch(session);
  }

  Future<ProxyListState> _fetch(SessionData? session) async {
    try {
      final result = await ref.read(proxyRepositoryProvider).fetchProxies(session);

      final guestSessionId = result.guestSessionId;
      if (guestSessionId != null && guestSessionId.isNotEmpty) {
        await ref.read(authControllerProvider.notifier).setGuestSessionId(guestSessionId);
      }

      return ProxyListState.initial().copyWith(
        loading: false,
        payload: result.data,
        clearError: true,
      );
    } catch (error) {
      return ProxyListState.initial().copyWith(
        loading: false,
        error: error.toString(),
      );
    }
  }

  Future<void> refresh() async {
    final current = state.valueOrNull ?? ProxyListState.initial();
    state = AsyncData(current.copyWith(refreshing: true, clearError: true));

    final authState = ref.read(authControllerProvider).valueOrNull;

    try {
      final result = await ref.read(proxyRepositoryProvider).fetchProxies(authState?.session);

      final guestSessionId = result.guestSessionId;
      if (guestSessionId != null && guestSessionId.isNotEmpty) {
        await ref.read(authControllerProvider.notifier).setGuestSessionId(guestSessionId);
      }

      state = AsyncData(current.copyWith(
        refreshing: false,
        payload: result.data,
        clearError: true,
      ));
    } catch (error) {
      state = AsyncData(current.copyWith(
        refreshing: false,
        error: error.toString(),
      ));
    }
  }
}

final proxyListControllerProvider =
    AsyncNotifierProvider<ProxyListController, ProxyListState>(ProxyListController.new);

final filteredProxiesProvider = Provider<List<ProxyNode>>((ref) {
  final proxyState = ref.watch(proxyListControllerProvider).valueOrNull;
  final filter = ref.watch(proxyFilterControllerProvider);

  final items = proxyState?.items ?? const <ProxyNode>[];
  final query = filter.searchQuery.trim().toLowerCase();

  return items.where((proxy) {
    if (filter.premiumFilter == ProxyPremiumFilter.freeOnly && proxy.isPremium) {
      return false;
    }

    if (filter.premiumFilter == ProxyPremiumFilter.premiumOnly && !proxy.isPremium) {
      return false;
    }

    if (filter.countryCode != null && filter.countryCode != proxy.countryCode.toUpperCase()) {
      return false;
    }

    if (query.isEmpty) {
      return true;
    }

    final haystack = '${proxy.country} ${proxy.countryCode}'.toLowerCase();
    return haystack.contains(query);
  }).toList();
});

final availableCountryCodesProvider = Provider<List<String>>((ref) {
  final proxyState = ref.watch(proxyListControllerProvider).valueOrNull;
  final items = proxyState?.items ?? const <ProxyNode>[];

  final codes = items.map((e) => e.countryCode.toUpperCase()).toSet().toList()..sort();
  return codes;
});
