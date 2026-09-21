import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_modest/core/widgets/avatar_circle.dart';

import '../../helpers/pump_app.dart';

/// **There are two ways a picture can be absent, and only one of them was
/// tested.**
///
/// `avatar_circle_test.dart` covers the first: a link that fails. In
/// `flutter_test` every network image fails at once, so that test lands in
/// `errorBuilder` and duly finds the letter.
///
/// This file covers the second: a link that has not arrived **yet**. Reaching
/// it needs a provider that is *slow* rather than *broken* — and with the
/// original `loadingBuilder` the circle was empty for that whole window, on a
/// real device for as long as the download took (measured on the emulator,
/// 2026-09-21).
///
/// Every network image added to this app from here on gets both.
void main() {
  late StreamController<List<int>> body;

  /// Installs the slow provider for one test and takes it back down **inside
  /// the test body**: the framework checks that painting's debug variables are
  /// unset the moment the body returns, which is before any `tearDown` runs.
  ///
  /// `debugNetworkImageHttpClientProvider`, not `HttpOverrides`: `NetworkImage`
  /// builds one `HttpClient` per process and keeps it in a static, so whichever
  /// override was current when the *first* image in the suite loaded is the one
  /// that sticks — injection would depend on test order. This hook is read on
  /// every load, and exists for exactly this.
  Future<void> withSlowNetwork(Future<void> Function() run) async {
    body = StreamController<List<int>>();
    debugNetworkImageHttpClientProvider = () => _FakeHttpClient(body.stream);
    try {
      await run();
    } finally {
      debugNetworkImageHttpClientProvider = null;
      if (!body.isClosed) await body.close();
    }
  }

  testWidgets('the letter stands in while the picture is still downloading', (
    tester,
  ) async {
    await withSlowNetwork(() async {
      await tester.pumpApp(
        const AvatarCircle(
          imageUrl: 'https://example.invalid/avatars/u1/avatar',
          displayName: 'سارة',
        ),
      );
      // One frame, with the request open and not a byte delivered.
      await tester.pump();

      // The regression this file exists for: `loadingBuilder` is handed a null
      // progress until the first chunk arrives, and reading that null as
      // "loaded" hands back a RawImage holding no image — a blank disc where
      // her initial should be.
      expect(find.text('س'), findsOneWidget);
    });
  });

  testWidgets('and steps aside the moment there is a frame to paint', (
    tester,
  ) async {
    await withSlowNetwork(() async {
      await tester.pumpApp(
        const AvatarCircle(
          imageUrl: 'https://example.invalid/avatars/u1/avatar',
          displayName: 'سارة',
        ),
      );
      await tester.pump();

      // **The other half of the branch, pinned at the builder.** Driving a
      // real decode to completion was tried and does not work here: the codec
      // is an engine call, and a load started under the fake clock posts its
      // continuation to a zone that never runs, so the image hangs instead of
      // arriving. The end-to-end evidence is the emulator run of 2026-09-21,
      // where the uploaded photograph replaced the letter — in the form, in
      // the account header, and again after a cold start.
      final image = tester.widget<Image>(find.byType(Image));
      final context = tester.element(find.byType(Image));
      const decoded = SizedBox(key: Key('a-decoded-frame'));

      expect(
        image.frameBuilder!(context, decoded, 0, false),
        same(decoded),
        reason: 'a frame exists, so the picture is what gets painted',
      );
      expect(
        image.frameBuilder!(context, decoded, null, false),
        isNot(same(decoded)),
        reason: 'no frame yet, so the letter holds the place',
      );
    });
  });
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
