import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

/// A slider tuned to read like iOS 26's `UISlider`.
class AppleSlider extends StatelessWidget {
  const AppleSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 300,
    this.activeColor,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double width;
  final Color? activeColor;

  static LiquidGlassStyle styleFor(Brightness brightness) =>
      LiquidGlassSlider.defaultStyle;

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final bool dark = brightness == Brightness.dark;
    return LiquidGlassSlider(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor ?? const Color(0xFF0088FF),
      inactiveColor: dark ? const Color(0x52787880) : const Color(0x33787880),
      layout: LiquidGlassSliderLayout(width: width),
      style: styleFor(brightness),
    );
  }
}
