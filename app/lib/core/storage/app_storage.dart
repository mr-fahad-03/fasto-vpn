import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/proxy_node.dart';
import '../models/session_data.dart';

class AppStorage {
  static const _onboardingDoneKey = 'onboarding_done';
  static const _sessionKey = 'session_data';
  static const _connectedProxyIdKey = 'connected_proxy_id';
  static const _connectedProxyConfigKey = 'connected_proxy_config';

  Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingDoneKey) ?? false;
  }

  Future<void> setOnboardingDone(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingDoneKey, value);
  }

  Future<SessionData?> readSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return SessionData.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSession(SessionData session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<String?> readConnectedProxyId() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_connectedProxyIdKey);
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }

  Future<void> saveConnectedProxyId(String proxyId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_connectedProxyIdKey, proxyId);
  }

  Future<ProxyConnect?> readConnectedProxyConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_connectedProxyConfigKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return ProxyConnect.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveConnectedProxyConfig(ProxyConnect connect) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_connectedProxyConfigKey, jsonEncode(connect.toJson()));
  }

  Future<void> clearConnectedProxyId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_connectedProxyIdKey);
  }

  Future<void> clearConnectedProxyState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_connectedProxyIdKey);
    await prefs.remove(_connectedProxyConfigKey);
  }
}
