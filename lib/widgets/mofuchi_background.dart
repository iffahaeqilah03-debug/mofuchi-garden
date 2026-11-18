import 'dart:ui';
import 'package:flutter/material.dart';

class MofuchiBackground extends StatelessWidget {
  final Widget child;

  const MofuchiBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base gradient canvas
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF7F4FB), Color(0xFFEEF7F1)],
            ),
          ),
        ),
        // Top-left purple ambient orb
        Positioned(
          left: -70,
          top: -45,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: const Color(0xFFE9D5FF).withValues(alpha: 0.40),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Top-right sage mint orb
        Positioned(
          right: -40,
          top: -40,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFFD8EEDB).withValues(alpha: 0.40),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Lower-right mint orb
        Positioned(
          right: -40,
          bottom: 120,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFFD8EEDB).withValues(alpha: 0.30),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Ambient backdrop blur
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: const SizedBox.expand(),
          ),
        ),
        // Foreground UI
        SafeArea(child: child),
      ],
    );
  }
}