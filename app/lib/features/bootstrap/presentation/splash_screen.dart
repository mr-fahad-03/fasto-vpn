import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  static const Duration _animationDuration = Duration(milliseconds: 950);
  static const AssetImage _logoAsset = AssetImage('assets/fast_vpn.png');

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
  late final Animation<double> _panelAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  bool _started = false;
  bool _logoPrecached = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
      animationBehavior: AnimationBehavior.preserve,
    );

    _panelAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.08, 0.70, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _started) {
        return;
      }
      _started = true;
      _runSplashSequence();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_logoPrecached) {
      return;
    }
    _logoPrecached = true;
    precacheImage(_logoAsset, context);
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(splashAnimationDoneProvider.notifier).state = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bootstrap = ref.watch(bootstrapControllerProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: bootstrap.when(
        data: (_) => _animatedSplash(size: size),
        loading: () => _animatedSplash(size: size),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(bootstrapControllerProvider),
        ),
      ),
    );
  }

  Widget _animatedSplash({required Size size}) {
    return RepaintBoundary(
      child: Stack(
        children: [
          const ColoredBox(color: Colors.white),

          /// Logo center me reveal hoga
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Image.asset(
                  _logoAsset.assetName,
                  width: 140,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          AnimatedBuilder(
            animation: _panelAnimation,
            builder: (context, _) {
              final progress = _panelAnimation.value;
              final offset = (size.height / 2) * progress;
              final movingRadius = 170 * progress;

              return Stack(
                children: [
                  /// Top container upar jayega
                  Positioned(
                    top: -offset,
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
                  ),

                  /// Bottom container neeche jayega
                  Positioned(
                    bottom: -offset,
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
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
