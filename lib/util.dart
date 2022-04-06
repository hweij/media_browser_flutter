import 'dart:collection';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as imglib;

const thumbsDirName = '.media_info';
const infoFileName = '_info.txt';

final extensions = Set<String>.from({'.png', '.jpg', '.jpeg', '.webp'});

final thumbEncoder = imglib.PngEncoder(filter: imglib.PngEncoder.FILTER_SUB);

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
  bool registered;
  bool exists;

  MediaDescriptor({
    required this.name,
    required this.size,
    required this.time,
    required this.registered,
    this.exists = false,
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
        tags: fields[3].split('|'),
        registered: true);
  }
}

class MediaCollectionInfo {
  String dirPath;
  List<MediaDescriptor> images;
  final List<String> subdirectories;

  MediaCollectionInfo(
      {required this.dirPath,
      required this.images,
      required this.subdirectories});
}

/// Get a list of media descriptors for the given directory.
/// this list contains all files found, merged with the files specified in the
/// media_info folder. For each item, it is indicated whether the item file
/// exists, and whether it is present in the index list.
Future<void> getMediaInfo2(MediaCollectionInfo mediaCollectionInfo) async {
  // Create a map to quickly look up image file names
  final Map<String, MediaDescriptor> descMap = HashMap();

  // Step 1: get media info from media-info folder
  final infoPath =
      path.join(mediaCollectionInfo.dirPath, thumbsDirName, infoFileName);
  final infoFile = File(infoPath);
  if (await infoFile.exists()) {
    final lines = await infoFile.readAsLines();
    for (var line in lines) {
      if (line.isNotEmpty) {
        final md = MediaDescriptor.parse(line);
        mediaCollectionInfo.images.add(md);
        descMap[md.name] = md;
      }
    }
  }

  // Step 2: merge with media info from actual files
  final dir = Directory(mediaCollectionInfo.dirPath);
  await for (var entry in dir.list()) {
    final baseName = path.basename(entry.path);
    // Ignore image info directory
    if (baseName != thumbsDirName) {
      // Check if it has been registered
      final md = descMap[baseName];
      if (md != null) {
        // Mark file exists
        md.exists = true;
      } else {
        // file has not been registered, or it is a directory/non-image file
        final entry = File(path.join(mediaCollectionInfo.dirPath, baseName));
        final stat = await entry.stat();
        if (stat.type == FileSystemEntityType.directory) {
          // Directory: no need to register, but include it in the directories
          mediaCollectionInfo.subdirectories.add(baseName);
        } else {
          // It's an image file
          if (extensions.contains(path.extension(entry.path).toLowerCase())) {
            // Image file: register it
            final md = MediaDescriptor(
                name: baseName,
                size: stat.size,
                time: stat.modified,
                registered: false,
                exists: true);
            mediaCollectionInfo.images.add(md);
          }
          // If not an image file: ignore
        }
      }
    }
  }
}

Future<int> updateMediaThumbs(MediaCollectionInfo mci) async {
  int numUpdates = 0;
  for (final entry in mci.images) {
    if (!entry.registered) {
      // Not registered yet: generate thumb
      await _generateThumb(path.join(mci.dirPath, entry.name));
      // Mark as registered
      entry.registered = true;
      numUpdates++;
    }
  }
  return numUpdates;
}

Future<void> writeMediaInfo(MediaCollectionInfo mci) async {
  // Update registry: write file
  // Write media descriptors to media info
  final thumbsDirPath = path.join(mci.dirPath, thumbsDirName);
  final mdPath = path.join(thumbsDirPath, infoFileName);
  await File(mdPath).writeAsString(mci.images
      .where((entry) => entry.exists)
      .map((d) => d.toString())
      .join('\n'));
}

Future<void> _generateThumb(String imagePath) async {
  final dirPath = path.dirname(imagePath);
  final thumbsDirPath = path.join(dirPath, thumbsDirName);

  final imageFile = File(imagePath);
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
  final thumbImagePath = path.join(
      thumbsDirPath, '_' + path.basenameWithoutExtension(imagePath) + '.png');
  await File(thumbImagePath).writeAsBytes(thumbEncoder.encodeImage(thumbImage));
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
