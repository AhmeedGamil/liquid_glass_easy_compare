import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

/// A switch tuned to read like iOS 26's `UISwitch`.
class AppleSwitch extends StatelessWidget {
  const AppleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;

  static LiquidGlassStyle styleFor(Brightness brightness) =>
      LiquidGlassSwitch.defaultStyle;

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final bool dark = brightness == Brightness.dark;
    return LiquidGlassSwitch(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor ?? const Color(0xFF34C759),
      inactiveColor: dark ? const Color(0xA3787880) : const Color(0x6B787880),
      style: styleFor(brightness),
    );
  }
}
