import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/emoji/emoji_utils.dart';

typedef OnEmojiClick = void Function(String emoji);

class EmojiComponent extends StatefulWidget {
  final OnEmojiClick onEmojiClick;

  const EmojiComponent({super.key, required this.onEmojiClick});

  @override
  State<StatefulWidget> createState() => _EmojiGridViewState();
}

class _EmojiGridViewState extends State<EmojiComponent> {
  final List<String> recentEmojiList = [];

  @override
  void initState() {
    super.initState();
    recentEmojiList.addAll(objectMgr.stickerMgr.recentEmojiList);
  }

  @override
  Widget build(BuildContext context) {
    final onEmojiClick = widget.onEmojiClick;
    return ListView(
      padding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: (objectMgr.loginMgr.isDesktop) ? 10 : 0,
      ),
      children: [
        if (recentEmojiList.isNotEmpty) ...[
          _EmojiGridView(
            header: localized(recentStickers),
            items: recentEmojiList,
            onEmojiClick: (String emoji) {
              onEmojiClick.call(emoji);
            },
          ),
          SizedBox(height: 8.w),
        ],
        _EmojiGridView(
          header: 'Emoji',
          items: EmojiUtils.getEmojiList(),
          onEmojiClick: (String emoji) {
            onEmojiClick.call(emoji);
          },
        ),
      ],
    );
  }
}

class _EmojiGridView extends StatelessWidget {
  const _EmojiGridView({
    required this.header,
    required this.items,
    required this.onEmojiClick,
  });

  final String header;
  final List<String> items;
  final OnEmojiClick onEmojiClick;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(header),
        SizedBox(height: 8.w),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: (objectMgr.loginMgr.isDesktop) ? 8 : 10,
            childAspectRatio: (28.w / 28.w),
          ),
          itemCount: items.length,
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              onTap: () {
                onEmojiClick(items[index]);
              },
              child: ForegroundOverlayEffect(
                radius: BorderRadius.circular(2.w),
                child: Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: FittedBox(child: _buildEmoji(items[index])),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmoji(String emoji) {
    return Text(
      textAlign: TextAlign.center,
      emoji,
      style: TextStyle(
        fontSize: 28,
        // fontFamily: 'emoji',
        height: ImLineHeight.getLineHeight(fontSize: 28, lineHeight: 32.81),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Text(
      title,
      style: jxTextStyle.textStyleBold12(color: colorTextSecondary).copyWith(
            fontFamily: 'pingfang',
            height: ImLineHeight.getLineHeight(fontSize: 12, lineHeight: 14.4),
          ),
      textAlign: TextAlign.center,
    );
  }
}
