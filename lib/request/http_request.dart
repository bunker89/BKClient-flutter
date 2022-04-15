import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bkclient_flutter/request/debug.dart';
import 'package:bkclient_flutter/request/bk_constants.dart';
import 'package:bkclient_flutter/request/link.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

/// result is network result not meaning api result
class RequestResult<T extends Link?> {
  bool success;
  bool result;
  T link;

  RequestResult(this.success, this.link, {this.result = false});
}

class Http {
  final String serverUrl;

  Http(this.serverUrl);

  Future<RequestResult<L?>> syncPost<L extends Link>(LinkNotifier<L> notifier,
      {GlobalKey<ScaffoldState>? globalKey, Function()? errorCallback}) {
    if (notifier.state != LinkState.ready)
      return Future.value(RequestResult(false, notifier.link));
    notifier.state = LinkState.progress;
    return postRequest(notifier,
        readyLock: false, globalKey: globalKey, errorCallback: errorCallback);
  }

  Future<RequestResult<L?>> postRequest<L extends Link>(
      LinkNotifier<L>? notifier,
      {GlobalKey<ScaffoldState>? globalKey,
      Function()? errorCallback,
      readyLock = true}) async {
    if (readyLock) {
      if (notifier!.state != LinkState.ready)
        return RequestResult(false, notifier.link);
      notifier.state = LinkState.progress;
    }
    http.Response response;
    try {
      response = await http
          .post(Uri.parse(serverUrl),
              body: jsonEncode(notifier!.link!.getSendJSON()))
          .timeout(Duration(seconds: 7));
    } on Exception catch (e) {
      Debug.debugging(
          "HttpPost", "http request timeout $e, by ${notifier!.link}");
      _showNetErrSnackBar(globalKey);
      if (errorCallback != null) errorCallback();
      notifier.state = LinkState.ready;
      return RequestResult(false, notifier.link);
    }

    if (response.statusCode == 200) {
      try {
        var json = jsonDecode(response.body);
        notifier.receive(json);
        return RequestResult(true, notifier.link,
            result: json[BKConstants.BK_WORKING_RESULT]);
      } catch (e, stack) {
        String errorMessage =
            "HttpRequest receive error, error message:$e, response body:${response.body}"
            " link${notifier.link}";
        Debug.debugging("HttpRequest", errorMessage);
        Debug.debugging("HttpRequest", stack.toString());
        _showNetErrSnackBar(globalKey);
      }
    } else {
      _showNetErrSnackBar(globalKey);
      notifier.state = LinkState.ready;
      Debug.debugging("HttpPost", "network error");
    }
    return RequestResult(false, notifier.link);
  }

  Future<RequestResult<T>> linkPostRequest<T extends Link>(T link,
      {GlobalKey<ScaffoldState>? globalKey,
      Function()? errorCallback,
      int timeout = 7}) async {
    http.Response response;
    try {
      response = await http
          .post(Uri.parse(serverUrl), body: jsonEncode(link.getSendJSON()))
          .timeout(Duration(seconds: timeout));
    } on Exception catch (e) {
      Debug.debugging("HttpPost", "http request timeout $e");
      _showNetErrSnackBar(globalKey);
      if (errorCallback != null) errorCallback();
      return RequestResult(false, link);
    }

    if (response.statusCode == 200) {
      try {
        var json = jsonDecode(response.body);
        link.receiveJSON(json);
        return RequestResult(true, link,
            result: json[BKConstants.BK_WORKING_RESULT]);
      } catch (e, stack) {
        String errorMessage =
            "HttpRequest receive error, error message:$e, response body:${response.body}"
            " link$link";
        Debug.debugging("HttpRequest", errorMessage);
        Debug.debugging("HttpRequest", stack.toString());
        _showNetErrSnackBar(globalKey);
      }
    } else {
      _showNetErrSnackBar(globalKey);
      Debug.debugging("HttpRequest", "network error");
    }
    return RequestResult(false, link);
  }

  Future<RequestResult<T>> linkPostRequestWithFile<T extends Link>(T link,
      {GlobalKey<ScaffoldState>? globalKey,
      Function()? errorCallback,
      int timeout = 7,
      String fileFiled = "files",
      String dataField = "json",
      List<File>? files}) async {
    http.StreamedResponse response;
    try {
      MultipartRequest request = new http.MultipartRequest('POST', Uri.parse(serverUrl));
      request.fields[dataField] = jsonEncode(link.getSendJSON());

      if (files != null) {
        for (File file in files) {
          request.files.add(
              await http.MultipartFile.fromPath(fileFiled, file.path));
        }
      }

      response = await request.send();
    } on Exception catch (e) {
      Debug.debugging("HttpPost", "http request timeout $e");
      _showNetErrSnackBar(globalKey);
      if (errorCallback != null) errorCallback();
      return RequestResult(false, link);
    }

    if (response.statusCode == 200) {
      String bodyString = await response.stream.bytesToString();
      try {
        var json = jsonDecode(bodyString);
        link.receiveJSON(json);
        return RequestResult(true, link,
            result: json[BKConstants.BK_WORKING_RESULT]);
      } catch (e, stack) {
        String errorMessage =
            "HttpRequest receive error, error message:$e, response body:$bodyString"
            " link$link";
        Debug.debugging("HttpRequest", errorMessage);
        Debug.debugging("HttpRequest", stack.toString());
        _showNetErrSnackBar(globalKey);
      }
    } else {
      _showNetErrSnackBar(globalKey);
      Debug.debugging("HttpRequest", "network error");
    }
    return RequestResult(false, link);
  }

  void _showNetErrSnackBar(GlobalKey<ScaffoldState>? globalKey) {
    if (globalKey != null)
      ScaffoldMessenger.of(globalKey.currentContext!).showSnackBar(new SnackBar(
        duration: Duration(seconds: 2),
        content: new Text("서버 연결이 원할하지 않습니다."),
      ));
  }
}
