import 'package:bkclient_flutter/request/base_model.dart';
import 'package:bkclient_flutter/request/bk_constants.dart';
import 'package:bkclient_flutter/request/debug.dart';
import 'package:bkclient_flutter/request/http_request.dart';
import 'package:bkclient_flutter/request/link.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

abstract class PullProxy<M extends JSONModel> {
  Map<String, dynamic> _baseJSON;
  int _trigger;
  int? offset;
  int _range;
  Link _decorator;
  int _ticketId = 0;
  LinkNotifier<PullLink>? _notifier;
  Function(int start, int size)? _callback;
  GlobalKey<ScaffoldState>? _state;
  bool _requesting = false;
  Http http;
  List<M> _pool = List.empty(growable: true);

  PullProxy(this._baseJSON, this._decorator, this.http,
      {LinkNotifier<PullLink>? notifier,
        Function(int start, int size)? callback,
        this.offset,
        int range = 15,
        int trigger = 3,
        GlobalKey<ScaffoldState>? state})
      : this._notifier = notifier,
        this._callback = callback,
        this._range = range,
        this._trigger = trigger,
        this._state = state {
    if (notifier == null) this._notifier = LinkNotifier<PullLink>.empty();
    _requestAsync();
  }

  M modelBuilder();

  M get(int i) {
    if (i + _trigger >= _pool.length) _requestAsync();
    return _pool.elementAt(i);
  }

  get length => _pool.length;

  _requestAsync() {
    Future.value().then((_) => _request());
  }

  reset({Map<String, dynamic>? baseJSON}) {
    _ticketId++;
    _pool.clear();
    if (baseJSON != null)
      _baseJSON = baseJSON;
    offset = null;
    _requesting = false;
    _requestAsync();
  }

  _request() {
    if (_requesting) return;
    _requesting = true;
    _notifier!.link = PullLink(_ticketId, _decorator, _baseJSON,
        offset: offset, range: _range);

    http.syncPost(_notifier!, globalKey: _state).then((netResult) {
      if (!netResult.success) return;
      if (netResult.link!.ticketId != _ticketId) return;
      if (!netResult.link!._result!) {
        Debug.debugging("PullProxy", "result false error");
        return;
      }
      pushModel(_notifier!.link!.limitArray!);
      offset = _notifier!.link!.returnOffset;

      if (_notifier!.link!.limitArray!.length > 0)
        _requesting = false;
      _notifier!.state = LinkState.ready;
      _notifier!.notify();
    });
  }

  pushModel(List<dynamic> array) {
    int start = _pool.length;
    int size = 0;
    array.forEach((json) {
      M m = modelBuilder();
      m.fromJSON(json);
      _pool.add(m);
      size++;
    });
    if (_callback != null && size > 0) _callback!(start, size);
  }
}

class PullLink extends Link {
  Map<String, dynamic> _baseJSON;
  Link _decorator;
  bool? _result = false;
  int? _range, _offset;
  int? returnOffset;
  int ticketId;
  List<dynamic>? limitArray;

  PullLink(this.ticketId, this._decorator, this._baseJSON,
      {int? offset, int range = 15})
      : this._offset = offset,
        this._range = range;

  @override
  Map<String, dynamic> getSendJSON() {
    Map<String, dynamic> map = _decorator.getSendJSON();
    map.addAll(_baseJSON);
    if (_offset != null) map[BKConstants.LIMIT_OFFSET] = _offset;
    map[BKConstants.LIMIT_RANGE] = _range;
    return map;
  }

  @override
  void receiveJSON(Map<String, dynamic> map) {
    _decorator.receiveJSON(map);
    _result = map[BKConstants.BK_WORKING_RESULT];
    returnOffset = map[BKConstants.LIMIT_OFFSET];
    limitArray = map[BKConstants.LIMIT_ARRAY];
  }
}
