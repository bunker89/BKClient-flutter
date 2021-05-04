import 'package:flutter/material.dart';

enum LinkState { ready, progress, done, error, finish }

class LinkNotifier<L extends Link> with ChangeNotifier {
  LinkState _state = LinkState.ready;
  L? link;

  LinkNotifier(this.link);

  LinkNotifier.empty() : this(null);

  set state(state) {
    this._state = state;
    notifyListeners();
  }

  LinkState get state {
    return _state;
  }

  void setStateDelayCallback(
      {required LinkState state, Duration? duration, Function()? callback}) {
    this.state = state;
    if (duration != null && callback != null) {
      Future.delayed(duration).then((_) => callback());
    }
  }

  void setStateDelayToOrigin(
      {required LinkState state, Duration? duration, Function()? callback}) {
    LinkState past = this.state;
    this.state = state;
    if (duration != null) {
      Future.delayed(duration).then((_) => this.state = past);
    }
  }

  receive(Map<String, dynamic> json) {
    link!.receiveJSON(json);
  }

  void notify() {
    notifyListeners();
  }
}

abstract class Link {
  void receiveJSON(Map<String, dynamic> map);

  Map<String, dynamic> getSendJSON();
}
