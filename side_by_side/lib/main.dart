import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'scenes/buttons_scene.dart';
import 'scenes/slider_scene.dart';
import 'scenes/switch_scene.dart';
import 'scenes/tab_bar_scene.dart';
import 'bands.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const SideBySideApp());
}

/// Every scene, by the name the capture script launches it with.
final Map<String, WidgetBuilder> kScenes = {
  'buttons_photo': (_) => const ButtonsScene(backdrop: Backdrop.photo),
  'buttons_stripes': (_) => const ButtonsScene(backdrop: Backdrop.stripes),
  'buttons_page': (_) => const ButtonsScene(backdrop: Backdrop.page),
  'slider_page': (_) => const SliderScene(backdrop: Backdrop.page),
  'slider_photo': (_) => const SliderScene(backdrop: Backdrop.photo),
  'switch_page': (_) => const SwitchScene(backdrop: Backdrop.page),
  'switch_photo': (_) => const SwitchScene(backdrop: Backdrop.photo),
  'tabbar_photo': (_) => const TabBarScene(backdrop: Backdrop.photo),
  'tabbar_stripes': (_) => const TabBarScene(backdrop: Backdrop.stripes),
  'tabbar_page': (_) => const TabBarScene(backdrop: Backdrop.page),
};

class SideBySideApp extends StatelessWidget {
  const SideBySideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
      darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      themeMode: ThemeMode.system,
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
  // The capture script launches straight into a scene through SCENE;
  // without it the app opens on the scene list.
  String? _scene = Platform.environment['SCENE'];

  @override
  Widget build(BuildContext context) {
    final WidgetBuilder? scene = kScenes[_scene];
    if (scene != null) {
      return Scaffold(body: Builder(builder: scene));
    }
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            for (final String name in kScenes.keys)
              ListTile(
                title: Text(name),
                onTap: () => setState(() => _scene = name),
              ),
          ],
        ),
      ),
    );
  }
}
