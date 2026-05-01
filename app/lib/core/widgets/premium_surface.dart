import 'dart:ui';

import 'package:flutter/material.dart';

class PremiumPageBackground extends StatelessWidget {
  final Widget child;

  const PremiumPageBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD137FF),
            Color(0xFF5D39FF),
            Color(0xFF12A9FF),
          ],
          stops: [0, 0.52, 1],
        ),
      ),
      child: Stack(
        children: [
          const _GlowCircle(
            alignment: Alignment.topLeft,
            size: 250,
            color: Color(0x44FFFFFF),
          ),
          const _GlowCircle(
            alignment: Alignment.bottomRight,
            size: 320,
            color: Color(0x29000000),
          ),
          child,
        ],
      ),
    );
  }
}

class PremiumGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final LinearGradient? gradient;

  const PremiumGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: gradient ??
                const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0x33FFFFFF),
                    Color(0x1DFFFFFF),
                  ],
                ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final Alignment alignment;
  final double size;
  final Color color;

  const _GlowCircle({
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
