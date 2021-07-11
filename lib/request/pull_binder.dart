
import 'package:bkclient_flutter/request/base_model.dart';
import 'package:bkclient_flutter/request/link.dart';
import 'package:bkclient_flutter/request/pull_proxy.dart';

class PullBinder <T extends JSONModel> extends LinkNotifier<PullLink> {
  late PullProxy<T> _proxy;

  PullBinder(PullProxy<T> Function(PullBinder<T> binder) builder) : super.empty() {
    _proxy = builder(this);
  }

  T get(i) => _proxy.get(i);

  int get length => _proxy.length;

  reset({Map<String, dynamic>? baseJSON}) => _proxy.reset(baseJSON: baseJSON);
}