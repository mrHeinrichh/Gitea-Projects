import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/favourite/favourite_asset_view.dart';
import 'package:jxim_client/favourite/model/favourite_model.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/transparent_page_route.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';
import 'package:jxim_client/utils/config.dart';

class FavouriteDetailAlbum extends StatelessWidget {
  final FavouriteAlbum data;

  const FavouriteDetailAlbum({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4.0,
        crossAxisSpacing: 4.0,
      ),
      itemCount: data.albumList.length,
      itemBuilder: (ctx, index) {
        AlbumDetailBean bean = data.albumList[index];
        Widget child;
        if (bean.isVideo) {
          child = Hero(
            tag: bean.url,
            child: Stack(
              alignment: Alignment.center,
              children: [
                RemoteImage(
                  src: bean.cover.isNotEmpty ? bean.cover : bean.coverPath,
                  width: bean.aswidth?.toDouble(),
                  height: bean.asheight?.toDouble(),
                  fit: BoxFit.cover,
                  mini: Config().sMessageMin,
                ),
                SvgPicture.asset(
                  key: ValueKey(bean.url.hashCode),
                  'assets/svgs/video_play_icon.svg',
                  width: 40,
                  height: 40,
                ),
              ],
            ),
          );
        } else {
          child = Hero(
            tag: bean.url,
            child: RemoteImage(
              src: bean.url,
              width: bean.aswidth?.toDouble(),
              height: bean.asheight?.toDouble(),
              fit: BoxFit.cover,
              mini: Config().sMessageMin,
            ),
          );
        }

        child = GestureDetector(
          onTap: () {
            if (objectMgr.loginMgr.isMobile) {
              _onTapMedia(ctx, index);
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: child,
          ),
        );

        return child;
      },
    );
  }

  _onTapMedia(context, index) {
    List<dynamic> dataList = [];
    for (AlbumDetailBean bean in data.albumList) {
      if (bean.isVideo) {
        dataList.add(FavouriteVideo.fromBean(bean));
      } else {
        dataList.add(FavouriteImage.fromBean(bean));
      }
    }
    Navigator.of(context).push(
      TransparentRoute(
        builder: (BuildContext context) => FavouriteAssetView(
          assets: dataList,
          index: index,
        ),
        settings: const RouteSettings(name: RouteName.favouriteAssetPreview),
      ),
    );
  }
}
