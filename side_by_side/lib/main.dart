import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'scenes/buttons_scene.dart';
import 'scenes/slider_scene.dart';
import 'scenes/switch_scene.dart';
import 'scenes/tab_bar_scene.dart';
import 'apple_match/apple_match_tuning.dart';
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

  HttpServer? _server;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) _serve();
  }

  @override
  void dispose() {
    _server?.close(force: true);
    super.dispose();
  }

  // Debug only: the live tuning server on the Mac drives the app through
  // http://127.0.0.1:8790 —
  //   GET  /scene?name=<scene>   switch scenes
  //   GET  /tune                 every apple_match knob with its value
  //   POST /tune  {id: value}    change knobs; POST /tune/reset drops them
  // Changes are answered once they have painted.
  Future<void> _serve() async {
    try {
      _server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        8790,
        shared: true,
      );
    } on SocketException {
      return;
    }
    await for (final HttpRequest req in _server!) {
      try {
        await _handle(req);
      } catch (e) {
        req.response.statusCode = HttpStatus.internalServerError;
        req.response.write('$e');
      }
      await req.response.close();
    }
  }

  Future<void> _handle(HttpRequest req) async {
    final String path = req.uri.path;
    if (path == '/scene') {
      final String? name = req.uri.queryParameters['name'];
      if (!kScenes.containsKey(name)) {
        req.response.statusCode = HttpStatus.notFound;
        req.response.write('scenes: ${kScenes.keys.join(' ')}');
        return;
      }
      setState(() => _scene = name);
    } else if (path == '/tune' && req.method == 'GET') {
      req.response.headers.contentType = ContentType.json;
      req.response.write(jsonEncode(AppleMatchTuning.toJson()));
      return;
    } else if (path == '/tune' && req.method == 'POST') {
      final Object? body = jsonDecode(await utf8.decodeStream(req));
      if (body is Map<String, Object?>) AppleMatchTuning.apply(body);
    } else if (path == '/tune/reset' && req.method == 'POST') {
      AppleMatchTuning.reset();
    } else {
      req.response.statusCode = HttpStatus.notFound;
      return;
    }
    await SchedulerBinding.instance.endOfFrame;
    await SchedulerBinding.instance.endOfFrame;
    req.response.write('ok');
  }

  @override
  Widget build(BuildContext context) {
    final WidgetBuilder? scene = kScenes[_scene];
    if (scene != null) {
      return Scaffold(
        body: AppleMatchTuningScope(
          child: KeyedSubtree(
            key: ValueKey(_scene),
            child: Builder(builder: scene),
          ),
        ),
      );
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
