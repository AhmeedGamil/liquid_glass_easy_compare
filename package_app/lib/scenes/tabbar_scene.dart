import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../layout.dart';

const List<(IconData, String)> _tabs = [
  (Icons.home_rounded, 'Home'),
  (Icons.grid_view_rounded, 'Browse'),
  (Icons.podcasts_rounded, 'Radio'),
  (Icons.library_music_rounded, 'Library'),
];

/// Card colours, shared with the Apple app's Feed so both bars bend the
/// same content.
const List<(Color, Color)> _cardColors = [
  (Color(0xFFFF3B30), Color(0xFFFF9500)),
  (Color(0xFF5856D6), Color(0xFF0A84FF)),
  (Color(0xFF34C759), Color(0xFF30B0C7)),
  (Color(0xFFFF2D55), Color(0xFFAF52DE)),
];

/// A four-tab bar over a scrolling colourful feed.
class TabBarScene extends StatefulWidget {
  const TabBarScene({super.key});

  @override
  State<TabBarScene> createState() => _TabBarSceneState();
}

class _TabBarSceneState extends State<TabBarScene> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final double width =
        MediaQuery.sizeOf(context).width - Spots.tabBarSideInset * 2;
    return LiquidGlassScaffold(
      body: _Feed(title: _tabs[_index].$2),
      bottomNavigationBar: LiquidGlassTabBar(
        items: [
          for (final (IconData icon, String label) in _tabs)
            LiquidGlassTabBarItem(icon: icon, label: label),
        ],
        selectedIndex: _index,
        onChanged: (i) => setState(() => _index = i),
        width: width,
        height: Spots.tabBarHeight,
        margin: const EdgeInsets.only(bottom: Spots.tabBarBottomMargin),
        itemStyle: const LiquidGlassTabItemStyle(
          selectedColor: kSystemBlue,
          unselectedColor: kInk,
        ),
      ),
    );
  }
}

class _Feed extends StatelessWidget {
  const _Feed({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFE7E5EB),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 110, 20, 140),
        children: [
          Text(
            title,
            style: const TextStyle(
              color: kInk,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.asset(
              'assets/backgrounds/control_center.jpg',
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          for (int i = 0; i < 14; i++) ...[
            const SizedBox(height: 14),
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _cardColors[i % _cardColors.length].$1,
                    _cardColors[i % _cardColors.length].$2,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(18),
              alignment: Alignment.bottomLeft,
              child: Text(
                'Card ${i + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
