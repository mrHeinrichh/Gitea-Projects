// 资源路径多语言翻译
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

String getPathName(AssetPathEntity? pathEntity) {
  switch (pathEntity?.name) {
    // 最近
    case "最近项目":
    case "Recent":
    case "recent":
      return localized(recent);
    //截屏
    case "截屏":
    case "Screenshots":
    case "ScreenShots":
    case "screenshots":
      return localized(screenshots);
    //电影
    case "电影":
    case "视频":
    case "Movies":
    case "movies":
      return localized(movies);
    //文件夹
    case "文件":
    case "文件夹":
    case "Documents":
    case "documents":
      return localized(documents);
    //拍照
    case "相机":
    case "Camera":
    case "camera":
      return localized(camera);
    //图片
    case "图片":
    case "Pictures":
    case "pictures":
      return localized(picture);
    //截屏记录
    case "455968004":
      return localized(screenRecording);
    //下载
    case "下载":
    case "Downloads":
    case "downloads":
    case "Download":
    case "download":
      return localized(downloads);
    //实况照片
    case "实况照片":
    case "Live Photos":
      return localized(livePhotos);
    //实况照片
    case "个人收藏":
    case "Favourites":
    case "favourites":
      return localized(favourites);
    default:
      return pathEntity?.name ?? '';
  }
}
