import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../apple_match/apple_tab_bar.dart';
import '../bands.dart';

const double _width = 370;

const List<LiquidGlassTabBarItem> _items = [
  LiquidGlassTabBarItem(icon: CupertinoIcons.house_fill, label: 'Home'),
  LiquidGlassTabBarItem(icon: CupertinoIcons.search, label: 'Search'),
  LiquidGlassTabBarItem(
    icon: CupertinoIcons.square_stack_fill,
    label: 'Library',
  ),
  LiquidGlassTabBarItem(
    icon: CupertinoIcons.person_crop_circle_fill,
    label: 'Profile',
  ),
];

/// A four-tab bar with the first tab selected.
class TabBarScene extends StatefulWidget {
  const TabBarScene({super.key, required this.backdrop});

  final Backdrop backdrop;

  @override
  State<TabBarScene> createState() => _TabBarSceneState();
}

class _TabBarSceneState extends State<TabBarScene> {
  final Map<Band, int> _index = {for (final Band b in Band.values) b: 0};

  @override
  Widget build(BuildContext context) {
    return ThreeBands(
      backdrop: widget.backdrop,
      photo: 'flower.jpg',
      builder: (context, band) => SizedBox(
        width: _width,
        height: 90,
        child: Center(child: _bar(band)),
      ),
    );
  }

  Widget _bar(Band band) {
    final int i = _index[band]!;
    void set(int x) => setState(() => _index[band] = x);
    return switch (band) {
      Band.apple => CNTabBar(
          items: const [
            CNTabBarItem(label: 'Home', icon: CNSymbol('house.fill')),
            CNTabBarItem(label: 'Search', icon: CNSymbol('magnifyingglass')),
            CNTabBarItem(label: 'Library', icon: CNSymbol('square.stack.fill')),
            CNTabBarItem(
              label: 'Profile',
              icon: CNSymbol('person.crop.circle.fill'),
            ),
          ],
          currentIndex: i,
          onTap: set,
        ),
      Band.package => LiquidGlassTabBar(
          items: _items,
          selectedIndex: i,
          onChanged: set,
          width: _width,
          margin: EdgeInsets.zero,
          alignment: Alignment.center,
        ),
      Band.match => AppleTabBar(
          items: _items,
          selectedIndex: i,
          onChanged: set,
          width: _width,
        ),
    };
  }
}
