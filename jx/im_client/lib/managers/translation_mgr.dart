import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/managers/lang_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/translate_array_model.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/regex/regular.dart';
import 'package:jxim_client/utils/unescape_util.dart';

final TranslationMgr translationMgr = TranslationMgr();

class TranslationMgr {
  List<String> validLanguages = ["en", "zh", "jp", "th", "vi", "km", "tr"];
  Map<String, String> validMap = {
    "en": "en",
    "cn": "zh",
    "jp": "jp",
    "vi": "vi",
    "km": "km",
    "th": "th",
    "tr": "tr",
  };

  Future<String> translate(
    String originalMessage,
    String targetLanguage, {
    int? chatId,
    int? chatIdx,
  }) async {
    targetLanguage = targetLanguage.toLowerCase();
    if (validMap[targetLanguage] != null) {
      targetLanguage = validMap[targetLanguage]!;
    } else {
      targetLanguage = _getAutoLocale();
    }

    var messageToTranslate = originalMessage;

    List<TranslationProcessModel> allModels = [];
    //无效字段：链接 ｜ @ ｜ 手机号 ｜ 换行（\n）｜ Emoji
    List<RegExpMatch> invalidItems =
        Regular.extractAllInvalidTranslations(messageToTranslate);
    //无效字段统合后需排序一下。
    //Assumption: 字段不会发生重叠的情况
    invalidItems.sort((a, b) => a.start.compareTo(b.start));

    int index = 0;
    //过滤所有没效的字段
    if (invalidItems.isNotEmpty) {
      for (var element in invalidItems) {
        if (element.start != index && index < element.start) {
          String item = messageToTranslate.substring(index, element.start);
          //字段以外的遗漏，若是range字段为空则设定为不必翻译，不是空则加入需翻译
          TranslationProcessModel model = TranslationProcessModel(
            originalText: item,
            toTranslate: notBlank(item),
            startIndex: index,
            endIndex: element.start,
          );
          allModels.add(model);
        }
        String invalidItem =
            messageToTranslate.substring(element.start, element.end);
        //无效字段全是不必翻译
        TranslationProcessModel model = TranslationProcessModel(
          originalText: invalidItem,
          toTranslate: false,
          startIndex: element.start,
          endIndex: element.end,
        );
        allModels.add(model);
        index = element.end;
      }
    }

    if (index < messageToTranslate.length) {
      String item = messageToTranslate.substring(index);
      TranslationProcessModel model = TranslationProcessModel(
        originalText: item,
        toTranslate: notBlank(item),
        startIndex: index,
        endIndex: messageToTranslate.length - 1,
      );
      allModels.add(model);
    }

    List<TranslationProcessModel> toTranslate =
        allModels.where((element) => element.toTranslate == true).toList();
    //没有filter，代表没有东西要翻译，返回原文即可
    if (toTranslate.isEmpty) return originalMessage;
    //剩余所有的信息，进行api翻译
    TranslateArrayModel? results = await _getTranslation(
      targetLanguage,
      toTranslate,
      chatId: chatId,
      chatIdx: chatIdx,
    );

    //若找不到任何翻译信息，返回空（翻译失败）
    if (results == null ||
        results.transText == null ||
        results.transText!.isEmpty) {
      return "";
    }

    //把相应翻译好的字段拼上
    String finalTranslated = messageToTranslate;
    for (int i = 0; i < results.transText!.length; i++) {
      String original = unescape.convert(results.oriText![i]);
      String translated = results.transText![i];
      finalTranslated = finalTranslated.replaceFirst(original, translated);
    }

    return finalTranslated;
  }

  Future<TranslateArrayModel?> _getTranslation(
    String langCode,
    List<TranslationProcessModel> messagesToTranslate, {
    int? chatId,
    int? chatIdx,
  }) async {
    try {
      List<String> messages = [];
      for (var element in messagesToTranslate) {
        messages.add(element.originalText);
      }

      final TranslateArrayModel data = await getTranslateArray(
        langCode,
        messages,
        chatId: chatId,
        chatIdx: chatIdx,
      );
      return data;
    } on AppException {
      // Toast.showToast(e.getMessage());
      return null;
    }
  }

  String _getAutoLocale() {
    String? langKeyFromLs = objectMgr.localStorageMgr.read(LangMgr.langKey);
    if (langKeyFromLs != null && langKeyFromLs.isNotEmpty) {
      List<String> localeParts = langKeyFromLs.split("_");
      langKeyFromLs = localeParts.first;
    } else {
      langKeyFromLs = objectMgr.langMgr.getSystemLang().languageCode;
    }
    if (langKeyFromLs == 'zh') langKeyFromLs = 'cn';
    if (langKeyFromLs == 'ja') langKeyFromLs = 'jp';
    if (notBlank(langKeyFromLs) && validMap[langKeyFromLs] != null) {
      return validMap[langKeyFromLs]!;
    }
    return "";
  }

  bool requireTranslation(String originalMessage) {
    List<TranslationProcessModel> allModels = [];
    //无效字段：链接 ｜ @ ｜ 手机号 ｜ 换行（\n）｜ Emoji
    List<RegExpMatch> invalidItems =
        Regular.extractAllInvalidTranslations(originalMessage);
    //无效字段统合后需排序一下。
    //Assumption: 字段不会发生重叠的情况
    invalidItems.sort((a, b) => a.start.compareTo(b.start));

    int index = 0;
    //过滤所有没效的字段
    if (invalidItems.isNotEmpty) {
      for (var element in invalidItems) {
        if (element.start != index) {
          String item = originalMessage.substring(index, element.start);
          //字段以外的遗漏，若是range字段为空则设定为不必翻译，不是空则加入需翻译
          TranslationProcessModel model = TranslationProcessModel(
            originalText: item,
            toTranslate: notBlank(item),
            startIndex: index,
            endIndex: element.start,
          );
          allModels.add(model);
        }
        String invalidItem =
            originalMessage.substring(element.start, element.end);
        //无效字段全是不必翻译
        TranslationProcessModel model = TranslationProcessModel(
          originalText: invalidItem,
          toTranslate: false,
          startIndex: element.start,
          endIndex: element.end,
        );
        allModels.add(model);
        index = element.end;
      }
    }

    if (index < originalMessage.length) {
      String item = originalMessage.substring(index);
      TranslationProcessModel model = TranslationProcessModel(
        originalText: item,
        toTranslate: notBlank(item),
        startIndex: index,
        endIndex: originalMessage.length - 1,
      );
      allModels.add(model);
    }

    List<TranslationProcessModel> toTranslate =
        allModels.where((element) => element.toTranslate == true).toList();
    //没有filter，代表没有东西要翻译，返回原文即可
    return toTranslate.isNotEmpty;
  }
}

class TranslationProcessModel {
  int startIndex;
  int endIndex;
  String originalText;
  String? translatedText;
  bool toTranslate;

  TranslationProcessModel({
    required this.startIndex,
    required this.endIndex,
    this.translatedText,
    required this.originalText,
    required this.toTranslate,
  });
}
