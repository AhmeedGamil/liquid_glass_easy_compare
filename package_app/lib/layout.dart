import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

// Every position here is mirrored in apple/AppleReference/Layout.swift and
// apple/CompareUITests/SceneTests.swift. Change all three together, or the
// scripted gestures land on different spots in the two apps.

/// Centres as fractions of the full screen (safe areas ignored).
class Spots {
  static const double glassBigY = 0.36;
  static const double glassCirclesY = 0.64;
  static const double glassCircleLeftX = 0.28;
  static const double glassCircleRightX = 0.72;
  static const double glassCapsuleY = 0.80;

  static const double buttonCircleY = 0.30;
  static const double buttonWideY = 0.44;
  static const double buttonSystemY = 0.60;
  static const double buttonProminentY = 0.72;

  static const List<double> sliderY = [0.38, 0.50, 0.62];
  static const List<double> sliderValues = [0.65, 0.40, 0.80];
  static const double sliderWidth = 300;

  static const List<double> toggleY = [0.40, 0.50, 0.60];
  static const List<bool> toggleValues = [true, false, true];

  static const double tabBarSideInset = 16;
  static const double tabBarHeight = 62;
  static const double tabBarBottomMargin = 8;
}

const Color kLightPage = Color(0xFFE9E9EC);
const Color kInk = Color(0xFF11131A);
const Color kSystemBlue = Color(0xFF0A84FF);
const Color kSystemGreen = Color(0xFF34C759);

/// The styles standing in for Apple's two glass variants. These are the
/// knobs to tune while comparing.
class CompareStyles {
  /// Apple `.regular`: frosted, lightly lifted.
  static LiquidGlassStyle regular(double cornerRadius) => LiquidGlassStyle(
        shape: LiquidGlassShape.continuousRoundedRectangle(
          cornerRadius: cornerRadius,
        ),
        appearance: const LiquidGlassAppearance(
          blur: LiquidGlassBlur(sigmaX: 6, sigmaY: 6),
          color: Color(0x1FFFFFFF),
        ),
      );

  /// Apple `.clear`: no frost, almost no tint.
  static LiquidGlassStyle clear(double cornerRadius) => LiquidGlassStyle(
        shape: LiquidGlassShape.continuousRoundedRectangle(
          cornerRadius: cornerRadius,
        ),
        appearance: const LiquidGlassAppearance(color: Color(0x0AFFFFFF)),
      );

  /// Apple `.glassProminent`: the accent colour poured into the glass.
  static LiquidGlassStyle prominent(double cornerRadius) => LiquidGlassStyle(
        shape: LiquidGlassShape.continuousRoundedRectangle(
          cornerRadius: cornerRadius,
        ),
        appearance: const LiquidGlassAppearance(color: Color(0xD90A84FF)),
      );

  /// Apple's `.interactive()` press response.
  static const LiquidGlassTouch touch =
      LiquidGlassTouch.flexing(LiquidGlassFlex());
}

/// Places [child] with its centre at ([fx], [fy]) of [screen].
Widget placeAt(
  Size screen,
  double fx,
  double fy,
  Size size,
  Widget child,
) {
  return Positioned(
    left: screen.width * fx - size.width / 2,
    top: screen.height * fy - size.height / 2,
    width: size.width,
    height: size.height,
    child: child,
  );
}

/// A photo from assets/backgrounds, filling the screen like SwiftUI's
/// `scaledToFill`.
class Backdrop extends StatelessWidget {
  const Backdrop(this.name, {super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/backgrounds/$name',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}
