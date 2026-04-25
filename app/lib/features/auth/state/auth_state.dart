import '../../../core/models/session_data.dart';

class AuthState {
  final bool initializing;
  final bool busy;
  final SessionData? session;
  final String? error;

  const AuthState({
    required this.initializing,
    required this.busy,
    required this.session,
    this.error,
  });

  bool get isAuthenticated => session != null;

  factory AuthState.initial() {
    return const AuthState(initializing: true, busy: false, session: null);
  }

  AuthState copyWith({
    bool? initializing,
    bool? busy,
    SessionData? session,
    bool clearSession = false,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      initializing: initializing ?? this.initializing,
      busy: busy ?? this.busy,
      session: clearSession ? null : (session ?? this.session),
      error: clearError ? null : (error ?? this.error),
    );
  }
}
