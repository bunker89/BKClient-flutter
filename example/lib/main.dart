import 'dart:io';

import 'package:bkclient_flutter/request/http_request.dart';
import 'package:bkclient_flutter/request/link.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class TestLink extends Link {
  @override
  Map<String, dynamic> getSendJSON() {
    return {};
  }

  @override
  void receiveJSON(Map<String, dynamic> map) {}
}

class _MyAppState extends State<MyApp> {
  static const String serverBaseAddr = "http://192.168.75.153:8080/apigate-resource";

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<File> getImageFileFromAssets(String path) async {
    final byteData = await rootBundle.load('assets/$path');

    final file = File('${(await getTemporaryDirectory()).path}/$path');
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

    return file;
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    TestLink link = TestLink();

    Http(serverBaseAddr).linkPostRequestWithFile(link,
        files: [await getImageFileFromAssets("test.png")]);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(),
      ),
    );
  }
}
