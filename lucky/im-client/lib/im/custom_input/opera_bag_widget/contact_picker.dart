import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/azItem.dart';
import 'package:jxim_client/utils/user_utils.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/searching_app_bar.dart';
import 'package:jxim_client/views/contact/components/contact_card.dart';
import 'package:jxim_client/im/custom_input/sheet_title_bar.dart';

class ContactPicker extends StatelessWidget {
  final CustomInputController controller;

  const ContactPicker({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          child: Column(
            children: [
              Visibility(
                visible: !controller.chatController.isContactSearching.value,
                child: SheetTitleBar(
                  title: localized(contact),
                  divider: false,
                ),
              ),
              Container(
                 decoration: BoxDecoration(
            color: Colors.white,
            
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: dividerColor,
                blurRadius: 0.0,
                offset: const Offset(0.0, -1.0),
              ),
            ],
          ),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: 8.0.h,
                    left: 16.w,
                    right: 16.w,
                    bottom: 8.0.h,
                  ),
                  child: Obx(() {
                    return SearchingAppBar(
                      onTap: () =>
                          controller.chatController.isContactSearching(true),
                      onChanged: controller.chatController.onSearchContactChanged,
                      onCancelTap: () {
                        controller.chatController.searchContactFocusNode
                            .unfocus();
                        controller.chatController.clearContactSearching();
                      },
                      isSearchingMode:
                          controller.chatController.isContactSearching.value,
                      isAutoFocus: false,
                      focusNode: controller.chatController.searchContactFocusNode,
                      controller:
                          controller.chatController.searchContactController,
                      suffixIcon: Visibility(
                        visible: controller
                            .chatController.searchContactParam.value.isNotEmpty,
                        child: GestureDetector(
                          onTap: () {
                            controller.chatController.searchContactController
                                .clear();
                            controller.chatController.searchContactParam.value =
                                '';
                            controller.chatController.getFriendList();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: SvgPicture.asset(
                              'assets/svgs/close_round_icon.svg',
                              width: 20,
                              height: 20,
                              color: JXColors.iconSecondaryColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        Obx(
          () {
            final contactList = buildList();
            return Expanded(
              child: Container(
                height: 500,
                color: sheetTitleBarColor,
                child: AzListView(
                  noResultFound: localized(noResultFound),
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  data: contactList,
                  itemScrollController: ItemScrollController(),
                  itemCount: controller.chatController.friendList.length,
                  itemBuilder: (context, index) {
                    final item = contactList[index];
                    final next = contactList.length > (index + 1)
                        ? contactList[index + 1]
                        : null;

                    return _buildListItem(
                        item,
                        next,
                        index == contactList.length - 1 ? false : true,
                        true,
                        context);
                  },
                  showIndexBar: true,
                  listFooter: _buildFooter(),
                  indexBarOptions: IndexBarOptions(
                    textStyle: jxTextStyle.textStyleBold10(color: accentColor),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Container _buildFooter() {
    return Container(
      height: 95.h,
      color: backgroundColor,
      child: Center(
        child: Text(
          localized(
            totalFriend,
            params: [controller.chatController.friendList.length.toString()],
          ),
          style: const TextStyle(
            color: Color(0x99121212),
          ),
        ),
      ),
    );
  }

  List<AZItem> buildList() {
    List<AZItem> list = controller.chatController.friendList.value
        .map(
          (e) => AZItem(
            user: e,
            tag: convertToPinyin(objectMgr.userMgr.getUserTitle(e)[0])[0]
                .toUpperCase(),
          ),
        )
        .toList();
    SuspensionUtil.setShowSuspensionStatus(list);
    return list;
  }

  /// create contact card
  Widget _buildListItem(
    AZItem item,
    AZItem? nextItem,
    bool withCustomBorder,
    bool isShowingTag,
    BuildContext context,
  ) {
    final tag = item.getSuspensionTag();
    final offstage = !item.isShowSuspension;
    final nextTag = nextItem != null ? nextItem.getSuspensionTag() : "";
    bool isSameTag = tag == nextTag;
    return Column(
      children: <Widget>[
        if (isShowingTag) Offstage(offstage: offstage, child: buildHeader(tag)),
        Container(
          color: Colors.white,
          child: ContactCard(
            key: ValueKey(item.user.uid),
            user: item.user,
            subTitle: UserUtils.onlineStatus(item.user.lastOnline),
            withCustomBorder: (isShowingTag && isSameTag),
            isCalling: false,
            onTap: () {
              controller.onSend(
                null,
                isSendContact: true,
                context: context,
                user: item.user,
              );
            },
          ),
        ),
      ],
    );
  }

  /// create alphabet bar
  Widget buildHeader(String tag) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
        alignment: Alignment.centerLeft,
        child: Text(
          '$tag',
          softWrap: false,
          style: jxTextStyle.textStyle14(color: JXColors.secondaryTextBlack),
        ),
      );
}
