import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as im;
import 'package:intl/intl.dart';
import 'package:jxim_client/camera/camerawesome_page.dart';
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/favourite/favourite_asset_view.dart';
import 'package:jxim_client/favourite/model/favourite_model.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/file/file_picker_controller_we.dart';
import 'package:jxim_client/im/services/media/general_file_picker.dart';
import 'package:jxim_client/im/services/media/general_media_picker.dart';
import 'package:jxim_client/im/services/media/location_picker.dart';
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/transparent_page_route.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/file_type_util.dart';
import 'package:jxim_client/utils/keyboard_util.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/permissions.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_dialog.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_item.dart';
import 'package:jxim_client/views/component/custom_confirmation_popup.dart';
import 'package:jxim_client/views/component/no_permission_view.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class EditNoteController extends GetxController {
  QuillController quillController = QuillController(
    document: Document(),
    keepStyleOnNewLine: true,
    selection: const TextSelection.collapsed(offset: 0),
  );
  FocusNode editorFocusNode = FocusNode();

  final isBold = false.obs;
  final isHighlight = false.obs;
  final isOrderedList = false.obs;
  final isUnorderedList = false.obs;
  final isCheckList = false.obs;
  final colorNoteTextBackground = '#FFEDB2';
  final isShowAttachmentOptions = false.obs;
  final keyboardHeight = 0.0.obs;
  final favouriteDetailList = <FavouriteDetailData>[].obs;
  final hasUndo = false.obs;
  final hasRedo = false.obs;
  final needSave = false.obs;
  final isUpdateNote = false.obs;

  FavouriteData? favouriteData;
  Map<int, dynamic> favouriteMediaList = {};
  List<AssetPreviewDetail> assetList = [];
  Map<int, FavouriteDetailData> assetToUpload = {};
  List<String> urls = [];
  List<String> tagList = [];

  ScrollController scrollController = ScrollController();
  DefaultAssetPickerProvider? assetPickerProvider;
  AssetPickerConfig? pickerConfig;
  PermissionState? ps;
  RxList<AssetEntity> selectedAssetList = <AssetEntity>[].obs;
  RxList<File> fileList = <File>[].obs;

  int docLength = 0;
  bool isFilePicking = false;
  bool isMediaPicking = false;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null) {
      favouriteData = Get.arguments[0];
      if (favouriteData!.isNote) {
        isUpdateNote.value = true;
        FavouriteDelta favouriteDelta = FavouriteDelta.fromJson(
          jsonDecode(favouriteData!.content.last.content!),
        );
        quillController.document = Document.fromDelta(
          favouriteDelta.delta,
        );
        favouriteDetailList.addAll(favouriteData!.content);
        for (FavouriteDetailData data in favouriteData!.content) {
          if (data.typ == FavouriteTypeImage ||
              data.typ == FavouriteTypeVideo) {
            favouriteMediaList[data.id!] = data;
          }
        }
      } else {
        needSave.value = true;
        convertFavouriteDetailToEmbed(favouriteData!.content);
      }
      urls.addAll(favouriteData!.urls ?? []);
      tagList.addAll(favouriteData!.tag);
    }
    scrollController.addListener(_onScroll);
    editorFocusNode.addListener(_onFocusNodeChange);
    quillController.addListener(_onQuillContentChanged);
  }

  @override
  void onClose() {
    super.onClose();
    quillController.removeListener(_onQuillContentChanged);
    quillController.dispose();
  }

  Future<bool> onPop() async {
    FocusManager.instance.primaryFocus?.unfocus();
    Document doc = quillController.document;
    if (needSave.value) {
      Delta delta = doc.toDelta();
      FavouriteDelta favouriteDelta = FavouriteDelta(delta: delta);
      if (isUpdateNote.value) {
        if (doc.length > 1) {
          objectMgr.favouriteMgr.updateNote(
            assetToUpload,
            favouriteDelta,
            urls,
            tagList,
            favouriteData!,
          );
          return true;
        } else {
          await showCustomBottomAlertDialog(
            Get.context!,
            title: localized(alertEmptyNote),
            items: [
              CustomBottomAlertItem(
                  text: localized(undoChanges),
                  onClick: () {
                    Get.back();
                    return true;
                  }),
              CustomBottomAlertItem(
                text: localized(deleteNote),
                textColor: colorRed,
                onClick: () {
                  objectMgr.favouriteMgr.deleteFavourite([favouriteData!]);
                  Get.back();
                  return true;
                },
              ),
            ],
          );
        }
        return false;
      } else {
        objectMgr.favouriteMgr.createFavouriteNote(
          assetToUpload,
          favouriteDelta,
          urls,
          tagList,
        );
        return true;
      }
    }
    return true;
  }

  void sendToChat() async {
    FocusManager.instance.primaryFocus!.unfocus();
    Document doc = quillController.document;
    if (doc.length > 1 && needSave.value) {
      im.showLoading();
      Delta delta = doc.toDelta();
      FavouriteDelta favouriteDelta = FavouriteDelta(delta: delta);
      if (isUpdateNote.value) {
        favouriteData = await objectMgr.favouriteMgr.updateNote(
          assetToUpload,
          favouriteDelta,
          urls,
          tagList,
          favouriteData!,
        );
      } else {
        favouriteData = await objectMgr.favouriteMgr.createFavouriteNote(
          assetToUpload,
          favouriteDelta,
          urls,
          tagList,
        );
      }
      im.dismissLoading();
      objectMgr.favouriteMgr.forwardFavouriteList([favouriteData!]);
      if (favouriteData!.isNote) {
        isUpdateNote.value = true;
        FavouriteDelta favouriteDelta = FavouriteDelta.fromJson(
          jsonDecode(favouriteData!.content.last.content!),
        );
        quillController.document = Document.fromDelta(
          favouriteDelta.delta,
        );
        favouriteDetailList.clear();
        favouriteDetailList.addAll(favouriteData!.content);
        favouriteMediaList.clear();
        for (FavouriteDetailData data in favouriteData!.content) {
          if (data.typ == FavouriteTypeImage ||
              data.typ == FavouriteTypeVideo) {
            favouriteMediaList[data.id!] = data;
          }
        }
      }
      urls.clear();
      tagList.clear();
      urls.addAll(favouriteData!.urls ?? []);
      tagList.addAll(favouriteData!.tag);
      needSave.value = false;
      isUpdateNote.value = true;
    } else {
      objectMgr.favouriteMgr.forwardFavouriteList([favouriteData!]);
    }
  }

  onDeleteTap() async {
    if (isUpdateNote.value) {
      await showModalBottomSheet(
        context: Get.context!,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return CustomConfirmationPopup(
            title: localized(confirmToDelete),
            confirmButtonColor: colorRed,
            cancelButtonColor: themeColor,
            confirmButtonText: localized(buttonDelete),
            cancelButtonText: localized(buttonCancel),
            confirmCallback: () async {
              if (favouriteData != null) {
                await objectMgr.favouriteMgr.deleteFavourite([favouriteData!]);
                Get.back();
              }
            },
            cancelCallback: () => Get.back(),
          );
        },
      );
    } else {
      needSave.value = false;
      Get.back();
    }
  }

  _onQuillContentChanged() {
    final currentDoc = quillController.document;
    if (isUpdateNote.value) {
      needSave.value = true;
    } else {
      needSave.value = currentDoc.length > 1;
    }
    _checkDocumentStyleChanges();
    if (currentDoc.length >= docLength) {
      docLength = currentDoc.length;
    } else {
      _checkAndRemoveEmbed(currentDoc);
    }
  }

  void _checkAndRemoveEmbed(Document doc) {
    List<int> idList = [];
    for (var operation in doc.toDelta().toList()) {
      if (operation.isInsert && operation.value is Map) {
        final value = operation.value as Map<String, dynamic>;
        if (value.containsKey('custom')) {
          Map<String, dynamic> dataMap = jsonDecode(value['custom']);
          Map<String, dynamic> result = jsonDecode(dataMap.values.first);
          idList.add(result['id']);
        }
      }
    }

    if (idList.length != favouriteDetailList.length) {
      List<FavouriteDetailData> missingIds = favouriteDetailList.where((data) {
        return !idList.contains(data.id);
      }).toList();
      for (FavouriteDetailData data in missingIds) {
        favouriteDetailList.remove(data);
        if (favouriteMediaList[data.id ?? data.hashCode] != null) {
          favouriteMediaList.remove(data.id ?? data.hashCode);
          assetToUpload.remove(data.id);
        }
      }
    }
  }

  _onFocusNodeChange() {
    if (editorFocusNode.hasFocus) {
      isShowAttachmentOptions.value = false;
    }
  }

  _onScroll() {
    if (editorFocusNode.hasFocus) {
      editorFocusNode.unfocus();
    }
    // if (scrollController.position.atEdge) {
    //   if (scrollController.position.pixels != 0) {
    //     // Animate back to top, logic need check again
    //     Future.delayed(_scrollDelay, () async {
    //       scrollController.animateTo(
    //         0,
    //         duration: _scrollDuration,
    //         curve: Curves.easeOut,
    //       );
    //     });
    //   }
    // }
  }

  void convertFavouriteDetailToEmbed(List<FavouriteDetailData> list) {
    for (FavouriteDetailData data in list) {
      switch (data.typ) {
        case FavouriteTypeText:
        case FavouriteTypeLink:
          _addTextToQuillController(data: data);
          break;
        case FavouriteTypeImage:
        case FavouriteTypeVideo:
          _addMediaToQuillController(data);
          break;
        case FavouriteTypeAudio:
          // _addVoiceToQuillController(data);
          break;
        case FavouriteTypeDocument:
          _addDocumentToQuillController(data);
          break;
        case FavouriteTypeLocation:
          _addLocationToQuillController(data);
          break;
        case FavouriteTypeAlbum:
          _addAlbumToQuillController(data);
          break;
      }

      // Insert new line
      _insertNewLine();
    }

    _scrollToBottom();
  }

  void _insertNewLine() {
    final length = quillController.document.length;
    int position = quillController.selection.isValid
        ? quillController.selection.baseOffset
        : length;

    // Ensure position is within the valid range, 0 <= position <= length
    if (position < 0 || position > length) {
      position = length;
    }

    quillController.replaceText(position, 0, '\n\n', null);

    // Update the cursor to be after the new line
    quillController.updateSelection(
      TextSelection.collapsed(offset: position + 2),
      ChangeSource.local,
    );
  }

  void _addTextToQuillController({FavouriteDetailData? data, String? caption}) {
    String text = '';
    FavouriteText? favouriteText;

    if (caption != null) {
      text = caption;
    } else {
      try {
        favouriteText = FavouriteText.fromJson(jsonDecode(data!.content!));
        text = favouriteText.text;
      } catch (e) {
        text = data!.content!;
      }
    }

    final length = quillController.document.length;
    int position = quillController.selection.isValid
        ? quillController.selection.baseOffset
        : length;

    // Ensure position is within the valid range, 0 <= position <= length
    if (position < 0 || position > length) {
      position = length;
    }

    // Insert the text
    quillController.replaceText(position, 0, text, null);

    // Move the cursor to the start of the new line
    quillController.updateSelection(
      TextSelection.collapsed(offset: position + text.length + 1),
      ChangeSource.local,
    );
  }

  void _addDocumentToQuillController(FavouriteDetailData data) {
    // Determine the position to insert the document embed
    final length = quillController.document.length;
    int position = quillController.selection.isValid
        ? quillController.selection.baseOffset
        : length;

    if (position < 0 || position > length) {
      position = length;
    }

    data.id ??= data.hashCode;
    Map<String, dynamic> content = {
      'id': data.id,
      'data': jsonEncode(data),
    };

    // Insert the custom document embed
    quillController.replaceText(
      position,
      0,
      BlockEmbed.custom(
        CustomBlockEmbed('favourite_document', jsonEncode(content)),
      ),
      null,
    );

    favouriteDetailList.add(data);
    // Move the cursor to the start of the new line
    quillController.updateSelection(
      TextSelection.collapsed(offset: position + 3),
      ChangeSource.local,
    );

    FavouriteFile file = FavouriteFile.fromJson(jsonDecode(data.content!));
    if (file.caption != null && notBlank(file.caption)) {
      _addTextToQuillController(caption: file.caption);
    }
  }

  void _addLocationToQuillController(FavouriteDetailData data) {
    // Determine the position to insert the document embed
    final length = quillController.document.length;
    int position = quillController.selection.isValid
        ? quillController.selection.baseOffset
        : length;

    if (position < 0 || position > length) {
      position = length;
    }
    data.id ??= data.hashCode;
    Map<String, dynamic> content = {
      'id': data.id,
      'data': jsonEncode(data),
    };

    // Insert the custom location embed
    quillController.replaceText(
      position,
      0,
      BlockEmbed.custom(
        CustomBlockEmbed('favourite_location', jsonEncode(content)),
      ),
      null,
    );

    favouriteDetailList.add(data);

    // Move the cursor to the position after the inserted content
    quillController.updateSelection(
      TextSelection.collapsed(offset: position + 1),
      ChangeSource.local,
    );
  }

  // void _addVoiceToQuillController(FavouriteDetailData data) {
  //   // Determine the position to insert the document embed
  //   final length = quillController.document.length;
  //   int position = quillController.selection.isValid
  //       ? quillController.selection.baseOffset
  //       : length;
  //
  //   if (position < 0 || position > length) {
  //     position = length;
  //   }
  //
  //   data.id ??= data.hashCode;
  //   Map<String, dynamic> content = {
  //     'id': data.id,
  //     'data': data.content!,
  //   };
  //
  //   // Insert the custom location embed
  //   quillController.replaceText(
  //     position,
  //     0,
  //     BlockEmbed.custom(
  //       CustomBlockEmbed('favourite_voice', jsonEncode(content)),
  //     ),
  //     null,
  //   );
  //   favouriteDetailList.add(data);
  //   // Move the cursor to the position after the inserted content
  //   quillController.updateSelection(
  //     TextSelection.collapsed(offset: position + 1),
  //     ChangeSource.local,
  //   );
  // }

  void _addMediaToQuillController(FavouriteDetailData data) {
    final length = quillController.document.length;
    int position = quillController.selection.isValid
        ? quillController.selection.baseOffset
        : length;

    if (position < 0 || position > length) {
      position = length;
    }

    data.id ??= data.hashCode;

    Map<String, dynamic> content = {
      'id': data.id,
      'data': jsonEncode(data),
    };

    quillController.replaceText(
      position,
      0,
      BlockEmbed.custom(
        CustomBlockEmbed(
            data.typ == FavouriteTypeImage
                ? 'favourite_image'
                : 'favourite_video',
            jsonEncode(content)),
      ),
      null,
    );
    favouriteDetailList.add(data);
    // Move the cursor to the position after the inserted content
    quillController.updateSelection(
      TextSelection.collapsed(offset: position + 1),
      ChangeSource.local,
    );
    favouriteMediaList.addAll({
      data.id!: data,
    });

    String caption = '';
    if (data.typ == FavouriteTypeImage) {
      FavouriteImage image = FavouriteImage.fromJson(jsonDecode(data.content!));
      if (image.caption != null) {
        caption = image.caption!;
      }
    } else {
      FavouriteVideo video = FavouriteVideo.fromJson(jsonDecode(data.content!));
      if (video.caption != null) {
        caption = video.caption!;
      }
    }

    if (notBlank(caption)) {
      _addTextToQuillController(caption: caption);
    }
  }

  void _addAlbumToQuillController(FavouriteDetailData data) {
    FavouriteAlbum album = FavouriteAlbum.fromJson(jsonDecode(data.content!));
    for (AlbumDetailBean bean in album.albumList) {
      if (bean.isVideo) {
        FavouriteVideo favouriteVideo = FavouriteVideo.fromBean(bean);
        FavouriteDetailData detailData = FavouriteDetailData(
          id: favouriteVideo.hashCode,
          typ: FavouriteTypeVideo,
          content: jsonEncode(favouriteVideo),
        );
        _addMediaToQuillController(detailData);
        _insertNewLine();
        favouriteMediaList.addAll({
          detailData.id!: detailData,
        });
      } else {
        FavouriteImage favouriteImage = FavouriteImage.fromBean(bean);
        FavouriteDetailData detailData = FavouriteDetailData(
          id: favouriteImage.hashCode,
          typ: FavouriteTypeImage,
          content: jsonEncode(favouriteImage),
        );
        _addMediaToQuillController(detailData);
        _insertNewLine();
        favouriteMediaList.addAll({
          detailData.id!: detailData,
        });
      }
    }

    if (album.caption != null && notBlank(album.caption)) {
      _addTextToQuillController(caption: album.caption);
    }
  }

  void _addAssetEntityToQuillController(FavouriteDetailData data) {
    // Determine the position to insert the document embed
    final length = quillController.document.length;
    int position = quillController.selection.isValid
        ? quillController.selection.baseOffset
        : length;

    if (position < 0 || position > length) {
      position = length;
    }

    Map<String, dynamic> content = {
      'id': data.id,
      'data': jsonEncode(data),
    };

    // Insert the custom location embed
    quillController.replaceText(
      position,
      0,
      BlockEmbed.custom(
        CustomBlockEmbed(
            data.typ == FavouriteTypeImage
                ? 'favourite_image'
                : 'favourite_video',
            jsonEncode(content)),
      ),
      null,
    );

    // Move the cursor to the position after the inserted content
    quillController.updateSelection(
      TextSelection.collapsed(offset: position + 1),
      ChangeSource.local,
    );

    favouriteMediaList.addAll({
      data.id!: data,
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    });
  }

  void toggleOptionsVisibility() {
    isShowAttachmentOptions.value = !isShowAttachmentOptions.value;
    if (isShowAttachmentOptions.value) {
      FocusManager.instance.primaryFocus?.unfocus();
    } else {
      editorFocusNode.requestFocus();
    }
  }

  void undo() {
    quillController.undo();
  }

  void redo() {
    quillController.redo();
  }

  void onTapBoldButton() {
    toggleAttribute(isBold, Attribute.bold);
  }

  void onTapHighlightButton() {
    toggleAttribute(
        isHighlight,
        Attribute(
            'background', AttributeScope.inline, colorNoteTextBackground));
  }

  void onTapOrderedListButton() {
    toggleListType(isOrderedList, Attribute.ol);
  }

  void onTapUnorderedListButton() {
    toggleListType(isUnorderedList, Attribute.ul);
  }

  void onTapCheckListButton() {
    toggleListType(isCheckList, Attribute.unchecked);
  }

  void toggleAttribute(RxBool isActive, Attribute attribute) {
    isActive.value = !isActive.value;
    if (isActive.value) {
      quillController.formatSelection(attribute);
    } else {
      quillController.formatSelection(Attribute.clone(attribute, null));
    }
  }

  void toggleListType(RxBool selectedList, Attribute listAttribute) {
    selectedList.value = !selectedList.value;

    if (selectedList.value) {
      isOrderedList.value = false;
      isUnorderedList.value = false;
      isCheckList.value = false;

      selectedList.value = true;

      quillController.formatSelection(listAttribute);
    } else {
      quillController.formatSelection(Attribute.clone(listAttribute, null));
    }
  }

  void _checkDocumentStyleChanges() {
    final currentStyle = quillController.getSelectionStyle();
    if (currentStyle.containsKey(Attribute.list.key)) {
      final listType = currentStyle.attributes[Attribute.list.key];

      if (listType == Attribute.ol) {
        isOrderedList.value = true;
        isUnorderedList.value = false;
        isCheckList.value = false;
      } else if (listType == Attribute.ul) {
        isOrderedList.value = false;
        isUnorderedList.value = true;
        isCheckList.value = false;
      } else if (listType == Attribute.unchecked ||
          listType == Attribute.checked) {
        isOrderedList.value = false;
        isUnorderedList.value = false;
        isCheckList.value = true;
      } else {
        isOrderedList.value = false;
        isUnorderedList.value = false;
        isCheckList.value = false;
      }
    } else {
      // reset all list-related states
      isOrderedList.value = false;
      isUnorderedList.value = false;
      isCheckList.value = false;
    }
    hasUndo.value = quillController.hasUndo;
    hasRedo.value = quillController.hasRedo;
  }

  void onTapTimestampButton() {
    final currentSelection = quillController.selection;
    final position = currentSelection.baseOffset;

    // Get current timestamp
    final now = DateTime.now();
    final formattedTimestamp = DateFormat('yyyy/MM/dd HH:mm').format(now);

    // Add a space after the timestamp
    final timestampWithSpace = '$formattedTimestamp ';

    // Insert the timestamp with space at the current position
    quillController.replaceText(
      position,
      0,
      timestampWithSpace,
      null,
    );

    // Move the cursor to the end of the newly inserted timestamp
    quillController.updateSelection(
      TextSelection.collapsed(offset: position + timestampWithSpace.length),
      ChangeSource.local,
    );
  }

  void onTapDividerButton() {
    final position = quillController.selection.isCollapsed
        ? quillController.selection.baseOffset
        : quillController.document.length;

    // Insert the custom block embed for the divider
    quillController.replaceText(
      position,
      0,
      BlockEmbed.custom(const CustomBlockEmbed('divider', '<hr/>')),
      null,
    );

    // Insert a new line after the divider to move the cursor to the next line
    quillController.replaceText(position + 1, 0, '\n', null);

    // Move the cursor to the start of the new line
    quillController.updateSelection(
      TextSelection.collapsed(offset: position + 2),
      ChangeSource.local,
    );
  }

  showBottomPopup(BuildContext context, MediaOption mediaOption) async {
    bool permissionStatus;
    try {
      if (mediaOption == MediaOption.gallery ||
          mediaOption == MediaOption.document) {
        await onPrepareMediaPicker(
          maxAssets: mediaOption == MediaOption.document ? 1 : 9,
        );
      }
      editorFocusNode.unfocus();
      permissionStatus = true;
    } on StateError {
      permissionStatus = false;
    }

    if (mediaOption == MediaOption.document && permissionStatus) {
      Future.delayed(const Duration(milliseconds: 200), () {
        final filePickerController = Get.find<FilePickerController>();
        filePickerController.loadAndroidFiles();
      });
    }
    //ignore: use_build_context_synchronously
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      useSafeArea: true,
      isScrollControlled: true,
      isDismissible: true,
      builder: (BuildContext ctx) {
        if (mediaOption == MediaOption.gallery) {
          isMediaPicking = true;
          return GeneralMediaPicker(
            provider: assetPickerProvider!,
            pickerConfig: pickerConfig!,
            ps: ps!,
            onSend: () => Navigator.of(context).pop({
              'shouldSend': true,
              'assets': assetPickerProvider?.selectedAssets,
            }),
            typeRestrict: true,
          );
        } else if (mediaOption == MediaOption.document) {
          isFilePicking = true;
          return permissionStatus
              ? GeneralFilePicker(
                  assetPickerProvider: assetPickerProvider!,
                  pickerConfig: pickerConfig!,
                  ps: ps!,
                  picTag: 'favourite',
                  isAllowMultiple: false,
                  onFilesSelected: (List<File> selectedFiles) {
                    isFilePicking = false;
                    Get.back();
                    _createFileFavouriteDetail(selectedFiles);
                  },
                )
              : NoPermissionView(
                  title: localized(files),
                  imageUrl: 'assets/svgs/noPermission_state_file.svg',
                  mainContent: localized(accessYourFiles),
                  subContent: localized(toSendFiles),
                );
        } else if (mediaOption == MediaOption.location) {
          return LocationPicker(
            onLocationSelected: (Map<String, dynamic> locationData) {
              _createLocationFavouriteDetail(locationData);
            },
          );
        }
        return const SizedBox();
      },
    ).then((result) {
      if (notBlank(result)) {
        if (!result.containsKey('shouldSend') || !result['shouldSend']) {
          return;
        }

        if (result['assets'] is List<AssetEntity>) {
          isMediaPicking = false;
          for (int i = 0; i < result['assets'].length; i++) {
            AssetEntity entity = result['assets'][i];
            assetList.add(
              AssetPreviewDetail(
                id: entity.id,
                entity: entity,
                index: i,
                caption: '',
              ),
            );
          }
          _generateMediaDetail(assetList);
        } else if (result['assets'] is List<AssetPreviewDetail>) {
          if (result['assets'].isNotEmpty) {
            isMediaPicking = false;
            _generateMediaDetail(result['assets']);
          }
        }
      }
    }).whenComplete(() async {
      if (isFilePicking) {
        if (assetPickerProvider!.selectedAssets.isNotEmpty) {
          for (var element in assetPickerProvider!.selectedAssets) {
            File? file = await element.originFile;
            if (file != null) {
              _createFileFavouriteDetail([file]);
            }
          }
        }
        isFilePicking = false;
      } else if (isMediaPicking) {
        if (selectedAssetList.isNotEmpty) {
          for (int i = 0; i < selectedAssetList.length; i++) {
            AssetEntity entity = selectedAssetList[i];
            assetList.add(
              AssetPreviewDetail(
                id: entity.id,
                entity: entity,
                index: i,
                caption: '',
              ),
            );
          }
          _generateMediaDetail(assetList);
        }
        isMediaPicking = false;
      }
      assetPickerProvider?.removeListener(onAssetPickerChanged);
      assetPickerProvider?.selectedAssets.clear();
      Get.findAndDelete<FilePickerController>();
      selectedAssetList.clear();
    });
  }

  // 拍照
  onPhoto(BuildContext context) async {
    if (objectMgr.callMgr.getCurrentState() != CallState.Idle) {
      Toast.showToast(localized(toastEndCallFirst));
      return;
    }

    if (Platform.isAndroid) {
      int version = await objectMgr.callMgr.getAndroidVersionApi();
      if (version < 33) {
        var a = await Permissions.request([Permission.storage]);
        if (!a) {
          return;
        }
      }
    } else {
      var b = await Permissions.request([Permission.photos]);
      if (!b) {
        return;
      }
    }
    var c = await Permissions.request([Permission.camera]);
    if (!c) {
      return;
    }
    var d = await Permissions.request([Permission.microphone]);
    if (!d) {
      return;
    }

    onPrepareMediaPicker();

    AssetEntity? entity;
    if (await isUseImCamera) {
      entity = await CamerawesomePage.openImCamera(
        enableRecording: true,
        maximumRecordingDuration: const Duration(seconds: 600),
        manualCloseOnSuccess: true,
        isMirrorFrontCamera: isMirrorFrontCamera,
      );
      if (entity == null) {
        return;
      }
      gotoMediaPreviewView(entity, context);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => CamerawesomePage(
            enableRecording: true,
            maximumRecordingDuration: const Duration(seconds: 600),
            onResult: (Map<String, dynamic> map) {
              entity = map["result"];
              if (entity == null) {
                return;
              }
              gotoMediaPreviewView(entity!, context, isFromPhoto: true);
            },
          ),
        ),
      );
    }
  }

  void gotoMediaPreviewView(
    AssetEntity? entity,
    BuildContext context, {
    bool isFromPhoto = false,
  }) async {
    Get.toNamed(
      RouteName.mediaPreviewView,
      preventDuplicates: false,
      arguments: {
        'isEdit': true,
        'entity': entity,
        'provider': assetPickerProvider,
        'pConfig': pickerConfig,
        'isFromPhoto': isFromPhoto,
        'showCaption': false,
        'showResolution': false,
        'backAction': () {
          // 按返回键
          if (Platform.isIOS) onPhoto(context);
        },
      },
    )?.then((result) {
      if (notBlank(result)) {
        if (!result.containsKey('shouldSend') || !result['shouldSend']) {
          assetPickerProvider?.selectedAssets.clear();
          return;
        }

        _generateMediaDetail(result['assets']);
        return;
      } else {}

      assetPickerProvider?.selectedAssets.clear();
      return;
    });
  }

  Future<void> onPrepareMediaPicker({int? maxAssets}) async {
    ps = await const AssetPickerDelegate().permissionCheck();

    if (assetPickerProvider != null) {
      assetPickerProvider!.removeListener(onAssetPickerChanged);
    }

    pickerConfig = AssetPickerConfig(
      requestType: RequestType.common,
      limitedPermissionOverlayPredicate: (permissionState) {
        return false;
      },
      shouldRevertGrid: false,
      gridThumbnailSize: ThumbnailSize.square(
        (Config().messageMin).toInt(),
      ),
      maxAssets: maxAssets ?? 1,
      textDelegate:
          AppLocalizations.of(Get.context!)!.locale.languageCode.contains('en')
              ? const EnglishAssetPickerTextDelegate()
              : const AssetPickerTextDelegate(),
    );
    assetPickerProvider = DefaultAssetPickerProvider(
      maxAssets: pickerConfig!.maxAssets,
      pageSize: pickerConfig!.pageSize,
      pathThumbnailSize: pickerConfig!.pathThumbnailSize,
      selectedAssets: pickerConfig!.selectedAssets,
      requestType: pickerConfig!.requestType,
      sortPathDelegate: pickerConfig!.sortPathDelegate,
      filterOptions: pickerConfig!.filterOptions,
    );

    assetPickerProvider!.addListener(onAssetPickerChanged);
  }

  onAssetPickerChanged() {
    if (selectedAssetList.length !=
        assetPickerProvider!.selectedAssets.length) {
      selectedAssetList.value = assetPickerProvider!.selectedAssets;
    }
  }

  _generateMediaDetail(List<AssetPreviewDetail> mediaList) async {
    if (mediaList.isNotEmpty) {
      for (AssetPreviewDetail asset in mediaList) {
        if (asset.entity.type == AssetType.image) {
          String filePath = asset.editedFile != null
              ? asset.editedFile!.path
              : (await asset.entity.originFile)!.path;
          int width = asset.editedWidth ?? asset.entity.orientatedWidth;
          int height = asset.editedHeight ?? asset.entity.orientatedHeight;
          Size fileSize = getResolutionSize(
            width,
            height,
            MediaResolution.image_standard.minSize,
          );

          FavouriteImage favouriteImage = FavouriteImage(
            url: '',
            filePath: filePath,
            size: 0,
            width: fileSize.width.toInt(),
            height: fileSize.height.toInt(),
          );
          FavouriteDetailData data = FavouriteDetailData(
            id: favouriteImage.hashCode,
            typ: FavouriteTypeImage,
            content: jsonEncode(favouriteImage),
          );
          _addMediaToQuillController(data);
          _insertNewLine();
          assetToUpload[data.id!] = data;
        } else {
          File? videoFile = await asset.entity.originFile;
          final videoCover = await generateThumbnailWithPath(
            videoFile!.path,
            savePath: '${DateTime.now().millisecondsSinceEpoch.toString()}.jpg',
            sub: 'favourite/',
          );
          Map<String, dynamic> data = {
            'id': asset.id,
            'coverPath': videoCover.path,
            'timestamp': videoCover.hashCode,
          };
          FavouriteVideo favouriteVideo = FavouriteVideo(
            url: '',
            fileName: getFileNameWithExtension(videoFile.path),
            filePath: videoFile.path,
            size: 0,
            width: asset.entity.orientatedWidth,
            height: asset.entity.orientatedHeight,
            second: 0,
            cover: '',
            coverPath: videoCover.path,
          );
          FavouriteDetailData detailData = FavouriteDetailData(
            id: data['timestamp'],
            typ: FavouriteTypeVideo,
            content: jsonEncode(favouriteVideo),
          );
          _addAssetEntityToQuillController(detailData);
          _insertNewLine();
          assetToUpload[detailData.id!] = detailData;
          favouriteDetailList.add(detailData);
        }
      }
      _scrollToBottom();
      assetList.clear();
    }
  }

  _createFileFavouriteDetail(List<File> files) {
    for (File file in files) {
      FavouriteFile favouriteFile = FavouriteFile(
        fileName: path.basename(file.path),
        suffix: path.extension(file.path),
        length: file.lengthSync(),
        url: file.path,
        cover: '',
        isEncrypt: 0,
      );

      FavouriteDetailData detail = FavouriteDetailData(
        id: favouriteFile.hashCode,
        typ: FavouriteTypeDocument,
        content: jsonEncode(favouriteFile),
      );

      assetToUpload[detail.id!] = detail;
      _addDocumentToQuillController(detail);
      _insertNewLine();
    }
  }

  _createLocationFavouriteDetail(Map<String, dynamic> data) {
    FavouriteLocation location = FavouriteLocation.fromJson(data);
    FavouriteDetailData detail = FavouriteDetailData(
      id: location.hashCode,
      typ: FavouriteTypeLocation,
      content: jsonEncode(location),
    );
    _addLocationToQuillController(detail);
    _insertNewLine();
    assetToUpload[detail.id!] = detail;
  }

  processTag(List<String> res) {
    tagList = res;
    if (favouriteData != null) {
      favouriteData!.tag = res;
      objectMgr.favouriteMgr
          .updateFavourite(favouriteData!, ignoreUpdate: true);
    }
  }

  onTapMedia(int id) {
    List<dynamic> dataList = [];
    int index = -1;
    List copiedList = favouriteMediaList.values.toList();
    for (FavouriteDetailData e in copiedList) {
      if (e.typ == FavouriteTypeVideo) {
        dataList.add(FavouriteVideo.fromJson(jsonDecode(e.content!)));
      } else if (e.typ == FavouriteTypeImage) {
        dataList.add(FavouriteImage.fromJson(jsonDecode(e.content!)));
      }
      if (e.id == id) {
        index = dataList.length - 1;
      }
    }
    if (index != -1) {
      Navigator.of(Get.context!).push(
        TransparentRoute(
          builder: (BuildContext context) => FavouriteAssetView(
            assets: dataList,
            index: index,
          ),
          settings: const RouteSettings(name: RouteName.favouriteAssetPreview),
        ),
      );
    }
  }

  double get getKeyboardHeight {
    if (keyboardHeight.value == 0) {
      if (KeyBoardObserver.instance.keyboardHeightOpen < 200 &&
          keyboardHeight.value < 200) {
        keyboardHeight.value = getPanelFixHeight;
        KeyBoardObserver.instance.keyboardHeightOpen = getPanelFixHeight;
      } else {
        keyboardHeight.value = KeyBoardObserver.instance.keyboardHeightOpen;
        return keyboardHeight.value;
      }
      if (Platform.isIOS) {
        return 336;
      } else {
        return 240;
      }
    }
    return keyboardHeight.value;
  }

  double get getPanelFixHeight {
    if (Platform.isIOS) {
      var sWidth = 1;
      var sHeight = 1;
      if (sWidth == 430 && sHeight == 932) {
        return 346;
      } else if (sWidth == 375 && sHeight == 667) {
        ///iphone SE
        return 260;
      } else {
        return 336;
      }
    } else {
      return 294;
    }
  }
}
