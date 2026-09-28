import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import 'layout.dart';
import 'scenes/buttons_scene.dart';
import 'scenes/glass_scene.dart';
import 'scenes/slider_scene.dart';
import 'scenes/tabbar_scene.dart';
import 'scenes/toggle_scene.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CompareApp());
}

enum CompareScene { glass, buttons, slider, toggle, tabbar }

/// Whether the scene sits on a photo (white caption) or a light page.
bool _onPhoto(CompareScene s) =>
    s == CompareScene.glass || s == CompareScene.buttons;

class CompareApp extends StatelessWidget {
  const CompareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      home: const _Root(),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  // The UI tests launch straight into a scene through the SCENE variable;
  // without it the app opens on the scene list, for poking at by hand.
  CompareScene? _scene = CompareScene.values
      .where((s) => s.name == Platform.environment['SCENE'])
      .firstOrNull;

  @override
  Widget build(BuildContext context) {
    final CompareScene? scene = _scene;
    if (scene == null) {
      return _Home(onOpen: (s) => setState(() => _scene = s));
    }
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          switch (scene) {
            CompareScene.glass => const GlassScene(),
            CompareScene.buttons => const ButtonsScene(),
            CompareScene.slider => const SliderScene(),
            CompareScene.toggle => const ToggleScene(),
            CompareScene.tabbar => const TabBarScene(),
          },
          _Caption(
            scene: scene,
            onBack: () => setState(() => _scene = null),
          ),
        ],
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({required this.scene, required this.onBack});

  final CompareScene scene;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final Color ink = _onPhoto(scene) ? Colors.white : kInk;
    final double top = MediaQuery.paddingOf(context).top + 4;
    return Positioned(
      left: 0,
      right: 0,
      top: top,
      height: 32,
      child: Stack(
        children: [
          Center(
            child: Text(
              'PACKAGE · ${scene.name}',
              style: TextStyle(
                color: ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: onBack,
              child: Center(
                child: Text(
                  '‹ Scenes',
                  style: TextStyle(color: ink, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home({required this.onOpen});

  final ValueChanged<CompareScene> onOpen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiquidGlassView(
        backgroundWidget: const Backdrop('flower.jpg'),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'liquid_glass_easy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),
              for (final CompareScene s in CompareScene.values) ...[
                LiquidGlassButton(
                  label: s.name,
                  width: 240,
                  height: 52,
                  style: CompareStyles.regular(26),
                  foregroundColor: Colors.white,
                  onPressed: () => onOpen(s),
                ),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
