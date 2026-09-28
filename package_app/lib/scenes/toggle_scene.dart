import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../layout.dart';

/// Three switches on a light page, at the iOS 26 switch size.
class ToggleScene extends StatefulWidget {
  const ToggleScene({super.key});

  @override
  State<ToggleScene> createState() => _ToggleSceneState();
}

class _ToggleSceneState extends State<ToggleScene> {
  final List<bool> _values = List.of(Spots.toggleValues);

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
                  Spots.toggleY[i],
                  const Size(120, 60),
                  Center(
                    child: LiquidGlassSwitch(
                      value: _values[i],
                      onChanged: (v) => setState(() => _values[i] = v),
                      activeColor: kSystemGreen,
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
