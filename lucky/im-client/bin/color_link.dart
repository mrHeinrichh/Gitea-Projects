import 'dart:io';

/// Arguments: [colorKey] [heyColorCode] [uuColorCode]
void main(List<String> args) {
  if (args.length < 3) {
    print('Error: arguments not enough');
    return;
  }

  List<String> readFileContent(String path) {
    return File(path).readAsLinesSync();
  }

  void writeFileContent(String path, List<String> content) {
    File(path).writeAsStringSync(content.join('\n'));
  }

  String oriFile = '../lib/utils/color.dart';
  String uuColor = '../config/color/uu_talk_color.dst';
  String heyColor = '../config/color/heytalk_color.dst';

  String uuColorLabel = '../config/color/uu_color_config.json';
  String heyColorLabel = '../config/color/hey_color_config.json';

  void processDstFile(String filePath, String colorKey, String colorArg) {
    List<String> oriContent = readFileContent(filePath);

    // check color exist
    int oriColorExistIdx =
        oriContent.indexWhere((element) => element.contains(args[0]));

    String heyInsertColorStatement =
        '  static const Color $colorKey = const Color($colorArg);';

    if (oriColorExistIdx != -1) {
      oriContent[oriColorExistIdx] = heyInsertColorStatement;
      writeFileContent(filePath, oriContent);
      return;
    }

    int classIndex = oriContent.indexOf('class JXColors {');
    if (classIndex == -1) {
      print('Error: class not found');
      return;
    }

    int endIndex = oriContent.indexOf('}', classIndex);
    if (endIndex == -1) {
      print('Error: end not found');
      return;
    }

    oriContent.insert(endIndex, heyInsertColorStatement);

    writeFileContent(filePath, oriContent);
  }

  void processLabelFile(String filePath, String colorKey, String colorArg) {
    List<String> heyContent = readFileContent(filePath);

    int colorExistIdx =
        heyContent.indexWhere((element) => element.contains(colorKey));
    if (colorExistIdx != -1) {
      heyContent[colorExistIdx] =
          '"${colorKey}": "${colorArg}"${colorExistIdx == heyContent.length - 1 ? '' : ','}';
      writeFileContent(filePath, heyContent);
      return;
    }

    String heyInsertColorStatement = '"${colorKey}": "${colorArg}",';

    heyContent.insert(1, heyInsertColorStatement);

    writeFileContent(filePath, heyContent);
  }

  processDstFile(oriFile, args[0], args[2]);
  processDstFile(uuColor, args[0], args[1]);
  processDstFile(heyColor, args[0], args[2]);
  processLabelFile(uuColorLabel, args[0], args[1]);
  processLabelFile(heyColorLabel, args[0], args[2]);
}
