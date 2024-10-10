import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as path;

void main() async {
  print('Clean language script');

  Map<String, String> availableLangKeys = <String, String>{};

  // Step 1. Go through every file in this project
  final Uri? libDir = await _resolveLibDir();

  if (libDir == null) {
    print(
        'Unable to resolve the lib directory. Please provide the correct package name.');
    return;
  }

  print('Lib directory: ${libDir.toString()}');

  final utilDir = Directory.fromUri(Uri.parse(libDir.toString() + 'utils/'));

  List<FileSystemEntity> utilFileList = utilDir.listSync(recursive: true);

  for (final entity in utilFileList) {
    if (entity is File && entity.path.contains('lang_util.dart')) {
      extractKeysInFile(entity, availableLangKeys);
    }
  }

  if (availableLangKeys.isEmpty) {
    print('No available language keys found in the project.');
    return;
  }

  Directory currentDir = Directory.fromUri(libDir);

  List<FileSystemEntity> fileList = currentDir.listSync(recursive: true);

  // Set to store extracted localized keys
  Set<String> localizedKeys = {};

  print('Start mapping...');

  for (final entity in fileList) {
    if (entity is File) {
      final String fileName = _getPathBaseName(entity.path);
      if (!fileName.endsWith('.dart') || fileName.startsWith('._')) continue;

      if (fileName.contains('lang_util')) continue;

      // Step 2: compare the file content with the available language keys
      _matchLocalizedWord(
          entity, availableLangKeys.keys.toSet(), localizedKeys);
    }
  }
  print('Mapping done.');

  if (localizedKeys.isEmpty) {
    print('No localized keys found in the project.');
    return;
  }

  // Step 3: Make a copy of availableLangkeys where exist in localized keys.
  Map<String, String> usedLangKeys = {};

  for (final key in localizedKeys) {
    if (availableLangKeys.containsKey(key)) {
      usedLangKeys[key] = availableLangKeys[key]!;
    }
  }

  print(
      'Length Diff after matching: ${usedLangKeys.length} | ${availableLangKeys.length}');

  // Write the usedKey to new file under this dir
  File usedKeyFile = File('used_key.dart');
  if (usedKeyFile.existsSync()) {
    usedKeyFile.deleteSync();
  }

  usedKeyFile.createSync(recursive: true);

  usedLangKeys.forEach((key, value) {
    usedKeyFile.writeAsStringSync(
      'const $key = $value;\n',
      mode: FileMode.append,
    );
  });

  // next step: extract the language file (json format) and get only the used key content

  final assetLangDirPath = path.dirname(libDir.toString()) + '/assets/lang/';

  Directory assetLangDir = Directory.fromUri(Uri.parse(assetLangDirPath));

  List<FileSystemEntity> assetLangFileList =
      assetLangDir.listSync(recursive: true);

  for (final entity in assetLangFileList) {
    if (entity is File && entity.path.endsWith('.json')) {
      final Map<String, String> usedLangMaps = <String, String>{};
      Set<String> copiedUsedLangKeys = usedLangKeys.values
          .map((e) => e.replaceAll('\'', ''))
          .map((e) => e.replaceAll('"', ''))
          .toSet();
      _processLangFile(entity, copiedUsedLangKeys, usedLangMaps);

      if (usedLangMaps.isEmpty) {
        print(
            'No used language keys found in this file : ${path.basename(entity.path)}');
        continue;
      }

      final content = LangContentFormat(1, usedLangMaps);

      // write in as a new file
      // Write the usedKey to new file under this dir
      File langFile = File(path.basename(entity.path));
      if (langFile.existsSync()) {
        langFile.deleteSync();
      }

      langFile.createSync(recursive: true);

      langFile.writeAsStringSync(
        jsonEncode(content.toJson()),
      );
    }
  }
}

Future<Uri> _resolveLibDir() async {
  Uri? currentUri =
      await Isolate.resolvePackageUri(Uri.parse('package:jxim_client/'));
  if (currentUri != null) {
    return currentUri;
  } else {
    throw Exception('Unable to resolve the lib directory.');
  }
}

void _matchLocalizedWord(
    File file, Set<String> availableLangKey, Set<String> localizedKeys) {
  List<String> lines = file.readAsLinesSync();

  for (String line in lines) {
    for (final key in availableLangKey) {
      if (line.contains(key)) {
        localizedKeys.add(key);
      }
    }
  }
}

void extractKeysInFile(File file, Map<String, String> keySet) {
  List<String> lines = file.readAsLinesSync();

  String key = '';
  String value = '';
  for (final line in lines) {
    int startIdx = line.indexOf('const ');

    if (startIdx != -1) {
      int nextEmptySpaceIdx = line.indexOf(' ', startIdx + 6);
      key = line.substring(startIdx + 6, nextEmptySpaceIdx);
    }

    int bigQuotationEqualIdx = line.indexOf(' "');
    if (bigQuotationEqualIdx != -1) {
      value = line.substring(bigQuotationEqualIdx + 1, line.length - 1);
    }

    int smallQuotationEqualIdx = line.indexOf(" '");
    if (smallQuotationEqualIdx != -1) {
      value = line.substring(smallQuotationEqualIdx + 1, line.length - 1);
    }

    if (key.isNotEmpty && value.isNotEmpty) {
      keySet[key] = value;
      key = '';
      value = '';
    }
  }
}

void _processLangFile(
  File entity,
  Set<String> usedLangValue,
  Map<String, String> usedLangMaps,
) {
  final String content = entity.readAsStringSync();
  final Map<String, dynamic> jsonContent = jsonDecode(content);
  final obj = LangContentFormat.fromJson(jsonContent);
  obj.data.forEach((key, value) {
    if (usedLangValue.contains(key)) {
      usedLangMaps[key] = value;
    }
  });
}

String _getPathBaseName(String filePath) {
  return path.basename(filePath);
}

class LangContentFormat {
  int ver;
  Map<String, dynamic> data;

  LangContentFormat(this.ver, this.data);

  factory LangContentFormat.fromJson(Map<String, dynamic> json) {
    return LangContentFormat(
      json['ver'],
      json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ver': ver,
      'data': data,
    };
  }
}
