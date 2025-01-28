import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/moment/component/create_tags_bottom_sheet_controller.dart';
import 'package:jxim_client/object/tags.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/check_tick_item.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';

class MomentTagBottomSheet extends StatelessWidget
{
  final CreateTagsBottomSheetController controller;
  final Function(Map<int,List<User>> tags) confirmCallback;
  final Function() cancelCallback;
  final String title;
  final String placeHolder;
  final bool isIncludeBlockedUsers;

  const MomentTagBottomSheet({
    super.key,
    required this.controller,
    required this.confirmCallback,
    required this.cancelCallback,
    required this.title,
    required this.placeHolder,
    this.isIncludeBlockedUsers = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: firstPage(context),
    );
  }

  Widget firstPage(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Container(
        color: colorBackground,
        height: MediaQuery.of(context).size.height * 0.94,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 60,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(
                vertical: 10.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomLeadingIcon(
                    buttonOnPressed: cancelCallback,
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: jxTextStyle.appTitleStyle(
                            color: colorTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Map<int,List<User>> tags = {};
                      for(var tag in controller.selectedMembers){
                        tags[tag.uid] = controller.allTagByGroup[tag.uid]??[];
                      }

                      confirmCallback.call(tags);
                      // Get.back();
                    },
                    child: OpacityEffect(
                      child: Container(
                        alignment: Alignment.centerRight,
                        width: 70,
                        padding: const EdgeInsets.only(right: 10.0),
                        child: Text(
                          localized(buttonDone),
                          style: jxTextStyle.textStyle17(color: themeColor),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const CustomDivider(),

            /// Search Bar
            Obx(
                  () => AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: Container(
                  constraints:
                  const BoxConstraints(minHeight: 40, maxHeight: 120),
                  padding: const EdgeInsets.only(
                    left: 16,
                  ),
                  child: SingleChildScrollView(
                    controller: controller.selectedMembersController,
                    physics: const ClampingScrollPhysics(),
                    child: Wrap(
                      // spacing: 8,
                      children: [
                        ...List.generate(
                          controller.selectedMembers.length, (index) => GestureDetector(
                            onTap: () {
                              if (controller.highlightMember.value != controller.selectedMembers[index].uid) {
                                controller.highlightMember.value = controller.selectedMembers[index].uid;
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(
                                top: 8,
                                left: 0,
                                right: 8,
                              ),
                              constraints: const BoxConstraints(maxWidth: 150),
                              child: Stack(
                                key: ValueKey(
                                  controller.selectedMembers[index].uid,
                                ),
                                children: <Widget>[
                                  Container(
                                    decoration: BoxDecoration(
                                      color: colorTextPrimary.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if(controller.selectedMembers.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 3),
                                            child: SvgPicture.asset(
                                              'assets/svgs/tag_bottom_sheet.svg',
                                              width: 22,
                                              height: 22,
                                              fit: BoxFit.fill,
                                              colorFilter: const ColorFilter.mode(
                                                colorTextPrimary,
                                                BlendMode.srcIn,
                                              )
                                            ),
                                          ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                            bottom: 4,
                                            left: 4,
                                            right: 8,
                                          ),
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 116,
                                            ),
                                            child:
                                              Text(
                                                  controller.selectedMembers[index].tagName,
                                                  style: jxTextStyle.textStyle14(color: colorTextPrimary),
                                                  overflow: TextOverflow.ellipsis,
                                              )
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Obx(() => Visibility(
                                      visible: controller.highlightMember.value == controller.selectedMembers[index].uid,
                                      child: Positioned(
                                        child: Container(
                                          margin:
                                          const EdgeInsets.only(right: 0),
                                          constraints: const BoxConstraints(
                                            maxWidth: 150,
                                          ),
                                          child: GestureDetector(
                                            onTap: () => controller.onSelect(context, null, controller.selectedMembers[index],),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: themeColor,
                                                borderRadius: BorderRadius.circular(20.0),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Padding(
                                                    padding: EdgeInsets.only(left: 8,),
                                                    child: Icon(
                                                      Icons.close,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                    const EdgeInsets.only(top: 4, bottom: 4, left: 4, right: 8,),
                                                    child: Container(
                                                      constraints: const BoxConstraints(maxWidth: 116,),
                                                      child:
                                                      Text(
                                                        controller.selectedMembers[index].tagName,
                                                        style: jxTextStyle.textStyle14(color: Colors.white),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 8),
                            child: TextField(
                              contextMenuBuilder: textMenuBar,
                              onTap: () => controller.isSearching(true),
                              controller: controller.searchController,
                              onChanged: controller.onSearchChanged,
                              cursorColor: themeColor,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                isCollapsed: true,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                hintText: placeHolder,
                                hintStyle: jxTextStyle.textStyle14(
                                  color: colorTextSupporting,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const CustomDivider(),

            /// Contact List
            Obx(() => (controller.tagsList.isNotEmpty)
                  ? Expanded(
                        child: AzListView(
                        noResultFound: localized(noResultFound),
                        itemCount: controller.tagsList.length,
                        itemBuilder: (context, index) {
                          final item = controller.tagsList[index];
                          return _buildListItem(context, item,index);
                        },
                        indexBarHeight:0,
                        indexBarOptions: IndexBarOptions(
                          textStyle: TextStyle(
                            color: themeColor,
                            fontSize: 10,
                            fontWeight: MFontWeight.bold5.value,
                          ),
                        ), data: controller.azFilterTagsList,
                      ),
                    )
                  : Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Center(
                  child: Text(
                    localized(noResultFound),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// create contact card
  Widget _buildListItem(BuildContext context, Tags item,int index) {
    return
      Obx(() {
        List<User>? user = controller.allTagByGroup[item.uid];
        return Container(
          color: Colors.white,
          child:
          GestureDetector(
            onTap: () {
              controller.onSelect(
                context,
                null,
                item,
              );
            },
            child:  Column(
              children: <Widget>[
                OverlayEffect(
                  child: Row(
                    children: [
                      /// CheckBox
                      Obx(() => Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.centerLeft,
                        child: CheckTickItem(
                          isCheck: controller.selectedMembers.contains(item),
                        ),
                      ),
                      ),

                      /// Contact Info
                      Expanded(
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.only(
                                  left: 0,
                                  right: 20,
                                ),
                                height: 50,
                                alignment: Alignment.centerLeft,
                                decoration: const BoxDecoration(
                                  border: null,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(item.tagName,
                                        style: jxTextStyle.textStyleBold16(color: colorTextPrimary,)
                                    ),
                                    const SizedBox(height: 4),
                                    Text("${user?.length??0} ${localized(groupMember)}",
                                      style: jxTextStyle.textStyle12(
                                        color: colorTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                index != controller.tagsList.length - 1
                    ? const Padding(
                        padding:  EdgeInsets.only(left: 44),
                        child:  Align(
                          alignment: Alignment.bottomCenter,
                          child: Divider(
                            height: 1,
                            color: colorTextPlaceholder,
                          ),
                        ),
                      )
                    : const SizedBox(height: 1,)
              ],
            ),
          ),
          );
      });

  }
}
