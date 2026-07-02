import 'package:flutter/material.dart';

import 'models.dart';
import 'theme.dart';
import 'widgets.dart';

/// The coin/insert-credit screen. Fully live-configurable from the daemon:
/// the messages, time vs. credit mode, and credit count all come from the
/// COIN_STATUS the store keeps up to date.
class CoinScreen extends StatelessWidget {
  final CoinStatus coin;
  const CoinScreen({super.key, required this.coin});

  String _fmtTime(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth, h = c.maxHeight;
        final aspect = (w > 0 && h > 0) ? w / h : kDW / kDH;
        final designW = (kDH * aspect).clamp(kDH, kDH * 4);
        return Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: designW,
              height: kDH,
              child: Stack(children: [
                Positioned.fill(child: Container(color: bg)),
                const Positioned.fill(child: CustomPaint(painter: DotsPainter())),
                const Positioned(right: 60, top: 40, child: Logo(height: 128)),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShaderMask(
                        shaderCallback: (r) => focusGradient.createShader(r),
                        child: Text(
                          coin.insertMessage.isEmpty
                              ? 'INSERT COIN'
                              : coin.insertMessage,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 150,
                              letterSpacing: 4),
                        ),
                      ),
                      const SizedBox(height: 30),
                      if (coin.infoMessage.isNotEmpty)
                        Text(coin.infoMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: mutedInk,
                                fontWeight: FontWeight.w700,
                                fontSize: 48)),
                      const SizedBox(height: 60),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 60, vertical: 24),
                        decoration: BoxDecoration(
                          color: pill,
                          borderRadius: BorderRadius.circular(60),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x1A000000),
                                offset: Offset(0, 6),
                                blurRadius: 18),
                          ],
                        ),
                        child: Text(
                          coin.timeMode
                              ? 'TIME  ${_fmtTime(coin.remainingSeconds)}'
                              : 'CREDITS  ${coin.credits}',
                          style: const TextStyle(
                              color: ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 64),
                        ),
                      ),
                      const SizedBox(height: 40),
                      if (!coin.hardwareConnected)
                        const Text('coin reader offline',
                            style: TextStyle(
                                color: Color(0xFFE05A5A),
                                fontWeight: FontWeight.w700,
                                fontSize: 30)),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        );
      }),
    );
  }
}
