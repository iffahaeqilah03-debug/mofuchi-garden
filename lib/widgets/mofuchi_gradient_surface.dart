import 'package:flutter/material.dart';

/// Mofuchi's shared purple gradient for primary action buttons.
/// Keep the original button inside so its callbacks, disabled state,
/// validation, and semantics remain unchanged.
class MofuchiGradientSurface extends StatelessWidget {
  const MofuchiGradientSurface({super.key, required this.child, this.radius = 16});
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFA485F8), Color(0xFF7135CD)],
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [BoxShadow(
          color: Color(0x357135CD), blurRadius: 12, offset: Offset(0, 5),
        )],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(radius), child: child),
    );
  }
}
