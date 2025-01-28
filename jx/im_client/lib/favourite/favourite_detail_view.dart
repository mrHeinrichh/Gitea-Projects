import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/favourite/component/favourite_detail_cell/favourite_detail_album.dart';
import 'package:jxim_client/favourite/component/favourite_detail_cell/favourite_detail_document.dart';
import 'package:jxim_client/favourite/component/favourite_detail_cell/favourite_detail_location.dart';
import 'package:jxim_client/favourite/component/favourite_detail_cell/favourite_detail_voice.dart';
import 'package:jxim_client/favourite/component/favourite_detail_cell/favourite_reply_component.dart';
import 'package:jxim_client/favourite/component/favourite_note_embed_component.dart';
import 'package:jxim_client/favourite/favourite_detail_controller.dart';
import 'package:jxim_client/favourite/model/favourite_model.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/reply_model.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/component/special_avatar/secretary_message_icon.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';

class FavouriteDetailView extends GetView<FavouriteDetailController> {
  const FavouriteDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorSurface,
      appBar: _buildAppbar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shrinkWrap: true,
          children: [
            _buildHeaderLine(),
            ...buildContent(),
            Obx(() => controller.addSpace.value
                ? const SizedBox(height: 10)
                : const SizedBox()),
            _buildFooterLine(),
          ],
        ),
      ),
    );
  }

  // Author and updated date related
  PrimaryAppBar _buildAppbar() {
    return PrimaryAppBar(
      bgColor: colorBackground,
      elevation: 0.3,
      leadingWidth: 65,
      titleWidget: Obx(
        () => Text(
          controller.title.value,
          style: jxTextStyle.appTitleStyle(),
          textAlign: TextAlign.center,
        ),
      ),
      trailing: [
        controller.favouriteData?.userId != null &&
                objectMgr.userMgr.isMe(controller.favouriteData?.userId ?? 0)
            ? GestureDetector(
                onTap: () => controller.onMoreTap(),
                child: OpacityEffect(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: SvgPicture.asset(
                      'assets/svgs/chat_info_more.svg',
                      width: 22,
                      height: 22,
                      color: themeColor,
                    ),
                  ),
                ),
              )
            : const SizedBox(
                width: 38,
                height: 22,
              ),
      ],
    );
  }

  Padding _buildHeaderLine() {
    if (controller.isShowHeader.value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(child: CustomDivider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Obx(() {
                return Text(
                  controller.isHistory.value
                      ? controller.date.value
                      : localized(
                          favouriteFrom,
                          params: [
                            controller.authorName.value,
                            controller.date.value,
                          ],
                        ),
                  style: jxTextStyle.textStyle10(color: colorTextSecondary),
                );
              }),
            ),
            const Expanded(child: CustomDivider()),
          ],
        ),
      );
    } else {
      return const Padding(padding: EdgeInsets.zero);
    }
  }

  Row _buildFooterLine() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(child: CustomDivider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Container(
            width: 2,
            height: 2,
            decoration: const BoxDecoration(
              color: colorTextPlaceholder,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const Expanded(child: CustomDivider()),
      ],
    );
  }

  // Main content
  List<Widget> buildContent() {
    List<Widget> children = [];
    if (controller.deltaController != null) {
      children.add(
        QuillProvider(
          configurations: QuillConfigurations(
            controller: controller.deltaController!,
            sharedConfigurations: const QuillSharedConfigurations(),
          ),
          child: QuillEditor.basic(
            configurations: QuillEditorConfigurations(
              contextMenuBuilder:
                  (BuildContext ctx, QuillRawEditorState editorState) {
                return AdaptiveTextSelectionToolbar(
                  anchors: editorState.contextMenuAnchors,
                  children: [
                    // Custom context menu actions
                    TextButton(
                      onPressed: () {
                        _copySelectedText(editorState);
                        FocusManager.instance.primaryFocus?.unfocus();
                        _clearTextSelection(editorState);
                      },
                      style: ButtonStyle(
                        overlayColor:
                            MaterialStateProperty.all(colorBackground6),
                        splashFactory: NoSplash.splashFactory,
                      ),
                      child: Text(
                        localized(copy),
                        style: const TextStyle(
                          color: colorTextPrimary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _selectAllText(editorState);
                      },
                      style: ButtonStyle(
                        overlayColor:
                            MaterialStateProperty.all(colorBackground6),
                        splashFactory: NoSplash.splashFactory,
                      ),
                      child: Text(
                        localized(selectAll),
                        style: const TextStyle(
                          color: colorTextPrimary,
                        ),
                      ),
                    ),
                  ],
                );
              },
              embedBuilders: [
                DividerEmbedBuilder(),
                DocumentEmbedBuilder(),
                LocationEmbedBuilder(),
                VoiceEmbedBuilder(),
                VideoEmbedBuilder(),
                ImageEmbedBuilder(),
              ],
              readOnly: true,
              showCursor: false,
              customStyleBuilder: (Attribute<dynamic> attribute) {
                if (attribute.key == 'phone' || attribute.key == 'link') {
                  return TextStyle(
                    fontSize: MFontSize.size17.value,
                    color: colorLink,
                    decoration: TextDecoration.none,
                  );
                }
                return TextStyle(
                  fontSize: MFontSize.size17.value,
                  color: colorTextPrimary,
                  decoration: TextDecoration.none,
                );
              },
              customRecognizerBuilder:
                  (Attribute<dynamic> attribute, Leaf leaf) {
                if (attribute.key == 'phone') {
                  return TapGestureRecognizer()
                    ..onTap = () {
                      final phoneNumber = leaf.toPlainText();
                      handlePhoneTap(phoneNumber);
                    };
                }
                return null;
              },
            ),
          ),
        ),
      );
      return children;
    }
    int previousSendId = 0;
    final List<FavouriteDetailData> contentList =
        controller.favouriteData?.content ?? [];

    for (int i = 0; i < contentList.length; i++) {
      FavouriteDetailData data = contentList[i];
      List<Widget> widgets = [];
      bool showAvatar = true;

      switch (data.typ) {
        case FavouriteTypeText:
        case FavouriteTypeLink:
          widgets.addAll(_buildTextOrLinkContent(data));
          break;
        case FavouriteTypeImage:
        case FavouriteTypeVideo:
          widgets.add(_buildMediaContent(data));
          break;
        case FavouriteTypeAudio:
          widgets.addAll(_buildAudioContent(data));
          break;
        case FavouriteTypeDocument:
          widgets.addAll(_buildDocumentContent(data));
          break;
        case FavouriteTypeLocation:
          widgets.add(_buildLocationContent(data));
          break;
        case FavouriteTypeAlbum:
          widgets.addAll(_buildAlbumContent(data));
          break;
      }

      if (data.sendId != null && controller.isHistory.value) {
        bool isAiBot =
            controller.favouriteData!.chatTyp == chatTypeSmallSecretary &&
                !objectMgr.userMgr.isMe(data.sendId!);
        if (previousSendId == data.sendId && !isAiBot) {
          showAvatar = false;
        }
        children.add(
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showAvatar)
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: isAiBot
                          ? const SecretaryMessageIcon(
                              size: 36,
                            )
                          : CustomAvatar.normal(
                              data.sendId!,
                              key: ValueKey(data.sendId!),
                              size: 36,
                              headMin: Config().headMin,
                            ),
                    )
                  else
                    const SizedBox(width: 48), // Space reserved for the avatar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: isAiBot
                                    ? Text(
                                        localized(chatSecretary),
                                        style: jxTextStyle.textStyle12(
                                          color: colorTextSecondary,
                                        ),
                                      )
                                    : NicknameText(
                                        uid: data.sendId!,
                                        fontSize: MFontSize.size12.value,
                                        color: colorTextSecondary,
                                      ),
                              ),
                            ),
                            Obx(() {
                              return Text(
                                controller.showDateTime.value
                                    ? FormatTime.getMMDDHHMM(data.sendTime!)
                                    : FormatTime.chartTime(
                                        data.sendTime!, false),
                                style: jxTextStyle.textStyle12(
                                    color: colorTextSecondary),
                              );
                            }),
                          ],
                        ),
                        ...widgets,
                      ],
                    ),
                  ),
                ],
              ),
              // Check if this is not the last item
              if (i != contentList.length - 1)
                const Padding(
                  padding: EdgeInsets.only(left: 48.0, top: 16),
                  child: CustomDivider(),
                ),
            ],
          ),
        );
        previousSendId = data.sendId!;
      } else {
        children.addAll(widgets);
      }
      children.add(const SizedBox(height: 16));
    }

    return children;
  }

  List<Widget> _buildTextOrLinkContent(FavouriteDetailData data) {
    List<Widget> children = [];
    String text = '';
    String? translation;
    FavouriteText? favouriteText;

    try {
      favouriteText = FavouriteText.fromJson(jsonDecode(data.content!));
      text = favouriteText.text;

      if (favouriteText.forwardUserId != null && controller.isHistory.value) {
        children.add(_buildForwardWidget());
      }

      if (favouriteText.reply != null && controller.isHistory.value) {
        children.add(_buildReplyComponent(favouriteText.reply!, data.sendId!));
      }

      translation = favouriteText.translation;
    } catch (e) {
      text = data.content!;
    }

    children.add(_buildQuillEditor(controller.addQuillController(text)));

    if (translation != null) {
      children.add(_buildTranslationWidget(translation));
    }

    return children;
  }

  // For text and link related
  Widget _buildQuillEditor(int controllerIndex) {
    return QuillProvider(
      configurations: QuillConfigurations(
        controller: controller.quillControllers[controllerIndex],
        sharedConfigurations: const QuillSharedConfigurations(),
      ),
      child: QuillEditor.basic(
        configurations: QuillEditorConfigurations(
          contextMenuBuilder:
              (BuildContext ctx, QuillRawEditorState editorState) {
            return AdaptiveTextSelectionToolbar(
              anchors: editorState.contextMenuAnchors,
              children: [
                // Custom context menu actions
                TextButton(
                  onPressed: () {
                    _copySelectedText(editorState);
                    FocusManager.instance.primaryFocus?.unfocus();
                    _clearTextSelection(editorState);
                  },
                  style: ButtonStyle(
                    overlayColor: MaterialStateProperty.all(colorBackground6),
                    splashFactory: NoSplash.splashFactory,
                  ),
                  child: Text(
                    localized(copy),
                    style: const TextStyle(
                      color: colorTextPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _selectAllText(editorState);
                  },
                  style: ButtonStyle(
                    overlayColor: MaterialStateProperty.all(colorBackground6),
                    splashFactory: NoSplash.splashFactory,
                  ),
                  child: Text(
                    localized(selectAll),
                    style: const TextStyle(
                      color: colorTextPrimary,
                    ),
                  ),
                ),
              ],
            );
          },
          embedBuilders: [DividerEmbedBuilder()],
          readOnly: true,
          showCursor: false,
          customStyleBuilder: (Attribute<dynamic> attribute) {
            if (attribute.key == 'phone' || attribute.key == 'link') {
              return TextStyle(
                fontSize: MFontSize.size17.value,
                color: colorLink,
                decoration: TextDecoration.none,
              );
            }
            return TextStyle(
              fontSize: MFontSize.size17.value,
              color: colorTextPrimary,
              decoration: TextDecoration.none,
            );
          },
          customRecognizerBuilder: (Attribute<dynamic> attribute, Leaf leaf) {
            if (attribute.key == 'phone') {
              return TapGestureRecognizer()
                ..onTap = () {
                  final phoneNumber = leaf.toPlainText();
                  handlePhoneTap(phoneNumber);
                };
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildCaptionWidget(String caption) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: _buildQuillEditor(controller.addQuillController(caption)),
    );
  }

  // FavouriteImage and FavouriteVideo
  Widget _buildMediaContent(FavouriteDetailData data) {
    Widget mediaContent;
    Widget? captionWidget;
    Widget? translationWidget;
    Widget? forwardWidget;
    Widget? replyWidget;

    final dynamic media = (data.typ == FavouriteTypeImage)
        ? FavouriteImage.fromJson(jsonDecode(data.content!))
        : FavouriteVideo.fromJson(jsonDecode(data.content!));

    if (media.forwardUserId != null && controller.isHistory.value) {
      forwardWidget = _buildForwardWidget();
    }

    mediaContent = Hero(
      tag: media.url,
      child: GestureDetector(
        onTap: () => controller.onTapMedia(data),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: media is FavouriteImage
              ? RemoteImage(
                  src: media.url,
                  width: media.width.toDouble(),
                  fit: BoxFit.cover,
                  mini: Config().sMessageMin,
                )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    RemoteImage(
                      src: media.cover.isNotEmpty
                          ? media.cover
                          : media.coverPath,
                      width: media.width.toDouble(),
                      fit: BoxFit.cover,
                      mini: Config().sMessageMin,
                    ),
                    SvgPicture.asset('assets/svgs/video_play_icon.svg',
                        width: 40, height: 40),
                  ],
                ),
        ),
      ),
    );

    if (controller.isHistory.value) {
      mediaContent = GridView(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 4.0,
          crossAxisSpacing: 4.0,
        ),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: [
          mediaContent,
        ],
      );
    }

    if (media.reply != null && controller.isHistory.value) {
      replyWidget = _buildReplyComponent(media.reply!, data.sendId!);
    }

    if (media.caption != null) {
      captionWidget = _buildCaptionWidget(media.caption!);
    }

    if (media.translation != null) {
      translationWidget = _buildTranslationWidget(media.translation!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (replyWidget != null) replyWidget,
        if (forwardWidget != null) forwardWidget,
        mediaContent,
        if (captionWidget != null) captionWidget,
        if (translationWidget != null) translationWidget,
      ],
    );
  }

  List<Widget> _buildAudioContent(FavouriteDetailData data) {
    List<Widget> children = [];
    FavouriteVoice voice = FavouriteVoice.fromJson(jsonDecode(data.content!));

    if (voice.forwardUserId != null && controller.isHistory.value) {
      children.add(_buildForwardWidget());
    }

    if (voice.reply != null && controller.isHistory.value) {
      children.add(_buildReplyComponent(voice.reply!, data.sendId!));
    }

    children.add(FavouriteDetailVoice(data: voice));

    if (voice.transcribe != null) {
      children.add(_buildCaptionWidget(voice.transcribe!));
    }

    if (voice.translation != null) {
      children.add(_buildTranslationWidget(voice.translation!));
    }

    return children;
  }

  List<Widget> _buildDocumentContent(FavouriteDetailData data) {
    List<Widget> children = [];
    FavouriteFile file = FavouriteFile.fromJson(jsonDecode(data.content!));

    if (file.forwardUserId != null && controller.isHistory.value) {
      children.add(_buildForwardWidget());
    }

    if (file.reply != null && controller.isHistory.value) {
      children.add(_buildReplyComponent(file.reply!, data.sendId!));
    }

    children.add(FavouriteDetailDocument(data: file));

    if (file.caption != null) {
      children.add(_buildCaptionWidget(file.caption!));
    }

    if (file.translation != null) {
      children.add(_buildTranslationWidget(file.translation!));
    }

    return children;
  }

  List<Widget> _buildAlbumContent(FavouriteDetailData data) {
    List<Widget> children = [];
    FavouriteAlbum album = FavouriteAlbum.fromJson(jsonDecode(data.content!));

    if (album.forwardUserId != null && controller.isHistory.value) {
      children.add(_buildForwardWidget());
    }

    if (album.reply != null && controller.isHistory.value) {
      children.add(_buildReplyComponent(album.reply!, data.sendId!));
    }

    children.add(FavouriteDetailAlbum(data: album));

    if (album.caption != null) {
      children.add(_buildCaptionWidget(album.caption!));
    }

    if (album.translation != null) {
      children.add(_buildTranslationWidget(album.translation!));
    }

    return children;
  }

  Widget _buildLocationContent(FavouriteDetailData data) {
    FavouriteLocation location =
        FavouriteLocation.fromJson(jsonDecode(data.content!));

    FavouriteDetailLocation locationWidget =
        FavouriteDetailLocation(data: location);

    if (location.forwardUserId != null && controller.isHistory.value) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Text(localized(forwarded),
                style: jxTextStyle.textStyle14(color: colorTextSecondary)),
          ),
          locationWidget,
        ],
      );
    }

    return locationWidget;
  }

  Widget _buildForwardWidget() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        localized(forwarded),
        style: jxTextStyle.textStyle14(
          color: colorTextSecondary,
        ),
      ),
    );
  }

  Widget _buildReplyComponent(String reply, int sendId) {
    ReplyModel replyModel = ReplyModel.fromJson(jsonDecode(reply));
    return FavouriteReplyComponent(
        replyModel: replyModel,
        isGroup: controller.favouriteData!.isGroupChat,
        sendId: sendId);
  }

  Widget _buildTranslationWidget(String translation) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 6.0),
          child: CustomDivider(),
        ),
        _buildQuillEditor(controller.addQuillController(translation)),
      ],
    );
  }

  /// Text menu related
  void _selectAllText(QuillRawEditorState editorState) {
    // Get the current text
    final text = editorState.textEditingValue.text;

    // Create a selection that spans the entire text
    final newSelection =
        TextSelection(baseOffset: 0, extentOffset: text.length);

    // Update the editor state with the new selection
    editorState.userUpdateTextEditingValue(
      editorState.textEditingValue.copyWith(selection: newSelection),
      SelectionChangedCause.toolbar,
    );
  }

  void _copySelectedText(QuillRawEditorState editorState) {
    // Get the current text selection
    final selection = editorState.textEditingValue.selection;

    // Check if there is a valid selection
    if (selection.isValid && !selection.isCollapsed) {
      // Extract the selected text
      final selectedText = editorState.textEditingValue.text
          .substring(selection.start, selection.end);

      // Copy the selected text to the clipboard
      copyToClipboard(selectedText);
    }
  }

  void _clearTextSelection(QuillRawEditorState editorState) {
    // Clear the text selection by collapsing it to the end of the current selection
    final textLength = editorState.textEditingValue.text.length;
    editorState.userUpdateTextEditingValue(
      editorState.textEditingValue.copyWith(
        selection: TextSelection.collapsed(offset: textLength),
      ),
      SelectionChangedCause.toolbar,
    );
  }
}
