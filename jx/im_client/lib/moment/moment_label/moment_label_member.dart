import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class MomentLabelMemberBottomSheet extends StatelessWidget
{
  final String tagName;
  final List<User> member;
  final Function() cancelCallback;

  const MomentLabelMemberBottomSheet({super.key,required this.tagName,required this.member, required this.cancelCallback,});

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
                            style: jxTextStyle.textStyle17(color: themeColor)),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    tagName,
                    style: jxTextStyle.appTitleStyle(color: colorTextPrimary),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
              child: member.isNotEmpty
                  ? CustomScrollView(
                      slivers: [
                        /// The list of mention friends
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                            sliver: DecoratedSliver(
                              decoration: BoxDecoration(
                                color: colorWhite,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              sliver: SliverList.builder(
                                itemCount: member.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final user = member[index];
                                  return friendsTile(user.alias.isEmpty?user.nickname:user.alias,index);
                                },
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
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.only(bottom: 24),
                          alignment: Alignment.center,
                          child: Image.asset(
                            'assets/images/tag_contact_empty_logo.png',
                            width: 84.0,
                            height: 84.0,
                          ),
                        ),
                        Padding(padding:const EdgeInsets.only(bottom: 8),
                          child:Text(localized(momentTagNoContact),style: jxTextStyle.textStyle17(),),
                        ),Padding(
                            padding: const EdgeInsets.only(left: 16,right: 16),
                            child: Center(
                              child: Text(localized(momentTagAddContact),textAlign: TextAlign.center,style: jxTextStyle.textStyle17(color: colorTextSecondary,),
                              ),
                            ),
                        ),
                      ],
                    )

          ),
        ],
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
                    member[index],
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

          if (index != member.length - 1)
            const Padding(
              padding: EdgeInsets.only(left: 66.0),
              child: CustomDivider(),
            ),
        ],
      ),
    );
  }
}