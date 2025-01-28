import 'package:jxim_client/data/row_object.dart';

///tpl_config:全局配置表
class ConfigModel extends RowObject {
  static const voiceHeart = 'voice_heart'; //解锁语音通话的心动值
  static const videoHeart = 'video_heart'; //解锁视频通话的心动值
  static const unchainHeart = 'unchain_heart'; //解锁成情侣需要的心动值
  static const heartValueGoldRatio = 'heart_value_gold_ratio'; //币与心动值比例
  static const messagePushSpan = 'message_push_span'; //新消息推送间隔
  static const userPushWealthVideo = 'user_push_wealth_video'; //视频聊天-推送对象男的财富等级
  static const userPushWealthVoice = 'user_push_wealth_voice'; //语音聊天-推送对象男财富等级
  static const userPushGlamourVideo =
      'user_push_glamour_video'; //视频聊天-推送对象男的魅力值等级
  static const userPushGlamourVoice =
      'user_push_glamour_voice'; //语音聊天-推送对象男的魅力值等级
  static const unchainGift = 'unchain_gift'; //解锁心动值得礼物
  static const loverTask = 'lover_task'; //亲密度每日任务完成数量
  static const fastMateGold = 'fast_mate_gold'; //加速匹配需要扣除的币
  static const lockSecretPhoto = 'lock_secret_photo'; //解锁上传私密照的心动值
  static const activityAverageCost = 'activity_average_cost'; //活动平均的花费
  static const activityHighPerson = 'activity_high_person'; //活动最高人数
  static const activityLowPerson = 'activity_low_person'; //活动最低人数
  static const openMessageRead = 'open_message_read'; //是否开启已读 0.不开启 1.开启
  static const createClubGold = 'create_club_gold'; //创建俱乐部金额
  static const clubCreateBg = 'club_create_bg'; //创建俱乐部背景
  static const livePKPunishTime = 'live_pk_punish_time'; //直播pk惩罚时间
  static const livePKRoundTime = 'live_pk_round_time'; //直播pk回合时间
  static const livePKStartCD = 'live_pk_start_cd'; //直播开始倒计时
  static const livePKRestTime = 'live_pk_rest_time'; //直播pk回合之间休息时间（目前没有回合）
  static const livePKEscapeCount = 'live_pk_escape_count'; //直播pk每日逃跑次数上限
  static const intimateTaskDay = 'intimate_task_day'; //情侣任务每完成7天任务额外奖励
  static const intimateTaskDayReward =
      'intimate_task_day_reward'; //情侣任务每完成7天任务的奖励值
  static const intimateGiftRatio = 'intimate_gift_ratio'; //亲密度礼物转化比例
  static const intimatePayNeedVal = 'intimate_pay_need_val'; //情侣支付开启需要的最低亲密度
  static const voiceMatchProfit = 'voice_match_profit'; //语音匹配收益
  static const voiceMatchPrice = 'voice_match_price'; //语音匹配价格
  static const livePKUpInviteCD = 'live_pk_up_invite_cd'; //pk升级邀请cd（s）
  static const accostGiftId = 'accost_gift_id'; //搭讪礼物id
  static const freeLoverCount = 'free_lover_count'; //每天可以点击喜欢的数
  static const loverUserPrice = 'lover_user_price'; //点击喜欢需要支付的币(针对用户)
  static const loverGroupPrice = 'lover_group_price'; //点击喜欢需要支付的币(针对群)

  String get configKey => getValue('config_key', '');
  String get configValue => getValue('config_value', '');
  String get remark => getValue('remark', '');
  int get type => getValue('type', 0);
  int get vType => getValue('v_type', 0);
  int get value {
    return int.tryParse(configValue) ?? 0;
  }

  double get valueDouble {
    return double.tryParse(configValue) ?? 0;
  }

  String get valueStr {
    return configValue;
  }

  static ConfigModel creator() {
    return ConfigModel();
  }
}
