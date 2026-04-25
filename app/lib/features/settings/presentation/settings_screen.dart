import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: _showConnectionTips,
                  onChanged: (value) => setState(() => _showConnectionTips = value),
                  title: const Text('Show connection tips'),
                  subtitle: const Text('Display quick guidance on server selection screens.'),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _enableAutoRefresh,
                  onChanged: (value) => setState(() => _enableAutoRefresh = value),
                  title: const Text('Enable auto refresh'),
                  subtitle: const Text('Allow app to refresh entitlement and proxy list.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('App version'),
              subtitle: Text(_versionText),
              leading: const Icon(Icons.info_outline),
            ),
          ),
        ],
      ),
    );
  }
}
