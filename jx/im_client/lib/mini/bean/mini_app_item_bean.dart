import 'package:intl/intl.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

/// 小程序列表
class MiniAppItemBean {
  int? total;
  int? count;
  List<Apps>? apps;

  MiniAppItemBean({this.total, this.count, this.apps});

  MiniAppItemBean.fromJson(Map<String, dynamic> json) {
    total = json['total'];
    count = json['count'];
    if (json['apps'] != null) {
      apps = <Apps>[];
      json['apps'].forEach((v) {
        apps!.add(Apps.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total'] = total;
    data['count'] = count;
    if (apps != null) {
      data['apps'] = apps!.map((v) => v.toJson()).toList();
    }
    return data;
  }

  /// 搜索页面，发现页面的推荐小程序
  List<Apps> getSearchRecommend() {
    List<Apps> list = [];
    for (Apps app in apps ?? []) {
      if (app.flag != null && app.flag! > 0) {
        if (app.flag! & 2 != 0) {
          list.add(app);
        }
      }
    }
    return list;
  }
}

class Apps {
  String? id;
  String? name;
  String? devId;
  String? icon;
  String? iconGaussian;
  String? downloadUrl;
  String? description;
  int? version;

  /// 0 表示内部，1，表示公开
  int? typ;

  ///1.是否可以在搜索接口中找到，
  ///2，是否默认出现在发现页中，
  ///3.可搜索和可推荐，
  ///4.是否小程序时，是否最小化
  ///5.可搜索，和关闭时最小化，没有设置可推荐
  int? flag;
  int? reviewStatus;
  int? favoriteAt;

  int? isActive;
  int? createdAt;
  int? updatedAt;
  int? deletedAt;
  int? last_login_at; //用户最近登陆小程序的时间戳
  double? score;
  String? channels;

  String? screen;

  String? devName;

  int? commentNum;

  String? openuid;

  String? picture;

  String? pictureGaussian;

  Apps({
    this.id,
    this.name,
    this.devId,
    this.icon,
    this.iconGaussian,
    this.downloadUrl,
    this.description,
    this.version,
    this.typ,
    this.flag,
    this.reviewStatus,
    this.favoriteAt,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.last_login_at,
    this.score,
    this.channels,
    this.screen,
    this.devName,
    this.commentNum,
    this.openuid,
    this.picture,
    this.pictureGaussian,
  });

  Apps.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? "0";
    openuid = json['openuid'] ?? "";
    name = json['name'] ?? '';
    devId = json['dev_id'] ?? '';
    icon = json['icon'] ?? '';
    iconGaussian = json['icon_gaussian'] ?? '';
    downloadUrl = json['download_url'];
    description = json['description'];
    version = json['version'];
    typ = json['typ'] ?? -1;
    flag = json['flag'] ?? -1;
    reviewStatus = json['review_status'] ?? -1;
    favoriteAt = json['favorite_at'] ?? 0;
    isActive = json['is_active'] ?? -1;
    createdAt = json['created_at'] ?? -1;
    updatedAt = json['updated_at'] ?? -1;
    deletedAt = json['deleted_at'] ?? -1;
    last_login_at = json['last_login_at'] ?? -1;
    score = json['score'] ?? 0.0;
    channels = json['channels'] ?? '';
    screen = json['screen'] ?? MiniAppScreenType.vertical.value;
    devName = json['dev_name'] ?? '';
    commentNum = json['comment_num'] ?? 0;
    picture = json['picture'] ?? '';
    pictureGaussian = json['picture_gaussian'] ?? '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['openuid'] = openuid;
    data['name'] = name;
    data['dev_id'] = devId;
    data['icon'] = icon;
    data['icon_gaussian'] = iconGaussian;
    data['download_url'] = downloadUrl;
    data['description'] = description;
    data['version'] = version;
    data['typ'] = typ;
    data['flag'] = flag;
    data['review_status'] = reviewStatus;
    data['favorite_at'] = favoriteAt;
    data['is_active'] = isActive;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['deleted_at'] = deletedAt;
    data['last_login_at'] = last_login_at;
    data['score'] = score;
    data['channels'] = channels;
    data['screen'] = screen;
    data['dev_name'] = devName;
    data['comment_num'] = commentNum;
    data['picture'] = picture;
    data['picture_gaussian'] = pictureGaussian;
    return data;
  }

  Apps copyWith({
    String? id,
    String? name,
    String? openuid,
    String? devId,
    String? icon,
    String? iconGaussian,
    String? downloadUrl,
    String? description,
    int? version,
    int? typ,
    int? flag,
    int? reviewStatus,
    int? favoriteAt,
    int? isActive,
    int? createdAt,
    int? updatedAt,
    int? deletedAt,
    int? last_login_at,
    double? score,
    String? channels,
    String? screen,
    String? devName,
    int? commentNum,
    String? picture,
    String? pictureGaussian,
  }) {
    return Apps(
      id: id ?? this.id,
      name: name ?? this.name,
      openuid: openuid??this.openuid,
      devId: devId ?? this.devId,
      icon: icon ?? this.icon,
      iconGaussian: iconGaussian ?? this.iconGaussian,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      description: description ?? this.description,
      version: version ?? this.version,
      typ: typ ?? this.typ,
      flag: flag ?? this.flag,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      favoriteAt: favoriteAt ?? this.favoriteAt,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      last_login_at: last_login_at ?? this.last_login_at,
      score: score ?? this.score,
      channels: channels ?? this.channels,
      screen: screen ?? this.screen,
      devName: devName ?? this.devName,
      commentNum: commentNum ?? this.commentNum,
      picture: picture ?? this.picture,
      pictureGaussian: pictureGaussian ?? this.pictureGaussian,
    );
  }

  bool get isNeedCloseMiniApp {
    if (flag != null) {
      if (flag! & 4 != 0) {
        return false;
      }
    }
    return true;
  }
///目前只有e和f
  bool get isCanOpenThisMiniApp {
    return typ == 0;
  }

  String get companyName {
    return devName ?? "--";
  }

  String get appScore {
    return '${score ?? 0.0}';
  }

  String get evaluateNum {
    int num = commentNum ?? 0;
    String numStr = '';
    if (num < 10000) {
      // 如果小於 10k，直接返回完整數字的字串
      numStr =  num.toString();
    } else if (num < 1000000) {
      // 如果數字在 10k 到 1M 之間，格式化到小數點第一位
      double formattedNumber = num / 1000;
      numStr =  '${formattedNumber.toStringAsFixed(1)}K';
    } else {
      // 如果超過 1M，使用 intl 的緊湊格式（例如 1.2M）
      numStr = formatNumberToKUsingIntl(num);
    }
    return localized(miniAppRatingTotal,
      params: [
        numStr,
      ],);
  }

  //數值轉換為K與M格式
  String formatNumberToKUsingIntl(int number) {
    final formatter = NumberFormat.compact();
    return formatter.format(number);
  }

  String get appName{
    return name??"--";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Apps && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

enum MiniAppScreenType {
  vertical("vertical"),
  horizontal("horizontal"),
  special("special"),
  unknown("unknown");

  final String value;

  const MiniAppScreenType(this.value);
}
