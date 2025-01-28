import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_button.dart';

import '../../main.dart';
import '../../object/user.dart';
import '../../utils/theme/text_styles.dart';

class DesktopShareContact extends StatelessWidget {
  const DesktopShareContact({
    Key? key,
    required this.controller,
  }) : super(key: key);
  final CustomInputController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: 450,
          width: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Send Contacts',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: MFontWeight.bold5.value,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Container(
                      height: 300,
                      child: ListView.separated(
                        itemCount: objectMgr.userMgr.friendWithoutBlacklist.length,
                        itemBuilder: (context, index) {
                          final User user = objectMgr.userMgr.friendWithoutBlacklist[index];
                          return DesktopGeneralButton(
                            onPressed: () {
                              objectMgr.chatMgr.sendRecommendFriend(
                                controller.chatController.chat.chat_id,
                                user.id,
                                user.nickname,
                                user.id,
                                user.countryCode,
                                user.contact,
                              );
                              Get.back();
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Container(
                                height: 50,
                                child: Row(
                                  children: <Widget>[
                                    CustomAvatar(
                                      uid: user.uid,
                                      size: 40,
                                    ),
                                    const SizedBox(
                                      width: 20,
                                    ),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            objectMgr.userMgr
                                                .getUserTitle(user),
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 14,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                          Text(
                                            user.profileBio.isEmpty
                                                ? '...'
                                                : user.profileBio,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (context, index) {
                          return const Padding(
                            padding: EdgeInsets.only(left: 65),
                            child: CustomDivider(),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
