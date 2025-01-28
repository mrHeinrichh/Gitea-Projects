import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import '../../../object/user.dart';
import '../../../routes.dart';
import '../../../utils/theme/text_styles.dart';
import '../../component/custom_confirmation_popup.dart';
import '../search_contact_controller.dart';
import 'contact_card.dart';

class SearchingResultList extends GetWidget<SearchContactController> {
  const SearchingResultList(this.list, this.title,
      {Key? key, this.isUsername = true})
      : super(key: key);
  final List<User> list;
  final String title;
  final bool isUsername;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ListView.builder(
        physics: const ClampingScrollPhysics(),
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: list.isNotEmpty ? list.length + 1 : list.length,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return Container(
              height: 30,
              width: double.infinity,
              color: backgroundColor,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                title,
                style:jxTextStyle.textStyle14(color: JXColors.secondaryTextBlack),
              ),
            );
          } else {
            final user = list[index - 1];
            return ContactCard(
              key: ValueKey(user.uid),
              onTap: () {
                Get.toNamed(RouteName.chatInfo, arguments: {"uid": user.uid});
              },
              withCustomBorder: index != list.length,
              user: user,
              subTitle: isUsername
                  ? user.username.isEmpty
                      ? ''
                      : "@${user.username}"
                  : "${user.countryCode}\t${user.contact}",
              trailing: [
                Visibility(
                  visible: user.relationship == Relationship.receivedRequest,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => controller.onAddFriendClick(context,user),
                        child: Padding(
                          padding: EdgeInsets.all(
                              MediaQuery.of(context).size.width * 0.02),
                          child: const Icon(
                            Icons.check,
                            color: Color(0xFF57C055),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          FocusManager.instance.primaryFocus?.unfocus();

                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (BuildContext context) {
                              return CustomConfirmationPopup(
                                title: localized(contactFriendRequest),
                                subTitle:
                                "${localized(reject)} ${user.nickname}${localized(sFriendRequest)}?",
                                confirmButtonText: localized(buttonConfirm),
                                cancelButtonText: localized(buttonCancel),
                                confirmCallback: () {
                                  controller.rejectFriend(user);
                                },
                                cancelCallback: () => Navigator.of(context).pop(),
                              );
                            },
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.all(
                              MediaQuery.of(context).size.width * 0.02),
                          child: const Icon(
                            Icons.close,
                            color: Color(0xFFFF3B30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Visibility(
                  visible: user.relationship != Relationship.receivedRequest,
                  child: GestureDetector(
                    child: controller.checkStatus(user.relationship),
                    onTap: () async {
                      FocusManager.instance.primaryFocus?.unfocus();
                      if (user.relationship == Relationship.stranger) {

                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (BuildContext context) {
                            return CustomConfirmationPopup(
                              title: localized(addingANewFriend),
                              subTitle:
                              "${localized(adding)} ${user.nickname} ${localized(asANewFriendSendAFriendRequest)}?",
                              confirmButtonText: localized(buttonConfirm),
                              cancelButtonText: localized(buttonCancel),
                              confirmCallback: () {
                                controller.addFriend(user);
                              },
                              cancelCallback: () => Navigator.of(context).pop(),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
