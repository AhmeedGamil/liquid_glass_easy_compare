import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../layout.dart';

/// Three sliders on a light page, the way Settings shows them.
class SliderScene extends StatefulWidget {
  const SliderScene({super.key});

  @override
  State<SliderScene> createState() => _SliderSceneState();
}

class _SliderSceneState extends State<SliderScene> {
  final List<double> _values = List.of(Spots.sliderValues);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: kLightPage,
      child: LayoutBuilder(
        builder: (context, c) {
          final Size screen = Size(c.maxWidth, c.maxHeight);
          return Stack(
            children: [
              for (int i = 0; i < _values.length; i++)
                placeAt(
                  screen,
                  0.5,
                  Spots.sliderY[i],
                  const Size(Spots.sliderWidth, 60),
                  Center(
                    child: LiquidGlassSlider(
                      value: _values[i],
                      onChanged: (v) => setState(() => _values[i] = v),
                      layout: const LiquidGlassSliderLayout(
                        width: Spots.sliderWidth,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
