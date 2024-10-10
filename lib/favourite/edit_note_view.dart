import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/favourite/component/favourite_note_embed_component.dart';
import 'package:jxim_client/favourite/edit_note_controller.dart';
import 'package:jxim_client/im/custom_input/component/chat_attachment_view.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

class EditNoteView extends GetView<EditNoteController> {
  const EditNoteView({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await controller.onPop();
      },
      child: Scaffold(
        backgroundColor: colorSurface,
        appBar: _noteAppbar(context),
        body: SafeArea(
          bottom: false,
          child: QuillProvider(
            configurations: QuillConfigurations(
              controller: controller.quillController,
              sharedConfigurations: const QuillSharedConfigurations(),
            ),
            child: GestureDetector(
              onTap: () {
                controller.editorFocusNode.requestFocus();
              },
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      child: ListView(
                        controller: controller.scrollController,
                        physics: const BouncingScrollPhysics(),
                        shrinkWrap: true,
                        children: [
                          QuillEditor.basic(
                            focusNode: controller.editorFocusNode,
                            configurations: QuillEditorConfigurations(
                              autoFocus: !controller.isUpdateNote.value,
                              embedBuilders: [
                                DividerEmbedBuilder(),
                                DocumentEmbedBuilder(),
                                LocationEmbedBuilder(),
                                VoiceEmbedBuilder(),
                                VideoEmbedBuilder(),
                                ImageEmbedBuilder(),
                              ],
                              placeholder: localized(noteEditorPlaceHolder),
                              customStyles: DefaultStyles(
                                // placeholder style
                                placeHolder: DefaultTextBlockStyle(
                                  TextStyle(
                                    fontSize: MFontSize.size17.value,
                                    color: colorTextPlaceholder,
                                  ),
                                  const VerticalSpacing(0, 0),
                                  const VerticalSpacing(0, 0),
                                  null,
                                ),
                              ),
                              customStyleBuilder:
                                  (Attribute<dynamic> attribute) {
                                return TextStyle(
                                  fontSize: MFontSize.size17.value,
                                );
                              },
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height / 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Obx(() {
                    return Visibility(
                      visible: controller.editorFocusNode.hasFocus ||
                          controller.isShowAttachmentOptions.value,
                      child: _customToolbar(context),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PrimaryAppBar _noteAppbar(context) {
    return PrimaryAppBar(
      bgColor: colorSurface,
      onPressedBackBtn: () async {
        bool canPop = await controller.onPop();
        if (canPop) {
          Get.back();
        }
      },
      title: localized(noteEditTitle),
      trailing: [
        Obx(() {
          return OpacityEffect(
            child: GestureDetector(
              onTap: controller.undo,
              child: SvgPicture.asset(
                'assets/svgs/undo_icon.svg',
                color:
                    controller.hasUndo.value ? themeColor : colorTextSupporting,
              ),
            ),
          );
        }),
        Obx(() {
          return OpacityEffect(
            child: GestureDetector(
              onTap: controller.redo,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SvgPicture.asset(
                  'assets/svgs/redo_icon.svg',
                  color: controller.hasRedo.value
                      ? themeColor
                      : colorTextSupporting,
                ),
              ),
            ),
          );
        }),
        OpacityEffect(
          child: GestureDetector(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              if (controller.needSave.value || controller.isUpdateNote.value) {
                _onMoreTap(context);
              }
            },
            child: Obx(() {
              return SvgPicture.asset(
                'assets/svgs/chat_info_more.svg',
                width: 22,
                height: 22,
                color:
                    controller.isUpdateNote.value || controller.needSave.value
                        ? themeColor
                        : colorTextSupporting,
              );
            }),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _customToolbar(buildContext) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 233),
          curve: Curves.easeOut,
          decoration: const BoxDecoration(
            color: colorBackground,
            border: Border(
              top: BorderSide(
                color: colorTextPlaceholder,
                width: 0.33,
              ),
            ),
          ),
          padding: EdgeInsets.only(
            right: 20,
            top: 15,
            bottom: 15 +
                ((controller.editorFocusNode.hasFocus ||
                        controller.isShowAttachmentOptions.value)
                    ? 0
                    : MediaQuery.of(buildContext).viewPadding.bottom),
          ),
          child: Stack(
            children: [
              _editorToolbarOptions(),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: _toolbarTrailing(),
              ),
            ],
          ),
        ),
        Obx(() {
          return AnimatedContainer(
            color: colorBackground,
            duration: const Duration(milliseconds: 233),
            curve: Curves.easeOut,
            height: controller.isShowAttachmentOptions.value
                ? controller.getPanelFixHeight
                : 0,
            child: ChatAttachmentView(
              options: [
                ChatAttachmentOption(
                  icon: 'assets/svgs/attachment_picture.svg',
                  title: localized(attachmentCallPicture),
                  onTap: () {
                    controller.showBottomPopup(
                      buildContext,
                      MediaOption.gallery,
                    );
                  },
                ),
                ChatAttachmentOption(
                  icon: 'assets/svgs/attachment_camera.svg',
                  title: localized(attachmentCamera),
                  onTap: () {
                    controller.onPhoto(buildContext);
                  },
                ),
                ChatAttachmentOption(
                  icon: 'assets/svgs/attachment_location.svg',
                  title: localized(attachmentLocation),
                  onTap: () {
                    controller.showBottomPopup(
                      buildContext,
                      MediaOption.location,
                    );
                  },
                ),
                ChatAttachmentOption(
                  icon: 'assets/svgs/attachment_file.svg',
                  title: localized(attachmentFiles),
                  onTap: () {
                    controller.showBottomPopup(
                      buildContext,
                      MediaOption.document,
                    );
                  },
                ),
                // ChatAttachmentOption(
                //   icon: 'assets/svgs/mic.svg',
                //   title: localized(attachmentRecording),
                //   onTap: () {},
                // ),
              ],
              onHideAttachmentView: () {},
            ),
          );
        }),
      ],
    );
  }

  Widget _editorToolbarOptions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const SizedBox(width: 20),
          OpacityEffect(
            child: GestureDetector(
              onTap: controller.onTapBoldButton,
              child: Obx(() {
                return SvgPicture.asset(
                  'assets/svgs/bold_icon.svg',
                  color:
                      controller.isBold.value ? themeColor : colorTextPrimary,
                );
              }),
            ),
          ),
          const SizedBox(width: 40),
          OpacityEffect(
            child: GestureDetector(
              onTap: controller.onTapHighlightButton,
              child: Obx(() {
                return SvgPicture.asset(
                  'assets/svgs/highlight_icon.svg',
                  color: controller.isHighlight.value
                      ? themeColor
                      : colorTextPrimary,
                );
              }),
            ),
          ),
          const SizedBox(width: 40),
          OpacityEffect(
            child: GestureDetector(
              onTap: controller.onTapOrderedListButton,
              child: Obx(() {
                return SvgPicture.asset(
                  'assets/svgs/ordered_list_icon.svg',
                  color: controller.isOrderedList.value
                      ? themeColor
                      : colorTextPrimary,
                );
              }),
            ),
          ),
          const SizedBox(width: 40),
          OpacityEffect(
            child: GestureDetector(
              onTap: controller.onTapUnorderedListButton,
              child: Obx(() {
                return SvgPicture.asset(
                  'assets/svgs/unordered_list_icon.svg',
                  color: controller.isUnorderedList.value
                      ? themeColor
                      : colorTextPrimary,
                );
              }),
            ),
          ),
          const SizedBox(width: 40),
          OpacityEffect(
            child: GestureDetector(
              onTap: controller.onTapCheckListButton,
              child: Obx(() {
                return SvgPicture.asset(
                  'assets/svgs/checklist_icon.svg',
                  color: controller.isCheckList.value
                      ? themeColor
                      : colorTextPrimary,
                );
              }),
            ),
          ),
          const SizedBox(width: 40),
          OpacityEffect(
            child: GestureDetector(
              onTap: controller.onTapTimestampButton,
              child: SvgPicture.asset(
                'assets/svgs/timestamp_icon.svg',
              ),
            ),
          ),
          const SizedBox(width: 40),
          OpacityEffect(
            child: GestureDetector(
              onTap: controller.onTapDividerButton,
              child: SvgPicture.asset(
                'assets/svgs/divider_icon.svg',
              ),
            ),
          ),
          const SizedBox(width: 76),
        ],
      ),
    );
  }

  Widget _toolbarTrailing() {
    return Container(
      color: colorBackground,
      child: Row(
        children: [
          const VerticalDivider(
            width: 0.33,
            color: colorTextPlaceholder,
          ),
          const SizedBox(width: 24),
          OpacityEffect(
            child: GestureDetector(
              onTap: controller.toggleOptionsVisibility,
              child: Obx(() {
                return SvgPicture.asset(
                  controller.isShowAttachmentOptions.value
                      ? 'assets/svgs/nav.svg'
                      : 'assets/svgs/paper_clip.svg',
                  color: colorTextPrimary,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  void _onMoreTap(context) {
    showCustomBottomAlertDialog(
      context,
      withHeader: false,
      items: [
        CustomBottomAlertItem(
          text: localized(sendToChat),
          onClick: () {
            controller.sendToChat();
          },
        ),
        CustomBottomAlertItem(
          text: localized(editTags),
          onClick: () {
            Get.toNamed(
              RouteName.favouriteEditTag,
              preventDuplicates: false,
              arguments: {
                'tagDataList': controller.tagList,
              },
            )?.then((result) async {
              if (notBlank(result)) {
                if (result!.containsKey('tag')) {
                  List<String> tag = result['tag'];
                  controller.processTag(tag);
                }
              }
            });
          },
        ),
        CustomBottomAlertItem(
          text: localized(buttonDelete),
          textColor: colorRed,
          onClick: () => controller.onDeleteTap(),
        ),
      ],
    );
  }
}
