import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:photo_view/photo_view.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:jxim_client/utils/photo_view_util.dart';
import 'package:dismissible_page/dismissible_page.dart';

class MomentCreateViewer extends StatefulWidget {
  final List<AssetPreviewDetail> assetList;

  final int index;

  const MomentCreateViewer({
    super.key,
    required this.assetList,
    required this.index,
  });

  @override
  State<MomentCreateViewer> createState() => _MomentCreateViewerState();
}

class _MomentCreateViewerState extends State<MomentCreateViewer> {
  late final PhotoViewPageController photoPageController;

  bool hideActionBar = false;

  Map<String, bool> loadedOriginMap = <String, bool>{};

  int currentIndex = 0;

  double get deviceRatio =>
      ObjectMgr.screenMQ!.size.width / ObjectMgr.screenMQ!.size.height;

  double imageRatio(int index) =>
      widget.assetList[index].entity.width /
      widget.assetList[index].entity.height;

  BoxFit get boxFit =>
      deviceRatio > imageRatio(currentIndex - 1 < 0 ? 0 : currentIndex - 1)
          ? BoxFit.fitHeight
          : BoxFit.fitWidth;

  bool isVideo = false;

  @override
  void initState() {
    super.initState();

    photoPageController = PhotoViewPageController(
      initialPage: widget.index,
      shouldIgnorePointerWhenScrolling: true,
    );

    currentIndex = widget.index + 1;

    widget.assetList.first.entity.type == AssetType.video
        ? isVideo = true
        : isVideo = false;
  }

  void onPageChange(int index) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      currentIndex = index + 1;
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        ),
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: null,
          body:
          SafeArea(
            child: Stack(
              children: [
                PhotoViewSlidePage(
                  slideAxis: SlideDirection.vertical,
                  slideType: SlideArea.onlyImage,
                  slidePageBackgroundHandler: (Offset offset, Size pageSize) {
                    return Colors.black;
                  },
                  child: PhotoViewGesturePageView.builder(
                    onPageChanged: onPageChange,
                    scrollDirection: Axis.horizontal,
                    controller:photoPageController,
                    itemCount: widget.assetList.length,
                    itemBuilder: (BuildContext context, int index) {
                      final asset = widget.assetList[index];

                  if (asset.entity.type == AssetType.video) {
                    return GestureDetector(
                      onTap: actionBarStatus,
                      behavior: HitTestBehavior.translucent,
                      child: DismissiblePage(
                        onDismissed: Navigator.of(context).pop,
                        direction: DismissiblePageDismissDirection.down,
                        child: Container(
                          color: Colors.black,
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewPadding.bottom,
                          ),
                          child: Stack(
                            children: <Widget>[
                              Align(
                                alignment: Alignment.center,
                                child: VideoPageBuilder(
                                  hasOnlyOneVideoAndMoment: true,
                                  asset: widget.assetList.first.entity,
                                  onLoadCallback: (bool hasLoaded) {},
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return Stack(
                    alignment: AlignmentDirectional.center,
                    children: <Widget>[buildImageAssetEntity(context, asset)],
                  );
                },
              ),
            ),

                //Top layer
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 150),
                  top: hideActionBar ? -(MediaQuery.of(context).size.height/20)*1.5 : 0,
                  left: 0,
                  right: 0,
                  child:Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      color: const Color(0x99000000),
                      height: (MediaQuery.of(context).size.height/20)*1.5,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            flex: 1,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pop(context, "none");
                              },
                              child: Padding(
                                  padding:
                                  const EdgeInsets.only(left: 16, bottom: 11.5),
                                  child: OpacityEffect(
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.arrow_back_ios_new_outlined,
                                          color: colorWhite,
                                        ),
                                        Text(
                                          localized(buttonBack),
                                          style: jxTextStyle.textStyle17(
                                            color: colorWhite,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ),),),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 11.5),
                                child: isVideo? const SizedBox() :
                                Text(
                                  "${currentIndex==0?1:currentIndex}/${widget.assetList.isEmpty?1:widget.assetList.length}",
                                  style: jxTextStyle.textStyleBold17(
                                      color: Colors.white),
                                ),
                              ),),),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 16, bottom: 11.5),
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: deleteDialog,
                                  child:
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 0.0),
                                    child: OpacityEffect(
                                      child: SvgPicture.asset('assets/svgs/moment_viewer_delete.svg',
                                        width: 24.0,
                                        height: 24.0,
                                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn,),
                                      )
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
              ],
            ),
          ),
        ),
      );
  }

  void actionBarStatus() {
    setState(() {
      hideActionBar = !hideActionBar;
    });
  }

  void deleteAsset() {
    int pageIndex = (currentIndex - 1) < 0 ? 0 : (currentIndex - 1);
    widget.assetList.removeAt(pageIndex);
    setState(() {
      if (pageIndex >= widget.assetList.length) {
        pageIndex = widget.assetList.length - 1;
        currentIndex = currentIndex - 1;
      }
      photoPageController.jumpToPage(pageIndex);
      if (widget.assetList.isEmpty) {
        Navigator.pop(context, "none");
      }
    });
  }

  void deleteDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return CustomConfirmationPopup(
          confirmButtonColor: colorRed,
          confirmButtonText: localized(buttonDelete),
          cancelButtonColor: themeColor,
          withHeader: false,
          cancelButtonText: localized(cancel),
          confirmCallback: () => deleteAsset(),
          cancelCallback: Navigator.of(context).pop,
        );
      },
    );
  }

  Widget buildImageAssetEntity(BuildContext context, AssetPreviewDetail asset) {
    Size screenSize = MediaQuery.of(context).size;

    if (asset.editedFile != null) {
      return RepaintBoundary(
        child: PhotoView.file(
          asset.editedFile!,
          mode: PhotoViewMode.gesture,
          enableSlideOutPage: true,
          constraints: BoxConstraints.loose(
            Size(screenSize.width * 2, screenSize.height * 2),
          ),
          initGestureConfigHandler: initGestureConfigHandler,
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: actionBarStatus,
      child: PhotoView(
        key: ValueKey('${asset.id}_ori_detail'),
        enableSlideOutPage: true,
        mode: PhotoViewMode.gesture,
        constraints: BoxConstraints.loose(
          Size(screenSize.width * 2, screenSize.height * 2),
        ),
        initGestureConfigHandler: initGestureConfigHandler,
        image: AssetEntityImageProvider(
          asset.entity,
          isOriginal: true,
          thumbnailSize: ThumbnailSize.square(Config().messageMin.toInt()),
        ),
        fit: boxFit,
      ),
    );
  }
}
