import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress_lite/flutter_image_compress_lite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Outcome of a pick+compress attempt — success carries the final file,
/// every failure mode is named instead of thrown, so the calling widget
/// can show the right message without a try/catch ladder at the call site.
sealed class PhotoPickResult {
  const PhotoPickResult();
}

class PhotoPickSuccess extends PhotoPickResult {
  const PhotoPickSuccess(this.file);
  final File file;
}

/// User backed out of the picker (camera/gallery dialog dismissed) —
/// not an error, the calling code should just do nothing.
class PhotoPickCancelled extends PhotoPickResult {
  const PhotoPickCancelled();
}

class PhotoPickFailure extends PhotoPickResult {
  const PhotoPickFailure(this.message);
  final String message;
}

/// Single entry point for "let the user pick a profile photo".
///
/// Owns three concerns that would otherwise be duplicated on every page
/// that needs a photo picker (profile setup, business logo upload later,
/// chat image attachments later): sourcing the image, compressing it off
/// the UI thread, and caching the compressed result to a stable app
/// directory so re-reading it (e.g. on hot restart during dev, or a
/// second preview elsewhere in the same flow) doesn't require re-picking.
abstract final class PhotoPickerService {
  static final ImagePicker _picker = ImagePicker();

  /// Compression targets tuned for a profile photo specifically — not a
  /// general-purpose image util. A business logo or chat attachment
  /// later should get its own constants, not reuse these blindly.
  static const int _maxDimension = 1024; // px, long edge
  static const int _jpegQuality = 82; // visually lossless at this size

  /// Call this from an icon's onTap. Shows the platform photo-source
  /// sheet, then compresses in a background isolate before returning.
  ///
  /// Returns a typed result instead of throwing — callers pattern-match
  /// on the sealed class rather than wrapping this in try/catch.
  static Future<PhotoPickResult> pick({
    ImageSource source = ImageSource.gallery,
  }) async {
    final XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        // Hint only — see the file-level note on why
        // flutter_image_compress still runs afterward regardless.
        maxWidth: _maxDimension.toDouble(),
        imageQuality: _jpegQuality,
      );
    } catch (e) {
      // Covers permission-denial exceptions on both platforms — the
      // picker throws a PlatformException when camera/photos access
      // is refused, rather than returning null like a plain cancel.
      return PhotoPickFailure(_mapPickException(e));
    }

    if (picked == null) {
      return const PhotoPickCancelled();
    }

    try {
      final compressed = await _compressAndCache(File(picked.path));
      return PhotoPickSuccess(compressed);
    } catch (e, stack) {
      debugPrint('PhotoPickerService: compression failed → $e\n$stack');
      return const PhotoPickFailure(
        'Could not process that image. Please try a different photo.',
      );
    }
  }

  /// Compresses off the UI thread and writes to the app's cache
  /// directory under a stable, collision-free filename.
  ///
  /// Using the CACHE directory (not documents/support) is deliberate:
  /// this is a derived artifact the OS is free to reclaim under storage
  /// pressure — the source of truth is whatever the user re-picks or
  /// what's already been uploaded to the server, never this local file.
  static Future<File> _compressAndCache(File source) async {
    final cacheDir = await getTemporaryDirectory();
    final targetPath =
        '${cacheDir.path}/profile_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';

    // Runs on a native background thread inside the plugin itself (not
    // the Dart isolate) — the UI never blocks during re-encoding, which
    // matters for a multi-megapixel phone camera photo.
    final XFile? result = await FlutterImageCompress.compressAndGetFile(
      source.path,
      targetPath,
      quality: _jpegQuality,
      minWidth: _maxDimension,
      minHeight: _maxDimension,
      format: CompressFormat.jpeg,
    );

    if (result == null) {
      throw StateError('Compression produced no output file');
    }

    return File(result.path);
  }

  static String _mapPickException(Object e) {
    final message = e.toString().toLowerCase();
    if (message.contains('permission') || message.contains('denied')) {
      return 'Photo access was denied. Enable it in Settings to '
          'choose a profile picture.';
    }
    return 'Could not open the photo picker. Please try again.';
  }
}