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

  /// The corner radius of a labelled button; icon-only ones are circles.
  static const double cornerRadius = 16;

  /// The regular glass for [brightness]. Light: a milky, saturated
  /// frost. Dark: a smoky veil. Both with a faint rim and a soft shadow.
  static LiquidGlassStyle regularStyle(
    Brightness brightness, {
    double radius = cornerRadius,
  }) {
    final bool dark = brightness == Brightness.dark;
    return _base(radius).copyWith(
      color: dark ? const Color(0x851C1C1E) : const Color(0xADFFFFFF),
      saturation: dark ? 1.0 : 2.0,
    );
  }

  /// The prominent glass filled with [fill].
  static LiquidGlassStyle prominentStyle(
    Color fill, {
    double radius = cornerRadius,
  }) =>
      _base(radius).copyWith(color: fill);

  static LiquidGlassStyle _base(double radius) => LiquidGlassStyle(
        shape:
            LiquidGlassShape.continuousRoundedRectangle(cornerRadius: radius),
        specular: const LiquidGlassLight.specular(
          thickness: 2,
          spread: 1,
          intensity: 1,
        ),
        blur: 8,
        refractionIndex: 1.08,
        refractionWidth: 12,
        shadow: const LiquidGlassShadow(blur: 20, opacity: 0.1),
      );

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final bool dark = brightness == Brightness.dark;
    final Color accent = tint ?? const Color(0xFF0088FF);
    final bool round = label == null;
    final double radius = round ? height / 2 : cornerRadius;
    return LiquidGlassButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      width: round ? height : width,
      height: height,
      padding:
          round ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 18),
      fontSize: 17,
      fontWeight: FontWeight.w400,
      iconSize: round ? height * 0.54 : 17,
      foregroundColor: prominent
          ? Colors.white
          : (tint ?? (dark ? Colors.white : Colors.black)),
      style: prominent
          ? prominentStyle(accent, radius: radius)
          : regularStyle(brightness, radius: radius),
    );
  }
}
