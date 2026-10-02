import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/utils/logo_image_cache.dart';

// No TestWidgetsFlutterBinding here: it would replace HttpClient with a mock that
// answers 400, and these tests talk to a real local server.
void main() {
  late HttpServer server;
  late Directory dir;
  var requests = 0;
  final png = Uint8List.fromList(List.generate(64, (i) => i));

  setUp(() async {
    requests = 0;
    dir = Directory.systemTemp.createTempSync('logo_cache_test');
    LogoImageCache.debugReset();
    LogoImageCache.debugDirectory = () async => dir;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) {
      requests++;
      if (req.uri.path == '/missing.png') {
        req.response.statusCode = 404;
      } else {
        req.response.add(png);
      }
      req.response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
    LogoImageCache.debugDirectory = null;
    LogoImageCache.debugReset();
    dir.deleteSync(recursive: true);
  });

  String url(String path) => 'http://${server.address.address}:${server.port}$path';

  test('downloads a logo once, then serves it from disk', () async {
    final first = await LogoImageCache.load(url('/logo.png'));
    await Future<void>.delayed(const Duration(milliseconds: 50)); // let the file write finish
    final second = await LogoImageCache.load(url('/logo.png'));
    expect(first, png);
    expect(second, png);
    expect(requests, 1);
  });

  test('a cached logo loads with the network gone (e.g. after a restart offline)', () async {
    final logo = url('/logo.png');
    await LogoImageCache.load(logo);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await server.close(force: true);
    LogoImageCache.debugReset(); // as on a fresh app start
    expect(await LogoImageCache.load(logo), png);
  });

  test('a failed download throws and caches nothing', () async {
    await expectLater(LogoImageCache.load(url('/missing.png')), throwsA(isA<Exception>()));
    expect(dir.listSync(recursive: true).whereType<File>(), isEmpty);
  });

  test('file names are stable and differ per URL', () {
    expect(LogoImageCache.fileNameFor('https://a.com/x.png'), LogoImageCache.fileNameFor('https://a.com/x.png'));
    expect(LogoImageCache.fileNameFor('https://a.com/x.png'), isNot(LogoImageCache.fileNameFor('https://a.com/y.png')));
    expect(LogoImageCache.fileNameFor('https://a.com/x.png'), hasLength(16));
  });

  test('one provider per URL, so every icon size and zoom shares one decode', () {
    expect(LogoImageCache.provider('https://a.com/x.png'), LogoImageCache.provider('https://a.com/x.png'));
  });
}
