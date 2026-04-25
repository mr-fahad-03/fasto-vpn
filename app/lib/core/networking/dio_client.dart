import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/env.dart';
import '../models/proxy_node.dart';

class AppTrafficProxyManager {
  Dio? _dio;
  ProxyConnect? _active;
  bool _interceptorAttached = false;

  ProxyConnect? get active => _active;

  void attach(Dio dio) {
    _dio = dio;
    _attachProxyAuthInterceptor();
    _reconfigureAdapter();
  }

  void activate(ProxyConnect connect) {
    _active = connect;
    _reconfigureAdapter();
  }

  void clear() {
    _active = null;
    _reconfigureAdapter();
  }

  void _attachProxyAuthInterceptor() {
    if (_interceptorAttached || _dio == null) {
      return;
    }

    _interceptorAttached = true;
    _dio!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final authHeader = _buildProxyAuthHeader();
          if (authHeader == null) {
            options.headers.remove('Proxy-Authorization');
          } else {
            options.headers['Proxy-Authorization'] = authHeader;
          }

          handler.next(options);
        },
      ),
    );
  }

  void _reconfigureAdapter() {
    final dio = _dio;
    if (dio == null) {
      return;
    }

    final adapter = dio.httpClientAdapter;
    if (adapter is! IOHttpClientAdapter) {
      return;
    }

    final activeProxy = _active;
    adapter.createHttpClient = () {
      final client = HttpClient();

      if (activeProxy == null) {
        client.findProxy = (_) => 'DIRECT';
        return client;
      }

      final directive = activeProxy.type.toUpperCase() == 'SOCKS5'
          ? 'SOCKS ${activeProxy.host}:${activeProxy.port}; DIRECT'
          : 'PROXY ${activeProxy.host}:${activeProxy.port}; DIRECT';

      client.findProxy = (_) => directive;
      return client;
    };
  }

  String? _buildProxyAuthHeader() {
    final activeProxy = _active;
    if (activeProxy == null) {
      return null;
    }

    final username = activeProxy.username?.trim();
    final password = activeProxy.password?.trim();

    if (username == null ||
        username.isEmpty ||
        password == null ||
        password.isEmpty ||
        activeProxy.type.toUpperCase() != 'HTTP') {
      return null;
    }

    final encoded = base64Encode(utf8.encode('$username:$password'));
    return 'Basic $encoded';
  }
}

final appTrafficProxyManagerProvider = Provider<AppTrafficProxyManager>((ref) {
  return AppTrafficProxyManager();
});

final dioProvider = Provider<Dio>((ref) {
  final proxyManager = ref.watch(appTrafficProxyManagerProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: const {
        'Content-Type': 'application/json',
      },
    ),
  );

  proxyManager.attach(dio);
  return dio;
});
