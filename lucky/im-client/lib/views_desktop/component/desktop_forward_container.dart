import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/forward/forward_chat_picker.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/forward/forward_contact_picker.dart';
import 'package:jxim_client/views_desktop/component/desktop_forward_controller.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class DesktopForwardContainer extends StatelessWidget {
  const DesktopForwardContainer({
    Key? key,
    required this.chat,
    this.fromMediaDetail = false,
    this.fromChatInfo = false,
    this.forwardMsg,
  }) : super(key: key);
  final Chat chat;
  final bool fromMediaDetail;
  final bool fromChatInfo;
  final List<dynamic>? forwardMsg;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DesktopForwardController());
    return VisibilityDetector(
      key: GlobalKey(),
      onVisibilityChanged: (VisibilityInfo info) {
        if (info.visibleFraction == 0) {
          controller.userSearchController.clear();
          controller.chatSearchController.clear();
        }
      },
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            height: 550,
            width: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Forward',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: MFontWeight.bold5.value,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  DefaultTabController(
                    length: 2,
                    child: Column(
                      children: <Widget>[
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade100,
                                // Customize the border color
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: TabBar(
                            controller: controller.tabController,
                            tabs: [
                              Padding(
                                padding: EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  'Chats',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: MFontWeight.bold5.value,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  'Contacts',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: MFontWeight.bold5.value,
                                  ),
                                ),
                              ),
                            ],
                            indicator: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: accentColor,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            labelColor: accentColor,
                            unselectedLabelColor: Colors.grey.shade500,
                            onTap: (index) {
                              controller.tabController!.index = index;
                            },
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Container(
                          height: 445,
                          width: 350,
                          child: TabBarView(
                            controller: controller.tabController,
                            children: [
                              ForwardChatPicker(
                                chat: chat,
                                fromMediaDetail: fromMediaDetail,
                                fromChatInfo: fromChatInfo,
                                forwardMsg: forwardMsg,
                              ),
                              ForwardContactPicker(
                                chat: chat,
                                fromMediaDetail: fromMediaDetail,
                                fromChatInfo: fromChatInfo,
                                forwardMsg: forwardMsg,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
