import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as imglib;

const thumbsDirName = '.media_info';
const infoFileName = '_info.txt';

final extensions = Set<String>.from({'.png', '.jpg', '.jpeg', '.webp'});

String formatDateTime(DateTime? dt) {
  if (dt != null) {
    return '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';
  } else {
    return '';
  }
}

DateTime parseDateTime(String s) {
  return DateTime(
    int.parse(s.substring(0, 4)),
    int.parse(s.substring(4, 6)),
    int.parse(s.substring(6, 8)),
  );
}

class MediaDescriptor {
  final String name;
  final int size;
  final List<String> tags;
  final DateTime? time;

  const MediaDescriptor({
    this.name = '',
    this.size = 0,
    this.time,
    this.tags = const [],
  });

  @override
  String toString() {
    return '$name\t$size\t${formatDateTime(time)}\t${tags.join('|')}';
  }

  static MediaDescriptor parse(String s) {
    final fields = s.split('\t');
    return MediaDescriptor(
        name: fields[0],
        size: int.parse(fields[1]),
        time: parseDateTime(fields[2]),
        tags: fields[3].split('|'));
  }
}

// class MediaInfo {
//   final String dir;
//   final List<MediaDescriptor> media;

//   MediaInfo(this.dir, this.media);
// }

/// Updates the media info (thumbs, index) for the given directory.
Future<List<MediaDescriptor>> updateMediaInfo(String dirPath,
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
  List<MediaDescriptor> mediaDescriptors = [];
  await for (var entry in dir.list()) {
    final stat = await entry.stat();
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
      final desc = MediaDescriptor(
          name: path.basename(entryPath),
          size: stat.size,
          time: stat.modified,
          tags: []);
      mediaDescriptors.add(desc);
      debugPrint(desc.toString());
    }

    // TEST TEST
    final mdPath = path.join(thumbsDirPath, infoFileName);
    await File(mdPath)
        .writeAsString(mediaDescriptors.map((d) => d.toString()).join('\n'));
  }
  return mediaDescriptors;
}

String getThumbPath(String dir, String img) {
  return path.join(
    dir,
    thumbsDirName,
    '_' + path.basenameWithoutExtension(img) + '.png',
  );
}
