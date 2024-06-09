import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

//Copy this CustomPainter code to the Bottom of the File
class UserCustomPaint extends CustomPainter {
  final Color color;

  UserCustomPaint({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint_0_fill = Paint()..style = PaintingStyle.fill;
    paint_0_fill.color = color;
    canvas.drawRRect(
        RRect.fromRectAndCorners(
            Rect.fromLTWH(0, 0, size.width * 0.9994312, size.height),
            bottomRight: Radius.circular(size.width * 0.04782388),
            bottomLeft: Radius.circular(size.width * 0.04782388),
            topLeft: Radius.circular(size.width * 0.04782388),
            topRight: Radius.circular(size.width * 0.04782388)),
        paint_0_fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

//Copy this CustomPainter code to the Bottom of the File
class PedometerBigShape extends CustomPainter {
  final Color color;

  PedometerBigShape({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    Path path_0 = Path();
    path_0.moveTo(size.width * 0.5156921, size.height * 0.01976029);
    path_0.cubicTo(
        size.width * 0.5157012,
        size.height * 0.009506983,
        size.width * 0.5260976,
        size.height * 0.001190450,
        size.width * 0.5389451,
        size.height * 0.001158175);
    path_0.lineTo(size.width * 0.9765732, size.height * 0.00005884599);
    path_0.cubicTo(
        size.width * 0.9894970,
        size.height * 0.00002638589,
        size.width * 0.9999909,
        size.height * 0.008382676,
        size.width * 0.9999756,
        size.height * 0.01869509);
    path_0.lineTo(size.width * 0.9987591, size.height * 0.9814015);
    path_0.cubicTo(
        size.width * 0.9987470,
        size.height * 0.9916764,
        size.width * 0.9883079,
        size.height,
        size.width * 0.9754329,
        size.height);
    path_0.lineTo(size.width * 0.5139329, size.height);
    path_0.cubicTo(
        size.width * 0.4810488,
        size.height,
        size.width * 0.4706037,
        size.height * 0.9916642,
        size.width * 0.4706037,
        size.height * 0.9813820);
    path_0.lineTo(size.width * 0.4706037, size.height * 0.6390560);
    path_0.cubicTo(
        size.width * 0.4706037,
        size.height * 0.6287737,
        size.width * 0.4601585,
        size.height * 0.6204380,
        size.width * 0.4472744,
        size.height * 0.6204380);
    path_0.lineTo(size.width * 0.02387463, size.height * 0.6204380);
    path_0.cubicTo(
        size.width * 0.01099909,
        size.height * 0.6204380,
        size.width * 0.0005579817,
        size.height * 0.6121144,
        size.width * 0.0005459024,
        size.height * 0.6018370);
    path_0.lineTo(size.width * 0.00002197186, size.height * 0.1561599);
    path_0.cubicTo(
        size.width * 0.000009851006,
        size.height * 0.1458494,
        size.width * 0.01050012,
        size.height * 0.1374944,
        size.width * 0.02341966,
        size.height * 0.1375248);
    path_0.lineTo(size.width * 0.4921890, size.height * 0.1386309);
    path_0.cubicTo(
        size.width * 0.5050915,
        size.height * 0.1386613,
        size.width * 0.5155762,
        size.height * 0.1303265,
        size.width * 0.5155884,
        size.height * 0.1200290);
    path_0.lineTo(size.width * 0.5156921, size.height * 0.01976029);
    path_0.close();

    Paint paint_0_fill = Paint()..style = PaintingStyle.fill;
    paint_0_fill.color = color;
    canvas.drawPath(path_0, paint_0_fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class PedometerGitShape extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Path path_0 = Path();
    path_0.moveTo(0, size.height * 0.05101213);
    path_0.cubicTo(0, size.height * 0.02283893, size.width * 0.02392132, 0,
        size.width * 0.05190795, 0);
    path_0.lineTo(size.width * 0.5685947, 0);
    path_0.cubicTo(
        size.width * 0.5965815,
        0,
        size.width * 0.6192695,
        size.height * 0.02283893,
        size.width * 0.6192695,
        size.height * 0.05101213);
    path_0.lineTo(size.width * 0.6192695, size.height * 0.3161207);
    path_0.cubicTo(
        size.width * 0.6192695,
        size.height * 0.3442940,
        size.width * 0.6419570,
        size.height * 0.3671327,
        size.width * 0.6699404,
        size.height * 0.3671327);
    path_0.lineTo(size.width * 0.9436358, size.height * 0.3671327);
    path_0.cubicTo(size.width * 0.9716225, size.height * 0.3671327, size.width,
        size.height * 0.3899720, size.width, size.height * 0.4181447);
    path_0.lineTo(size.width, size.height * 0.9489867);
    path_0.cubicTo(size.width, size.height * 0.9771600, size.width * 0.9716225,
        size.height, size.width * 0.9436358, size.height);
    path_0.lineTo(size.width * 0.05190795, size.height);
    path_0.cubicTo(
        size.width * 0.02392132,
        size.height,
        size.width * 0.001233636,
        size.height * 0.9771600,
        size.width * 0.001233636,
        size.height * 0.9489867);
    path_0.lineTo(size.width * 0.001233636, size.height * 0.05101213);
    path_0.close();

    Paint paint_0_fill = Paint()..style = PaintingStyle.fill;
    paint_0_fill.color = Color(0xffFEDE00).withOpacity(1.0);
    canvas.drawPath(path_0, paint_0_fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
