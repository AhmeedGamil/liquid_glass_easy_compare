import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

/// A tab bar tuned to read like iOS 26's floating `UITabBar`.
class AppleTabBar extends StatelessWidget {
  const AppleTabBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    this.width = 370,
    this.height = 62,
    this.tint,
  });

  final List<LiquidGlassTabBarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double width;
  final double height;
  final Color? tint;

  static LiquidGlassStyle styleFor(Brightness brightness, double height) =>
      LiquidGlassTabBar.defaultStyle.copyWith(
        shape: LiquidGlassShape.continuousRoundedRectangle(
          cornerRadius: height / 2,
        ),
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
      alignment: Alignment.center,
      style: styleFor(brightness, height),
      itemStyle: LiquidGlassTabItemStyle(
        selectedColor: tint ?? const Color(0xFF0088FF),
        unselectedColor: dark ? Colors.white : Colors.black,
        iconSize: 24,
        labelFontSize: 10,
      ),
    );
  }
}
