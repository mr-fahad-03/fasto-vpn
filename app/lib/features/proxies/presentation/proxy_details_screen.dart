import 'package:flutter/material.dart';
import '../../../core/models/proxy_node.dart';

class ProxyDetailsScreen extends StatelessWidget {
  final ProxyNode proxy;

  const ProxyDetailsScreen({super.key, required this.proxy});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Info'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 22,
                      child: Text(proxy.flag, style: const TextStyle(fontSize: 20)),
                    ),
                    title: Text(proxy.country, style: Theme.of(context).textTheme.titleLarge),
                    subtitle: Text(proxy.isPremium ? 'Premium server' : 'Free server'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(
                        label: Text(proxy.isPremium ? 'Premium' : 'Free'),
                        avatar: Icon(
                          proxy.isPremium ? Icons.workspace_premium : Icons.check_circle,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(label: Text('Code: ${proxy.countryCode}')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pick your country from the server list and tap Connect to secure your connection.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
