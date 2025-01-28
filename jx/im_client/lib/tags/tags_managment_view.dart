import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:jxim_client/tags/tags_management_controller.dart';
import 'package:jxim_client/tags/tags_tile.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

class TagsManagementView extends StatelessWidget {
  const TagsManagementView({super.key});

  @override
  Widget build(BuildContext context)
  {
    return GetBuilder<TagsManagementController>(
      init: Get.find<TagsManagementController>(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: colorBackground,
          appBar: PrimaryAppBar(
            title:localized(favouriteTag),
            trailing: <Widget>[
              /// Edit button
              OpacityEffect(
                child: GestureDetector(
                  onTap: controller.toggleEdit,
                  child: Obx(() => controller.allTagByGroup.isNotEmpty || controller.tagsList.length>1
                        ? Container(
                            padding: const EdgeInsets.only(right: 16.0),
                            alignment: Alignment.centerRight,
                            child: Text(
                              controller.isEditing.value
                                  ? localized(buttonDone)
                                  : localized(edit),
                              style: jxTextStyle.textStyle17(color: themeColor),
                            ),
                           )
                        :const SizedBox()
                  ),
                ),
              ),
            ],
          ),
          body: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: CustomScrollView(
              slivers: <Widget>[
                ///Cover
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    alignment: Alignment.center,
                    child: Column(
                      children: <Widget>[
                        Image.asset(
                          'assets/images/tags_logo.png',
                          width: 84.0,
                          height: 84.0,
                        ),
                        const SizedBox(height: 12.0),
                        Text(localized(tagYourFriends),
                          style: jxTextStyle.textStyle14(
                            color: colorTextSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                ///Subtitle
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      localized(favouriteTag),
                      style: jxTextStyle.textStyle13(color: colorTextSecondary),
                    ),
                  ),
                ),

                /// The list of tags
                SlidableAutoCloseBehavior(
                  child:
                  Obx(() => SliverPadding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      sliver: DecoratedSliver(
                        decoration: BoxDecoration(
                          color: colorWhite,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        sliver:
                        SliverList.builder(
                          itemCount: controller.tagsList.length,
                          itemBuilder: (BuildContext context, int index) {
                            if (index == 0) {
                              /// create tags
                              return _buildCreateTagsItem(
                                const ValueKey("create_tags"),
                                context,
                                controller,
                                controller.tagsList.length,
                              );
                            }

                            final tag = controller.tagsList[index];

                            return TagsTile(
                              index: index ,
                              controller: controller,
                              tag: tag,
                            );
                          },
                        ),
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildCreateTagsItem(Key? key, BuildContext context, TagsManagementController controller,int tagsLength)
  {
    return GestureDetector(
      key: key,
      onTap: () => controller.onTagsPress(context),
      child: OverlayEffect(
        radius: const BorderRadius.only(
          topLeft: Radius.circular(8.0),
          topRight: Radius.circular(8.0),
        ),
        child: Container(
          margin: const EdgeInsets.only(
            left: 16.0,
          ),
          padding: const EdgeInsets.only(
            top: 11.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                localized(tagAddTags),
                style: jxTextStyle.textStyle17(
                  color: themeColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 11.0),
                child: tagsLength > 1 ? Container(
                    width: double.infinity,
                    height: 0.5,
                    color: colorTextPlaceholder
                ) : const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
