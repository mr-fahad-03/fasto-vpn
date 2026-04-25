import 'entitlement.dart';

String flagEmoji(String countryCode) {
  if (countryCode.length != 2) {
    return '🌐';
  }

  final upper = countryCode.toUpperCase();
  final first = upper.codeUnitAt(0) + 127397;
  final second = upper.codeUnitAt(1) + 127397;
  return String.fromCharCodes([first, second]);
}

class ProxyConnect {
  final String host;
  final int port;
  final String type;
  final String? username;
  final String? password;

  const ProxyConnect({
    required this.host,
    required this.port,
    required this.type,
    this.username,
    this.password,
  });

  factory ProxyConnect.fromJson(Map<String, dynamic> json) {
    final username = (json['username'] as String?)?.trim();
    final password = (json['password'] as String?)?.trim();

    return ProxyConnect(
      host: (json['host'] as String?) ?? '',
      port: (json['port'] as num?)?.toInt() ?? 0,
      type: (json['type'] as String?) ?? 'HTTP',
      username: (username == null || username.isEmpty) ? null : username,
      password: (password == null || password.isEmpty) ? null : password,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'host': host,
      'port': port,
      'type': type,
      if (username != null) 'username': username,
      if (password != null) 'password': password,
    };
  }
}

class ProxyNode {
  final String id;
  final String country;
  final String countryCode;
  final bool isPremium;
  final ProxyConnect connect;

  const ProxyNode({
    required this.id,
    required this.country,
    required this.countryCode,
    required this.isPremium,
    required this.connect,
  });

  String get flag => flagEmoji(countryCode);

  String get title => '$country ${isPremium ? 'Premium' : 'Free'}';

  factory ProxyNode.fromJson(Map<String, dynamic> json) {
    return ProxyNode(
      id: (json['id'] as String?) ?? '',
      country: (json['country'] as String?) ?? 'Unknown',
      countryCode: (json['countryCode'] as String?) ?? 'XX',
      isPremium: (json['isPremium'] as bool?) ?? false,
      connect: ProxyConnect.fromJson((json['connect'] as Map<String, dynamic>?) ?? {}),
    );
  }
}

class ProxyListPayload {
  final String plan;
  final bool hasPremium;
  final bool adsEnabled;
  final List<ProxyNode> items;
  final PlanMetadata? freePlan;
  final PlanMetadata? premiumPlan;

  const ProxyListPayload({
    required this.plan,
    required this.hasPremium,
    required this.adsEnabled,
    required this.items,
    this.freePlan,
    this.premiumPlan,
  });

  factory ProxyListPayload.fromJson(Map<String, dynamic> json) {
    final planMetadata = (json['planMetadata'] as Map<String, dynamic>?) ?? {};

    return ProxyListPayload(
      plan: (json['plan'] as String?) ?? 'free',
      hasPremium: (json['hasPremium'] as bool?) ?? false,
      adsEnabled: (json['adsEnabled'] as bool?) ?? true,
      items: ((json['items'] as List<dynamic>?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ProxyNode.fromJson)
          .toList(),
      freePlan: planMetadata['free'] is Map<String, dynamic>
          ? PlanMetadata.fromJson(planMetadata['free'] as Map<String, dynamic>)
          : null,
      premiumPlan: planMetadata['premium'] is Map<String, dynamic>
          ? PlanMetadata.fromJson(planMetadata['premium'] as Map<String, dynamic>)
          : null,
    );
  }
}
