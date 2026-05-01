import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/proxy_node.dart';
import '../../../core/widgets/premium_surface.dart';
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
        appBar: AppBar(
          title: const Text('Proxy Details'),
          backgroundColor: const Color(0xFF3555D9),
          foregroundColor: Colors.white,
        ),
        body: PremiumPageBackground(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: PremiumGlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFFFCDD2), size: 42),
                    const SizedBox(height: 10),
                    const Text(
                      'Proxy not found in current list. Refresh proxy list and try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.read(proxyListControllerProvider.notifier).refresh(),
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ProxyDetailsScreen(proxy: proxy);
  }
}
