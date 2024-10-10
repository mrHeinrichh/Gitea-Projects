import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/chat_info/chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/object/az_item.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/searching_app_bar.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views_desktop/component/desktop_forward_controller.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_button.dart';
import 'package:jxim_client/views_desktop/component/desktop_searching_bar.dart';

class ForwardContactPicker extends StatefulWidget {
  final Chat chat;
  final List<dynamic>? forwardMsg;
  final bool fromChatInfo;
  final bool fromMediaDetail;
  final bool isForward;

  const ForwardContactPicker({
    super.key,
    required this.chat,
    this.forwardMsg,
    this.fromChatInfo = false,
    this.fromMediaDetail = false,
    this.isForward = true,
  });

  @override
  State<ForwardContactPicker> createState() => _ForwardContactPickerState();
}

class _ForwardContactPickerState extends State<ForwardContactPicker> {
  late CustomInputController controller;
  List<User> _contactList = [];
  bool isVisible = false;
  RxList<AZItem> displayFriendList = <AZItem>[].obs;

  final FocusNode searchFocus = FocusNode();
  TextEditingController forwardContactsSearchController =
      TextEditingController();
  RxBool isSearching = false.obs;
  RxString searchParam = ''.obs;

  bool get isDesktop => objectMgr.loginMgr.isDesktop;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<CustomInputController>(
      tag: widget.chat.id.toString(),
    )) {
      controller =
          Get.find<CustomInputController>(tag: widget.chat.id.toString());
    }
    _contactList.clear();
    _contactList = objectMgr.userMgr.friendWithoutBlacklist
        .where((e) => e.deletedAt == 0)
        .toList();
    updateAZFriendList();
    if (mounted) {
      setState(() {});
    }
  }

  void onForwardAction(
    BuildContext context,
    User user,
    List<dynamic> forwardData,
  ) async {
    Chat? chat =
        await objectMgr.chatMgr.getChatByFriendId(user.uid, remote: true);
    if (chat != null) {
      if (!widget.isForward) {
        if (isDesktop) {
          Get.back();
        } else {
          Navigator.of(context).pop(chat);
        }
        return;
      }

      if (isDesktop) {
        Get.back();
      } else {
        Get.back();
      }

      List<Message> forwardMessages = [];
      for (var bean in forwardData) {
        if (bean is Message) {
          Message newMsg = bean.removeReplyContent();
          newMsg = newMsg.processMentionContent();
          forwardMessages.add(newMsg);
        } else if (bean is AlbumDetailBean) {
          Message newMsg = bean.currentMessage;

          newMsg = newMsg.removeReplyContent();
          newMsg = newMsg.processMentionContent();
          forwardMessages.add(newMsg);
        } else {
          pdebug("未识别类型,请检查");
        }
      }
      objectMgr.chatMgr.selectedMessageMap[chat.chat_id] = forwardMessages;

      if (chat.id == widget.chat.id) {
        controller.sendState.value = true;
        if (widget.fromChatInfo) {
          Get.back(id: isDesktop ? 1 : null);
        }

        if (widget.fromMediaDetail) {
          if (!isDesktop) {
            Get.back();
          } else {
            if (Get.isRegistered<ChatInfoController>() ||
                Get.isRegistered<GroupChatInfoController>()) {
              Get.back(id: isDesktop ? 1 : null);
            }
          }
        }
      } else {
        if (!isDesktop) {
          if (Get.isRegistered<ChatInfoController>()) {
            Get.until((route) => Get.currentRoute == RouteName.chatInfo);
          } else if (Get.isRegistered<GroupChatInfoController>()) {
            Get.until((route) => Get.currentRoute == RouteName.groupChatInfo);
          }
        }

        Get.back(id: isDesktop ? 1 : null);

        if (isDesktop) {
          Routes.toChat(chat: chat);
        } else {
          Routes.toChat(chat: chat);
        }
      }

      controller.update();
    } else {
      Get.back();
    }
  }

  Future<void> onSearch(String searchParam) async {
    List<User> tempList = objectMgr.userMgr.friendWithoutBlacklist;
    if (searchParam.isNotEmpty) {
      tempList = tempList
          .where(
            (element) => objectMgr.userMgr
                .getUserTitle(element)
                .toLowerCase()
                .contains(searchParam.toLowerCase()),
          )
          .toList();
    }
    setState(() {
      _contactList = tempList;
    });
    updateAZFriendList();
  }

  void clearSearching() {
    isSearching.value = false;
    if (!isSearching.value) {
      forwardContactsSearchController.clear();
      searchParam.value = '';
    }
    onSearch(searchParam.value);
  }

  void updateAZFriendList() {
    displayFriendList.value = _contactList
        .map(
          (e) => AZItem(
            user: e,
            tag: convertToPinyin(objectMgr.userMgr.getUserTitle(e)[0])[0]
                .toUpperCase(),
          ),
        )
        .toList();
    SuspensionUtil.setShowSuspensionStatus(displayFriendList);
  }

  @override
  Widget build(BuildContext context) {
    if (!objectMgr.loginMgr.isDesktop) {
      return Column(
        children: <Widget>[
          Container(
            height: kToolbarHeight,
            padding: const EdgeInsets.all(18.0),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18.0),
                topRight: Radius.circular(18.0),
              ),
            ),
            child: Center(
              child: Text(
                localized(forward),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: MFontWeight.bold5.value,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: colorBorder,
                  width: 1.w,
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                top: 8.h,
                right: 16.w,
                left: 16.w,
                bottom: 8.h,
              ),
              child: SearchingAppBar(
                onTap: () => isSearching(true),
                onChanged: (value) async {
                  searchParam.value = value;
                  onSearch(value);
                },
                onCancelTap: () {
                  searchFocus.unfocus();
                  clearSearching();
                },
                isSearchingMode: isSearching.value,
                isAutoFocus: false,
                focusNode: searchFocus,
                controller: forwardContactsSearchController,
                suffixIcon: Visibility(
                  visible: searchParam.value.isNotEmpty,
                  child: GestureDetector(
                    onTap: () {
                      forwardContactsSearchController.clear();
                      searchParam.value = '';
                      onSearch(searchParam.value);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: SvgPicture.asset(
                        'assets/svgs/close_round_icon.svg',
                        width: 20,
                        height: 20,
                        color: colorTextSupporting,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView.separated(
                itemCount: _contactList.length,
                itemBuilder: (BuildContext context, int index) {
                  final User user = _contactList[index];
                  return GestureDetector(
                    key: ValueKey(_contactList[index].uid),
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      List<Message> forwardMessage = controller
                          .chatController.chooseMessage.values
                          .map((e) => e.copyWith(null))
                          .toList();

                      onForwardAction(
                        context,
                        user,
                        widget.forwardMsg ?? forwardMessage,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 12.5,
                      ),
                      child: Row(
                        children: <Widget>[
                          CustomAvatar.user(
                            user,
                            size: 52,
                            headMin: Config().headMin,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: NicknameText(
                              uid: user.id,
                              isGroup: false,
                              isTappable: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  return const CustomDivider();
                },
              ),
            ),
          ),
        ],
      );
    } else {
      final desktopForwardController = Get.find<DesktopForwardController>();

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: DesktopSearchingBar(
              fontSize: 12,
              height: 25,
              iconSize: 15,
              controller: desktopForwardController.userSearchController,
              onChanged: (param) =>
                  desktopForwardController.searchingNow<User>(param),
              suffixIcon: DesktopGeneralButton(
                onPressed: () =>
                    desktopForwardController.clearSearching<User>(),
                child: const Icon(
                  Icons.close,
                  size: 15,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          Expanded(
            child: Builder(
              builder: (BuildContext context) {
                return Obx(
                  () => desktopForwardController.chatList.isNotEmpty &&
                          desktopForwardController.contactList.isNotEmpty
                      ? ListView.separated(
                          shrinkWrap: true,
                          itemCount:
                              desktopForwardController.contactList[0].length,
                          itemBuilder: (context, index) {
                            final List<User> users =
                                desktopForwardController.contactList[0];
                            final User user = users[index];
                            int uid = user.uid;
                            return DesktopGeneralButton(
                              onPressed: () {
                                Get.back();
                                List<Message> forwardMessage = controller
                                    .chatController.chooseMessage.values
                                    .map((e) => e.copyWith(null))
                                    .toList();

                                onForwardAction(
                                  context,
                                  user,
                                  widget.forwardMsg ?? forwardMessage,
                                );
                              },
                              child: SizedBox(
                                height: 55,
                                child: Row(
                                  children: <Widget>[
                                    desktopForwardController.getHead<User>(
                                      uid,
                                      false,
                                      user,
                                    ),
                                    const SizedBox(
                                      width: 15,
                                    ),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          desktopForwardController
                                              .getTitle<User>(uid, false, user),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (BuildContext context, int index) {
                            return const CustomDivider();
                          },
                        )
                      : Center(
                          child: SizedBox(
                            height: 30,
                            width: 30,
                            child: BallCircleLoading(
                              radius: 10,
                              ballStyle: BallStyle(
                                size: 4,
                                color: themeColor,
                                ballType: BallType.solid,
                                borderWidth: 1,
                                borderColor: themeColor,
                              ),
                            ),
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
    forwardContactsSearchController.dispose();
  }
}
