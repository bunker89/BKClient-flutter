import 'package:bkclient_flutter/request/base_model.dart';
import 'package:bkclient_flutter/request/bk_constants.dart';
import 'package:bkclient_flutter/request/debug.dart';
import 'package:bkclient_flutter/request/http_request.dart';
import 'package:bkclient_flutter/request/link.dart';
import 'package:flutter/material.dart';

enum Order { desc, asc }
enum PullStrategy {
  countPolicy, offsetPolicy
}

abstract class PullProxy<M extends JSONModel> {
  final List<M> _pool = List.empty(growable: true);
  Map<String, dynamic> _baseJSON;
  final int _trigger;
  int? offset;
  int? baseId;
  final int _range;
  Link? decorator;
  int _ticketId = 0;
  LinkNotifier<PullLink>? _notifier;
  final Function(int start, int size)? _callback;
  final GlobalKey<ScaffoldState>? _state;
  bool _requesting = false;
  Http http;
  Order order;
  PullStrategy strategy;
  late int? Function(RequestResult<PullLink?> netresult) nextOffset;

  PullProxy(this._baseJSON, this.http,
      {LinkNotifier<PullLink>? notifier,
        this.decorator,
        Function(int start, int size)? callback,
        this.order = Order.desc,
        this.offset,
        int range = 15,
        int trigger = 3,
        GlobalKey<ScaffoldState>? state,
        this.strategy = PullStrategy.offsetPolicy,
        bool initRequest = true})
      : _notifier = notifier,
        _callback = callback,
        _range = range,
        _trigger = trigger,
        _state = state {
    if (notifier == null) _notifier = LinkNotifier<PullLink>.empty();
    offset ??= offsetDefault();
    if (strategy == PullStrategy.countPolicy) {
      nextOffset = nextByCount;
    }

    if (initRequest) {
      _request();
    }
  }

  int offsetDefault() => 0;

  M modelBuilder();

  M get(int i, bool autoReload) {
    if (autoReload && i + _trigger >= _pool.length) {
      WidgetsBinding.instance?.addPostFrameCallback((_) {
        _request();
      });
    }
    return _pool.elementAt(i);
  }

  get length {
    return _pool.length;
  }

  reset({Map<String, dynamic>? baseJSON}) async {
    _ticketId++;
    _pool.clear();
    if (baseJSON != null) _baseJSON = baseJSON;
    offset = offsetDefault();
    _requesting = false;
    _notifier!.state = LinkState.ready;

    await _request();
  }

  _request() async {
    if (_requesting) return;
    _requesting = true;
    _notifier!.link = PullLink(_ticketId, decorator, _baseJSON,
        offset: offset, range: _range, baseId: baseId);

    RequestResult<PullLink?> netResult =
    await http.syncPost(_notifier!, globalKey: _state);
    if (!netResult.success) return;
    if (netResult.link!.ticketId != _ticketId) return;
    if (!netResult.link!._result!) {
      Debug.debugging("PullProxy", "result false error");
      return;
    }
    baseId ??= netResult.link!._baseId;
    pushModel(netResult.link!.limitArray!);
    offset = nextOffset(netResult);

    if (_notifier!.link!.limitArray!.isNotEmpty) _requesting = false;
    _notifier!.state = LinkState.ready;
    _notifier!.notify();
  }

  int? nextByOffset(RequestResult<PullLink?> netResult) => netResult.link!.returnOffset;
  int? nextByCount(RequestResult<PullLink?> netResult) => length;

  pushModel(List<dynamic> array) {
    int start = _pool.length;
    int size = 0;
    for (var json in array) {
      M m = modelBuilder();
      m.fromJSON(json);
      _pool.add(m);
      size++;
    }
    if (_callback != null && size > 0) _callback!(start, size);
  }
}

class PullLink extends Link {
  final Map<String, dynamic> _baseJSON;
  Link? decorator;
  bool? _result = false;
  int? _range, _offset, _baseId;
  int? returnOffset;
  int? returnBase;
  int ticketId;
  List<dynamic>? limitArray;

  PullLink(this.ticketId, this.decorator, this._baseJSON,
      {int? offset, int range = 15, int? baseId})
      : _offset = offset,
        _range = range,
        _baseId = baseId;

  @override
  Map<String, dynamic> getSendJSON() {
    Map<String, dynamic> map = decorator?.getSendJSON() ?? {};
    if (_baseId != null) map[BKConstants.LIMIT_BASE] = _baseId;
    if (_offset != null) map[BKConstants.LIMIT_OFFSET] = _offset;
    map[BKConstants.LIMIT_RANGE] = _range;
    map.addAll(_baseJSON);
    return map;
  }

  @override
  void receiveJSON(Map<String, dynamic> map) {
    decorator?.receiveJSON(map);
    _result = map[BKConstants.BK_WORKING_RESULT];
    returnOffset = map[BKConstants.LIMIT_OFFSET];
    returnBase = map[BKConstants.LIMIT_BASE];
    limitArray = map[BKConstants.LIMIT_ARRAY];
  }
}