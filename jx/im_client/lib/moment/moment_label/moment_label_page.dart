import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/moment/index.dart';
import 'package:jxim_client/moment/moment_label/moment_label_controller.dart';
import 'package:jxim_client/object/tags.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/custom_button.dart';

class MomentLabelBottomSheet extends StatelessWidget
{
  final int type;
  final MomentLabelController controller;
  final Function(Tags tag) clickTagCallback;
  final Function(MomentVisibility momentVisibility,List<User> selectedFriends,List<Tags> selectedLabel,List<User> selectLabelFriends) changeCallback;

  const MomentLabelBottomSheet({super.key, this.type = 0,required this.controller,required this.changeCallback, required this.clickTagCallback,});

  @override
  Widget build(BuildContext context)
  {
    return Container(
      height: MediaQuery.of(context).size.height * 0.94,
      decoration: const BoxDecoration(
        color: colorBackground,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(12),
          topLeft: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
            SizedBox(
              height: 58 ,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: OpacityEffect(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(localized(cancel),
                              style:
                              jxTextStyle.textStyle17(color: themeColor)),
                        ),
                      ),
                    ),
                  ),
                  Obx(()=> Center(
                    child: Text(
                        localized(controller.viewPermission.value == MomentVisibility.public ?
                        momentPublic: controller.viewPermission.value == MomentVisibility.specificFriends?
                        momentCreateVisible:controller.viewPermission.value == MomentVisibility.hideFromSpecificFriends?
                        momentPermissionHiddenFrom:momentPrivate),
                        style: jxTextStyle.appTitleStyle(color: colorTextPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child:
                controller.viewPermission.value == MomentVisibility.private
                    || ((controller.viewPermission.value == MomentVisibility.specificFriends || controller.viewPermission.value == MomentVisibility.hideFromSpecificFriends)
                          &&
                        (controller.tagsList.isEmpty && controller.userList.isEmpty))
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.only(bottom: 24),
                            alignment: Alignment.center,
                            child: Image.asset(
                              controller.viewPermission.value == MomentVisibility.private
                                  ?'assets/images/tag_private_logo.png'
                                  :'assets/images/tag_contact_empty_logo.png',
                              width: 84.0,
                              height: 84.0,
                            ),
                          ),
                          Padding(padding:const EdgeInsets.only(bottom: 8),
                            child:Text(controller.viewPermission.value == MomentVisibility.private
                                ? localized(momentTagVisibilityPrivate)
                                : localized(momentTagEmpty),style: jxTextStyle.textStyle17(),),
                          ),
                          Text(controller.viewPermission.value == MomentVisibility.private
                              ?localized(momentTagVisibilityPrivateContent)
                              :localized(momentTagChangeVisibility),style: jxTextStyle.textStyle17(color: colorTextSecondary)),
                        ],
                      )
                    : CustomScrollView(
                        slivers: [
                          ///Label Subtitle
                          SliverToBoxAdapter(
                            child:
                              controller.tagsList.isNotEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.fromLTRB(32.0, 16, 0, 0),
                                      child: Text(
                                        localized(momentTagFriends),
                                        style: jxTextStyle.textStyle13(color: colorTextSecondary),
                                      ),
                                    )
                                  :const SizedBox(),
                          ),

                          /// The list of tags
                          Obx(() => SliverPadding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                            sliver: DecoratedSliver(
                                decoration: BoxDecoration(
                                  color: colorWhite,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                sliver: SliverList.builder(
                                  itemCount: controller.tagsList.length,
                                  itemBuilder: (BuildContext context, int index) {

                                    final tag = controller.tagsList[index];

                                    return tagsTile(tag.tagName,tag.uid,index);
                                  },
                                ),
                              ),
                            ),
                          ),

                          ///Other Subtitle
                          SliverToBoxAdapter(
                            child:
                            Obx(()=>
                              controller.userList.isNotEmpty
                                  ? Padding(
                                        padding: const EdgeInsets.fromLTRB(32.0, 16, 0, 0),
                                        child: Text(
                                        localized(momentTagOtherFriends),
                                        style: jxTextStyle.textStyle13(color: colorTextSecondary),
                                      ),
                                    )
                                  : const SizedBox()
                            ),
                          ),

                          /// The list of mention friends
                          Obx(() => SliverPadding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0,horizontal: 16),
                            sliver: DecoratedSliver(
                              decoration: BoxDecoration(
                                color: colorWhite,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              sliver: SliverList.builder(
                                itemCount: controller.userList.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final user = controller.userList[index];
                                  return friendsTile(user.alias.isEmpty?user.nickname:user.alias,index);
                                },
                              ),
                            ),
                           ),
                          ),

                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: MediaQuery.of(context).viewPadding.bottom + 24.0,
                            ),
                          ),
                        ],
                      )
            ),
            Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
              child:
                  CustomButton(
                    text: localized(momentVisibleRange),
                    callBack: () {
                      controller.onPermissionSelect(changeCallback);
                    },
                  ),
            ),
        ],
      ),
    );
  }

  Widget tagsTile(String tagName,int uid,int index) {
    return
      GestureDetector(
        onTap: (){
          clickTagCallback.call(controller.tagsList[index]);
        },
        child: OverlayEffect(
          withEffect: true,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  top: 11.0,
                  bottom: 11.0,
                  right: 16.0,
                ),
                child:
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(tagName,
                        style: jxTextStyle.textStyle17(color: uid==MomentLabelController.LABEL_IS_NOT_EXIST?colorTextPlaceholder:Colors.black),
                      ),
                    ),

                    Row(
                      children: [
                        Padding(padding: const EdgeInsets.only(right: 3),
                          child:
                            Text(uid==MomentLabelController.LABEL_IS_NOT_EXIST?"":objectMgr.tagsMgr.allTagByGroup[uid]?.length.toString()??"0",
                              style: jxTextStyle.textStyle17(color:colorTextSecondary),
                            ),
                        ),
                        SvgPicture.asset(
                          'assets/svgs/right_arrow_thick.svg',
                          width: 16.0,
                          height: 16.0,
                          colorFilter: ColorFilter.mode(
                            uid==MomentLabelController.LABEL_IS_NOT_EXIST?colorTextPlaceholder:colorTextSupporting,
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    )

                  ],
                ),
              ),

              if (index != controller.tagsList.length - 1)
                const Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: CustomDivider(),
                ),
            ],
          ),
        ),
      );
  }

  Widget friendsTile(String userName,int index)
  {
    return OverlayEffect(
      withEffect: true,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              top: 11.0,
              bottom: 11.0,
              right: 16.0,
            ),
            child:
            Row(
              children: <Widget>[
                Padding(padding: const EdgeInsets.only(right: 12),
                  child: CustomAvatar.user(
                    controller.userList[index],
                    size: 40,
                    headMin: Config().headMin,
                  ),
                ),
                Expanded(
                  child: Text(userName,
                    style: jxTextStyle.textStyle17(),
                  ),
                ),
              ],
            ),
          ),

          if (index != controller.userList.length - 1)
            const Padding(
              padding: EdgeInsets.only(left: 66.0),
              child: CustomDivider(),
            ),
        ],
      ),
    );
  }
}