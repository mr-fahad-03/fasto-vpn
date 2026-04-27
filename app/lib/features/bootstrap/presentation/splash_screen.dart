import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/widgets/error_view.dart';
import '../state/bootstrap_controller.dart';
import '../state/splash_animation_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _animationDuration = Duration(milliseconds: 1800);

  static const LinearGradient _splashGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFD137FF),
      Color(0xFF5D39FF),
      Color(0xFF12A9FF),
    ],
    stops: [0, 0.58, 1],
  );

  late final AnimationController _controller;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
      animationBehavior: AnimationBehavior.preserve,
    );

    _slideAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _logoAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutBack),
    );

    _runSplashSequence();
  }

  Future<void> _runSplashSequence() async {
    try {
      await _controller.forward().orCancel;
    } on TickerCanceled {
      return;
    }

    if (!mounted) {
      return;
    }

    var onboardingDone = false;
    try {
      onboardingDone = await ref.read(appStorageProvider).isOnboardingDone();
    } catch (_) {
      onboardingDone = false;
    }

    if (!mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(splashAnimationDoneProvider.notifier).state = true;
      if (!onboardingDone) {
        context.go(AppRoutes.onboarding);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bootstrap = ref.watch(bootstrapControllerProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: bootstrap.when(
        data: (_) => _AnimatedSplash(size: size),
        loading: () => _AnimatedSplash(size: size),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(bootstrapControllerProvider),
        ),
      ),
    );
  }

  Widget _AnimatedSplash({required Size size}) {
    return Stack(
      children: [
        Container(color: Colors.white),

        /// Logo center me reveal hoga
        Center(
          child: ScaleTransition(
            scale: _logoAnimation,
            child: FadeTransition(
              opacity: _slideAnimation,
              child: Image.asset(
                'assets/fast_vpn.png',
                width: 140,
              ),
            ),
          ),
        ),
        /// Top container upar jayega
        AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, _) {
            final progress = _slideAnimation.value;
            final movingRadius = 200 * progress;
            return Positioned(
              top: -((size.height / 2) * progress),
              left: 0,
              right: 0,
              height: size.height / 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: _splashGradient,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(movingRadius),
                  ),
                ),
              ),
            );
          },
        ),
        /// Bottom container neeche jayega
        AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, _) {
            final progress = _slideAnimation.value;
            final movingRadius = 200 * progress;
            return Positioned(
              bottom: -((size.height / 2) * progress),
              left: 0,
              right: 0,
              height: size.height / 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: _splashGradient,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(movingRadius),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
