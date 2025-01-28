import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/setting/chat_category_folder/chat_category_controller.dart';
import 'package:jxim_client/setting/chat_category_folder/components/chat_category_tile.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

class ChatCategoryView extends StatelessWidget {
  const ChatCategoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatCategoryController>(
      init: Get.find<ChatCategoryController>(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: colorBackground,
          appBar: PrimaryAppBar(
            title: localized(chatCategoryTitle),
            trailing: <Widget>[
              // 编辑按钮

              OpacityEffect(
                child: GestureDetector(
                  onTap: controller.toggleEdit,
                  child: Obx(
                    () => controller.categoryList.length < 2
                        ? const SizedBox()
                        : Container(
                            padding: const EdgeInsets.only(right: 16.0),
                            alignment: Alignment.centerRight,
                            child: Text(
                              controller.isEditing.value
                                  ? localized(buttonDone)
                                  : localized(edit),
                              style: jxTextStyle.textStyle17(color: themeColor),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          body: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    alignment: Alignment.center,
                    child: Column(
                      children: <Widget>[
                        Image.asset(
                          'assets/images/chat_category_folder_main.png',
                          width: 84.0,
                          height: 84.0,
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          localized(chatCategorySubTitle),
                          style: jxTextStyle.textStyle14(
                            color: colorTextSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      localized(chatCategoryFolderTitle),
                      style: jxTextStyle.textStyle13(color: colorTextSecondary),
                    ),
                  ),
                ),

                // 文件夹 列表
                SlidableAutoCloseBehavior(
                  child: Obx(
                    () => SliverPadding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      sliver: DecoratedSliver(
                        decoration: BoxDecoration(
                          color: colorWhite,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        sliver: SliverReorderableList(
                          itemBuilder: (BuildContext context, int index) {
                            if (index == 0) {
                              // create folder
                              return _buildCreateFolderItem(
                                UniqueKey(),
                                context,
                                controller,
                              );
                            }

                            final category = controller.categoryList[index - 1];

                            return IgnorePointer(
                              key: category.isAllChatRoom
                                  ? UniqueKey()
                                  : ValueKey('${category.id}_child'),
                              ignoring: category.isAllChatRoom,
                              child: ChatCategoryTile(
                                index: index - 1,
                                controller: controller,
                                category: category,
                              ),
                            );
                          },
                          itemCount: controller.categoryList.length + 1,
                          proxyDecorator: (Widget child, _, __) {
                            return _buildCategoryDragProxy(context, child);
                          },
                          onReorderStart: controller.onReorderStart,
                          onReorderEnd: controller.onReorderEnd,
                          onReorder: controller.onReorder,
                        ),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      localized(chatCategoryHintSubtitle),
                      style: jxTextStyle.textStyle13(color: colorTextSecondary),
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

  Widget _buildCategoryDragProxy(BuildContext context, Widget child) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: colorWhite,
        boxShadow: [
          BoxShadow(
            color: colorTextPrimary.withOpacity(0.30),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildCreateFolderItem(
    Key? key,
    BuildContext context,
    ChatCategoryController controller,
  ) {
    return GestureDetector(
      key: key,
      onTap: () => controller.onChatCategoryPress(context),
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
                localized(chatCategoryCreateFolder),
                style: jxTextStyle.textStyle17(
                  color: themeColor,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 11.0),
                child: CustomDivider(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
