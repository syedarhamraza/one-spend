import 'dart:ui';
import 'package:flutter/material.dart';

/// Samsung One UI Status Bar Scrim (Edge-to-Edge Progressive Blur & Gradient Scrim).
///
/// Prevents scrolling cards and text from clashing with the white system status bar
/// icons (clock, battery, Wi-Fi).
/// Confined strictly to 90% of the system status bar height from the top of the device.
class OneUIStatusBarScrim extends StatelessWidget {
  final double? height;

  const OneUIStatusBarScrim({
    super.key,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final scrimHeight = height ?? (topPadding > 0 ? topPadding * 0.90 : 32.0);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: scrimHeight,
      child: IgnorePointer(
        child: ClipRect(
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black,
                  Colors.transparent,
                ],
                stops: [0.35, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 16.0,
                sigmaY: 16.0,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xF2000000), // Pure OLED pitch black ~95%
                      Colors.transparent,
                    ],
                    stops: [0.25, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
