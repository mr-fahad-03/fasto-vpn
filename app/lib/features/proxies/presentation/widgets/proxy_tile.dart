import 'package:flutter/material.dart';
import '../../../../core/models/proxy_node.dart';

class ProxyTile extends StatelessWidget {
  final ProxyNode proxy;
  final VoidCallback onTap;

  const ProxyTile({
    super.key,
    required this.proxy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          child: Text(proxy.flag),
        ),
        title: Text(proxy.country),
        subtitle: const Text('Secure VPN server'),
        trailing: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(
              label: Text(proxy.isPremium ? 'Premium' : 'Free'),
              avatar: Icon(
                proxy.isPremium ? Icons.workspace_premium : Icons.check_circle,
                size: 16,
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
