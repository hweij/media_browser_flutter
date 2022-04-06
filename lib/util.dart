import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as imglib;

const thumbsDirName = '.media_info';
const infoFileName = '_info.txt';

final extensions = Set<String>.from({'.png', '.jpg', '.jpeg', '.webp'});

String formatDateTime(DateTime dt) {
  return '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';
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
  final DateTime time;

  const MediaDescriptor({
    required this.name,
    required this.size,
    required this.time,
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

class MediaCollectionInfo {
  final List<MediaDescriptor> images;
  final List<String> subdirectories;

  MediaCollectionInfo({required this.images, required this.subdirectories});
}

/// Updates the media info (thumbs, index) for the given directory.
Future<MediaCollectionInfo> updateMediaInfo(String dirPath,
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
  List<String> subDirectories = [];
  List<String> thumbPaths = [];
  List<MediaDescriptor> mediaDescriptors = [];
  var encoder = imglib.PngEncoder(filter: imglib.PngEncoder.FILTER_SUB);
  await for (var entry in dir.list()) {
    final baseName = path.basename(entry.path);
    if ((await entry.stat()).type == FileSystemEntityType.directory) {
      if (baseName != thumbsDirName) {
        subDirectories.add(baseName);
      }
    } else {
      if (extensions.contains(path.extension(entry.path).toLowerCase())) {
        if (onProgress != null) {
          onProgress(entry.path);
        }
        final imageFile = File(entry.path);
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
            '_' + path.basenameWithoutExtension(entry.path) + '.png');
        await File(thumbImagePath)
            .writeAsBytes(encoder.encodeImage(thumbImage));
        thumbPaths.add(thumbImagePath);
        // Collect stats and create media descriptor
        final stat = await entry.stat();
        final desc = MediaDescriptor(
            name: baseName, size: stat.size, time: stat.modified, tags: []);
        mediaDescriptors.add(desc);
      }
    }

    // Write media descriptors to media info
    final mdPath = path.join(thumbsDirPath, infoFileName);
    await File(mdPath)
        .writeAsString(mediaDescriptors.map((d) => d.toString()).join('\n'));
  }
  return MediaCollectionInfo(
      images: mediaDescriptors, subdirectories: subDirectories);
}

/// Get a list of media descriptors for the given directory.
/// If no list exists, null will be returned.
Future<MediaCollectionInfo?> getMediaInfo(String dir) async {
  final mdPath = path.join(dir, thumbsDirName, infoFileName);
  final mdFile = File(mdPath);
  if (await mdFile.exists()) {
    final List<MediaDescriptor> res = [];
    final lines = await mdFile.readAsLines();
    for (var line in lines) {
      if (line.isNotEmpty) {
        res.add(MediaDescriptor.parse(line));
      }
    }
    return MediaCollectionInfo(
        images: res, subdirectories: await getSubdirectories(dir));
  } else {
    return null;
  }
}

Future<List<String>> getSubdirectories(String dirPath) async {
  final List<String> res = [];
  final dir = Directory(dirPath);
  await for (var entry in dir.list()) {
    final stat = await entry.stat();
    if (stat.type == FileSystemEntityType.directory) {
      final baseName = path.basename(entry.path);
      debugPrint('$baseName==$thumbsDirName');
      if (baseName != thumbsDirName) {
        res.add(path.basename(entry.path));
      }
    }
  }
  return res;
}

String getImagePath(String dir, String img) {
  return path.join(
    dir,
    img,
  );
}

String joinPath(String dir, String fname) {
  return path.join(dir, fname);
}

String parentPath(String fname) {
  return path.dirname(fname);
}

String getThumbPath(String dir, String img) {
  return path.join(
    dir,
    thumbsDirName,
    '_' + path.basenameWithoutExtension(img) + '.png',
  );
}
