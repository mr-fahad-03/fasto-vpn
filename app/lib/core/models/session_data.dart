enum AuthMode { guest, google }

class SessionData {
  final AuthMode mode;
  final String? guestSessionId;
  final String? firebaseIdToken;
  final String? firebaseUid;
  final String? email;
  final String? displayName;
  final String? userId;
  final String? rcAppUserId;
  final String? deviceSessionId;

  const SessionData({
    required this.mode,
    this.guestSessionId,
    this.firebaseIdToken,
    this.firebaseUid,
    this.email,
    this.displayName,
    this.userId,
    this.rcAppUserId,
    this.deviceSessionId,
  });

  bool get isGuest => mode == AuthMode.guest;
  bool get isGoogle => mode == AuthMode.google;

  bool get isValid {
    if (isGuest) {
      return (guestSessionId ?? '').isNotEmpty;
    }

    return (firebaseIdToken ?? '').isNotEmpty;
  }

  Map<String, String> toHeaders() {
    final headers = <String, String>{'x-platform': 'flutter-mobile'};

    if (isGoogle && firebaseIdToken != null && firebaseIdToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $firebaseIdToken';
    }

    if (isGuest && guestSessionId != null && guestSessionId!.isNotEmpty) {
      headers['x-guest-session-id'] = guestSessionId!;
    }

    return headers;
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'guestSessionId': guestSessionId,
      'firebaseIdToken': firebaseIdToken,
      'firebaseUid': firebaseUid,
      'email': email,
      'displayName': displayName,
      'userId': userId,
      'rcAppUserId': rcAppUserId,
      'deviceSessionId': deviceSessionId,
    };
  }

  factory SessionData.fromJson(Map<String, dynamic> json) {
    return SessionData(
      mode: json['mode'] == 'google' ? AuthMode.google : AuthMode.guest,
      guestSessionId: json['guestSessionId'] as String?,
      firebaseIdToken: json['firebaseIdToken'] as String?,
      firebaseUid: json['firebaseUid'] as String?,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      userId: json['userId'] as String?,
      rcAppUserId: json['rcAppUserId'] as String?,
      deviceSessionId: json['deviceSessionId'] as String?,
    );
  }

  SessionData copyWith({
    AuthMode? mode,
    String? guestSessionId,
    String? firebaseIdToken,
    String? firebaseUid,
    String? email,
    String? displayName,
    String? userId,
    String? rcAppUserId,
    String? deviceSessionId,
  }) {
    return SessionData(
      mode: mode ?? this.mode,
      guestSessionId: guestSessionId ?? this.guestSessionId,
      firebaseIdToken: firebaseIdToken ?? this.firebaseIdToken,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      userId: userId ?? this.userId,
      rcAppUserId: rcAppUserId ?? this.rcAppUserId,
      deviceSessionId: deviceSessionId ?? this.deviceSessionId,
    );
  }
}
