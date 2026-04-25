import '../../../core/models/proxy_node.dart';
import '../../../core/models/session_data.dart';
import '../../../core/networking/backend_api.dart';

class ProxyRepository {
  final BackendApi backendApi;

  ProxyRepository({required this.backendApi});

  Future<ApiEnvelope<ProxyListPayload>> fetchProxies(SessionData? session) {
    return backendApi.getProxies(session);
  }

  Future<ApiEnvelope<MobileProxyConnectResponse>> connectToProxy(
    SessionData? session, {
    required String proxyId,
  }) {
    return backendApi.connectProxy(session, proxyId: proxyId);
  }
}
