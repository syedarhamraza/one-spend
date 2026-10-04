import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Custom logo images (subscriptions' `logoUrl`), downloaded once and kept on disk.
///
/// Every icon of a logo shares one decoded image, whatever its size or zoom, so
/// resizing or zooming never refetches, screens don't flash the fallback icon while
/// each size loads separately, and logos show instantly after a restart.
class LogoImageCache {
  const LogoImageCache._();

  /// Decode width for large icons: sharp at the largest icon (the 200 dp editor)
  /// zoomed in, without holding full-size originals in memory.
  static const int decodeWidth = 768;

  /// Decode width for list-sized icons (up to [smallIconMaxSize] dp). The logo fills
  /// about 68% of the icon, so a 48 dp icon at 3x density and the editor's 4x zoom
  /// needs ~392 px; 384 keeps it sharp at a quarter of the 768 px decode's memory
  /// (~0.6 MB instead of ~2.4 MB per logo).
  static const int smallDecodeWidth = 384;
  static const double smallIconMaxSize = 48;

  /// The decode width for an icon [size] dp wide.
  static int decodeWidthFor(double size) => size <= smallIconMaxSize ? smallDecodeWidth : decodeWidth;

  /// The image provider for [url] shown in an icon [size] dp wide. Icons of the same
  /// size class share one decode; the downloaded file is shared by all of them.
  static ImageProvider provider(String url, {double size = double.infinity}) =>
      ResizeImage(LogoImage(url), width: decodeWidthFor(size), policy: ResizeImagePolicy.fit, allowUpscaling: false);

  /// Overrides the cache folder (tests). Null uses the app support directory.
  @visibleForTesting
  static Future<Directory?> Function()? debugDirectory;

  static Future<Directory?>? _dir;

  /// Forgets the resolved cache folder (tests).
  @visibleForTesting
  static void debugReset() => _dir = null;

  static Future<Directory?> _directory() => _dir ??= () async {
        try {
          final base = debugDirectory != null ? await debugDirectory!() : await getApplicationSupportDirectory();
          if (base == null) return null;
          final dir = Directory(p.join(base.path, 'logo_cache'));
          if (!dir.existsSync()) await dir.create(recursive: true);
          return dir;
        } catch (_) {
          return null; // no disk cache (e.g. widget tests): memory cache only
        }
      }();

  /// File name for [url], the same on every run: two independent 32-bit hashes
  /// (FNV-1a and djb2) of the URL, in hex. (`String.hashCode` isn't stable across runs.)
  static String fileNameFor(String url) {
    var fnv = 0x811c9dc5;
    var djb = 5381;
    for (final b in utf8.encode(url)) {
      fnv = ((fnv ^ b) * 0x01000193) & 0xFFFFFFFF;
      djb = ((djb * 33) + b) & 0xFFFFFFFF;
    }
    return '${fnv.toRadixString(16).padLeft(8, '0')}${djb.toRadixString(16).padLeft(8, '0')}';
  }

  /// Bytes for [url]: from disk if cached, otherwise downloaded and saved.
  static Future<Uint8List> load(String url) async {
    final dir = await _directory();
    final file = dir == null ? null : File(p.join(dir.path, fileNameFor(url)));
    if (file != null && file.existsSync()) {
      final cached = await file.readAsBytes();
      if (cached.isNotEmpty) return cached;
    }
    final bytes = await _download(url);
    if (file != null) unawaited(file.writeAsBytes(bytes, flush: true).catchError((Object _) => file));
    return bytes;
  }

  static Future<Uint8List> _download(String url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw NetworkImageLoadException(statusCode: response.statusCode, uri: Uri.parse(url));
      }
      final bytes = await consolidateHttpClientResponseBytes(response);
      if (bytes.isEmpty) throw StateError('Empty logo image: $url');
      return bytes;
    } finally {
      client.close();
    }
  }

  /// Removes every cached logo file (e.g. from a "clear cache" option).
  static Future<void> clear() async {
    final dir = await _directory();
    if (dir != null && dir.existsSync()) await dir.delete(recursive: true);
    _dir = null;
  }
}

/// [ImageProvider] for a logo URL backed by [LogoImageCache]. Equal by URL, so
/// Flutter's image cache shares one decode between every icon of the logo.
@immutable
class LogoImage extends ImageProvider<LogoImage> {
  final String url;

  const LogoImage(this.url);

  @override
  Future<LogoImage> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(LogoImage key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _load(decode),
      scale: 1.0,
      debugLabel: url,
      informationCollector: () => [DiagnosticsProperty<String>('URL', url)],
    );
  }

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final bytes = await LogoImageCache.load(url);
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) => other is LogoImage && other.url == url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => 'LogoImage("$url")';
}
