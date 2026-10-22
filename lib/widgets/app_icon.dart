import 'package:flutter/material.dart';

class GameiatyLogo extends StatelessWidget {
  final double size;
  const GameiatyLogo({super.key, this.size = 46});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0D5D44),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: CustomPaint(
        painter: _LogoPainter(),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final goldPaint = Paint()
      ..color = const Color(0xFFF3C769)
      ..style = PaintingStyle.fill;

    final darkGold = Paint()
      ..color = const Color(0xFFD69F3D)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF0D5D44)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    double w = size.width;
    double h = size.height;

    // رؤوس الأشخاص الثلاثة
    canvas.drawCircle(Offset(w * 0.50, h * 0.26), w * 0.08, goldPaint);
    canvas.drawCircle(Offset(w * 0.32, h * 0.34), w * 0.07, goldPaint);
    canvas.drawCircle(Offset(w * 0.68, h * 0.34), w * 0.07, goldPaint);

    // الأجسام والأذرع المتشابكة
    Path bodies = Path();
    bodies.moveTo(w * 0.22, h * 0.65);
    bodies.quadraticBezierTo(w * 0.18, h * 0.42, w * 0.32, h * 0.42);
    bodies.quadraticBezierTo(w * 0.40, h * 0.50, w * 0.50, h * 0.50);
    bodies.quadraticBezierTo(w * 0.60, h * 0.50, w * 0.68, h * 0.42);
    bodies.quadraticBezierTo(w * 0.82, h * 0.42, w * 0.78, h * 0.65);
    bodies.quadraticBezierTo(w * 0.50, h * 0.72, w * 0.22, h * 0.65);
    canvas.drawPath(bodies, goldPaint);

    // العملات الذهبية في الأسفل
    for (int i = 0; i < 3; i++) {
      double coinY = h * (0.68 + (i * 0.075));
      Rect coinRect = Rect.fromCenter(
        center: Offset(w * 0.5, coinY),
        width: w * 0.46,
        height: h * 0.12,
      );
      canvas.drawOval(coinRect, i == 2 ? goldPaint : darkGold);
      canvas.drawOval(coinRect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
