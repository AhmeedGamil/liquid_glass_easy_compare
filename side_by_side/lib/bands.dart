import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

/// The three rows every scene shows, top to bottom.
enum Band {
  /// Apple's own control (a native platform view).
  apple('APPLE'),

  /// The package component on its defaults.
  package('PACKAGE'),

  /// The tuned component from lib/apple_match.
  match('MATCH');

  const Band(this.caption);

  final String caption;
}

/// What sits behind a scene's controls.
enum Backdrop {
  /// The iOS grouped page colour.
  page,

  /// A photo.
  photo,

  /// Coloured diagonal stripes, to read refraction off.
  stripes,
}

const Color kPageLight = Color(0xFFF2F2F7);
const Color kPageDark = Color(0xFF000000);

/// Splits the screen into three equal bands, each with an identical copy
/// of [backdrop] behind it, and builds one band's controls with [builder].
///
/// Every band is laid out the same way, so a control sits at the same
/// spot over the same pixels in all three.
class ThreeBands extends StatelessWidget {
  const ThreeBands({
    super.key,
    required this.backdrop,
    required this.builder,
    this.photo = 'mountain.jpg',
  });

  final Backdrop backdrop;
  final String photo;
  final Widget Function(BuildContext context, Band band) builder;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = backdrop == Backdrop.page && !dark
        ? const Color(0x99000000)
        : const Color(0xCCFFFFFF);
    return LiquidGlassView(
      backgroundWidget: Column(
        children: [
          for (final Band _ in Band.values)
            Expanded(child: _BandBackdrop(kind: backdrop, photo: photo)),
        ],
      ),
      child: Column(
        children: [
          for (final Band band in Band.values)
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    left: 12,
                    bottom: 8,
                    child: Text(
                      band.caption,
                      style: TextStyle(
                        color: ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                  Center(child: builder(context, band)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BandBackdrop extends StatelessWidget {
  const _BandBackdrop({required this.kind, required this.photo});

  final Backdrop kind;
  final String photo;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRect(
      child: switch (kind) {
        Backdrop.page => ColoredBox(color: dark ? kPageDark : kPageLight),
        Backdrop.photo => Image.asset(
            'assets/backgrounds/$photo',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        Backdrop.stripes => const CustomPaint(painter: _Stripes()),
      },
    );
  }
}

class _Stripes extends CustomPainter {
  const _Stripes();

  static const List<Color> _colors = [
    Color(0xFFFF3B30),
    Color(0xFFFF9500),
    Color(0xFFFFCC00),
    Color(0xFF34C759),
    Color(0xFF007AFF),
    Color(0xFFAF52DE),
    Color(0xFFFFFFFF),
    Color(0xFF1C1C1E),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const double band = 18;
    final Paint p = Paint();
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-0.5);
    final double reach = size.longestSide;
    int i = 0;
    for (double x = -reach; x < reach; x += band, i++) {
      p.color = _colors[i % _colors.length];
      canvas.drawRect(Rect.fromLTWH(x, -reach, band, reach * 2), p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Stripes oldDelegate) => false;
}
