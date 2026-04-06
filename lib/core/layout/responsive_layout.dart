import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Shared breakpoints for phone / tablet / desktop layouts.
abstract final class AppBreakpoints {
  /// Bottom nav; below this width use [NavigationBar].
  static const double rail = 840;

  /// Typical “tablet” threshold for denser grids.
  static const double medium = 600;

  /// Large desktop: extra columns / padding.
  static const double expanded = 1200;

  /// Product detail: gallery + purchase info side‑by‑side.
  static const double productDetailTwoColumn = 900;

  static const double authFormMaxWidth = 440;
  static const double authWideFormMaxWidth = 560;
  static const double pageContentMaxWidth = 1280;

  static bool useSideRail(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= rail;
  }

  static bool useProductDetailTwoColumn(double maxWidth) {
    return maxWidth >= productDetailTwoColumn;
  }

  static int productGridCrossAxisCount(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= expanded) return 4;
    if (w >= medium) return 3;
    return 2;
  }

  static int categoryGridCrossAxisCount(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= expanded) return 4;
    if (w >= medium) return 3;
    return 2;
  }
}

/// Horizontally centers [child] and limits width (e.g. for desktop).
class CenteredMaxWidth extends StatelessWidget {
  final double maxWidth;
  final Widget child;
  final AlignmentGeometry alignment;

  const CenteredMaxWidth({
    super.key,
    required this.maxWidth,
    required this.child,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: math.min(maxWidth, MediaQuery.sizeOf(context).width),
        ),
        child: child,
      ),
    );
  }
}
