import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:path/path.dart' as p;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../main.dart';
import 'net/download_mgr.dart';

class FileUtils {
  static String waPath = '/storage/emulated/0/WhatsApp/Media/.Statuses';

  /// Convert Byte to KB, MB, .......
  static String formatBytes(bytes, decimals) {
    if (bytes == 0) return '0.0 KB';
    var k = 1024,
        dm = decimals <= 0 ? 0 : decimals,
        sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'],
        i = (log(bytes) / log(k)).floor();
    return (((bytes / pow(k, i)).toStringAsFixed(dm)) + ' ' + sizes[i]);
  }

  // /// Get mime information of a file
  // static String getMime(String path) {
  //   File file = File(path);
  //   String mimeType = mime(file.path) ?? '';
  //   return mimeType;
  // }

  /// Return all available Storage path
  static Future<List<Directory>> getStorageList() async {
    List<Directory>? paths = await getExternalStorageDirectories();
    List<Directory> filteredPaths = <Directory>[];
    if (paths != null) {
      for (Directory dir in paths) {
        filteredPaths.add(removeDataDirectory(dir.path));
      }
    }
    return filteredPaths;
  }

  static Directory removeDataDirectory(String path) {
    return Directory(path.split('Android')[0]);
  }

  /// Get all Files and Directories in a Directory
  static Future<List<FileSystemEntity>> getFilesInPath(String path) async {
    Directory dir = Directory(path);
    return dir.listSync();
  }

  /// Get all Files on the Device
  // static Future<List<FileSystemEntity>> getAllFiles(
  //     {bool showHidden = false}) async {
  //   List<Directory> storages = await getStorageList();
  //   List<FileSystemEntity> files = <FileSystemEntity>[];
  //   for (Directory dir in storages) {
  //     List<FileSystemEntity> allFilesInPath = [];
  //     try {
  //       allFilesInPath =
  //           await compute(getAllFilesInPath, dir.path); // listSync会阻塞现成，改用并发
  //     } catch (e) {
  //       allFilesInPath = [];
  //       pdebug(e);
  //     }
  //     files.addAll(allFilesInPath);
  //   }
  //
  //   return files;
  // }

  // static Future<List<FileSystemEntity>> getRecentFiles(
  //     {bool showHidden = false}) async {
  //   List<FileSystemEntity> files = await getAllFiles(showHidden: showHidden);
  //   files.sort((a, b) => File(a.path)
  //       .lastModifiedSync()
  //       .compareTo(File(b.path).lastModifiedSync()));
  //   return files.reversed.toList();
  // }

  // static Future<List<FileSystemEntity>> searchFiles(String query,
  //     {bool showHidden = false}) async {
  //   List<Directory> storage = await getStorageList();
  //   List<FileSystemEntity> files = <FileSystemEntity>[];
  //   for (Directory dir in storage) {
  //     List fs =
  //         await compute(getAllFilesInPath, dir.path); // listSync会阻塞现成，改用并发
  //     for (FileSystemEntity fs in fs) {
  //       if (basename(fs.path).toLowerCase().contains(query.toLowerCase())) {
  //         files.add(fs);
  //       }
  //     }
  //   }
  //   return files;
  // }

  /// Get all files
  static String curDirPath = '';
  static List<FileSystemEntity> curFileList = [];

