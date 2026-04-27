import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_routes.dart';
import '../../bootstrap/state/bootstrap_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _index = 0;
  bool _submitting = false;

  static const LinearGradient _backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD137FF),
      Color(0xFF5D39FF),
      Color(0xFF12A9FF),
    ],
    stops: [0, 0.55, 1],
  );

  static const _slides = <_OnboardingSlide>[
    _OnboardingSlide(
      icon: Icons.lock_person_rounded,
      eyebrow: 'Privacy First',
      title: 'Private by default',
      body: 'Fasto VPN protects your browsing with secure, encrypted traffic from the moment you connect.',
      chip: 'AES-256 Shield',
    ),
    _OnboardingSlide(
      icon: Icons.bolt_rounded,
      eyebrow: 'Fast Routes',
      title: 'Blazing speed, smooth experience',
      body: 'Stream, scroll, and browse without slowdowns using optimized routes built for everyday speed.',
      chip: 'Low-latency Tunnels',
    ),
    _OnboardingSlide(
      icon: Icons.public_rounded,
      eyebrow: 'Global Access',
      title: 'Freedom without limits',
      body: 'Unlock content, stay protected on public Wi-Fi, and enjoy the internet with confidence anywhere.',
      chip: 'Worldwide Coverage',
    ),
  ];

  bool get _isLast => _index == _slides.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_submitting) {
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(bootstrapControllerProvider.notifier).markOnboardingDone();
      if (!mounted) {
        return;
      }
      context.go(AppRoutes.authChoice);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _onPrimaryTap() async {
    if (_isLast) {
      await _finish();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _skipToLast() async {
    await _pageController.animateToPage(
      _slides.length - 1,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: _backgroundGradient),
        child: Stack(
          children: [
            const _BackgroundGlow(
              alignment: Alignment.topLeft,
              size: 280,
              color: Color(0x55FFFFFF),
            ),
            const _BackgroundGlow(
              alignment: Alignment.bottomRight,
              size: 330,
              color: Color(0x33000000),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  children: [
                    _TopBar(
                      index: _index,
                      total: _slides.length,
                      onSkip: _isLast ? null : _skipToLast,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _slides.length,
                        onPageChanged: (value) => setState(() => _index = value),
                        itemBuilder: (context, pageIndex) {
                          return _AnimatedSlideCard(
                            pageController: _pageController,
                            pageIndex: pageIndex,
                            slide: _slides[pageIndex],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    _PageIndicators(currentIndex: _index, count: _slides.length),
                    const SizedBox(height: 18),
                    _PrimaryButton(
                      label: _submitting
                          ? 'Please wait...'
                          : (_isLast ? 'Get Started' : 'Continue'),
                      onTap: _submitting ? null : _onPrimaryTap,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String body;
  final String chip;

  const _OnboardingSlide({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.chip,
  });
}

class _TopBar extends StatelessWidget {
  final int index;
  final int total;
  final VoidCallback? onSkip;

  const _TopBar({
    required this.index,
    required this.total,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final progress = '${index + 1} / $total';
    return Row(
      children: [
        const Text(
          'FASTO VPN',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.white.withValues(alpha: 0.22),
          ),
          child: Text(
            progress,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onSkip,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white.withValues(alpha: 0.45),
          ),
          child: const Text('Skip'),
        ),
      ],
    );
  }
}

class _AnimatedSlideCard extends StatelessWidget {
  final PageController pageController;
  final int pageIndex;
  final _OnboardingSlide slide;

  const _AnimatedSlideCard({
    required this.pageController,
    required this.pageIndex,
    required this.slide,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pageController,
      child: _SlideCard(slide: slide),
      builder: (context, child) {
        double page = pageIndex.toDouble();
        if (pageController.hasClients && pageController.position.haveDimensions) {
          page = pageController.page ?? pageIndex.toDouble();
        }

        final delta = (page - pageIndex).clamp(-1.0, 1.0).toDouble();
        final scale = 1 - (delta.abs() * 0.06);
        final opacity = 1 - (delta.abs() * 0.24);

        return Transform.translate(
          offset: Offset(delta * 24, 0),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity.clamp(0.6, 1.0).toDouble(),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _SlideCard extends StatelessWidget {
  final _OnboardingSlide slide;

  const _SlideCard({required this.slide});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color: Colors.white.withValues(alpha: 0.14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                child: Icon(slide.icon, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                slide.eyebrow.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.84),
                  letterSpacing: 1.4,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                slide.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                slide.body,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.93),
                  fontSize: 16,
                  height: 1.45,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      slide.chip,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageIndicators extends StatelessWidget {
  final int currentIndex;
  final int count;

  const _PageIndicators({
    required this.currentIndex,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: index == currentIndex ? 26 : 9,
          height: 9,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: index == currentIndex
                ? Colors.white
                : Colors.white.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: disabled
              ? [
                  Colors.white.withValues(alpha: 0.22),
                  Colors.white.withValues(alpha: 0.22),
                ]
              : const [
                  Color(0xFF0B1021),
                  Color(0xFF0A1A3D),
                ],
        ),
        boxShadow: disabled
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: disabled ? 0.6 : 1),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  final Alignment alignment;
  final double size;
  final Color color;

  const _BackgroundGlow({
    required this.alignment,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }
}
