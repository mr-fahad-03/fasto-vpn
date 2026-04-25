import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entitlement.dart';
import '../models/proxy_node.dart';
import '../models/session_data.dart';
import 'dio_client.dart';

class ApiEnvelope<T> {
  final T data;
  final String? guestSessionId;

  const ApiEnvelope({required this.data, this.guestSessionId});
}

class MobileGuestSessionResponse {
  final String guestSessionId;
  final String userId;
  final String rcAppUserId;
  final String mode;
  final Entitlement entitlement;

  const MobileGuestSessionResponse({
    required this.guestSessionId,
    required this.userId,
    required this.rcAppUserId,
    required this.mode,
    required this.entitlement,
  });

  factory MobileGuestSessionResponse.fromJson(Map<String, dynamic> json) {
    return MobileGuestSessionResponse(
      guestSessionId: (json['guestSessionId'] as String?) ?? '',
      userId: (json['userId'] as String?) ?? '',
      rcAppUserId: (json['rcAppUserId'] as String?) ?? '',
      mode: (json['mode'] as String?) ?? 'guest',
      entitlement: Entitlement.fromJson((json['entitlement'] as Map<String, dynamic>?) ?? {}),
    );
  }
}

class MobileFirebaseAuthResponse {
  final String userId;
  final String rcAppUserId;
  final String mode;
  final String? deviceSessionId;
  final String? mergedGuestUserId;
  final Entitlement entitlement;

  const MobileFirebaseAuthResponse({
    required this.userId,
    required this.rcAppUserId,
    required this.mode,
    this.deviceSessionId,
    this.mergedGuestUserId,
    required this.entitlement,
  });

  factory MobileFirebaseAuthResponse.fromJson(Map<String, dynamic> json) {
    return MobileFirebaseAuthResponse(
      userId: (json['userId'] as String?) ?? '',
      rcAppUserId: (json['rcAppUserId'] as String?) ?? '',
      mode: (json['mode'] as String?) ?? 'mobile',
      deviceSessionId: json['deviceSessionId'] as String?,
      mergedGuestUserId: json['mergedGuestUserId'] as String?,
      entitlement: Entitlement.fromJson((json['entitlement'] as Map<String, dynamic>?) ?? {}),
    );
  }
}

class MobileProxyConnectResponse {
  final bool connected;
  final String proxyId;
  final String country;
  final String countryCode;
  final ProxyConnect connect;
  final String connectedAt;

  const MobileProxyConnectResponse({
    required this.connected,
    required this.proxyId,
    required this.country,
    required this.countryCode,
    required this.connect,
    required this.connectedAt,
  });

  factory MobileProxyConnectResponse.fromJson(Map<String, dynamic> json) {
    return MobileProxyConnectResponse(
      connected: (json['connected'] as bool?) ?? false,
      proxyId: (json['proxyId'] as String?) ?? '',
      country: (json['country'] as String?) ?? 'Unknown',
      countryCode: (json['countryCode'] as String?) ?? 'XX',
      connect: ProxyConnect.fromJson((json['connect'] as Map<String, dynamic>?) ?? {}),
      connectedAt: (json['connectedAt'] as String?) ?? '',
    );
  }
}

class BackendApi {
  final Dio _dio;

  BackendApi(this._dio);

  Map<String, String> _headers(SessionData? session) {
    if (session == null) {
      return {
        'x-platform': 'flutter-mobile',
      };
    }

    return session.toHeaders();
  }

  Future<ApiEnvelope<Map<String, dynamic>>> _request(
    String path, {
    required String method,
    SessionData? session,
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    try {
      final mergedHeaders = <String, String>{
        ..._headers(session),
        ...?headers,
      };

      final response = await _dio.request<Map<String, dynamic>>(
        path,
        data: data,
        options: Options(
          method: method,
          headers: mergedHeaders,
        ),
      );

      final body = response.data ?? <String, dynamic>{};
      if (body['success'] == false) {
        throw Exception((body['message'] as String?) ?? 'Request failed');
      }

      return ApiEnvelope(
        data: (body['data'] as Map<String, dynamic>?) ?? <String, dynamic>{},
        guestSessionId: response.headers.value('x-guest-session-id'),
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;
      String? message;
      if (responseData is Map<String, dynamic>) {
        message = responseData['message'] as String?;
      }

      throw Exception(message ?? e.message ?? 'Network request failed');
    }
  }

  Future<MobileGuestSessionResponse> createGuestSession() async {
    final result = await _request(
      '/mobile/sessions/guest',
      method: 'POST',
      data: const {},
    );

    return MobileGuestSessionResponse.fromJson(result.data);
  }

  Future<MobileFirebaseAuthResponse> authenticateFirebase({
    required String firebaseIdToken,
    String? guestSessionId,
  }) async {
    final headers = <String, String>{
      'Authorization': 'Bearer $firebaseIdToken',
      if (guestSessionId != null && guestSessionId.isNotEmpty)
        'x-guest-session-id': guestSessionId,
    };

    final result = await _request(
      '/mobile/auth/firebase',
      method: 'POST',
      data: const {},
      headers: headers,
    );

    return MobileFirebaseAuthResponse.fromJson(result.data);
  }

  Future<ApiEnvelope<Entitlement>> getEntitlement(SessionData? session) async {
    final result = await _request(
      '/mobile/entitlement',
      method: 'GET',
      session: session,
    );
    return ApiEnvelope(
      data: Entitlement.fromJson(result.data),
      guestSessionId: result.guestSessionId,
    );
  }

  Future<ApiEnvelope<ProxyListPayload>> getProxies(SessionData? session) async {
    final result = await _request(
      '/mobile/proxies',
      method: 'GET',
      session: session,
    );

    return ApiEnvelope(
      data: ProxyListPayload.fromJson(result.data),
      guestSessionId: result.guestSessionId,
    );
  }

  Future<ApiEnvelope<MobileProxyConnectResponse>> connectProxy(
    SessionData? session, {
    required String proxyId,
  }) async {
    final result = await _request(
      '/mobile/proxies/connect',
      method: 'POST',
      session: session,
      data: {
        'proxyId': proxyId,
      },
    );

    return ApiEnvelope(
      data: MobileProxyConnectResponse.fromJson(result.data),
      guestSessionId: result.guestSessionId,
    );
  }
}

final backendApiProvider = Provider<BackendApi>((ref) {
  final dio = ref.watch(dioProvider);
  return BackendApi(dio);
});
