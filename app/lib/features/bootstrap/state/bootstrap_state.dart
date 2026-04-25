class BootstrapState {
  final bool initialized;
  final bool onboardingDone;

  const BootstrapState({
    required this.initialized,
    required this.onboardingDone,
  });

  factory BootstrapState.initial() {
    return const BootstrapState(initialized: false, onboardingDone: false);
  }

  BootstrapState copyWith({
    bool? initialized,
    bool? onboardingDone,
  }) {
    return BootstrapState(
      initialized: initialized ?? this.initialized,
      onboardingDone: onboardingDone ?? this.onboardingDone,
    );
  }
}
