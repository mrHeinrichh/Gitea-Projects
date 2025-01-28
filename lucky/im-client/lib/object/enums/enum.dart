
enum ChatInfoTabOption {
  member(tabType: "member"),
  media(tabType: "media"),
  file(tabType: "file"),
  audio(tabType: "audio"),
  link(tabType: "link"),
  group(tabType: "group"),
  redPacket(tabType: "redPacket"),
  tasks(tabType: "tasks");

  const ChatInfoTabOption({
    required this.tabType,
  });

  final String tabType;
}

enum GameChatInfoTabOption {
  details(tabType: "details"),
  member(tabType: "member"),
  game(tabType: "game");

  const GameChatInfoTabOption({
    required this.tabType,
  });

  final String tabType;
}



enum MutePopupOption {
  oneHour(optionType: "oneHour"),
  eighthHours(optionType: "eighthHours"),
  oneDay(optionType: "oneDay"),
  sevenDays(optionType: "sevenDays"),
  oneWeek(optionType: "oneWeek"),
  oneMonth(optionType: "oneMonth"),
  muteUntil(optionType: "muteUntil"),
  muteForever(optionType: "muteForever");

  const MutePopupOption({
    required this.optionType,
  });

  final String optionType;
}

enum MorePopupOption {
  inviteGroup(optionType: "inviteGroup"),
  search(optionType: "search"),
  autoDeleteMessage(optionType: "autoDeleteMessage"),
  groupManagement(optionType: "groupManagement"),
  clearChatHistory(optionType: "clearChatHistory"),
  permissions(optionType: "permissions"),
  leaveGroup(optionType: "leaveGroup"),
  disbandGroup(optionType: "disbandGroup"),
  deleteChatHistory(optionType: "deleteChatHistory"),
  back(optionType: "back"),
  createGroup(optionType: "createGroup"),
  groupCertified(optionType: "groupCertified"),
  promoteCenter(optionType: "promoteCenter"),
  groupOperate(optionType: "groupOperate"),
  betRecordHome(optionType: "betRecordHome"),
  blockUser(optionType: "blockUser"),
  screenshotNotification(optionType: "screenshotNotification");

  const MorePopupOption({
    required this.optionType,
  });

  final String optionType;
}

enum DeletePopupOption {
  deleteForEveryone(optionType: "deleteForEveryone"),
  deleteForMe(optionType: "deleteForMe");

  const DeletePopupOption({
    required this.optionType,
  });

  final String optionType;
}

enum AutoDeleteDurationOption {
  tenSecond(
    optionType: "tenSecond",
    duration: 10,
  ),
  thirtySecond(
    optionType: "thirtySecond",
    duration: 30,
  ),
  oneMinute(
    optionType: "oneMinute",
    duration: 60,
  ),
  fiveMinute(
    optionType: "fiveMinute",
    duration: 300,
  ),
  tenMinute(
    optionType: "tenMinute",
    duration: 600,
  ),
  fifteenMinute(
    optionType: "fifteenMinute",
    duration: 900,
  ),
  thirtyMinute(
    optionType: "thirtyMinute",
    duration: 1800,
  ),
  oneHour(
    optionType: "oneHour",
    duration: 3600,
  ),
  twoHour(
    optionType: "twoHour",
    duration: 7200,
  ),
  sixHour(
    optionType: "sixHour",
    duration: 21600,
  ),
  twelveHour(
    optionType: "twelveHour",
    duration: 43200,
  ),
  oneDay(
    optionType: "oneDay",
    duration: 86400,
  ),
  oneWeek(
    optionType: "oneWeek",
    duration: 604800,
  ),
  oneMonth(
    optionType: "oneMonth",
    duration: 2592000,
  ),
  disable(
    optionType: "disable",
    duration: 0,
  );

  const AutoDeleteDurationOption({
    required this.optionType,
    required this.duration,
  });

  final String optionType;
  final int duration;
}

enum GroupAdminMemberPopupOption {
  transferOwnership(optionType: "transferOwnership"),
  promoteAdmin(optionType: "promoteAdmin"),
  demoteAdmin(optionType: "demoteAdmin"),
  deleteMember(optionType: "deleteMember");

  const GroupAdminMemberPopupOption({
    required this.optionType,
  });

  final String optionType;
}

enum MessagePopupOption {
  forward(optionType: "forward"),
  share(optionType: "share"),
  showInChat(optionType: "showInChat"),
  saveToGallery(optionType: "saveToGallery"),
  edit(optionType: "edit"),
  delete(optionType: "delete"),
  copy(optionType: "copy"),
  translate(optionType: "translate"),
  playbackDevice(optionType: "playbackDevice"),
  showInText(optionType: "showInText"),
  reply(optionType: "reply"),
  retry(optionType: "retry"),
  pin(optionType: "pin"),
  unPin(optionType: "unpin"),
  findInChat(optionType: "findInChat"),
  saveToDownload(optionType: "saveToDownload"),
  select(optionType: "select"),
  report(optionType: "report"),
  forward10sec(optionType: "forward10sec"),
  backward10sec(optionType: "backward10sec"),
  play(optionType: "play"),
  pause(optionType: "pause"),
  mute(optionType: "mute"),
  unmute(optionType: "unmute"),
  speed(optionType: "speed"),
  minimize(optionType: "minimize"),
  more(optionType: "more");

