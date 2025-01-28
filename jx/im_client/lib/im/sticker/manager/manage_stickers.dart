import 'package:flutter/material.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/sticker/manager/manage_stickers_list.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/sticker_mgr.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/component.dart';

class ManageStickers extends StatefulWidget {
  const ManageStickers({super.key});

  @override
  State<ManageStickers> createState() => _ManageStickersState();
}

class _ManageStickersState extends State<ManageStickers> {
  bool isLoading = true;

  @override
  void initState() {
    objectMgr.stickerMgr.selectedStickerCollections.clear();
    objectMgr.stickerMgr.on(StickerMgr.eventStickerChange, onStickerChange);

    Future.delayed(const Duration(milliseconds: 500), () {
      isLoading = false;
      if (mounted) setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    objectMgr.stickerMgr.off(StickerMgr.eventStickerChange, onStickerChange);
    super.dispose();
  }

  void onStickerChange(Object sender, Object type, Object? data) {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheetContent(
      height: MediaQuery.of(context).size.height * 0.94,
      title: localized(stickerMng),
      leading: const CustomLeadingIcon(needPadding: false),
      middleChild: isLoading
          ? Padding(
              padding: const EdgeInsets.only(top: 64.0),
              child: CircularProgressIndicator(color: themeColor),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 32, bottom: 8.0),
                  child: Text(
                    localized(stickers),
                    style: jxTextStyle.normalSmallText(
                      color: colorTextLevelTwo,
                    ),
                  ),
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: 12,
                      left: 16,
                      right: 16,
                    ),
                    child: ManageStickersList(),
                  ),
                ),
                Column(
                  children: [
                    const CustomDivider(),
                    _showDeleteButton(context),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _showDeleteButton(BuildContext context) {
    final isDisabled = objectMgr.stickerMgr.selectedStickerCollections.isEmpty;
    return Container(
      height: 57,
      color: colorBackground,
      alignment: Alignment.centerRight,
      child: IgnorePointer(
        ignoring: isDisabled,
        child: Opacity(
          opacity: isDisabled ? 0.3 : 1,
          child: CustomTextButton(
            localized(buttonDelete),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            color: colorRed,
            onClick: () async {
              final count =
                  objectMgr.stickerMgr.selectedStickerCollections.length;
              Toast.showAlert(
                context: context,
                container: CustomAlertDialog(
                  title: localized(deleteStickerSet, params: ['$count']),
                  confirmText: localized(buttonDelete),
                  confirmCallback: () {
                    objectMgr.stickerMgr.removeStickerCollection();

                    imBottomToast(
                      context,
                      title: localized(stickerDeleteSuccess),
                      icon: ImBottomNotifType.delete,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
