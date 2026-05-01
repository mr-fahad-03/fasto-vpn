import 'package:flutter/material.dart';
import '../../../core/models/proxy_node.dart';
import '../../../core/widgets/premium_surface.dart';

class ProxyDetailsScreen extends StatelessWidget {
  final ProxyNode proxy;

  const ProxyDetailsScreen({super.key, required this.proxy});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Info'),
        backgroundColor: const Color(0xFF3555D9),
        foregroundColor: Colors.white,
      ),
      body: PremiumPageBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PremiumGlassCard(
              borderRadius: BorderRadius.circular(26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(proxy.flag, style: const TextStyle(fontSize: 20)),
                    ),
                    title: Text(
                      proxy.country,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    subtitle: Text(
                      proxy.isPremium ? 'Premium server' : 'Free server',
                      style: const TextStyle(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
                        label: Text(
                          proxy.isPremium ? 'Premium' : 'Free',
                          style: const TextStyle(color: Colors.white),
                        ),
                        avatar: Icon(
                          proxy.isPremium ? Icons.workspace_premium : Icons.check_circle,
                          size: 16,
                          color: proxy.isPremium ? Colors.amberAccent : const Color(0xFF86EFAC),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
                        label: Text(
                          'Code: ${proxy.countryCode}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pick your country from the server list and tap Connect to secure your connection.',
                    style: TextStyle(color: Color(0xFFE2E8F0)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}
