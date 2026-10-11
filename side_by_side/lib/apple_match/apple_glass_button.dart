import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import 'apple_match_tuning.dart';

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
  static double get cornerRadius => AppleMatchTuning.d('button.radius');

  /// The regular glass for [brightness]. Light: a milky, saturated
  /// frost. Dark: a smoky veil. Both with a faint rim and a soft shadow.
  static LiquidGlassStyle regularStyle(
    Brightness brightness, {
    double? radius,
  }) {
    final bool dark = brightness == Brightness.dark;
    return _base(radius ?? cornerRadius).copyWith(
      color: AppleMatchTuning.c(dark ? 'glass.fillDark' : 'glass.fillLight'),
      saturation: AppleMatchTuning.d(dark ? 'glass.satDark' : 'glass.satLight'),
    );
  }

  /// The prominent glass filled with [fill].
  static LiquidGlassStyle prominentStyle(Color fill, {double? radius}) =>
      _base(radius ?? cornerRadius).copyWith(color: fill);

  static LiquidGlassStyle _base(double radius) {
    final double Function(String) t = AppleMatchTuning.d;
    return LiquidGlassStyle(
      shape: LiquidGlassShape.continuousRoundedRectangle(cornerRadius: radius),
      specular: LiquidGlassLight.specular(
        thickness: t('glass.specThickness'),
        intensity: t('glass.specIntensity'),
        angle: t('glass.specAngle'),
        spread: t('glass.specSpread'),
      ),
      blur: t('glass.blur'),
      refractionIndex: t('glass.refIndex'),
      refractionWidth: t('glass.refWidth'),
      shadow: LiquidGlassShadow(
        blur: t('button.shadowBlur'),
        opacity: t('button.shadowOpacity'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppleMatchTuning.watch(context);
    final Brightness brightness = Theme.of(context).brightness;
    final bool dark = brightness == Brightness.dark;
    final Color accent = tint ?? AppleMatchTuning.c('button.prominentFill');
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
      fontSize: AppleMatchTuning.d('button.fontSize'),
      fontWeight: AppleMatchTuning.w('button.fontWeight'),
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
