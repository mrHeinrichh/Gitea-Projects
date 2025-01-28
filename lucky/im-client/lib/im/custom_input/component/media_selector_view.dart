import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/im/chat_info/tool_option_model.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/contact_picker.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/location/location_selector.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/task/task_selector_view.dart';
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/no_permission_view.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/file/file_picker_bottom_modal.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/file/file_picker_controller_we.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/location/location_controller.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/media_picker.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet.dart';

import '../../../views/component/check_tick_item.dart';

class MediaSelectorView extends StatefulWidget {
  final String tag;
  final bool isPermissionGranted;
  final MediaOption? mediaOption;

  const MediaSelectorView(
    this.tag,
    this.isPermissionGranted, {
    this.mediaOption,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => MediaSelectorViewState();
}

class MediaSelectorViewState extends State<MediaSelectorView>
    with TickerProviderStateMixin {
  CustomInputController? controller;
  late final TabController mediaPickerController;
  TabController? bottomTabController;

  FocusNode inputFocusNode = FocusNode();

  List<ToolOptionModel> optionList = <ToolOptionModel>[
    ToolOptionModel(
      title: localized(gallery),
      optionType: MediaOption.gallery.type,
      isShow: true,
      tabBelonging: 1,
      unCheckImageUrl: 'assets/svgs/picture_uncheck.svg',
      checkImageUrl: 'assets/svgs/picture_check.svg',
    ),
    ToolOptionModel(
      title: localized(files),
      optionType: MediaOption.document.type,
      isShow: true,
      tabBelonging: 1,
      checkImageUrl: 'assets/svgs/document_check.svg',
      unCheckImageUrl: 'assets/svgs/document_uncheck.svg',
    ),
    ToolOptionModel(
      title: localized(registerLocation),
      optionType: MediaOption.location.type,
      isShow: true,
      tabBelonging: 1,
      checkImageUrl: 'assets/svgs/location_check.svg',
      unCheckImageUrl: 'assets/svgs/location_uncheck.svg',
    ),
    ToolOptionModel(
      title: localized(contact),
      optionType: MediaOption.contact.type,
      isShow: true,
      tabBelonging: 1,
      checkImageUrl: 'assets/svgs/contact_check.svg',
      unCheckImageUrl: 'assets/svgs/contact_uncheck.svg',
    ),
    ToolOptionModel(
      title: localized(redPacketTab),
      optionType: MediaOption.redPacket.type,
      isShow: true,
      tabBelonging: 1,
      unCheckImageUrl: 'assets/svgs/redPacket_uncheck.svg',
      checkImageUrl: 'assets/svgs/redPacket_check.svg',
    ),
    ToolOptionModel(
      title: localized(tasks),
      optionType: MediaOption.task.type,
      isShow: true,
      tabBelonging: 1,
      unCheckImageUrl: 'assets/svgs/task_uncheck.svg',
      checkImageUrl: 'assets/svgs/task_check.svg',
    ),
  ];

  final currentActionPage = 0.obs;
  final RxDouble currentHeight = 530.0.obs;
  bool hasAudioRoom = true;

  final RxBool originalSelect = false.obs;
  ValueNotifier<List<AssetEntity>> selectedAssets = ValueNotifier([]);

  @override
  void initState() {
    configAudio();
    super.initState();
    controller = Get.find<CustomInputController>(tag: widget.tag);

    controller!.mediaPickerInputController.text =
        controller?.inputController.text ?? '';

    if (controller!.type == 1) {
      optionList.removeWhere(
          (element) => element.optionType == MediaOption.task.type);
    }

    if (controller!.type == 1 || !Config().enableRedPacket) {
      optionList.removeWhere(
          (element) => element.optionType == MediaOption.redPacket.type);
    } else {
      if (!controller!.chatController.showGallery) {
        optionList.removeWhere(
            (element) => element.optionType == MediaOption.gallery.type);
      }

      if (!controller!.chatController.showDocument) {
        optionList.removeWhere(
            (element) => element.optionType == MediaOption.document.type);
      }

      if (!controller!.chatController.showContact) {
        optionList.removeWhere(
            (element) => element.optionType == MediaOption.contact.type);
      }

      if (!controller!.chatController.showRedPacket) {
        optionList.removeWhere(
            (element) => element.optionType == MediaOption.redPacket.type);
      }
    }

    if (widget.mediaOption != null) {
      optionList.removeWhere(
          (element) => element.optionType != widget.mediaOption!.type);
    }

    mediaPickerController = TabController(
      length: 2,
      vsync: this,
    );

    bottomTabController = TabController(
      length: optionList.length,
      vsync: this,
    );
    bottomTabController?.addListener(handleTabSelection);

    if (optionList.first.optionType == 'document') {
      _loadFiles();
    }

    if (widget.isPermissionGranted) {
      controller!.assetPickerProvider!.addListener(() {
        if (controller!.assetPickerProvider!.selectedAssets.isEmpty) {
          selectedAssets.value = [];
          mediaPickerController.index = 0;
          if (inputFocusNode.hasFocus) {
            inputFocusNode.unfocus();
            FocusManager.instance.primaryFocus!.unfocus();
          }
        } else {
          selectedAssets.value =
              controller!.assetPickerProvider!.selectedAssets;
        }
      });
    }
  }

  void configAudio() {
    hasAudioRoom = true;
    if (!hasAudioRoom) {
      optionList.removeWhere(
          (element) => element.optionType == MediaOption.audio.type);
    }
  }

  handleTabSelection() {
    if (bottomTabController == null) return;
    if (!bottomTabController!.indexIsChanging) {
      //所有的他不都应该显示的时候在初始化，并且数据加载一次就行了，不需要切换后重新加载
      if (optionList[bottomTabController!.index].optionType == 'document') {
        if (Get.isRegistered<FilePickerController>()) {
          _loadFiles();
        }
      } else if (Get.isRegistered<LocationController>()) {
        if (Platform.isAndroid) {
          Future.delayed(const Duration(milliseconds: 200), () {
            final controller = Get.find<LocationController>();
            controller.init();
          });
        }
      }
    }
  }

  _loadFiles() async {
    Future.delayed(const Duration(milliseconds: 200), () {
      final filePickerController = Get.find<FilePickerController>();
      filePickerController.loadAndroidFiles();
    });
  }

  void onInputTap() {
    if (controller == null) return;
    controller!.inputState = 1;

    if (controller!.mediaPickerInputController.text.trim().isNotEmpty) {
      controller!.sendState.value = true;
    }

    controller!.chatController.showFaceView.value = false;

    if (!inputFocusNode.hasFocus) {
      FocusScope.of(controller!.chatController.context)
          .requestFocus(inputFocusNode);
    }
  }

  void onChangeActionPage(int index) {
    if (controller == null) return;

    currentActionPage.value = index;
    if (index != 0) controller!.assetPickerProvider?.selectedAssets = [];
    if (optionList[index].optionType == MediaOption.contact.type)
      controller?.chatController.clearContactSearching();

    bottomTabController!.animateTo(index,
        duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
  }

  /// result content:
  /// params: [assets], [originalSelect], [caption],
  /// assets: List<AssetPreviewDetail>
  /// originalSelect: bool
  /// caption: String
  ///
  /// params: [sendAsFile]
  /// sendAsFile: bool
  void onSendTap({
    Map<String, dynamic>? result,
    bool sendAsFile = false,
  }) async {
    if (controller!.fileList.length > 1 &&
        controller!.mediaPickerInputController.text.trim().isNotEmpty) {
      Toast.showToast(localized(errorMoreThanOneFileSendCaption));
      return;
    }

    if (notBlank(result)) {
      if (result!.containsKey('originalSelect')) {
        originalSelect.value = result['originalSelect'] ?? false;
      }

      if (result.containsKey('caption')) {
        controller!.mediaPickerInputController.text = result['caption'] ?? '';
      }

      if (!result.containsKey('shouldSend') || !result['shouldSend']) {
        return;
      }
    }

    await controller!.onSend(
      controller!.mediaPickerInputController.text.isEmpty
          ? null
          : controller!.mediaPickerInputController.text.trim(),
      assets: result != null
          ? (result['assets'] ?? <AssetPreviewDetail>[])
          : <AssetPreviewDetail>[],
      isOriginalImageSend: originalSelect.value,
      sendAsFile: sendAsFile,
    );
    Get.back();
    return;
  }

  void navigateMediaPreview() {
    final selectedIdx;
    if (mediaPickerController.index == 0 &&
        controller!.assetPickerProvider!.selectedAssets.isNotEmpty) {
      selectedIdx = controller!.assetPickerProvider!.currentAssets
          .indexOf(controller!.assetPickerProvider!.selectedAssets.first);
    } else {
      selectedIdx = 0;
    }

    Get.toNamed(RouteName.mediaPreviewView,
        preventDuplicates: false,
        arguments: {
          'provider': controller!.assetPickerProvider,
          'pConfig': controller!.pickerConfig,
          'originalSelect': originalSelect.value,
          'isSelectedMode': mediaPickerController.index == 1,
          'caption': controller!.mediaPickerInputController.text,
          'index': selectedIdx,
        })?.then((result) {
      if (notBlank(result)) {
        onSendTap(result: result);
      }
    });
  }

  @override
  void dispose() {
    bottomTabController?.dispose();
    controller!.mediaPickerInputController.text = '';
    inputFocusNode.unfocus();
    controller?.fileList.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null) {
      return Container();
    }

    return GestureDetector(
      onTap: () {
        FocusManager().primaryFocus?.unfocus();
        inputFocusNode.unfocus();
      },
      behavior: HitTestBehavior.translucent,
      child: Obx(
        () => SizedBox(
          height: MediaQuery.of(context).size.height - Get.statusBarHeight,
          // height: currentHeight.value +
          // min(
          //   200,
          //   MediaQuery.of(context).viewInsets.bottom,
          // ),
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  Expanded(
                    child: TabBarView(
                      physics: const NeverScrollableScrollPhysics(),
                      controller: bottomTabController,
                      children: getTabBarView,
                    ),
                  ),

                  // 底部
                  if (controller!.sendState.value)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 133),
                      curve: Curves.easeOut,
                      key: const ValueKey('send'),
                      padding: EdgeInsets.only(
                        top: 4,
                        bottom: MediaQuery.of(context).padding.bottom + 8.0,
                      ),
                      margin: EdgeInsets.only(
                        bottom: controller!.sendState.value &&
                                MediaQuery.of(context).viewInsets.bottom > 0
                            ? MediaQuery.of(context).viewInsets.bottom
                            : 0.0,
                      ),
                      color: backgroundColor,
                      child: Column(
                        children: <Widget>[
                          if (widget.isPermissionGranted &&
                              widget.mediaOption == MediaOption.gallery)
                            ...assetInput(),

                          // File Send
                          if (widget.mediaOption == MediaOption.document)
                            fileInput(),
                        ],
                      ),
                    )
                ],
              ),
              if (false) // 解决附近位置最后一条无法点击，先封印
                Positioned(
                  bottom: 0.0,
                  left: 0.0,
                  right: 0.0,
                  child: IgnorePointer(
                    ignoring: controller!.sendState.value,
                    child: AnimatedOpacity(
                      opacity: controller!.sendState.value ? 0 : 0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOutCubic,
                      child: AnimatedAlign(
                        alignment: Alignment.topCenter,
                        duration: const Duration(milliseconds: 200),
                        heightFactor: controller!.sendState.value ? 0.8 : 1,
                        curve: Curves.easeInOutCubic,
                        child: Container(
                          key: const ValueKey('more'),
                          color: Colors.white,
                          padding: EdgeInsets.only(
                            left: 8.0,
                            right: 8.0,
                            top: 4,
                            bottom: MediaQuery.of(context).padding.bottom,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: _loadOptionList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _loadOptionList() {
    return List.generate(
      optionList.length,
      (index) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChangeActionPage(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // const SizedBox(height: 4.5),
              SvgPicture.asset(
                currentActionPage.value == index
                    ? optionList[index].checkImageUrl!
                    : optionList[index].unCheckImageUrl!,
                width: 28,
                height: 24,
              ),
              const SizedBox(height: 4.0),
              Obx(
                () => Text(
                  optionList[index].title,
                  style: TextStyle(
                    fontSize: 10.0,
                    fontWeight: MFontWeight.bold5.value,
                    color: currentActionPage.value == index
                        ? accentColor
                        : JXColors.supportingTextBlack,
                  ),
                ),
              ),
              const SizedBox(height: 5.0),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> get getTabBarView {
    List<Widget> children = [];
    for (ToolOptionModel option in optionList) {
      switch (option.optionType) {
        case 'gallery':
          children.add(widget.isPermissionGranted
              ? ValueListenableBuilder(
                  valueListenable: selectedAssets,
                  builder: (BuildContext context, List<AssetEntity> value,
                      Widget? child) {
                    return MediaPicker(
                      assetPickerProvider: controller!.assetPickerProvider!,
                      pickerConfig: controller!.pickerConfig!,
                      ps: controller!.ps!,
                      tag: widget.tag,
                      controller: mediaPickerController,
                      selectedAssets: value,
                      originalSelect: originalSelect.value,
                      onSendTap: (r) => onSendTap(result: r),
                    );
                  })
              : NoPermissionView(
                  title: localized(gallery),
                  imageUrl: 'assets/svgs/noPermission_state_photo.svg',
                  mainContent: localized(accessYourPhotoAndVideos),
                  subContent:
                      localized(toSendMedia, params: [Config().appName]),
                ));
          break;
        case 'document':
          children.add(widget.isPermissionGranted
              ? FilePickerBottomModal(
                  inputController: controller!,
                  picTag: widget.tag,
                )
              : NoPermissionView(
                  title: localized(files),
                  imageUrl: 'assets/svgs/noPermission_state_file.svg',
                  mainContent: localized(accessYourFiles),
                  subContent: localized(toSendFiles),
                ));
          break;
        case 'location':
          children.add(LocationSelector(inputController: controller!));
          break;
        case 'contact':
          controller?.chatController.getFriendList();
          children.add(ContactPicker(controller: controller!));
          break;
        case 'redPacket':
          children.add(RedPacket(tag: widget.tag));
          break;
        case 'task':
          children.add(TaskSelectorView(chat: controller!.chatController.chat));
          break;
        default:
      }
    }

    return children;
  }

  List<Widget> assetInput() {
    return [
      // Show caption
      if (bottomTabController!.index == 0 &&
          (controller!.assetPickerProvider!.selectedAssets.isNotEmpty))
        Padding(
          padding: const EdgeInsets.only(
            top: 4.0,
            left: 16.0,
            right: 16.0,
            bottom: 8.0,
          ),
          child: TextField(
            contextMenuBuilder: textMenuBar,
            autocorrect: false,
            enableSuggestions: false,
            textAlignVertical: TextAlignVertical.center,
            textAlign: controller!.mediaPickerInputController.text.isNotEmpty ||
                    inputFocusNode.hasFocus
                ? TextAlign.left
                : TextAlign.center,
            enabled: !(controller!.fileList.length > 1),
            maxLines: 10,
            minLines: 1,
            focusNode: inputFocusNode,
            controller: controller!.mediaPickerInputController,
            keyboardType: TextInputType.multiline,
            scrollPhysics: const ClampingScrollPhysics(),
            selectionControls: controller!.txtSelectControl,
            maxLength: 4096,
            inputFormatters: [
              LengthLimitingTextInputFormatter(4096),
            ],
            cursorColor: accentColor,
            style: const TextStyle(
              decoration: TextDecoration.none,
              fontSize: 16.0,
              color: Colors.black,
              height: 1.25,
              textBaseline: TextBaseline.alphabetic,
            ),
            enableInteractiveSelection: true,
            decoration: InputDecoration(
              hintText: localized(writeACaption),
              hintStyle: TextStyle(
                fontSize: 16.0,
                color: JXColors.supportingTextBlack,
                fontFamily: appFontfamily,
              ),
              isDense: true,
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
                borderSide: const BorderSide(
                  style: BorderStyle.none,
                  width: 0,
                ),
              ),
              isCollapsed: true,
              counterText: '',
              contentPadding: const EdgeInsets.only(
                top: 8,
                bottom: 8,
                right: 12,
                left: 16,
              ),
            ),
          ),
        ),

      // Selected
      if (bottomTabController?.index == 0)
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 24.0, right: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              /// View Button
              GestureDetector(
                onTap: navigateMediaPreview,
                child: OpacityEffect(
                  child: Text(
                    localized(previewImage),
                    style: jxTextStyle.textStyle17(color: accentColor),
                  ),
                ),
              ),

              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => originalSelect.value = !originalSelect.value,
                child: OpacityEffect(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => originalSelect.value = !originalSelect.value,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: CheckTickItem(
                            isCheck: originalSelect.value,
                          ),
                        ),
                        Text(
                          localized(original),
                          style: jxTextStyle.textStyleBold16(
                              color: JXColors.primaryTextBlack,
                              fontWeight: MFontWeight.bold6.value),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Send Button
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: controller!.sendState.value
                    ? () => onSendTap(result: {
                          'originalSelect': originalSelect.value,
                          'caption': controller!.mediaPickerInputController.text
                              .trim(),
                          'shouldSend': true,
                        })
                    : null,
                child: OpacityEffect(
                  child: Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(
                      left: 10.0,
                      right: 0.0,
                    ),
                    padding: const EdgeInsets.all(6.0),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: SvgPicture.asset(
                      'assets/svgs/send_arrow.svg',
                      width: 20,
                      height: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
    ];
  }

  Widget fileInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Visibility(
              visible: controller!.fileList.length == 1,
              child: TextField(
                contextMenuBuilder: textMenuBar,
                autocorrect: false,
                enableSuggestions: false,
                textAlignVertical: TextAlignVertical.center,
                textAlign: TextAlign.left,
                enabled: !(controller!.fileList.length > 1),
                maxLines: 10,
                minLines: 1,
                focusNode: inputFocusNode,
                controller: controller!.mediaPickerInputController,
                keyboardType: TextInputType.multiline,
                scrollPhysics: const ClampingScrollPhysics(),
                selectionControls: controller!.txtSelectControl,
                maxLength: 4096,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(4096),
                ],
                cursorColor: accentColor,
                style: const TextStyle(
                  decoration: TextDecoration.none,
                  fontSize: 16.0,
                  color: Colors.black,
                  height: 1.25,
                  textBaseline: TextBaseline.alphabetic,
                ),
                enableInteractiveSelection: true,
                decoration: InputDecoration(
                  hintText: localized(writeACaption),
                  hintStyle: const TextStyle(
                    fontSize: 16.0,
                    color: JXColors.supportingTextBlack,
                  ),
                  isDense: true,
                  fillColor: Colors.white30,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: const BorderSide(
                      color: JXColors.borderPrimaryColor,
                      style: BorderStyle.none,
                    ),
                  ),
                  isCollapsed: true,
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8.0),

          // Send Button
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: controller!.sendState.value
                ? () => onSendTap(sendAsFile: true)
                : null,
            child: ClipOval(
              child: Container(
                color: accentColor,
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(8.0),
                child: SvgPicture.asset(
                  'assets/svgs/send_arrow.svg',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget cancelWidget(BuildContext context) {
  return Align(
    alignment: Alignment.centerLeft,
    child: GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: OpacityEffect(
        child: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            localized(cancel),
            style: jxTextStyle.textStyle17(color: accentColor),
          ),
        ),
      ),
    ),
  );
}
