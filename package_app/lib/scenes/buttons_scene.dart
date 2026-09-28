import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../layout.dart';

/// Glass buttons over a photo: a fixed-size circle and wide capsule, then
/// the package's take on Apple's system `.glass` / `.glassProminent`.
class ButtonsScene extends StatelessWidget {
  const ButtonsScene({super.key});

  @override
  Widget build(BuildContext context) {
    return LiquidGlassView(
      backgroundWidget: const Backdrop('mountain.jpg'),
      child: LayoutBuilder(
        builder: (context, c) {
          final Size screen = Size(c.maxWidth, c.maxHeight);
          return Stack(
            children: [
              placeAt(
                screen,
                0.5,
                Spots.buttonCircleY,
                const Size(88, 88),
                LiquidGlassButton(
                  icon: Icons.favorite_rounded,
                  width: 88,
                  height: 88,
                  iconSize: 34,
                  padding: EdgeInsets.zero,
                  foregroundColor: Colors.white,
                  style: CompareStyles.regular(44),
                  touch: CompareStyles.touch,
                  onPressed: () {},
                ),
              ),
              placeAt(
                screen,
                0.5,
                Spots.buttonWideY,
                const Size(340, 64),
                LiquidGlassButton(
                  icon: Icons.add_rounded,
                  label: 'Add to library',
                  width: 340,
                  height: 64,
                  fontSize: 17,
                  foregroundColor: Colors.white,
                  style: CompareStyles.regular(32),
                  touch: CompareStyles.touch,
                  onPressed: () {},
                ),
              ),
              placeAt(
                screen,
                0.5,
                Spots.buttonSystemY,
                const Size(160, 48),
                LiquidGlassButton(
                  label: 'Glass',
                  width: 160,
                  height: 48,
                  foregroundColor: Colors.white,
                  style: CompareStyles.regular(24),
                  touch: CompareStyles.touch,
                  onPressed: () {},
                ),
              ),
              placeAt(
                screen,
                0.5,
                Spots.buttonProminentY,
                const Size(160, 48),
                LiquidGlassButton(
                  label: 'Prominent',
                  width: 160,
                  height: 48,
                  foregroundColor: Colors.white,
                  style: CompareStyles.prominent(24),
                  touch: CompareStyles.touch,
                  onPressed: () {},
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
