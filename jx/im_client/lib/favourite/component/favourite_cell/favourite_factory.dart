import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/favourite/component/favourite_cell/favourite_ui_comnination.dart';
import 'package:jxim_client/favourite/component/favourite_cell/favourite_ui_history.dart';
import 'package:jxim_client/favourite/component/favourite_cell/favourite_ui_media.dart';
import 'package:jxim_client/favourite/component/favourite_cell/favourite_ui_multiple_content.dart';
import 'package:jxim_client/favourite/component/favourite_cell/favourite_ui_single_content.dart';
import 'package:jxim_client/favourite/component/favourite_cell/favourite_ui_text.dart';
import 'package:jxim_client/favourite/favourite_controller.dart';
import 'package:jxim_client/favourite/model/favourite_model.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/utility.dart';

class FavouriteFactory {
  static Widget createComponent({
    required FavouriteData favouriteData,
    required int index,
    required FavouriteController controller,
  }) {
    FavouriteUiType? type;
    dynamic favourite;
    String title = "";
    List<String> contentList = [];
    List<Map<String, dynamic>> iconPathList = [];
    List<FavouriteDetailData> favouriteContent = favouriteData.content.toList();

    if (favouriteData.source == FavouriteSourceNote) {
      if (favouriteContent.isNotEmpty &&
          favouriteContent.last.typ == FavouriteTypeDelta) {
        favouriteContent.removeLast();
      }
    }

    if (favouriteContent.length == 1) {
      FavouriteDetailData favouriteDetailData = favouriteContent.first;
      favourite = objectMgr.favouriteMgr.getFavouriteContent(
          favouriteDetailData.typ, favouriteDetailData.content ?? '');

      switch (favouriteDetailData.typ) {
        case FavouriteTypeText:
        case FavouriteTypeLink:
          type = FavouriteUiType.onlyText;
          String text = '';
          if (favourite is FavouriteText) {
            text = favourite.text;
          } else {
            text = favourite;
          }
          List<String> listOfString = text.split('\n');
          if (listOfString.isNotEmpty) {
            title = listOfString[0];

            if (listOfString.length > 1) {
              for (String item
                  in listOfString.sublist(1, listOfString.length)) {
                if (item.isNotEmpty) {
                  contentList.add(item);
                }
              }
            }
          }
          break;
        case FavouriteTypeImage:
        case FavouriteTypeVideo:
          if (favourite.caption != null) {
            type = FavouriteUiType.combination;
            title = favourite.caption;
          } else {
            type = FavouriteUiType.onlyMedia;
          }
          Map<String, dynamic> iconMap = {};
          iconMap['typ'] = favouriteDetailData.typ;
          if (favouriteDetailData.typ == FavouriteTypeVideo) {
            iconMap['path'] = notBlank(favourite.cover)
                ? favourite.cover
                : favourite.coverPath;
            iconMap['isFake'] = !notBlank(favourite.cover);
            iconMap['gausPath'] = favourite.gausPath ?? '';
            iconPathList.add(iconMap);
          } else {
            iconMap['path'] =
                notBlank(favourite.url) ? favourite.url : favourite.filePath;
            iconMap['isFake'] = !notBlank(favourite.url);
            iconMap['gausPath'] = favourite.gausPath ?? '';
            iconPathList.add(iconMap);
          }
        case FavouriteTypeAlbum:
          if (favourite.caption != null) {
            type = FavouriteUiType.combination;
            title = favourite.caption;
          } else {
            type = FavouriteUiType.onlyMedia;
          }
          for (AlbumDetailBean item in favourite.albumList) {
            Map<String, dynamic> iconMap = {};
            iconMap['typ'] =
                item.isVideo ? FavouriteTypeVideo : FavouriteTypeImage;
            iconMap['path'] = item.isVideo ? item.cover : item.url;
            iconMap['gausPath'] =
                notBlank(item.gausPath) ? item.gausPath : iconMap['path'];
            iconMap['isFake'] = !notBlank(item.url);
            iconPathList.add(iconMap);
          }
          break;
        case FavouriteTypeAudio:
          type = FavouriteUiType.singleContent;
          title = constructTime(
            favourite.second ~/ 1000,
            showHour: false,
          );
          Map<String, dynamic> iconMap = {};
          iconMap['typ'] = favouriteDetailData.typ;
          iconMap['path'] = 'assets/svgs/voice_icon.svg';
          iconPathList.add(iconMap);
          break;
        case FavouriteTypeDocument:
          if (favourite.caption != null) {
            type = FavouriteUiType.combination;
            title = favourite.caption;
            contentList
                .add("[${localized(attachmentFiles)}] ${favourite.fileName}");
          } else {
            type = FavouriteUiType.singleContent;
            title = favourite.fileName;
            contentList.add(fileSize(favourite.length));
            Map<String, dynamic> iconMap = {};
            iconMap['typ'] = favouriteDetailData.typ;
            iconMap['fileName'] = favourite.fileName;
            iconMap['path'] = favourite.cover ?? favourite.fileName;
            iconMap['isEncrypt'] = favourite.isEncrypt;
            iconPathList.add(iconMap);
          }
        case FavouriteTypeLocation:
          type = FavouriteUiType.singleContent;
          title = favourite.name;
          contentList.add(favourite.address);
          Map<String, dynamic> iconMap = {};
          iconMap['typ'] = favouriteDetailData.typ;
          iconMap['path'] =
              notBlank(favourite.url) ? favourite.url : favourite.filePath;
          iconMap['isFake'] = !notBlank(favourite.url);
          iconPathList.add(iconMap);
          break;
      }
    } else if (favouriteContent.length > 1) {
      if (favouriteData.source == FavouriteSourceHistory) {
        type = FavouriteUiType.history;
        Map<String, dynamic> map =
            objectMgr.favouriteMgr.getContentList(favouriteData);
        title = map['title'];
        contentList = map['contentList'];
      } else {
        final textList = favouriteContent
            .where((element) =>
                element.typ == FavouriteTypeText ||
                element.typ == FavouriteTypeLink)
            .toList();
        final mediaList = favouriteContent
            .where((element) =>
                element.typ == FavouriteTypeImage ||
                element.typ == FavouriteTypeVideo)
            .toList();
        final documentList = favouriteContent
            .where((element) => element.typ == FavouriteTypeDocument)
            .toList();
        final locationList = favouriteContent
            .where((element) => element.typ == FavouriteTypeLocation)
            .toList();
        final voiceList = favouriteContent
            .where((element) => element.typ == FavouriteTypeAudio)
            .toList();

        if (textList.isNotEmpty) {
          FavouriteDetailData? data = textList.first;
          String text = '';
          favourite = objectMgr.favouriteMgr
              .getFavouriteContent(data.typ, data.content ?? '');
          if (favourite is FavouriteText) {
            text = favourite.text;
          } else {
            text = favourite;
          }
          List<String> listOfString = text.split('\n');
          if (listOfString.isNotEmpty) {
            title = listOfString[0];

            if (listOfString.length > 1) {
              for (String item
                  in listOfString.sublist(1, listOfString.length)) {
                if (item.isNotEmpty) {
                  contentList.add(item);
                }
              }
            }
          }
          textList.removeAt(0);
          for (FavouriteDetailData item in textList) {
            final data = objectMgr.favouriteMgr
                .getFavouriteContent(item.typ, item.content ?? '');
            if (data is FavouriteText) {
              contentList.add(data.text);
            } else {
              contentList.add(data);
            }
          }
        }

        for (FavouriteDetailData item in mediaList) {
          Map<String, dynamic> iconMap = {};
          iconMap['typ'] = item.typ;
          if (item.typ == FavouriteTypeVideo) {
            FavouriteVideo video =
                FavouriteVideo.fromJson(jsonDecode(item.content!));
            iconMap['path'] =
                notBlank(video.cover) ? video.cover : video.coverPath;
            iconMap['isFake'] = !notBlank(video.cover);
            iconMap['gausPath'] = video.gausPath;
          } else if (item.typ == FavouriteTypeImage) {
            FavouriteImage image =
                FavouriteImage.fromJson(jsonDecode(item.content!));
            iconMap['path'] = notBlank(image.url) ? image.url : image.filePath;
            iconMap['isFake'] = !notBlank(image.url);
            iconMap['gausPath'] = image.gausPath;
          }
          iconPathList.add(iconMap);
        }

        for (FavouriteDetailData item in documentList) {
          FavouriteFile data =
              FavouriteFile.fromJson(jsonDecode(item.content ?? ""));
          contentList.add("[${localized(files)}] ${data.fileName}");
        }

        for (FavouriteDetailData item in locationList) {
          FavouriteLocation data =
              FavouriteLocation.fromJson(jsonDecode(item.content ?? ""));
          contentList.add("${localized(replyLocation)} ${data.name}");
        }

        for (FavouriteDetailData item in voiceList) {
          FavouriteVoice data =
              FavouriteVoice.fromJson(jsonDecode(item.content ?? ""));
          contentList.add("[${localized(chatTagVoiceCall)}] ${constructTime(
            data.second ~/ 1000,
            showHour: false,
          )}");
        }

        if (iconPathList.isNotEmpty && title == "" && contentList.isEmpty) {
          type = FavouriteUiType.onlyMedia;
        } else if (iconPathList.isNotEmpty &&
            (title != "" || contentList.isNotEmpty)) {
          type = FavouriteUiType.combination;
        } else if (title != "" || contentList.isNotEmpty) {
          type = FavouriteUiType.multipleContent;
        }
      }
    }

