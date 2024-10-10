import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:path/path.dart' as p;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class FileUtils {
  static Directory removeDataDirectory(String path) {
    return Directory(path.split('Android')[0]);
  }

  /// Get all files
  static String curDirPath = '';
  static List<FileSystemEntity> curFileList = [];

  static List<FileSystemEntity> getAllFilesInPath(
    List<FileSystemEntity> filesInPaths,
    String path, {
    bool showHidden = false,
    int from = 0,
    int limit = 0,
  }) {
    Directory d = Directory(path);
    List<FileSystemEntity> fileList = d.listSync();
    fileList
        .sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    if (fileList.length == from) {
      Directory curDirParent = Directory(d.parent.path);
      List<String> fileParts = curDirParent.path.split('/');
      if (fileParts.length != 3 && fileParts.last != 'emulated') {
        List<FileSystemEntity> parentFileList = curDirParent.listSync();
        parentFileList.sort(
          (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
        );
        final index = parentFileList.indexWhere((e) => e.path == d.path);
        if (index != -1 && index < parentFileList.length - 1) {
          getAllFilesInPath(
            filesInPaths,
            curDirParent.path,
            from: index + 1,
            limit: limit,
          );
        }
      }
    }

    if (!notBlank(curDirPath) ||
        (curDirPath != path && curDirPath != d.parent.path)) {
      curDirPath = d.path;
      curFileList = fileList;
    }

    for (int i = from; i < fileList.length; i++) {
      FileSystemEntity file = fileList[i];
      final isFile = FileSystemEntity.isFileSync(file.path);
      if (isFile) {
        if (p.basename(file.path).split('.').length > 1) {
          if (!showHidden) {
            if (!file.isHidden) {
              if (limit > 0 && filesInPaths.length < limit) {
                filesInPaths.add(file);
              }
            }
          } else {
            if (limit > 0 && filesInPaths.length < limit) {
              filesInPaths.add(file);
            }
          }
        }
      } else {
        if (!file.path.contains('/storage/emulated/0/Android')) {
          if (!showHidden) {
            if (!file.isHidden) {
              getAllFilesInPath(
                filesInPaths,
                file.path,
                showHidden: showHidden,
                limit: limit,
              );
            }
          } else {
            getAllFilesInPath(
              filesInPaths,
              file.path,
              showHidden: showHidden,
              limit: limit,
            );
          }
        }
      }

      if (limit > 0 && filesInPaths.length >= limit) {
        break;
      }
    }

    if (limit > 0 && filesInPaths.length < limit) {
      final index = curFileList.indexWhere((e) => e.path == d.path);
      if (index > -1) {
        if (index < curFileList.length - 1) {
          FileSystemEntity f = curFileList[index + 1];
          if (FileSystemEntity.isDirectorySync(f.path)) {
            getAllFilesInPath(
              filesInPaths,
              curFileList[index + 1].path,
              from: 0,
              limit: limit,
            );
          } else {
            getAllFilesInPath(
              filesInPaths,
              d.parent.path,
              from: index + 1,
              limit: limit,
            );
          }
        } else {
          FileSystemEntity lastFileParent = curFileList.last.parent;
          Directory parentOfLastFileParent =
              Directory(lastFileParent.parent.path);
          List<String> fileParts = parentOfLastFileParent.path.split('/');
          if (fileParts.length == 3 && fileParts.last == 'emulated') {
            return filesInPaths;
          }
          List<FileSystemEntity> parentFileList =
              parentOfLastFileParent.listSync();
          parentFileList.sort(
            (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
          );
          final index =
              parentFileList.indexWhere((e) => e.path == lastFileParent.path);
          if (index != -1 && index < parentFileList.length - 1) {
            getAllFilesInPath(
              filesInPaths,
              lastFileParent.parent.path,
              from: index + 1,
              limit: limit,
            );
          }
        }
      }
    }

    return filesInPaths;
  }
}

extension FilesExt on FileSystemEntity {
  bool get isHidden => basename(path).startsWith('.');
}

Future<String> getFileSizeWithFormat(File file) async {
  final int sizeByte = await file.length();
  final double sizeKiloByte = sizeByte / 1024;
  final double sizeMegaByte = sizeKiloByte / 1024;
  final double sizeGigaByte = sizeMegaByte / 1024;
  if (sizeKiloByte < 1) {
    return '$sizeByte B';
  } else if (sizeMegaByte < 1) {
    return '${sizeKiloByte.toStringAsFixed(2)} KB';
  } else if (sizeGigaByte < 1) {
    return '${sizeMegaByte.toStringAsFixed(2)} MB';
  } else {
    return '${sizeGigaByte.toStringAsFixed(2)} MB';
  }
}

Future<XFile> saveImageToXFile(Uint8List imageData) async {
  try {
    // Get the temporary directory path
    final directory = await getTemporaryDirectory();
    final filePath =
        '${directory.path}/image_${DateTime.now().millisecondsSinceEpoch}.jpg';

    // Write the compressed data to the file
    await File(filePath).writeAsBytes(imageData);

    // Return the XFile with the file path
    return XFile(filePath);
  } catch (e) {
    pdebug('Error saving image: $e');
    rethrow;
  }
}

String addCounterToPath(String originalPath, int counter) {
  if (counter < 1) {
    return originalPath;
  }

  String baseName = p.basenameWithoutExtension(originalPath);
  String extension = p.extension(originalPath);
  String newPath =
      "${p.dirname(originalPath)}/$baseName ($counter)$extension";
  return newPath;
}
