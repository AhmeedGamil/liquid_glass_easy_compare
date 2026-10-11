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

  /// Length of the track, end to end, like a `UISlider` frame. The
  /// widget is wider by the room the lifted thumb needs at each end.
  final double width;
  final Color? activeColor;

  static const LiquidGlassLensMotionSpec motion = LiquidGlassLensMotionSpec();

  /// The layout whose track is [trackWidth] long.
  static LiquidGlassSliderLayout layoutFor(double trackWidth) {
    const LiquidGlassSliderLayout base = LiquidGlassSliderLayout();
    final double inset = base.resolveHorizontalInset(motion.maxDeformation);
    return base.copyWith(width: trackWidth + inset * 2);
  }

  /// The package glass with Apple's thumb shadow: centred on the thumb,
  /// not dropped below it, and lighter.
  static LiquidGlassStyle styleFor(Brightness brightness) =>
      LiquidGlassSlider.defaultStyle.copyWith(
        shadow: const LiquidGlassShadow(
          blur: 8,
          opacity: 0.12,
          offset: Offset.zero,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final bool dark = brightness == Brightness.dark;
    return LiquidGlassSlider(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor ?? const Color(0xFF0088FF),
      inactiveColor: dark ? const Color(0x3B787880) : const Color(0x2B787880),
      layout: layoutFor(width),
      style: styleFor(brightness),
    );
  }
}
