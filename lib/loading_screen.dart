import 'package:flutter/material.dart';

import 'theme.dart';
import 'widgets.dart';

/// Shown while the daemon is launching a game or app (UPDATE_SCREEN = LOADING).
/// The launched program takes over the screen as a separate fullscreen client;
/// this is the brief hand-off state.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Stack(children: [
        const Positioned.fill(child: CustomPaint(painter: DotsPainter())),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  strokeWidth: 8,
                  valueColor: AlwaysStoppedAnimation(glowBlue),
                  backgroundColor: glowPurple.withValues(alpha: 0.2),
                ),
              ),
              const SizedBox(height: 50),
              ShaderMask(
                shaderCallback: (r) => focusGradient.createShader(r),
                child: const Text('LOADING',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 80,
                        letterSpacing: 6)),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}
