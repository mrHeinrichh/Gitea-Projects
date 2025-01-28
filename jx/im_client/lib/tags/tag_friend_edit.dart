import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/favourite/model/favourite_model.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/component.dart';

class TagFriendEdit extends StatefulWidget {
  final List<String> tagDataList;

  const TagFriendEdit({super.key, required this.tagDataList,});

  @override
  State<TagFriendEdit> createState() => _TagFriendEditState();
}

class _TagFriendEditState extends State<TagFriendEdit>
{
  late final TextEditingController inputController;

  final FocusNode inputFocusNode = FocusNode();

  int oldTextLength = 0;

  RxBool hasText = false.obs;

  RxBool isEnableSubmit = false.obs;

  List<MomentInputTagModel> oriTagList = []; // original tagList

  RxList<MomentInputTagModel> tagList = <MomentInputTagModel>[].obs; // add to tag favourite

  RxList<MomentInputTagModel> mainTagList = <MomentInputTagModel>[].obs; // submit to main tag

  @override
  void initState() {
    super.initState();
    inputController = TextEditingController();
    hasText.value = inputController.text.isNotEmpty;
    oldTextLength = inputController.text.length;

    inputController.addListener(_onInputChanged);
    inputFocusNode.addListener(_onInputFocusChanged);

    _getTagList();
    _getMainTagList();
  }

  @override
  void dispose() {
    inputController.removeListener(_onInputChanged);
    inputFocusNode.removeListener(_onInputFocusChanged);
    inputController.dispose();
    inputFocusNode.dispose();
    super.dispose();
  }

  void _getTagList() async {
    tagList.value = widget.tagDataList.map((e) {
      return MomentInputTagModel(
        title: e,
        type: FavouriteTag,
        selected: false,
      );
    }).toList();
    oriTagList = tagList.toList();
    checkTagMatch();
  }

  Future<void> _getMainTagList() async {
    List<String> dataList = [];
    final jsonString =
        objectMgr.localStorageMgr.read(LocalStorageMgr.FAVOURITE_TAG) ?? "";
    if (jsonString != "") {
      dataList =
      List<String>.from(jsonDecode(jsonString).map((e) => e as String));
    }

    List<MomentInputTagModel> data = dataList.map((e) {
      return MomentInputTagModel(
        title: e,
        type: FavouriteTag,
        selected: false,
      );
    }).toList();

    mainTagList.value = data;
  }

  void _onInputChanged() {
    hasText.value = inputController.text.isNotEmpty && inputController.text.trim().isNotEmpty;

    // 删除判断
    final isDelete = oldTextLength - 1 == inputController.text.length && !(oldTextLength > 1 && !hasText.value);

    if (isDelete)
    {
      if (tagList.isNotEmpty && tagList.last.selected)
      {
        tagList.removeLast();

        if (tagList.isEmpty) {
          oldTextLength = 0;
        } else {
          inputController.text = ' ';
          oldTextLength = 1;
        }
        checkTagMatch();
        return;
      }

      if (inputController.text.trim().isEmpty && tagList.isNotEmpty && !tagList.last.selected)
      {
        tagList[tagList.length - 1] = tagList[tagList.length - 1].copyWith(selected: true,);

        inputController.text = ' ';
        oldTextLength = 1;
      }
      return;
    }

    final isAdd = oldTextLength + 1 == inputController.text.length;

    if (inputController.text.isEmpty)
    {
      if (tagList.isNotEmpty) {
        inputController.text = ' ';
        oldTextLength = 1;
      }
      return;
    }

    // 增加
    if (isAdd && tagList.isNotEmpty && tagList.last.selected) {
      tagList[tagList.length - 1] = tagList[tagList.length - 1].copyWith(selected: false,);
    }

    oldTextLength = inputController.text.length;
  }

  void _onInputFocusChanged() {
    if (!inputFocusNode.hasFocus) {
      _onTextSubmitted(
        inputController.text,
        requestFocus: false,
      );
    }
  }

  void _onTextSubmitted(String text, {bool requestFocus = true,})
  {
    if (text.trim().isEmpty) return;

    _addMomentTag(
      inputController.text.substring(0, inputController.text.length).trim(),
      isTextSubmitted: true,
    );

    if (requestFocus) {
      inputFocusNode.requestFocus();
    }
    return;
  }

  void _addMomentTag(String lastTag, {bool isTextSubmitted = false}) {
    int index = tagList.indexWhere((element) => element.title == lastTag);
    if (index == -1) {
      MomentInputTagModel model = MomentInputTagModel(
        title: lastTag,
        type: FavouriteTag,
        selected: false,
      );
      tagList.add(model);
    } else {
      if (!isTextSubmitted) {
        tagList.removeAt(index);
      }
    }

    inputController.text = ' ';
    oldTextLength = 1;

    checkTagMatch();
  }

  void _removeMomentTag(MomentInputTagModel tag) {
    if (tagList.contains(tag)) {
      if (tag.selected) {
        tagList.remove(tag);
      }
    }
    checkTagMatch();
  }

  Future<void> submitTag() async {
    if (!isEnableSubmit.value) return;
    List<String> tag = tagList.map((element) => element.title).toList();
    Get.back(result: {'tag': tag});
  }

