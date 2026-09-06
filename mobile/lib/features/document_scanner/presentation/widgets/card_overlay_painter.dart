import 'package:flutter/material.dart';
import 'package:docushield_ai/core/theme/app_theme.dart';

class CardOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.65);
    
    final width = size.width * 0.88;
    final height = width / 1.586; // ID-1 aspect ratio
    final left = (size.width - width) / 2;
    final top = (size.height - height) / 2;
    
    final cutoutRect = Rect.fromLTWH(left, top, width, height);
    final cutoutRRect = RRect.fromRectAndRadius(cutoutRect, const Radius.circular(16));

    final path = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      Path()..addRRect(cutoutRRect),
    );

    canvas.drawPath(path, backgroundPaint);

    final borderPaint = Paint()
      ..color = AppTheme.primaryCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(cutoutRRect, borderPaint);
    
    // Draw thick corner marks
    final cornerPaint = Paint()
      ..color = AppTheme.primaryCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
      
    const double cornerLength = 30.0;
    
    // Top-left
    canvas.drawLine(Offset(left, top + cornerLength), Offset(left, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), cornerPaint);
    
    // Top-right
    canvas.drawLine(Offset(left + width - cornerLength, top), Offset(left + width, top), cornerPaint);
    canvas.drawLine(Offset(left + width, top), Offset(left + width, top + cornerLength), cornerPaint);
    
    // Bottom-left
    canvas.drawLine(Offset(left, top + height - cornerLength), Offset(left, top + height), cornerPaint);
    canvas.drawLine(Offset(left, top + height), Offset(left + cornerLength, top + height), cornerPaint);
    
    // Bottom-right
    canvas.drawLine(Offset(left + width - cornerLength, top + height), Offset(left + width, top + height), cornerPaint);
    canvas.drawLine(Offset(left + width, top + height), Offset(left + width, top + height - cornerLength), cornerPaint);

    // Optional: guide lines (e.g. for MRZ)
    final mrzLinePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
      
    final mrzTop = top + height * 0.75;
    
    // Draw dashed line for MRZ area
    double dashWidth = 5, dashSpace = 5, startX = left;
    while(startX < left + width) {
      canvas.drawLine(Offset(startX, mrzTop), Offset(startX + dashWidth, mrzTop), mrzLinePaint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
