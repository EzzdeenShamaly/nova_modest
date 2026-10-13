import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A network image that is **slow rather than broken**.
///
/// In `flutter_test` every network image fails at once, so an ordinary widget
/// test only ever lands in `errorBuilder` — it cannot see the window where the
/// request is open and nothing has arrived. That window is where the blank disc
/// lived (`avatar_circle_loading_test.dart`, 2026-09-21) and where a storefront
/// of white gaps lives.
///
/// Runs [run] with that provider installed and takes it down **inside the test
/// body**: the framework checks that painting's debug variables are unset the
/// moment the body returns, which is before any `tearDown`.
///
/// `debugNetworkImageHttpClientProvider`, not `HttpOverrides`: `NetworkImage`
/// builds one `HttpClient` per process and keeps it in a static, so whichever
/// override was current when the *first* image in the suite loaded is the one
/// that sticks — injection would depend on test order. This hook is read on
/// every load, and exists for exactly this.
Future<void> withSlowNetworkImages(Future<void> Function() run) async {
  final body = StreamController<List<int>>();
  debugNetworkImageHttpClientProvider = () => _FakeHttpClient(body.stream);
  try {
    await run();
  } finally {
    debugNetworkImageHttpClientProvider = null;
    if (!body.isClosed) await body.close();
  }
}

/// Enough of `HttpClient` for `NetworkImage`, and no more: it asks for a URL,
/// closes the request, and reads the response as a stream.
class _FakeHttpClient extends Fake implements HttpClient {
  _FakeHttpClient(this._body);

  final Stream<List<int>> _body;

  @override
  bool autoUncompress = false;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeRequest(_body);
}

class _FakeRequest extends Fake implements HttpClientRequest {
  _FakeRequest(this._body);

  final Stream<List<int>> _body;

  @override
  final HttpHeaders headers = _FakeHeaders();

  @override
  Future<HttpClientResponse> close() async => _FakeResponse(_body);
}

class _FakeResponse extends Fake implements HttpClientResponse {
  _FakeResponse(this._body);

  final Stream<List<int>> _body;

  @override
  int get statusCode => HttpStatus.ok;

  /// Unknown length, which is also what Supabase's storage answers with — and
  /// it is what leaves `loadingProgress` null until bytes actually arrive.
  @override
  int get contentLength => -1;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _body.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
}

class _FakeHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
}
