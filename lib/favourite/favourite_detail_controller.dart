import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:intl/intl.dart';
import 'package:jxim_client/favourite/favourite_asset_view.dart';
import 'package:jxim_client/favourite/model/favourite_model.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/transparent_page_route.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_dialog.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_item.dart';
import 'package:jxim_client/views/component/custom_confirmation_popup.dart';

class FavouriteDetailController extends GetxController {
  List<QuillController> quillControllers = [];
  QuillController? deltaController;
  FavouriteData? favouriteData;
  List<FavouriteDetailData> detailList = [];
  final date = ''.obs;
  final authorName = ''.obs;
  final isHistory = false.obs;
  final showDateTime = false.obs;
  final title = ''.obs;
  final isShowHeader = true.obs;
  final addSpace = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  @override
  void onClose() {
    _disposeQuillControllers();
    super.onClose();
  }

  _initializeData() {
    if (Get.arguments != null) {
      if (Get.arguments["favouriteData"] != null) {
        favouriteData = Get.arguments["favouriteData"];
      }

      if (Get.arguments["isShowHeader"] != null) {
        isShowHeader.value = Get.arguments["isShowHeader"] ?? true;
      }
    }

    isHistory.value = favouriteData?.source == FavouriteSourceHistory;
    if (favouriteData?.source == FavouriteSourceNote) {
      _showDeltaContent();
    } else {
      detailList = favouriteData?.content ?? [];
    }
    final dateTime =
        DateTime.fromMillisecondsSinceEpoch(favouriteData!.updatedAt! * 1000);
    date.value = DateFormat('dd/MM/yyyy').format(dateTime);

    if (isHistory.value) {
      title.value = objectMgr.favouriteMgr.getFavouriteTitle(
          favouriteData!.chatTyp,
          favouriteData?.authorId,
          favouriteData?.userId);

      if (detailList.isNotEmpty) {
        DateTime firstMessageTime =
            DateTime.fromMillisecondsSinceEpoch(detailList[0].sendTime! * 1000);
        DateTime lastMessageTime = DateTime.fromMillisecondsSinceEpoch(
            detailList.last.sendTime! * 1000);

        if (!isSameDay(firstMessageTime, lastMessageTime)) {
          date.value = localized(
            favouriteDatePeriod,
            params: [
              formatDate(firstMessageTime),
              formatDate(lastMessageTime),
            ],
          );
          showDateTime.value = true;
        }
      }
    } else {
      if (!isShowHeader.value) {
        title.value = localized(noteEditTitle);
      } else {
        title.value = localized(momentDetail);
      }
    }

    if (!isHistory.value &&
        favouriteData?.source != FavouriteSourceNote &&
        detailList[0].sendId != null) {
      if (favouriteData!.chatTyp == chatTypeSmallSecretary) {
        authorName.value =
            objectMgr.favouriteMgr.getFavouriteAuthorName(favouriteData!);
      } else {
        authorName.value = objectMgr.userMgr.getUserTitle(
          objectMgr.userMgr.getUserById(detailList[0].sendId!),
        );
      }
    } else {
      authorName.value = objectMgr.userMgr.getUserTitle(
        objectMgr.userMgr.getUserById(favouriteData!.authorId!),
      );
    }
  }

  _showDeltaContent() {
    for (FavouriteDetailData data in favouriteData!.content) {
      if (data.typ == FavouriteTypeDelta) {
        FavouriteDelta delta =
            FavouriteDelta.fromJson(jsonDecode(data.content!));
        deltaController = QuillController(
          document: Document.fromDelta(
            delta.delta,
          ),
          selection: const TextSelection.collapsed(offset: 0),
        );
        FavouriteDetailData lastFavourite =
            favouriteData!.content[favouriteData!.content.length - 2];
        if (lastFavourite.typ == FavouriteTypeText ||
            lastFavourite.typ == FavouriteTypeLink) {
          addSpace.value = true;
        }
      }
    }
  }

  int addQuillController(String text) {
    final quillController = QuillController(
      document: Document.fromJson(
        objectMgr.favouriteMgr.convertStringToQuillDelta(text),
      ),
      selection: const TextSelection.collapsed(offset: 0),
    );
    quillControllers.add(quillController);

    // Return the index of the newly added QuillController
    return quillControllers.length - 1;
  }

