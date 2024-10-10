import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/gaussian_image/gaussian_image.dart';

class PostItem extends StatefulWidget {
  final ReelPost item;
  final bool showSelect;
  final bool isSelectCheck;
  final Function()? onSelectTap;
  final ReelPostType? type;
  final bool showDraft;

  const PostItem({
    super.key,
    required this.item,
    this.showSelect = false,
    this.isSelectCheck = false,
    this.onSelectTap,
    this.type,
    this.showDraft = false,
  });

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;


  @override
  dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(PostItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // if (oldWidget.item.post!.id != widget.item.post!.id) {
    //   reelData.value = widget.item;
    //   post.value = widget.item.post!;
    //   isLiked.value = reelData.value.isLiked!;
    //   likedCount.value = post.value.likedCount ?? 0;
    // }
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        GaussianImage(
          src: widget.item.thumbnail.value!,
          gaussianPath: widget.item.gausPath.value,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          mini: Config().messageMin,
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withOpacity(0.40)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                Visibility(
                  visible: widget.showDraft,
                  child: Row(
                    children: [
                      Text(
                        localized(reelPostDraft),
                        style: jxTextStyle.textStyleBold12(color: colorWhite),
                      ),
                      ImGap.hGap4,
                      Text(
                        "2",
                        style: TextStyle(
                          fontSize: MFontSize.size12.value,
                          color: colorWhite,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.16),
                              offset: const Offset(0, 0),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Visibility(
                  visible: !widget.showDraft,
                  child: Row(
                    children: [
                      const CustomImage(
                        'assets/svgs/favourite_outline_icon.svg',
                        color: colorWhite,
                        padding: EdgeInsets.only(right: 4),
                      ),
                      Obx(
                        () => Text(
                          "${widget.item.likedCount.value ?? 0}",
                          style: TextStyle(
                            fontSize: MFontSize.size12.value,
                            color: colorWhite,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.16),
                                offset: const Offset(0, 0),
                                blurRadius: 4,
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
        ),
        if (widget.showSelect)
          Positioned(
            right: 8,
            top: 8,
            child: GestureDetector(
              onTap: widget.onSelectTap,
              child: CheckTickItem(
                isCheck: widget.isSelectCheck,
                borderColor: colorWhite,
              ),
            ),
          ),
      ],
    );
  }
}
