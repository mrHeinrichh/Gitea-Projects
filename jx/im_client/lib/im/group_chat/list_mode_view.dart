import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/controllers/message_item_controller.dart';
import 'package:jxim_client/home/chat/message_cell_view.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/base/base_chat_controller.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/im/private_chat/single_chat_controller.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/nickname_text.dart';

class ListModeView extends StatelessWidget {
  late final BaseChatController controller;

  ListModeView({super.key, required this.tag, required this.isGroupChat}) {
    if (isGroupChat) {
      controller = Get.find<GroupChatController>(tag: tag);
    } else {
      controller = Get.find<SingleChatController>(tag: tag);
    }
  }

  final String tag;
  final bool isGroupChat;

  double get userSearchHeight =>
      143.5 / (41 * controller.groupMemberList.toList().length.toDouble());

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      edgeOffset: -100.0,
      displacement: 0.0,
      onRefresh: () async => controller.onRefresh(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(left: 16, top: 6, bottom: 6),
            width: double.infinity,
            color: colorBackground,
            child: Text(
              localized(homeTabMessage),
              style: jxTextStyle.textStyle14(color: colorTextSecondary),
            ),
          ),
          Flexible(
            child: Obx(
              () => Container(
                // color: Colors.white,
                child: controller.isTextTypeSearch.value
                    ? Container(
                        height: 1.sh,
                        color: Colors.white,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount:
                              controller.searchedIndexList.toList().length,
                          itemBuilder: (BuildContext context, int index) {
                            Message message =
                                controller.searchedIndexList[index];

                            return Column(
                              children: <Widget>[
                                MessageCellView<MessageItemController>(
                                  message: message,
                                  chatId: message.chat_id,
                                  searchText: controller.searchController.text,
                                  isListMode: true,
                                  onClick: () {
                                    controller.positioningMessage(
                                      message,
                                      index,
                                    );
                                  },
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: jxDimension.chatCellPadding(),
                                  ),
                                  child: const CustomDivider(),
                                )
                              ],
                            );
                          },
                        ),
                      )
                    : controller.groupMemberList.toList().length <= 3
                        ? ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            reverse: true,
                            itemExtent: 41,
                            itemCount:
                                controller.groupMemberList.toList().length,
                            itemBuilder: (BuildContext context, int index) {
                              User user = controller.groupMemberList[index];
                              return _buildGroupMemberView(user);
                            },
                          )
                        : RotatedBox(
                            quarterTurns: 2,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                Container(
                                  height: 41,
                                  color: Colors.white,
                                ),
                                SizedBox(
                                  height: 41 *
                                      controller.groupMemberList
                                          .toList()
                                          .length
                                          .toDouble(),
                                  child: DraggableScrollableSheet(
                                    initialChildSize: userSearchHeight >= 0.44
                                        ? userSearchHeight
                                        : 0.44,
                                    minChildSize: userSearchHeight >= 0.44
                                        ? userSearchHeight
                                        : 0.44,
                                    maxChildSize: 1,
                                    expand: false,
                                    builder:
                                        (_, ScrollController scrollController) {
                                      return ListView.builder(
                                        padding: EdgeInsets.zero,
                                        physics: const ClampingScrollPhysics(),
                                        controller: scrollController,
                                        shrinkWrap: true,
                                        itemExtent: 41,
                                        itemCount: controller.groupMemberList
                                            .toList()
                                            .length,
                                        itemBuilder: (
                                          BuildContext context,
                                          int index,
                                        ) {
                                          User user =
                                              controller.groupMemberList[index];
                                          return RotatedBox(
                                            quarterTurns: 2,
                                            child: _buildGroupMemberView(
                                              user,
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupMemberView(User user) {
    return GestureDetector(
      onTap: () {
        controller.onSelectUser(user);
      },
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            CustomAvatar.user(
              user,
              size: 30,
              headMin: Config().headMin,
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: Column(
                children: [
                  const Divider(
                    thickness: 1,
                    height: 1,
                    color: colorBackground6,
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      NicknameText(
                        isTappable: false,
                        uid: user.id,
                        fontSize: MFontSize.size14.value,
                        fontWeight: MFontWeight.bold5.value,
                        overflow: TextOverflow.ellipsis,
                        color: Colors.black,
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      Flexible(
                        child: Text(
                          "@${user.nickname}",
                          style: TextStyle(
                            fontSize: MFontSize.size14.value,
                            fontWeight: MFontWeight.bold4.value,
                            color: Colors.black.withOpacity(0.44),
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