  void checkTagMatch() {
    if (oriTagList.length != tagList.length) {
      isEnableSubmit.value = true;
      return;
    }

    List<String> oriData = oriTagList.map((element) => element.title).toList();
    List<String> tagData = tagList.map((element) => element.title).toList();

    oriData.sort();
    tagData.sort();

    bool status = oriData.every((element) => tagData.contains(element));
    isEnableSubmit.value = !status;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        title: localized(favouriteTag),
        isBackButton: false,
        leading: OpacityEffect(
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: CustomTextButton(
              padding: const EdgeInsets.symmetric(vertical: 8),
              localized(buttonCancel),
              onClick: () => Get.back(),
            ),
          ),
        ),
        trailing: [
          Obx(
                () => OpacityEffect(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: CustomTextButton(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  localized(buttonDone),
                  color: isEnableSubmit.value ? themeColor : colorTextSecondary,
                  onClick: () async => submitTag(),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              inputFocusNode.requestFocus();
            },
            child: Container(
              color: colorWhite,
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.only(
                top: 12.0,
                left: 4.0,
                right: 16.0,
              ),
              child: Obx(
                    () => Wrap(
                  children: <Widget>[
                    ...List<Widget>.generate(
                      tagList.length,
                          (index) => _buildTagItem(index),
                    ),
                    IntrinsicWidth(
                      child: Container(
                        margin: EdgeInsets.only(
                          top: 0.0,
                          left: !hasText.value ? 0.0 : 6.0,
                          bottom: 12.0,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100.0),
                          border: Border.all(
                            color: themeColor.withOpacity(0.08),
                            // Border color
                            style: !hasText.value
                                ? BorderStyle.none
                                : BorderStyle.solid,
                          ),
                        ),
                        child: Stack(
                          children: <Widget>[
                            TextField(
                              controller: inputController,
                              focusNode: inputFocusNode,
                              onSubmitted: _onTextSubmitted,
                              style: jxTextStyle.headerSmallText(),
                              maxLength: 10 + tagList.length,
                              buildCounter: (
                                  BuildContext context, {
                                    required int currentLength,
                                    required int? maxLength,
                                    required bool isFocused,
                                  }) {
                                return null;
                              },
                              // cursorHeight: MFontSize.size15.value,
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: localized(addOrSearchTag),
                                hintStyle: jxTextStyle.headerSmallText(
                                  color: Colors.transparent,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: !hasText.value ? 12.0 : 6.0,
                                  vertical: 4.0,
                                ),
                              ),
                            ),
                            if (inputController.text.trim().isEmpty &&
                                tagList.isNotEmpty ||
                                inputController.text.trim().isEmpty &&
                                    tagList.isEmpty)
                              Positioned(
                                top: 4.0,
                                bottom: 4.0,
                                left: 16.0,
                                child: Text(
                                  localized(addOrSearchTag),
                                  style: jxTextStyle.headerSmallText(
                                    color: colorTextPlaceholder,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Obx(
                () => Visibility(
              visible: mainTagList.isNotEmpty,
              child: Container(
                padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        localized(allTags),
                        style:
                        jxTextStyle.normalText(color: colorTextSecondary),
                      ),
                    ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: <Widget>[
                        ...List<Widget>.generate(
                          mainTagList.length,
                              (index) => _tagMainItem(mainTagList[index]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagItem(int index) {
    final MomentInputTagModel tag = tagList[index];

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _removeMomentTag(tag),
      child: Container(
        margin: const EdgeInsets.only(
          left: 12.0,
          bottom: 12.0,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12.0,
          vertical: 4.0,
        ),
        decoration: BoxDecoration(
          color: tag.selected ? themeColor : themeColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(100.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              tag.title,
              style: TextStyle(
                fontSize: MFontSize.size15.value,
                color: tag.selected ? colorWhite : themeColor,
              ),
            ),
            if (tag.selected)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: SvgPicture.asset(
                  'assets/svgs/close_icon.svg',
                  width: 12.0,
                  height: 12.0,
                  colorFilter: const ColorFilter.mode(
                    colorWhite,
                    BlendMode.srcIn,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tagMainItem(MomentInputTagModel model) {
    int index = tagList.indexWhere((element) => element.title == model.title);
    if (index != -1) {
      model = model.copyWith(selected: true);
    }
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _addMomentTag(model.title),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12.0,
          vertical: 4.0,
        ),
        decoration: BoxDecoration(
          color: model.selected ? themeColor.withOpacity(0.08) : colorBorder,
          borderRadius: BorderRadius.circular(100.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              model.title,
              style: jxTextStyle.headerSmallText(
                color: model.selected ? themeColor : colorTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MomentInputTagModel {
  final String title;
  final int type;
  final bool selected;

  MomentInputTagModel({
    required this.title,
    required this.type,
    required this.selected,
  });

  MomentInputTagModel copyWith({
    String? title,
    int? type,
    bool? selected,
  }) {
    return MomentInputTagModel(
      title: title ?? this.title,
      type: type ?? this.type,
      selected: selected ?? this.selected,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'type': type,
      'selected': selected,
    };
  }

  factory MomentInputTagModel.fromJson(Map<String, dynamic> map) {
    return MomentInputTagModel(
      title: map['title'],
      type: map['type'],
      selected: map['selected'],
    );
  }
}
