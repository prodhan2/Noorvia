import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Utility class providing reusable gradient decorations, painters, and widgets.
/// All methods use [AppColors.gradient] (purple → blue) — Airkom design.
class GradientHelper {
  GradientHelper._();

  // ── BoxDecoration helpers ─────────────────────────────────

  /// Returns a [BoxDecoration] filled with the Airkom gradient.
  static BoxDecoration boxDecoration({
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: AppColors.gradient,
      borderRadius: borderRadius,
      boxShadow: boxShadow,
    );
  }

  /// Returns a [BoxDecoration] filled with the dark-mode gradient.
  static BoxDecoration darkBoxDecoration({
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: AppColors.gradientDark,
      borderRadius: borderRadius,
      boxShadow: boxShadow,
    );
  }

  // ── Widget helpers ────────────────────────────────────────

  /// Wraps [text] in a [ShaderMask] so the text renders with the gradient shader.
  static Widget gradientText(String text, TextStyle style) {
    return ShaderMask(
      shaderCallback: (bounds) => AppColors.gradient.createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Text(text, style: style),
    );
  }

  /// Wraps an [Icon] in a [ShaderMask] so the icon renders with the gradient shader.
  static Widget gradientIcon(IconData icon, double size) {
    return ShaderMask(
      shaderCallback: (bounds) => AppColors.gradient.createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Icon(icon, size: size, color: Colors.white),
    );
  }

  // ── Painter helper ────────────────────────────────────────

  /// Returns a [Paint] with a gradient shader fitted to [bounds].
  /// Use inside [CustomPainter.paint] to draw gradient arcs/lines.
  static Paint gradientPaint(Rect bounds) {
    return Paint()
      ..shader = AppColors.gradient.createShader(bounds)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
  }
}