  Future<void> deleteFavourite() async {
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
              confirmDeleteFavourite(favouriteData!);
            }
          },
          cancelCallback: () => Get.back(),
        );
      },
    );
  }

  bool checkNeedToRedirect(FavouriteData data) {
    final dataFromList = objectMgr.favouriteMgr.favouriteList
        .toList()
        .firstWhereOrNull((element) => element.parentId == data.parentId);
    bool isNotExist = dataFromList != data;

    if (isNotExist) {
      showModalBottomSheet(
        context: Get.context!,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return CustomConfirmationPopup(
            title: localized(thisContentComesFromChatHistoryNotes),
            confirmButtonColor: themeColor,
            cancelButtonColor: themeColor,
            confirmButtonText: localized(findInFavouriteContent),
            cancelButtonText: localized(buttonCancel),
            confirmCallback: () {
              Get.back();
              Future.delayed(const Duration(milliseconds: 300), () {
                if (dataFromList!.isNote) {
                  Get.toNamed(RouteName.editNotePage,
                      arguments: [dataFromList]);
                } else {
                  Get.toNamed(RouteName.favouriteDetailPage,
                      arguments: {'favouriteData': dataFromList});
                }
              });
            },
            cancelCallback: () => Get.back(),
          );
        },
      );
      return true;
    }
    return false;
  }

  confirmDeleteFavourite(FavouriteData deleteData) {
    bool needRedirect = checkNeedToRedirect(deleteData);
    if (!needRedirect) {
      handleDeleteFavourite([deleteData]);
    }
  }

  Future<void> handleDeleteFavourite(List<FavouriteData> deleteDataList) async {
    await objectMgr.favouriteMgr.deleteFavourite([favouriteData!]);
    Get.back();
  }

  void _disposeQuillControllers() {
    for (var controller in quillControllers) {
      controller.dispose();
    }
  }

  onMoreTap() {
    bool needRedirect = checkNeedToRedirect(favouriteData!);

    if (!needRedirect) {
      showCustomBottomAlertDialog(
        Get.context!,
        withHeader: false,
        items: [
          CustomBottomAlertItem(
            text: localized(saveAsNote),
            onClick: () {
              Get.offAndToNamed(
                RouteName.editNotePage,
                arguments: [
                  favouriteData,
                ],
              );
            },
          ),
          CustomBottomAlertItem(
            text: localized(sendToChat),
            onClick: () {
              forwardFavourite();
            },
          ),
          CustomBottomAlertItem(
            text: localized(editTags),
            onClick: () {
              Get.toNamed(
                RouteName.favouriteEditTag,
                preventDuplicates: false,
                arguments: {
                  'tagDataList': favouriteData?.tag,
                },
              )?.then((result) async {
                if (notBlank(result)) {
                  if (result!.containsKey('tag')) {
                    List<String> tag = result['tag'];
                    final data = objectMgr.favouriteMgr.favouriteList
                        .firstWhereOrNull((element) =>
                            element.parentId == favouriteData!.parentId);
                    if (data != null) {
                      data.tag = tag;
                      await objectMgr.favouriteMgr
                          .updateFavourite(data, ignoreUpdate: true);
                    }
                  }
                }
              });
            },
          ),
          CustomBottomAlertItem(
            text: localized(buttonDelete),
            textColor: colorRed,
            onClick: () => deleteFavourite(),
          ),
        ],
      );
    }
  }

  void onTapMedia(FavouriteDetailData data) {
    List<dynamic> dataList = [];
    int index = 0;
    for (FavouriteDetailData e in favouriteData!.content) {
      if (e.typ == FavouriteTypeVideo) {
        dataList.add(FavouriteVideo.fromJson(jsonDecode(e.content!)));
      } else if (e.typ == FavouriteTypeImage) {
        dataList.add(FavouriteImage.fromJson(jsonDecode(e.content!)));
      }

      if (data == e) {
        index = dataList.length - 1;
      }
    }
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

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String formatDate(DateTime date) {
    DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    return dateFormat.format(date);
  }

  void forwardFavourite() {
    if (favouriteData != null) {
      if (favouriteData!.isUploaded == 1) {
        objectMgr.favouriteMgr.forwardFavouriteList([favouriteData!]);
      } else {
        Toast.showToast(localized(chatInfoPleaseTryAgainLater));
      }
    }
  }
}
