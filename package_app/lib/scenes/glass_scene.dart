import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../layout.dart';

/// Plain glass shapes over a photo: a big draggable rounded rectangle,
/// a regular and a clear circle, and a capsule.
class GlassScene extends StatelessWidget {
  const GlassScene({super.key});

  static const TextStyle _label = TextStyle(
    color: Colors.white,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  @override
  Widget build(BuildContext context) {
    return LiquidGlassView(
      backgroundWidget: const Backdrop('flower.jpg'),
      child: LayoutBuilder(
        builder: (context, c) {
          final Size screen = Size(c.maxWidth, c.maxHeight);
          return Stack(
            children: [
              placeAt(
                screen,
                0.5,
                Spots.glassBigY,
                const Size(280, 176),
                LiquidGlassDraggable(
                  child: LiquidGlassLens(
                    style: CompareStyles.regular(44),
                    touch: CompareStyles.touch,
                    child: const Center(
                      child: Text(
                        'Glass',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              placeAt(
                screen,
                Spots.glassCircleLeftX,
                Spots.glassCirclesY,
                const Size(88, 88),
                LiquidGlassLens(
                  style: CompareStyles.regular(44),
                  touch: CompareStyles.touch,
                  child: const Center(child: Text('Regular', style: _label)),
                ),
              ),
              placeAt(
                screen,
                Spots.glassCircleRightX,
                Spots.glassCirclesY,
                const Size(88, 88),
                LiquidGlassLens(
                  style: CompareStyles.clear(44),
                  touch: CompareStyles.touch,
                  child: const Center(child: Text('Clear', style: _label)),
                ),
              ),
              placeAt(
                screen,
                0.5,
                Spots.glassCapsuleY,
                const Size(260, 64),
                LiquidGlassLens(
                  style: CompareStyles.regular(32),
                  child: const Center(child: Text('Capsule', style: _label)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