  static List<FileSystemEntity> getAllFilesInPath(
      List<FileSystemEntity> filesInPaths, String path,
      {bool showHidden = false, int from = 0, int limit = 0}) {
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
            (a, b) => b.statSync().modified.compareTo(a.statSync().modified));
        final index = parentFileList.indexWhere((e) => e.path == d.path);
        if (index != -1 && index < parentFileList.length - 1) {
          getAllFilesInPath(filesInPaths, curDirParent.path,
              from: index + 1, limit: limit);
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
              getAllFilesInPath(filesInPaths, file.path,
                  showHidden: showHidden, limit: limit);
            }
          } else {
            getAllFilesInPath(filesInPaths, file.path,
                showHidden: showHidden, limit: limit);
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
            getAllFilesInPath(filesInPaths, curFileList[index + 1].path,
                from: 0, limit: limit);
          } else {
            getAllFilesInPath(filesInPaths, d.parent.path,
                from: index + 1, limit: limit);
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
              (a, b) => b.statSync().modified.compareTo(a.statSync().modified));
          final index =
              parentFileList.indexWhere((e) => e.path == lastFileParent.path);
          if (index != -1 && index < parentFileList.length - 1) {
            getAllFilesInPath(filesInPaths, lastFileParent.parent.path,
                from: index + 1, limit: limit);
          }
        }
      }
    }

    return filesInPaths;
  }

  static nextDirectory(List<FileSystemEntity> filesInPaths, int limit) {
    FileSystemEntity lastFileParent = curFileList.last.parent;
    Directory parentOfLastFileParent = Directory(lastFileParent.parent.path);
    List<String> fileParts = parentOfLastFileParent.path.split('/');
    if (fileParts.length == 3 && fileParts.last == 'emulated') {
      return filesInPaths;
    }
    List<FileSystemEntity> parentFileList = parentOfLastFileParent.listSync();
    parentFileList
        .sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    final index =
        parentFileList.indexWhere((e) => e.path == lastFileParent.path);
    if (index != -1 && index < parentFileList.length - 1) {
      getAllFilesInPath(filesInPaths, lastFileParent.parent.path,
          from: index + 1, limit: limit);
    }
  }

  static List<FileSystemEntity> sortList(
      List<FileSystemEntity> list, int sort) {
    switch (sort) {
      /// Sort by name
      case 0:
        list.sort((f1, f2) => basename(f1.path)
            .toLowerCase()
            .compareTo(basename(f2.path).toLowerCase()));
        break;

      case 1:
        list.sort((f1, f2) => basename(f2.path)
            .toLowerCase()
            .compareTo(basename(f1.path).toLowerCase()));
        break;

      /// Sort by date
      case 2:
        list.sort((FileSystemEntity f1, FileSystemEntity f2) =>
            f1.statSync().modified.compareTo(f2.statSync().modified));
        break;

      case 3:
        list.sort((FileSystemEntity f1, FileSystemEntity f2) =>
            f2.statSync().modified.compareTo(f1.statSync().modified));
        break;

      /// sort by size
      case 4:
        list.sort((FileSystemEntity f1, FileSystemEntity f2) =>
            f2.statSync().size.compareTo(f1.statSync().size));
        break;

      case 5:
        list.sort((FileSystemEntity f1, FileSystemEntity f2) =>
            f1.statSync().size.compareTo(f2.statSync().size));
        break;

      default:
        list.sort();
    }

    return list;
  }
}

extension FilesExt on FileSystemEntity {
  bool get isHidden => basename(this.path).startsWith('.');
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
    final filePath = '${await directory.path}/image_${DateTime.now()}.jpg';

    // Write the compressed data to the file
    await File(filePath).writeAsBytes(imageData);

    // Return the XFile with the file path
    return XFile(filePath);
  } catch (e) {
    pdebug('Error saving image: $e');
    throw (e);
  }
}

String addTimeStampToPath(String originalPath, int timeStamp,
    {bool isBaseName = false}) {
  if (isBaseName) {
    String basename = p.basenameWithoutExtension(originalPath);
    String extension = p.extension(originalPath);
    return "${basename}_${timeStamp.toString()}" + extension;
  }
  String baseName = p.basenameWithoutExtension(originalPath);
  String extension = p.extension(originalPath);
  String newPath = p.dirname(originalPath) +
      "/$baseName" +
      "_${timeStamp.toString()}$extension";
  return newPath;
}

String addCounterToPath(String originalPath, int counter) {
  if (counter <1) {
    return originalPath;
  }

  String baseName = p.basenameWithoutExtension(originalPath);
  String extension = p.extension(originalPath);
  String newPath = p.dirname(originalPath) +
      "/$baseName" +
      " ($counter)$extension";
  return newPath;
}

String? getOpenFilePath(String originalPath, int timeStamp) {
  if (objectMgr.loginMgr.isMobile) {
    return originalPath;
  } else {
    final String updatedPath = originalPath.split('/').last;
    return addTimeStampToPath(
        '${desktopDownloadMgr.desktopDownloadsDirectory.path}/$updatedPath',
        timeStamp);
  }
}
