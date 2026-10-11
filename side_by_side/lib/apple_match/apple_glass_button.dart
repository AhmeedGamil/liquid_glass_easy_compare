import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

/// A glass button tuned to read like iOS 26's `.glass` and
/// `.glassProminent` buttons.
class AppleGlassButton extends StatelessWidget {
  const AppleGlassButton({
    super.key,
    this.label,
    this.icon,
    this.onPressed,
    this.prominent = false,
    this.tint,
    this.width,
    this.height = 44,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;

  /// Solid accent fill, like `.glassProminent`.
  final bool prominent;

  /// The prominent fill, or the regular button's label colour.
  final Color? tint;

  final double? width;
  final double height;

  /// The regular glass for [brightness].
  static LiquidGlassStyle regularStyle(Brightness brightness, double height) =>
      LiquidGlassButton.defaultStyle.copyWith(
        shape: LiquidGlassShape.continuousRoundedRectangle(
          cornerRadius: height / 2,
        ),
      );

  /// The prominent glass filled with [fill].
  static LiquidGlassStyle prominentStyle(
    Brightness brightness,
    double height,
    Color fill,
  ) =>
      regularStyle(brightness, height).copyWith(color: fill);

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final bool dark = brightness == Brightness.dark;
    final Color accent = tint ?? const Color(0xFF0088FF);
    final bool round = label == null;
    return LiquidGlassButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      width: round ? height : width,
      height: height,
      padding: round ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 18),
      fontSize: 17,
      fontWeight: FontWeight.w400,
      iconSize: round ? 20 : 17,
      foregroundColor: prominent
          ? Colors.white
          : (tint ?? (dark ? Colors.white : Colors.black)),
      style: prominent
          ? prominentStyle(brightness, height, accent)
          : regularStyle(brightness, height),
    );
  }
}
