import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../apple_match/apple_switch.dart';
import '../bands.dart';

/// An on and an off switch per band.
class SwitchScene extends StatefulWidget {
  const SwitchScene({super.key, required this.backdrop});

  final Backdrop backdrop;

  @override
  State<SwitchScene> createState() => _SwitchSceneState();
}

class _SwitchSceneState extends State<SwitchScene> {
  final Map<Band, List<bool>> _values = {
    for (final Band b in Band.values) b: [true, false],
  };

  @override
  Widget build(BuildContext context) {
    return ThreeBands(
      backdrop: widget.backdrop,
      builder: (context, band) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < 2; i++) ...[
            if (i > 0) const SizedBox(width: 40),
            SizedBox(
              width: 100,
              height: 60,
              child: Center(child: _switch(band, i)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _switch(Band band, int i) {
    final bool v = _values[band]![i];
    void set(bool x) => setState(() => _values[band]![i] = x);
    return switch (band) {
      Band.apple => CNSwitch(value: v, onChanged: set),
      Band.package => LiquidGlassSwitch(value: v, onChanged: set),
      Band.match => AppleSwitch(value: v, onChanged: set),
    };
  }
}
