import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'bkclient_flutter_method_channel.dart';

abstract class BkclientFlutterPlatform extends PlatformInterface {
  /// Constructs a BkclientFlutterPlatform.
  BkclientFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static BkclientFlutterPlatform _instance = MethodChannelBkclientFlutter();

  /// The default instance of [BkclientFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelBkclientFlutter].
  static BkclientFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [BkclientFlutterPlatform] when
  /// they register themselves.
  static set instance(BkclientFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
