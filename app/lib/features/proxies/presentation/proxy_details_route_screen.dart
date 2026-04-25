import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/proxy_node.dart';
import '../../../core/widgets/error_view.dart';
import '../state/proxy_list_controller.dart';
import 'proxy_details_screen.dart';

class ProxyDetailsRouteScreen extends ConsumerWidget {
  final String proxyId;
  final ProxyNode? initialProxy;

  const ProxyDetailsRouteScreen({
    super.key,
    required this.proxyId,
    this.initialProxy,
  });

  ProxyNode? _findById(List<ProxyNode> items) {
    for (final item in items) {
      if (item.id == proxyId) {
        return item;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (initialProxy != null) {
      return ProxyDetailsScreen(proxy: initialProxy!);
    }

    final listState = ref.watch(proxyListControllerProvider).valueOrNull;
    final proxy = _findById(listState?.items ?? const []);

    if (proxy == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Proxy Details')),
        body: ErrorView(
          message: 'Proxy not found in current list. Refresh proxy list and try again.',
          onRetry: () => ref.read(proxyListControllerProvider.notifier).refresh(),
        ),
      );
    }

    return ProxyDetailsScreen(proxy: proxy);
  }
}
