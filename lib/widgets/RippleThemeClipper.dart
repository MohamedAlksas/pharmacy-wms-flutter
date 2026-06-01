import 'package:flutter/material.dart';
import 'dart:math' as math;

class RippleThemeClipper extends CustomClipper<Path> {
  final Offset center;
  final double radiusFraction;

  RippleThemeClipper({required this.center, required this.radiusFraction});

  @override
  Path getClip(Size size) {
    final maxRadius = math.sqrt(math.pow(size.width, 2) + math.pow(size.height, 2));
    final currentRadius = maxRadius * radiusFraction;

    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: currentRadius));
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

class ThemeTransitionWrapper extends StatefulWidget {
  final Widget child;
  const ThemeTransitionWrapper({super.key, required this.child});

  @override
  State<ThemeTransitionWrapper> createState() => _ThemeTransitionWrapperState();
}

class ThemeTransitionWrapperState extends State<ThemeTransitionWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _transitionController;
  Offset _toggleOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  void triggerThemeSwitch(TapDownDetails details) {
    setState(() {
      _toggleOffset = details.globalPosition;
    });
    _transitionController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _transitionController,
      builder: (context, child) {
        if (_transitionController.value == 0.0) return widget.child;

        return ClipPath(
          clipper: RippleThemeClipper(
            center: _toggleOffset,
            radiusFraction: _transitionController.value,
          ),
          child: widget.child,
        );
      },
    );
  }
}
