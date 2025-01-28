import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/moment/index.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:lottie/lottie.dart';

class MomentPostToolBox extends StatefulWidget {
  final bool isLikePost;
  final Function(BuildContext context) onLikePost;
  final Function(BuildContext context) onCommentTap;

  final bool isOverlayEnabled;
  final VoidCallback? onEnd;

  const MomentPostToolBox({
    super.key,
    required this.isLikePost,
    required this.onLikePost,
    required this.onCommentTap,
    this.isOverlayEnabled = false,
    this.onEnd,
  });

  @override
  State<MomentPostToolBox> createState() => _MomentPostToolBoxState();
}

class _MomentPostToolBoxState extends State<MomentPostToolBox>
    with SingleTickerProviderStateMixin {
  bool isInit = false;
  late AnimationController likeAnimationControllers;

  final _kDrawerAnimationDuration = const Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        isInit = true;
      });
    });

    likeAnimationControllers = AnimationController(
      value: widget.isLikePost ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(MomentPostToolBox oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (isInit && !widget.isOverlayEnabled && oldWidget.isOverlayEnabled) {
      if (mounted) {
        setState(() {
          isInit = false;
        });
      }

      Future.delayed(_kDrawerAnimationDuration, widget.onEnd);
    }
  }

  @override
  void dispose() async {
    likeAnimationControllers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40.0,
      color: Colors.transparent,
      margin: const EdgeInsets.only(right: 4.0, bottom: 20.0),
      child: ClipRect(
        child: AnimatedAlign(
          alignment: Alignment.centerRight,
          widthFactor: isInit ? 1.0 : 0.0,
          duration: _kDrawerAnimationDuration,
          curve: Curves.easeOut,
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 2.0,
              horizontal: 2.0,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF4C4C4C),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                buildToolBox(context, 0),
                buildToolBox(context, 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 创建 工具栏组件
  /// @params:\
  /// buttonType: 按钮类型 | 0: 点赞, 1: 评论
  ///
  Widget buildToolBox(BuildContext context, int buttonType) {
    switch (buttonType) {
      case 0:
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            widget.isLikePost
                ? likeAnimationControllers.reverse()
                : likeAnimationControllers.forward();
            widget.onLikePost(context);
          },
          child: OverlayEffect(
            child: Row(
              children: [
                Container(
                  width: 100.0,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      OpacityEffect(
                        child: Lottie.asset(
                          'assets/lottie/like-animation2_white.json',
                          controller: likeAnimationControllers,
                          width: 24.0,
                          height: 24.0,
                          animate: false,
                        ),
                      ),
                      const SizedBox(width: 2.0),
                      Text(
                        widget.isLikePost
                            ? localized(buttonCancel)
                            : localized(momentLike),
                        style: jxTextStyle.textStyle14(
                          color: colorWhite,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 20.0,
                  child: VerticalDivider(
                    width: 0.5,
                    color: momentVerticalBorderColor,
                  ),
                ),
              ],
            ),
          ),
        );
      case 1:
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onCommentTap(context),
          child: OverlayEffect(
              child: Row(
            children: [
              const SizedBox(
                height: 20.0,
                child: VerticalDivider(
                  width: 0.5,
                  color: momentVerticalBorderColor,
                ),
              ),
              Container(
                width: 100.0,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SvgPicture.asset(
                      'assets/svgs/comment_outlined.svg',
                      width: 24.0,
                      height: 24.0,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 2.0),
                    Text(
                      localized(momentComment),
                      style: jxTextStyle.textStyle14(
                        color: colorWhite,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )),
        );
      default:
        return const SizedBox();
    }
  }
}
