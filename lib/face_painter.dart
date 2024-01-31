import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class FacePainter extends CustomPainter {
  ui.Image image;
  List<Offset> leftEyePoints = [];
  List<Offset> rightEyePoints = [];
  List<Offset> mouthPoints = [];

  FacePainter({
    required this.image,
    required this.leftEyePoints,
    required this.rightEyePoints,
    required this.mouthPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (image != null) {
      canvas.drawImage(image, Offset.zero, Paint());
    }

    for (Offset point in leftEyePoints) {
      _drawOval(canvas, point, point.dx * 0.3, point.dy * 0.2,
          Paint()..color = Color(0xff01FF0B).withOpacity(0.5));
    }

    for (Offset point in rightEyePoints) {
      _drawOval(canvas, point, point.dx * 0.3, point.dy * 0.2,
          Paint()..color = Color(0xff01FF0B).withOpacity(0.5));
    }

    for (Offset point in mouthPoints) {
      _drawOval(canvas, point, point.dx * 0.40, point.dy * 0.12,
          Paint()..color = Color(0xff01FF0B).withOpacity(0.5));
    }
  }

  void _drawOval(
      Canvas canvas, Offset center, double width, double height, Paint paint) {
    Rect oval = Rect.fromCenter(center: center, width: width, height: height);
    canvas.drawOval(oval, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
