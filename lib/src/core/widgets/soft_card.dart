import 'package:flutter/material.dart';

import '../design/tokens.dart';

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.radius,
    this.backgroundColor,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double? radius;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColors;
    final surface = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppPalette.surface,
        borderRadius: BorderRadius.circular(radius ?? AppRadius.lg),
        border: Border.all(
          color: borderColor ?? accent.primary.withValues(alpha: 0.12),
        ),
        boxShadow: [
          const BoxShadow(
            color: Color(0x18000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: accent.soft.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: padding ?? const EdgeInsets.all(AppSpace.md),
        child: child,
      ),
    );

    if (onTap == null) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.985, end: 1),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Transform.scale(
          scale: value,
          child: Opacity(
            opacity: 0.985 + (value - 0.985) * 4,
            child: child,
          ),
        ),
        child: surface,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius ?? AppRadius.lg),
        splashColor: accent.primary.withValues(alpha: 0.12),
        highlightColor: accent.primary.withValues(alpha: 0.08),
        hoverColor: accent.primary.withValues(alpha: 0.05),
        child: surface,
      ),
    );
  }
}
