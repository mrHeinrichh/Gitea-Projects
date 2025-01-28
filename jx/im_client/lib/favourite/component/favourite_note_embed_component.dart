import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:jxim_client/favourite/component/favourite_detail_cell/favourite_detail_document.dart';
import 'package:jxim_client/favourite/component/favourite_detail_cell/favourite_detail_location.dart';
import 'package:jxim_client/favourite/component/favourite_detail_cell/favourite_detail_media.dart';
import 'package:jxim_client/favourite/component/favourite_detail_cell/favourite_detail_voice.dart';
import 'package:jxim_client/favourite/model/favourite_model.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/regex/regular.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:url_launcher/url_launcher.dart';

class DividerEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'divider';

  @override
  Widget build(
    BuildContext context,
    QuillController controller,
    Embed node,
    bool readOnly,
    bool inline,
    TextStyle textStyle,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
      child: const CustomDivider(),
    );
  }
}

class DocumentEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'favourite_document';

  @override
  Widget build(
    BuildContext context,
    QuillController controller,
    Embed node,
    bool readOnly,
    bool inline,
    TextStyle textStyle,
  ) {
    final data = jsonDecode(node.value.data);
    final FavouriteDetailData detail =
        FavouriteDetailData.fromJson(jsonDecode(data['data']));
    final FavouriteFile file =
        FavouriteFile.fromJson(jsonDecode(detail.content!));

    return FavouriteDetailDocument(data: file);
  }
}

class LocationEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'favourite_location';

  @override
  Widget build(
    BuildContext context,
    QuillController controller,
    Embed node,
    bool readOnly,
    bool inline,
    TextStyle textStyle,
  ) {
    final data = jsonDecode(node.value.data);
    final FavouriteDetailData detail =
        FavouriteDetailData.fromJson(jsonDecode(data['data']));
    final FavouriteLocation location =
        FavouriteLocation.fromJson(jsonDecode(detail.content!));

    return FavouriteDetailLocation(data: location);
  }
}

class VoiceEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'favourite_voice';

  @override
  Widget build(
    BuildContext context,
    QuillController controller,
    Embed node,
    bool readOnly,
    bool inline,
    TextStyle textStyle,
  ) {
    final data = jsonDecode(node.value.data);
    final FavouriteVoice voice =
        FavouriteVoice.fromJson(jsonDecode(data['data']));

    return FavouriteDetailVoice(data: voice);
  }
}

class VideoEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'favourite_video';

  @override
  Widget build(
    BuildContext context,
    QuillController controller,
    Embed node,
    bool readOnly,
    bool inline,
    TextStyle textStyle,
  ) {
    final data = jsonDecode(node.value.data);
    final FavouriteDetailData detail =
        FavouriteDetailData.fromJson(jsonDecode(data['data']));
    return FavouriteDetailMedia(data: detail);
  }
}

class ImageEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'favourite_image';

  @override
  Widget build(
    BuildContext context,
    QuillController controller,
    Embed node,
    bool readOnly,
    bool inline,
    TextStyle textStyle,
  ) {
    final data = jsonDecode(node.value.data);
    final FavouriteDetailData detail =
        FavouriteDetailData.fromJson(jsonDecode(data['data']));
    return FavouriteDetailMedia(data: detail);
  }
}

void handlePhoneTap(String text) {
  RegExpMatch match = Regular.extractPhoneNumber(text).first;
  String phoneNumber = text.substring(match.start, match.end);
  String realNumber = "tel:$phoneNumber";

  showCupertinoModalPopup(
    context: Get.context!,
    builder: (BuildContext context) {
      return CupertinoActionSheet(
        actions: [
          Material(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
              color: Colors.white,
              child: Text(
                phoneNumber,
                style: jxTextStyle.textStyle14(color: colorTextPrimary),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Container(
            color: Colors.white,
            child: CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.pop(context);
                Uri callUri = Uri.parse(realNumber);
                if (await canLaunchUrl(callUri)) {
                  await launchUrl(callUri);
                } else {
                  // Handle error
                  Toast.showToast(localized(invalidPhoneNumber));
                }
              },
              child: Text(
                localized(callNumber),
                style: jxTextStyle.textStyle16(color: themeColor),
              ),
            ),
          ),
          Container(
            color: Colors.white,
            child: CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                Get.toNamed(RouteName.searchUserView, arguments: {
                  'phoneNumber': phoneNumber,
                  'isModalBottomSheet': false
                });
              },
              child: Text(
                localized(searchUser),
                style: jxTextStyle.textStyle16(color: themeColor),
              ),
            ),
          ),
          Container(
            color: Colors.white,
            child: CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                copyToClipboard(phoneNumber);
              },
              child: Text(
                localized(copyNumber),
                style: jxTextStyle.textStyle16(color: themeColor),
              ),
            ),
          )
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(
            localized(buttonCancel),
            style: jxTextStyle.textStyle16(color: themeColor),
          ),
        ),
      );
    },
  );
}
