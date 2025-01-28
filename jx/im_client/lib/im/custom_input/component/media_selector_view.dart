import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/im/chat_info/tool_option_model.dart';
import 'package:jxim_client/im/custom_input/chat_translate_bar.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/contact_picker.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/file/file_picker_bottom_modal.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/file/file_picker_controller_we.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/location/location_selector.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/media_picker.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/task/task_selector_view.dart';
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/no_permission_view.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

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

  bool hasAudioRoom = true;

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
        (element) => element.optionType == MediaOption.task.type,
      );
    }

    if (controller!.type == 1 || !Config().enableRedPacket) {
      optionList.removeWhere(
        (element) => element.optionType == MediaOption.redPacket.type,
      );
    } else {
      if (!controller!.chatController.showGallery) {
        optionList.removeWhere(
          (element) => element.optionType == MediaOption.gallery.type,
        );
      }

      if (!controller!.chatController.showDocument) {
        optionList.removeWhere(
          (element) => element.optionType == MediaOption.document.type,
        );
      }

      if (!controller!.chatController.showContact) {
        optionList.removeWhere(
          (element) => element.optionType == MediaOption.contact.type,
        );
      }

      if (!controller!.chatController.showRedPacket) {
        optionList.removeWhere(
          (element) => element.optionType == MediaOption.redPacket.type,
        );
      }
    }

    if (widget.mediaOption != null) {
      optionList.removeWhere(
        (element) => element.optionType != widget.mediaOption!.type,
      );
    }

    mediaPickerController = TabController(
      length: 2,
      vsync: this,
    );

    if (optionList.first.optionType == 'document') {
      _loadFiles();
    }

    if (widget.isPermissionGranted) {
      controller!.assetPickerProvider?.addListener(() {
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
        (element) => element.optionType == MediaOption.audio.type,
      );
    }
  }

  handleTabSelection() {}

  _loadFiles() async {
    Future.delayed(const Duration(milliseconds: 200), () {
      final filePickerController =
          Get.findOrPut<FilePickerController>(FilePickerController());
      filePickerController.loadAndroidFiles();
    });
  }

  void onChangeActionPage(int index) {}

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
      if (result!.containsKey('caption')) {
        controller!.mediaPickerInputController.text = result['caption'] ?? '';
      }

      if (result['translation'] != null) {
        controller!.translatedText.value = result['translation'];
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
      sendAsFile: sendAsFile,
    );
    Get.back();
    return;
  }

  void navigateMediaPreview() {}

  @override
  void dispose() {
    controller!.mediaPickerInputController.text = '';
    inputFocusNode.unfocus();
    controller?.fileList.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null) return const SizedBox();

    return GestureDetector(
      onTap: () {
        FocusManager().primaryFocus?.unfocus();
        inputFocusNode.unfocus();
      },
      behavior: HitTestBehavior.translucent,
      child: Obx(
        () => SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
            children: <Widget>[
              Expanded(child: getChildWidget()),
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
                  color: colorBackground,
                  child: Column(
                    children: <Widget>[
                      Obx(() {
                        return Visibility(
                          visible: controller!.showTranslateBar.value,
                          child: ChatTranslateBar(
                            isTranslating: controller!.isTranslating.value,
                            translatedText: controller!.translatedText.value,
                            chat: controller!.chat!,
                            translateLocale: controller!.translateLocale.value,
                            needTopBorder:
                                widget.mediaOption == MediaOption.document,
                          ),
                        );
                      }),
                      if (widget.isPermissionGranted &&
                          widget.mediaOption == MediaOption.gallery)
                        assetInput(),
                      if (widget.isPermissionGranted &&
                          widget.mediaOption == MediaOption.document)
                        fileInput(),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget getChildWidget() {
    switch (optionList.first.optionType) {
      case 'gallery':
        return widget.isPermissionGranted
            ? ValueListenableBuilder(
                valueListenable: selectedAssets,
                builder: (
                  BuildContext context,
                  List<AssetEntity> value,
                  Widget? child,
                ) {
                  return MediaPicker(
                    assetPickerProvider: controller!.assetPickerProvider!,
                    pickerConfig: controller!.pickerConfig!,
                    ps: controller!.ps!,
                    tag: widget.tag,
                    controller: mediaPickerController,
                    selectedAssets: value,
                    onSendTap: (r) => onSendTap(result: r),
                  );
                },
              )
            : NoPermissionView(
                title: localized(gallery),
                imageUrl: 'assets/svgs/noPermission_state_photo.svg',
                mainContent: localized(accessYourPhotoAndVideos),
                subContent: localized(toSendMedia, params: [Config().appName]),
              );
      case 'document':
        return widget.isPermissionGranted
            ? FilePickerBottomModal(
                assetPickerProvider: controller!.assetPickerProvider!,
                pickerConfig: controller!.pickerConfig!,
                ps: controller!.ps!,
                inputController: controller!,
                picTag: widget.tag,
              )
            : NoPermissionView(
                title: localized(files),
                imageUrl: 'assets/svgs/noPermission_state_file.svg',
                mainContent: localized(accessYourFiles),
                subContent: localized(toSendFiles),
              );
      case 'location':
        return LocationSelector(inputController: controller!);
      case 'contact':
        controller?.chatController.getFriendList();
        return ContactPicker(controller: controller!);
      case 'redPacket':
        return RedPacket(tag: widget.tag);
      case 'task':
        return TaskSelectorView(chat: controller!.chatController.chat);
      default:
        return const SizedBox();
    }
  }

  List<Widget> get getTabBarView {
    return [];
  }

  Widget assetInput() {
    if (optionList.first.optionType == 'gallery' &&
        (controller!.assetPickerProvider!.selectedAssets.isNotEmpty)) {
      return Padding(
        padding: const EdgeInsets.only(
          top: 4.0,
          left: 16.0,
          right: 16.0,
          bottom: 8.0,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                contextMenuBuilder: textMenuBar,
                autocorrect: false,
                enableSuggestions: false,
                textAlignVertical: TextAlignVertical.center,
                textAlign:
                    controller!.mediaPickerInputController.text.isNotEmpty ||
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
                maxLength: 4096,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(4096),
                ],
                cursorColor: themeColor,
                style: jxTextStyle.headerText().copyWith(
                    decoration: TextDecoration.none,
                    textBaseline: TextBaseline.alphabetic,
                    height: 1.25),
                enableInteractiveSelection: true,
                decoration: InputDecoration(
                  hintText: localized(writeACaption),
                  hintStyle: jxTextStyle
                      .headerText(
                        color: colorTextPlaceholder,
                      )
                      .copyWith(height: 1.25),
                  isDense: true,
                  fillColor: colorSurface,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18.0),
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
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: controller!.sendState.value
                  ? () => onSendTap(
                        result: {
                          'caption': controller!.mediaPickerInputController.text
                              .trim(),
                          'shouldSend': true,
                        },
                      )
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
                    color: themeColor,
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
      );
    }

    return const SizedBox();
  }

  Widget fileInput() {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 4.0),
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
                textAlign:
                    controller!.mediaPickerInputController.text.isNotEmpty ||
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
                maxLength: 4096,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(4096),
                ],
                cursorColor: themeColor,
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
                    color: colorTextSupporting,
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
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: controller!.sendState.value
                ? () => onSendTap(sendAsFile: true)
                : null,
            child: ClipOval(
              child: Container(
                color: themeColor,
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
          padding: const EdgeInsets.only(
            left: 16,
            right: 24,
          ),
          child: Text(
            localized(cancel),
            style: jxTextStyle.textStyle17(color: themeColor),
          ),
        ),
      ),
    ),
  );
}
