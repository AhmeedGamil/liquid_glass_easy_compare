import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import 'apple_glass_button.dart';

/// A tab bar tuned to read like iOS 26's floating `UITabBar`.
class AppleTabBar extends StatelessWidget {
  const AppleTabBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    this.width = 328,
    this.height = 62,
    this.tint,
  });

  final List<LiquidGlassTabBarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double width;
  final double height;

  /// The selected tab's colour; system blue when null.
  final Color? tint;

  /// The bar's glass: the regular button glass as a capsule, with the
  /// wider shadow a larger floating surface casts.
  static LiquidGlassStyle styleFor(Brightness brightness, double height) =>
      AppleGlassButton.regularStyle(brightness, radius: height / 2).copyWith(
        shadow: const LiquidGlassShadow(blur: 24, opacity: 0.12),
      );

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final bool dark = brightness == Brightness.dark;
    return LiquidGlassTabBar(
      items: items,
      selectedIndex: selectedIndex,
      onChanged: onChanged,
      width: width,
      height: height,
      margin: EdgeInsets.zero,
      itemPadding: 4,
      alignment: Alignment.center,
      style: styleFor(brightness, height),
      itemStyle: LiquidGlassTabItemStyle(
        selectedColor:
            tint ?? (dark ? const Color(0xFF0091FF) : const Color(0xFF0088FF)),
        unselectedColor: dark ? Colors.white : Colors.black,
        iconSize: 28,
        labelFontSize: 10,
        iconLabelGap: 1,
        selectedFontWeight: FontWeight.w600,
        unselectedFontWeight: FontWeight.w600,
      ),
    );
  }
}
