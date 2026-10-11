import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import 'apple_glass_button.dart';
import 'apple_match_tuning.dart';

/// A tab bar tuned to read like iOS 26's floating `UITabBar`.
class AppleTabBar extends StatelessWidget {
  const AppleTabBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    this.width,
    this.height,
    this.tint,
  });

  final List<LiquidGlassTabBarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  /// Apple's 328 x 62 when null.
  final double? width;
  final double? height;

  /// The selected tab's colour; system blue when null.
  final Color? tint;

  /// The bar's glass: the regular button glass as a capsule, with the
  /// wider shadow a larger floating surface casts.
  static LiquidGlassStyle styleFor(Brightness brightness, double height) =>
      AppleGlassButton.regularStyle(brightness, radius: height / 2).copyWith(
        shadow: LiquidGlassShadow(
          blur: AppleMatchTuning.d('tab.shadowBlur'),
          opacity: AppleMatchTuning.d('tab.shadowOpacity'),
        ),
      );

  @override
  Widget build(BuildContext context) {
    AppleMatchTuning.watch(context);
    final Brightness brightness = Theme.of(context).brightness;
    final bool dark = brightness == Brightness.dark;
    final double h = height ?? AppleMatchTuning.d('tab.height');
    final FontWeight weight = AppleMatchTuning.w('tab.labelWeight');
    return LiquidGlassTabBar(
      items: items,
      selectedIndex: selectedIndex,
      onChanged: onChanged,
      width: width ?? AppleMatchTuning.d('tab.width'),
      height: h,
      margin: EdgeInsets.zero,
      itemPadding: AppleMatchTuning.d('tab.itemPadding'),
      alignment: Alignment.center,
      style: styleFor(brightness, h),
      pillStyle: LiquidGlassTabPillStyle(
        color: AppleMatchTuning.c('tab.pillColor'),
      ),
      itemStyle: LiquidGlassTabItemStyle(
        selectedColor: tint ??
            AppleMatchTuning.c(dark ? 'tab.selectedDark' : 'tab.selectedLight'),
        unselectedColor: dark ? Colors.white : Colors.black,
        iconSize: AppleMatchTuning.d('tab.iconSize'),
        labelFontSize: AppleMatchTuning.d('tab.labelSize'),
        iconLabelGap: 1,
        selectedFontWeight: weight,
        unselectedFontWeight: weight,
      ),
    );
  }
}
