import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bkclient_flutter/bkclient_flutter.dart';

void main() {
  const MethodChannel channel = MethodChannel('bkclient_flutter');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await BkclientFlutter.platformVersion, '42');
  });
}