  const MessagePopupOption({
    required this.optionType,
  });

  final String optionType;
}

enum ReportPopupOption {
  violence(optionType: "violence"),
  drugs(optionType: "drugs"),
  gambling(optionType: "gambling"),
  pornography(optionType: "pornography"),
  scams(optionType: "scams"),
  others(optionType: "others");

  const ReportPopupOption({
    required this.optionType,
  });

  final String optionType;
}

enum SettingOption {
  myWallet(type: "myWallet"),
  notificationAndSound(type: "notificationAndSound"),
  privacyAndSecurity(type: "privacyAndSecurity"),
  dataAndStorage(type: "dataAndStorage"),
  language(type: "language"),
  appearance(type: "appearance"),
  linkDevices(type: "linkDevices"),
  accounts(type: "accounts"),
  inviteFriends(type: "inviteFriends"),
  appInfo(type: "appInfo"),
  logout(type: "logout"),
  // 这个测试页面
  testPage(type: "testPage"),
  dateTime(type: "dateTime"),
  channel(type: "channel");

  const SettingOption({
    required this.type,
  });

  final String type;
}

enum MediaOption {
  audio(type: "audio"),
  gallery(type: "gallery"),
  document(type: "document"),
  contact(type: "contact"),
  location(type: "location"),
  redPacket(type: "redPacket"),
  task(type: "task");

  const MediaOption({
    required this.type,
  });

  final String type;
}

enum WalletPasscodeOption {
  setPasscode(type: "setPasscode"),
  changePasscode(type: "changePasscode"),
  resetPasscode(type: "resetPasscode");

  const WalletPasscodeOption({
    required this.type,
  });

  final String type;
}

enum OtpPageType {
  login(page: "loginView", type: 1),
  changePhoneNumber(page: "userBioView", type: 2),
  resetPasscode(page: "resetPasscodeView", type: 3),
  deleteAccount(page: "deleteAccount", type: 4),
  changeEmail(page: "addEmail", type: 5),
  secondVerification(page: "secondVerification", type: 6);

  const OtpPageType({
    required this.page,
    required this.type,
  });

  final String page;
  final int type;
}

enum SystemPlatform {
  android(value: 'android'),
  ios(value: 'ios'),
  windows(value: 'windows'),
  mac(value: 'mac');

  const SystemPlatform({
    required this.value,
  });

  final String value;
}

enum OsType {
  android(value: 0),
  ios(value: 1),
  windows(value: 2),
  mac(value: 3);

  const OsType({
    required this.value,
  });

  final int value;
}

enum DownloadPlatform {
  apk(value: "apk"),
  play(value: "play"),
  supersign(value: "supersign"),
  testflight(value: "testflight"),
  windows(value: "windows"),
  mac(value: "web");

  const DownloadPlatform({
    required this.value,
  });

  final String value;
}

enum LanguageOption {
  autoDetect(value: ""),
  auto(value: "auto"),
  english(value: "en"),
  chinese(value: "zh");

  const LanguageOption({
    required this.value,
  });

  final String value;
}

enum AppVersionUpdateType {
  version(value: 1),
  minVersion(value: 2),
  uninstallVersion(value: 3);

  const AppVersionUpdateType({
    required this.value,
  });

  final int value;
}

enum RegexTextType {
  mention(value: 'mention'),
  link(value: 'link'),
  number(value: 'number'),
  emoji(value: 'emoji'),
  text(value: 'text'),
  search(value: 'search');

  const RegexTextType({
    required this.value,
  });

  final String value;
}

enum QRCodeDurationType {
  defaultSet(value: 0),
  oneMin(value: 60),
  fiveMin(value: 300),
  sixtyMin(value: 3600),
  forever(value: -1);

  const QRCodeDurationType({
    required this.value,
  });

  final int value;
}

enum StoreData {
  defaultData(''),
  messageSoundData('messageSound'),
  recentStickers('recentStickers');

  const StoreData(this.key);

  final String key;

  static StoreData fromValue(String key) {
    switch (key) {
      case 'messageSound':
        return StoreData.messageSoundData;
      case 'recentStickers':
        return StoreData.recentStickers;
      default:
        return StoreData.defaultData;
    }
  }
}

/// 所有貨幣
enum CurrencyALLType {
  currencyUnknown('', ''),
  currencyUSDT('USDT', 'USDT'),
  currencyCNY('CNY', '人民币');

  const CurrencyALLType(this.type, this.title);

  final String type;
  final String title;

  static CurrencyALLType fromValue(String type) {
    switch (type) {
      case 'USDT':
        return CurrencyALLType.currencyUSDT;
      case 'CNY':
        return CurrencyALLType.currencyCNY;
      default:
        return CurrencyALLType.currencyUnknown;
    }
  }
}
