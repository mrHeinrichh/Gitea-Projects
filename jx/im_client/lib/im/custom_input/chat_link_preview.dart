import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/link_analyzer/parser.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';

class ChatLinkPreview extends StatefulWidget {
  final Metadata metadata;
  final CustomInputController controller;

  const ChatLinkPreview({
    super.key,
    required this.metadata,
    required this.controller,
  });

  @override
  State<ChatLinkPreview> createState() => _ChatLinkPreviewState();
}

class _ChatLinkPreviewState extends State<ChatLinkPreview> {
  late Metadata data;

  @override
  void initState() {
    super.initState();
    data = widget.metadata;
  }

  @override
  void didUpdateWidget(ChatLinkPreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.metadata.hashCode != oldWidget.metadata.hashCode) {
      data = widget.metadata;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  void _onClear() {
    objectMgr.chatMgr.linkPreviewData.remove(widget.controller.chatId);
    if (widget.controller.inputFocusNode.hasFocus) {
      widget.controller.ignoreLinkPreview = true;
    }
    widget.controller.update();
  }

  void _onImageLoadError() async {
    final previewImage = downloadMgrV2.getLocalPath(data.image!);
    if (previewImage != null) return;
    data.image = null;
    data.imageHeight = null;
    data.imageWidth = null;

    widget.controller.updateLinkPreviewData(data);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 8.0,
        left: objectMgr.loginMgr.isDesktop ? 14.5 : 12.0,
        right: objectMgr.loginMgr.isDesktop ? 14.5 : 12.0,
      ),
      height: 46,
      color: colorBackground,
      width: double.infinity,
      child: _buildPreview(data),
    );
  }

  Widget _buildPreview(Metadata metadata) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: SvgPicture.asset(
            'assets/svgs/link.svg',
            width: 24,
            height: 24,
            color: themeColor,
          ),
        ),
        Expanded(
          child: Row(
            children: <Widget>[
              Container(
                height: 35,
                width: 2,
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(width: 8.0),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: notBlank(metadata.image)
                    ? RemoteImage(
                        src: metadata.image!,
                        width: 36.0,
                        height: 36.0,
                        fit: BoxFit.cover,
                        onLoadError: _onImageLoadError,
                      )
                    : const SizedBox(),
              ),
              if (notBlank(metadata.image)) const SizedBox(width: 8.0),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      metadata.desc ??
                          metadata.title ??
                          localized(chatLinkLoading),
                      style: jxTextStyle.textStyle15(color: themeColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      metadata.hostDomain,
                      style: jxTextStyle.textStyle15(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: GestureDetector(
            onTap: _onClear,
            child: const OpacityEffect(
              child: Icon(
                Icons.close,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildContent(BuildContext context) {
    return const SizedBox();
  }
}
