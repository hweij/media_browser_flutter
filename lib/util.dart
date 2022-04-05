import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as imglib;

const thumbsDirName = '.media_info';

final extensions = Set<String>.from({'.png', '.jpg', '.jpeg', '.webp'});

/// Updates the media info (thumbs, index) for the given directory.
Future<List<String>> updateMediaInfo(String dirPath,
    {final void Function(String)? onProgress}) async {
// Scan all files in the directory
  final dir = Directory(dirPath);

  final thumbsDirPath = path.join(dirPath, thumbsDirName);
  final thumbsDir = Directory(thumbsDirPath);
  // Create thumbs dir if it doesn't exist yet
  if (!(await thumbsDir.exists())) {
    await (thumbsDir.create());
  }

  // Process file entries
  List<String> thumbPaths = [];
  await for (var entry in dir.list()) {
    // final stat = await entry.stat();
    // final fileSize = stat.size;
    final entryPath = entry.path;
    if (extensions.contains(path.extension(entryPath).toLowerCase())) {
      if (onProgress != null) {
        onProgress(entryPath);
      }
      final imageFile = File(entryPath);
      final image = imglib.decodeImage(imageFile.readAsBytesSync())!;

      int? w;
      int? h;
      if (image.width >= image.height) {
        w = 128;
      } else {
        h = 128;
      }

      // Resize the image to a max 128x128 thumbnail (maintaining the aspect ratio).
      final thumbImage = imglib.copyResize(image, width: w, height: h);

      // Save thumbnail
      final thumbImagePath = path.join(thumbsDirPath,
          '_' + path.basenameWithoutExtension(entryPath) + '.png');
      await File(thumbImagePath).writeAsBytes(imglib.encodePng(thumbImage));
      thumbPaths.add(thumbImagePath);
    }
  }

  return thumbPaths;
}
