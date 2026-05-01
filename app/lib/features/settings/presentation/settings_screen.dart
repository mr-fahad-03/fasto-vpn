import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/widgets/premium_surface.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showConnectionTips = true;
  bool _enableAutoRefresh = true;
  String _versionText = '-';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) {
      return;
    }

    setState(() {
      _versionText = '${info.version}+${info.buildNumber}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF3555D9),
        foregroundColor: Colors.white,
      ),
      body: PremiumPageBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PremiumGlassCard(
              child: Column(
                children: [
                  SwitchListTile(
                    value: _showConnectionTips,
                    activeColor: const Color(0xFF86EFAC),
                    onChanged: (value) => setState(() => _showConnectionTips = value),
                    title: const Text(
                      'Show connection tips',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Display quick guidance on server selection screens.',
                      style: TextStyle(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  Divider(height: 1, color: Colors.white.withValues(alpha: 0.2)),
                  SwitchListTile(
                    value: _enableAutoRefresh,
                    activeColor: const Color(0xFF86EFAC),
                    onChanged: (value) => setState(() => _enableAutoRefresh = value),
                    title: const Text(
                      'Enable auto refresh',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Allow app to refresh entitlement and proxy list.',
                      style: TextStyle(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PremiumGlassCard(
              child: ListTile(
                title: const Text(
                  'App version',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  _versionText,
                  style: const TextStyle(color: Color(0xFFE2E8F0)),
                ),
                leading: const Icon(Icons.info_outline, color: Colors.white),
              ),
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}
