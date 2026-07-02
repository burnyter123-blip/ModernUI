import 'package:flutter/material.dart';
import 'theme.dart';

/// A home/library tile with a constant footprint. When focused it gains the
/// cyan→blue→purple gradient border + glow, exactly like the HearthOS launcher.
class Tile extends StatelessWidget {
  final bool focused;
  final ImageProvider? image;
  final String label;
  final double width;
  final double height;
  final bool empty;

  const Tile({
    super.key,
    required this.focused,
    required this.label,
    this.image,
    this.width = 197,
    this.height = 196,
    this.empty = false,
  });

  Widget _fill(double radius) => Container(
        decoration: BoxDecoration(
          gradient: tileFillGradient,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: const [
            BoxShadow(
                color: Color(0x73FFFFFF), offset: Offset(-7, -7), blurRadius: 11),
            BoxShadow(
                color: Color(0x4D000000), offset: Offset(7, 9), blurRadius: 16),
            BoxShadow(
                color: Color(0x26000000), offset: Offset(11, 16), blurRadius: 30),
          ],
        ),
        alignment: Alignment.center,
        clipBehavior: Clip.antiAlias,
        child: empty
            ? null
            : image != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Image(image: image!, fit: BoxFit.contain),
                  )
                : Text(
                    _initials(label),
                    style: const TextStyle(
                        color: ink, fontWeight: FontWeight.w800, fontSize: 64),
                  ),
      );

  static String _initials(String s) {
    final t = s.trim();
    if (t.isEmpty) return '?';
    final parts = t.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return t.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: focused
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                gradient: focusGradient,
                boxShadow: [
                  BoxShadow(
                      color: glowBlue.withValues(alpha: 0.55),
                      blurRadius: 26,
                      spreadRadius: 1),
                ],
              ),
              padding: const EdgeInsets.all(6),
              child: _fill(30),
            )
          : _fill(34),
    );
  }
}

/// The faint dot texture over the background.
class DotsPainter extends CustomPainter {
  const DotsPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0x07000000);
    const step = 19.0;
    const r = 1.4;
    for (double y = 10; y < size.height; y += step) {
      for (double x = 10; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), r, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A single button hint, e.g. (A) Select.
class Hint extends StatelessWidget {
  final String glyph;
  final String label;
  final bool filled;
  const Hint(
      {super.key,
      required this.glyph,
      required this.label,
      this.filled = false});

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? const Color(0xFF4A4F5E) : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF9A9AA0), width: 2.0),
      ),
      child: Text(glyph,
          style: TextStyle(
              color: filled ? Colors.white : ink,
              fontWeight: FontWeight.w700,
              fontSize: 22,
              height: 1.0)),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        circle,
        const SizedBox(width: 13),
        Text(label,
            style: const TextStyle(
                color: ink, fontWeight: FontWeight.w700, fontSize: 30)),
      ],
    );
  }
}

/// The Arcader logo.
class Logo extends StatelessWidget {
  final double height;
  const Logo({super.key, this.height = 120});
  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/images/logo.png', height: height);
  }
}