    /// 搜索高亮
    int findCount = 0;

    /// 搜索text
    String searchText = controller.keyWordList
            .firstWhereOrNull((element) => element.type == FavouriteCustom)
            ?.title
            .trim() ??
        controller.inputController.text.trim();

    /// 标题高亮
    List<InlineSpan> titleTextList =
        getHighlightSpanList(title, searchText, jxTextStyle.headerText());
    if (titleTextList.isNotEmpty) {
      findCount += 1;
    }

    /// 高亮content
    List<List<InlineSpan>> contentTextList = [];
    for (String item in contentList) {
      final content = getHighlightSpanList(
          item, searchText, jxTextStyle.normalText(color: colorTextSecondary));
      contentTextList.add(content);
      if (content.length > 1) {
        findCount += 1;
      }

      // not more than 2 content
      if (contentTextList.length > 1) {
        break;
      }
    }

    /// 当没有搜索任何字
    if (searchText.isEmpty) {
      findCount = 1;
    }

    if (findCount > 0) {
      switch (type) {
        case FavouriteUiType.onlyText:
          return FavouriteUIText(
            index: index,
            title: titleTextList,
            contentList: contentTextList,
            iconPathList: const [],
          );
        case FavouriteUiType.onlyMedia:
          return FavouriteUIMedia(
            index: index,
            title: const [],
            contentList: const [],
            iconPathList: iconPathList,
          );
        case FavouriteUiType.singleContent:
          return FavouriteUISingleContent(
            index: index,
            title: titleTextList,
            contentList: contentTextList,
            iconPathList: iconPathList,
          );
        case FavouriteUiType.multipleContent:
          return FavouriteUIMultipleContent(
            index: index,
            title: titleTextList,
            contentList: contentTextList,
            iconPathList: const [],
          );
        case FavouriteUiType.combination:
          return FavouriteUICombination(
            index: index,
            title: titleTextList,
            contentList: contentTextList,
            iconPathList: iconPathList,
          );
        case FavouriteUiType.history:
          return FavouriteUIHistory(
            index: index,
            title: titleTextList,
            contentList: contentTextList,
            iconPathList: const [],
          );
        default:
          return const SizedBox();
      }
    } else {
      return const SizedBox();
    }
  }
}
