import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:plugin_demo/plugin_demo.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _pluginDemoPlugin = PluginDemo();
  String _sum = '';
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await _pluginDemoPlugin.getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: [
            Text('Running on: $_platformVersion\n'),
            ElevatedButton(
                onPressed: () async {
                  try {
                    await _pluginDemoPlugin.getNativeAlert();
                  } on PlatformException {}
                },
                child: const Text("Show native alert")),
            Text(_sum),
            ElevatedButton(
                onPressed: () async {
                  _pluginDemoPlugin.streamDemo().listen((event) {
                    setState(() {
                      _sum = event;
                    });
                  });
                },
                child: const Text("Get sum")),
            if(_isLoading)
              const CircularProgressIndicator()
          ],
        ),
      ),
    );
  }
}
