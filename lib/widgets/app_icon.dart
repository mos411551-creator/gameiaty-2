import 'package:flutter/material.dart';

class GameiatyLogo extends StatelessWidget {
  final double size;
  const GameiatyLogo({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0F5A47), // نفس الدرجة الخضراء الزمردية في الصورة الأصلية
        borderRadius: BorderRadius.circular(size * 0.24), // زوايا دائرية فائقة النعومة
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
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
      ..color = const Color(0xFFE5B54F) // اللون الذهبي الدافئ
      ..style = PaintingStyle.fill;

    final darkGold = Paint()
      ..color = const Color(0xFFC2902B) // ظلال وتفاصيل العملات
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF0F5A47)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    double w = size.width;
    double h = size.height;

    // رسم الرأس الأوسط
    canvas.drawCircle(Offset(w * 0.50, h * 0.24), w * 0.09, goldPaint);
    // رسم الرأس الأيسر
    canvas.drawCircle(Offset(w * 0.31, h * 0.31), w * 0.08, goldPaint);
    // رسم الرأس الأيمن (مع الشعر المنسدل)
    canvas.drawCircle(Offset(w * 0.69, h * 0.31), w * 0.08, goldPaint);

    // الأجسام والأذرع المتشابكة المترابطة بالكامل
    Path bodies = Path();
    bodies.moveTo(w * 0.20, h * 0.62);
    bodies.quadraticBezierTo(w * 0.16, h * 0.38, w * 0.30, h * 0.38);
    bodies.quadraticBezierTo(w * 0.38, h * 0.46, w * 0.50, h * 0.46);
    bodies.quadraticBezierTo(w * 0.62, h * 0.46, w * 0.70, h * 0.38);
    bodies.quadraticBezierTo(w * 0.84, h * 0.38, w * 0.80, h * 0.62);
    bodies.quadraticBezierTo(w * 0.50, h * 0.72, w * 0.20, h * 0.62);
    canvas.drawPath(bodies, goldPaint);

    // رسم الشعر المنسدل للفتاة على اليمين
    Path hair = Path();
    hair.moveTo(w * 0.76, h * 0.34);
    hair.quadraticBezierTo(w * 0.80, h * 0.40, w * 0.76, h * 0.46);
    hair.quadraticBezierTo(w * 0.72, h * 0.44, w * 0.70, h * 0.34);
    canvas.drawPath(hair, goldPaint);

    // كومة العملات الذهبية في المنتصف والأسفل
    for (int i = 0; i < 4; i++) {
      double coinY = h * (0.64 + (i * 0.065));
      Rect coinRect = Rect.fromCenter(
        center: Offset(w * 0.5, coinY),
        width: w * 0.34,
        height: h * 0.09,
      );
      canvas.drawOval(coinRect, i == 3 ? goldPaint : darkGold);
      canvas.drawOval(coinRect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
