class Entitlement {
  final String plan;
  final bool hasPremium;
  final bool adsEnabled;
  final String status;
  final String? userId;
  final String? rcAppUserId;
  final DateTime? expiresAt;

  const Entitlement({
    required this.plan,
    required this.hasPremium,
    required this.adsEnabled,
    required this.status,
    this.userId,
    this.rcAppUserId,
    this.expiresAt,
  });

  bool get isPremium => hasPremium;

  factory Entitlement.fromJson(Map<String, dynamic> json) {
    final expires = json['expiresAt'];

    return Entitlement(
      plan: (json['plan'] as String?) ?? 'free',
      hasPremium: (json['hasPremium'] as bool?) ?? false,
      adsEnabled: (json['adsEnabled'] as bool?) ?? true,
      status: (json['status'] as String?) ?? ((json['hasPremium'] as bool?) == true ? 'premium' : 'free'),
      userId: json['userId'] as String?,
      rcAppUserId: json['rcAppUserId'] as String?,
      expiresAt: expires is String && expires.isNotEmpty ? DateTime.tryParse(expires) : null,
    );
  }

  Entitlement copyWith({
    String? plan,
    bool? hasPremium,
    bool? adsEnabled,
    String? status,
    String? userId,
    String? rcAppUserId,
    DateTime? expiresAt,
  }) {
    return Entitlement(
      plan: plan ?? this.plan,
      hasPremium: hasPremium ?? this.hasPremium,
      adsEnabled: adsEnabled ?? this.adsEnabled,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      rcAppUserId: rcAppUserId ?? this.rcAppUserId,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  static const free = Entitlement(
    plan: 'free',
    hasPremium: false,
    adsEnabled: true,
    status: 'free',
  );
}

class PlanMetadata {
  final bool adsEnabled;
  final int proxyLimit;
  final double? priceUsd;
  final String? currency;

  const PlanMetadata({
    required this.adsEnabled,
    required this.proxyLimit,
    this.priceUsd,
    this.currency,
  });

  factory PlanMetadata.fromJson(Map<String, dynamic> json) {
    return PlanMetadata(
      adsEnabled: (json['adsEnabled'] as bool?) ?? true,
      proxyLimit: (json['proxyLimit'] as num?)?.toInt() ?? 0,
      priceUsd: (json['priceUsd'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
    );
  }
}
