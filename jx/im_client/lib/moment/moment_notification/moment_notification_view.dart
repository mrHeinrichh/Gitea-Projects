import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/moment/index.dart';
import 'package:jxim_client/moment/moment_notification/moment_notification_controller.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/component/nickname_text.dart';

class MomentNotificationView extends GetView<MomentNotificationController> {
  const MomentNotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PrimaryAppBar(
        withBackTxt: false,
        backButtonColor: colorTextPrimary,
        bgColor: colorBackground,
        centerTitle: true,
        titleWidget: Text(
          localized(messages).capitalizeFirst ?? localized(messages),
          style: jxTextStyle.textStyleBold17(color: Colors.black),
        ),
        trailing: <Widget>[
          Obx(
            () => GestureDetector(
              onTap: () => controller.onClearNotification(context),
              child: OpacityEffect(
                isDisabled: controller.notificationList.isEmpty,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text(
                      localized(chatClear),
                      style: jxTextStyle.textStyle17(color: colorTextPrimary),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: <Widget>[
          Obx(
            () => SliverList.builder(
              itemCount: controller.notificationList.length,
              itemBuilder: (BuildContext context, int index) {
                final MomentDetailUpdate notification =
                    controller.notificationList[index];
                return _buildNotificationItem(context, notification);
              },
            ),
          ),
          Obx(
            () => SliverToBoxAdapter(
              child: controller.hasMore.value
                  ? _buildHasMore(context)
                  : const SizedBox(),
            ),
          ),
          Obx(
            () => controller.notificationList.isEmpty &&
                    !controller.isLoading.value
                ? SliverFillRemaining(
                    child: Center(
                      child: Text(
                        localized(noResults),
                        style: jxTextStyle.textStyleBold17(
                          color: colorTextPrimary,
                        ),
                      ),
                    ),
                  )
                : const SliverToBoxAdapter(),
          ),
          SliverPadding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewPadding.bottom,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    MomentDetailUpdate notification,
  ) {
    return GestureDetector(
      onTap: () => controller.enterMomentDetail(context, notification),
      child: OverlayEffect(
        child: Container(
          padding: const EdgeInsets.only(
            left: 16.0,
            top: 6.0,
            right: 8.0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CustomAvatar.normal(
                notification.content?.userId ?? 0,
                size: 40.0,
                headMin: Config().headMin,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(
                    bottom: 6.0,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: colorBackground6,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            NicknameText(
                              uid: notification.content!.userId!,
                              fontWeight: FontWeight.w600,
                              color: momentThemeColor,
                              overflow: TextOverflow.ellipsis,
                              isTappable: false,
                            ),

                            // content (Based on typ)
                            _buildNotificationContent(context, notification),

                            Text(
                              FormatTime.getCountTime(
                                (notification.createdAt ?? 0) * 1000,
                              ),
                              style: jxTextStyle.textStyle12(
                                color: colorTextSupporting,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      if (notBlank(notification.content!.postContent?.assets))
                        MomentCellMedia(
                          url: notBlank(
                            notification
                                .content!.postContent!.assets!.first.cover,
                          )
                              ? notification
                                  .content!.postContent!.assets!.first.cover!
                              : notification
                                  .content!.postContent!.assets!.first.url,
                          width: 54.0,
                          height: 54.0,
                          fit: BoxFit.cover,
                          gausPath: notification
                              .content!.postContent?.assets!.first.gausPath,
                        )
                      else
                        const SizedBox(
                          height: 54.0,
                          width: 54.0,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationContent(
    BuildContext context,
    MomentDetailUpdate notification,
  ) {
    if (notification.typ == null) {
      return const SizedBox();
    }

    switch (notification.typ) {
      case MomentNotificationType.commentNotificationType:
        bool isReplied = notification.content!.replyUserId != null &&
            notification.content!.replyUserId! > 0;
        return Text.rich(
          TextSpan(
            style: jxTextStyle.normalText(),
            children: <InlineSpan>[
              if (isReplied)
                TextSpan(
                  text: '${localized(reply)} '.toLowerCase(),
                  children: <InlineSpan>[
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: NicknameText(
                        uid: notification.content!.replyUserId!,
                        isTappable: false,
                        fontSize: Platform.isAndroid
                            ? MFontSize.size13.value
                            : MFontSize.size14.value,
                        color: momentThemeColor,
                        fontLineHeight: 1.36,
                      ),
                    ),
                    const TextSpan(text: ': '),
                  ],
                ),
              TextSpan(text: '${notification.content!.msg}'),
            ],
          ),
        );
      case MomentNotificationType.deleteCommentNotificationType:
        return Container(
          color: const Color(0xFFF8F8F8),
          child: Text(
            localized(mentionCommentHasBeenDeleted),
            style: jxTextStyle.textStyle14(color: colorTextSupporting),
          ),
        );
      case MomentNotificationType.likeNotificationType:
        return SvgPicture.asset(
          'assets/svgs/like_outlined_bold.svg',
          width: 16.0,
          height: 16.0,
          colorFilter: const ColorFilter.mode(
            momentThemeColor,
            BlendMode.srcIn,
          ),
        );
      case MomentNotificationType.commentMentionNotificationType:
      case MomentNotificationType.postMentionNotificationType:
        return Text(
          localized(mentionYou),
          maxLines: 1,
          style: jxTextStyle.textStyle14(),
          overflow: TextOverflow.ellipsis,
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildHasMore(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: controller.isLoading.value
          ? const Center(
              key: ValueKey('loading'),
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            )
          : GestureDetector(
              key: const ValueKey('load_more'),
              onTap: controller.onLoadMore,
              child: OverlayEffect(
                child: Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.symmetric(vertical: 24.0),
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    localized(momentNotificationViewHistory),
                    style: jxTextStyle.textStyle14(color: colorTextSecondary),
                  ),
                ),
              ),
            ),
    );
  }
}
