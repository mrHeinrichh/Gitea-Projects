import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

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
  blockUser(optionType: "blockUser"),
  screenshotNotification(optionType: "screenshotNotification"),
  aiRealTimeTranslate(optionType: "aiRealTimeTranslate"),
  encryptionSettings(optionType: "encryptionSettings");

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
  editMessage(optionType: "editMessage"),
  translate(optionType: "translate"),
  showOriginal(optionType: "showOriginal"),
  playbackDevice(optionType: "playbackDevice"),
  showInText(optionType: "showInText"),
  hideText(optionType: "hideText"),
  reply(optionType: "reply"),
  saveImage(optionType: "saveImage"),
  saveVideo(optionType: "saveVideo"),
  saveAll(optionType: "saveAll"),
  forwardAll(optionType: "forwardAll"),
  retry(optionType: "retry"),
  pin(optionType: "pin"),
  unPin(optionType: "unpin"),
  findInChat(optionType: "findInChat"),
  saveToDownload(optionType: "saveToDownload"),
  select(optionType: "select"),
  selectAll(optionType: "selectAll"),
  report(optionType: "report"),
  forward10sec(optionType: "forward10sec"),
  backward10sec(optionType: "backward10sec"),
  play(optionType: "play"),
  pause(optionType: "pause"),
  mute(optionType: "mute"),
  unmute(optionType: "unmute"),
  speed(optionType: "speed"),
  minimize(optionType: "minimize"),
  more(optionType: "more"),
  textToVoice(optionType: "textToVoice"),
  textToVoiceOriginal(optionType: "textToVoiceOriginal"),
  textToVoiceTranslation(optionType: "textToVoiceTranslation"),
  cancelSending(optionType: "cancelSending"),
  collect(optionType: "collect"),
  menuMore(optionType: "menuMore"),
  friendRequest(optionType: "friendRequest");

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
  settingRecentCall(type: "settingRecentCall"),
  notificationAndSound(type: "notificationAndSound"),
  privacyAndSecurity(type: "privacyAndSecurity"),
  generalSettings(type: "generalSettings"),
  dataAndStorage(type: "dataAndStorage"),
  language(type: "language"),
  appearance(type: "appearance"),
  linkDevices(type: "linkDevices"),
  chatCategoryFolder(type: "chatCategoryFolder"),
  accounts(type: "accounts"),
  inviteFriends(type: "inviteFriends"),
  appInfo(type: "appInfo"),
  logout(type: "logout"),
  // 这个测试页面
  testPage(type: "testPage"),
  dateTime(type: "dateTime"),
  channel(type: "channel"),
  moment(type: "moment"),
  scan(type: "scan"),
  favourite(type: "favourite"),
  miniApp(type: "miniApp"),
  networkDiagnose(type: "networkDiagnose");

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
  secondVerification(page: "secondVerification", type: 6),
  encryptionResetKey(page: "encryptionResetKey", type: 7);

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
  store(value: "apk"), // google play版本
  play(value: "play"), // 非google play版本
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
  systemLanguage(value: "", name: "", key: "langSystemLanguage"),
  auto(value: "auto", name: "App Language", key: "langAuto"),
  english(value: "EN", name: "English", key: "langEn"),
  chinese(value: "CN", name: "中文", key: "langZh"),
  japan(value: "JP", name: "にほんご", key: "langJp"),
  thai(value: "TH", name: "ภาษาไทย", key: "langTh"),
  vietnam(value: "VI", name: "Tiếng Việt", key: "langVi"),
  cambodia(value: "KM", name: "កម្ពុជា។", key: "langKm"),
  turkish(value: "TR", name: "Türkce", key: "langTr");

  const LanguageOption({
    required this.value,
    required this.name,
    required this.key,
  });

  final String value;
  final String name;
  final String key;

  static LanguageOption? getByValue(String value) {
    for (var option in LanguageOption.values) {
      if (option.value == value) {
        return option;
      }
    }
    return null;
  }
}

enum AppVersionUpdateType {
  version,
  minVersion,
  uninstallVersion,
  revertVersion;
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
  // currencyCNY('CNY', '人民币'),
  currencyUSDT('USDT', 'USDT');

  const CurrencyALLType(this.type, this.title);

  final String type;
  final String title;

  static CurrencyALLType fromValue(String type) {
    switch (type) {
      case 'USDT':
        return CurrencyALLType.currencyUSDT;
      // case 'CNY':
      //   return CurrencyALLType.currencyCNY;
      default:
        return CurrencyALLType.currencyUnknown;
    }
  }
}

enum SecondaryMenuOption {
  back(
    optionType: "back",
    duration: -1,
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
  deactivate(
    optionType: "deactivate",
    duration: 0,
  ),
  tip(
    optionType: "tip",
    duration: 0,
  ),
  other(
    optionType: "other",
    duration: -1,
  ),
  secondaryMenuClearRecordOnlyForMe(
    optionType: "secondaryMenuClearRecordOnlyForMe",
    duration: -1,
  );

  const SecondaryMenuOption({
    required this.optionType,
    required this.duration,
  });

  final String optionType;
  final int duration;
}

enum GroupLinkEffectiveTime {
  oneHour(type: 1, key: "hour1", value: 3600),
  oneDay(type: 2, key: "invitationLinkOneDay", value: 86400),
  oneWeek(type: 3, key: "invitationLinkOneWeek", value: 604800),
  noLimit(type: 4, key: "linkUnlimited", value: 0);

  const GroupLinkEffectiveTime({
    required this.type,
    required this.key,
    required this.value,
  });

  final int type;
  final String key;
  final int value;

  static int getValueByType(int type) {
    switch (type) {
      case 1:
        return GroupLinkEffectiveTime.oneHour.value;
      case 2:
        return GroupLinkEffectiveTime.oneDay.value;
      case 3:
        return GroupLinkEffectiveTime.oneWeek.value;
      case 4:
        return GroupLinkEffectiveTime.noLimit.value;
      default:
        return GroupLinkEffectiveTime.noLimit.value;
    }
  }

  static int getTypeByValue(int type) {
    switch (type) {
      case 3600:
        return GroupLinkEffectiveTime.oneHour.type;
      case 86400:
        return GroupLinkEffectiveTime.oneDay.type;
      case 604800:
        return GroupLinkEffectiveTime.oneWeek.type;
      case 0:
        return GroupLinkEffectiveTime.noLimit.type;
      default:
        return GroupLinkEffectiveTime.noLimit.type;
    }
  }

  static List<String> getLocales(
      String Function(String jsonPath, {List<String> params}) localized) {
    final list = <String>[];
    for (final item in GroupLinkEffectiveTime.values) {
      list.add(localized(item.key));
    }
    return list;
  }
}

enum GroupLinkUsageLimit {
  one(type: 1, key: "1", value: 1),
  ten(type: 2, key: "10", value: 10),
  hundred(type: 3, key: "100", value: 100),
  noLimit(type: 4, key: "linkUnlimited", value: 0);

  const GroupLinkUsageLimit({
    required this.type,
    required this.key,
    required this.value,
  });

  final int type;
  final String key;
  final int value;

  static int getValueByType(int type) {
    switch (type) {
      case 1:
        return GroupLinkUsageLimit.one.value;
      case 2:
        return GroupLinkUsageLimit.ten.value;
      case 3:
        return GroupLinkUsageLimit.hundred.value;
      case 4:
        return GroupLinkUsageLimit.noLimit.value;
      default:
        return GroupLinkUsageLimit.noLimit.value;
    }
  }

  static int getTypeByValue(int value) {
    switch (value) {
      case 1:
        return GroupLinkUsageLimit.one.type;
      case 10:
        return GroupLinkUsageLimit.ten.type;
      case 100:
        return GroupLinkUsageLimit.hundred.type;
      case 0:
        return GroupLinkUsageLimit.noLimit.type;
      default:
        return GroupLinkUsageLimit.noLimit.type;
    }
  }

  static List<String> getLocales(
      String Function(String jsonPath, {List<String> params}) localized) {
    final list = <String>[];
    for (final item in GroupLinkUsageLimit.values) {
      list.add(localized(item.key));
    }
    return list;
  }
}

enum DialogType {
  loading,
  success,
  fail;
}

enum EncryptionPasswordType {
  setup,
  changePassword,
  forgetPassword,
  createEncGroup;
}

enum ScanQrCodeType {
  encryption,
  verifyPrivateKey,
}

enum EncryptionSetupPasswordType {
  neverSetup,
  anotherDeviceSetup,
  doneSetup,
  abnormal;
}

enum EncryptionMessageType {
  requireInputPassword,
  awaitingFriend,
  defaultFailure
}

enum EncryptionPanelType { backup, recover, recoverKick, none }

enum HomePageTabIndex {
  chatView(value: 0),
  contactView(value: 1),
  discoverView(value: 2),
  settingView(value: 3);

  const HomePageTabIndex({
    required this.value,
  });

  final int value;
}

enum HomePageMenu {
  createChat(optionType: "createChat"),
  addFriend(optionType: "addFriend"),
  scan(optionType: "scan"),
  scanPaymentQr(optionType: "scanPaymentQr");

  const HomePageMenu({
    required this.optionType,
  });

  final String optionType;
}

enum ContactPageMenu {
  lastOnline(optionType: "lastOnline"),
  name(optionType: "name");

  const ContactPageMenu({
    required this.optionType,
  });

  final String optionType;
}

enum ChatCategoryMenuType {
  editChatCategory('editChatCategory'),
  addChatRoom('addChatRoom'),
  allRead('allRead'),
  allMuted('allMuted'),
  allUnMuted('allUnMuted'),
  deleteChatCategory('deleteChatCategory'),
  reorderChatCategory('reorderChatCategory');

  const ChatCategoryMenuType(this.menuType);

  final String menuType;

  String get title {
    switch (this) {
      case ChatCategoryMenuType.editChatCategory:
        return localized(chatCategoryEditFolder);
      case ChatCategoryMenuType.addChatRoom:
        return localized(chatCategoryAddChatRoom);
      case ChatCategoryMenuType.allRead:
        return localized(chatCategoryReadAll);
      case ChatCategoryMenuType.allMuted:
        return localized(chatCategoryMuteAll);
      case ChatCategoryMenuType.allUnMuted:
        return localized(chatCategoryUnMuteAll);
      case ChatCategoryMenuType.deleteChatCategory:
        return localized(chatCategoryRemoveCategory);
      case ChatCategoryMenuType.reorderChatCategory:
        return localized(chatCategoryRearrange);
      default:
        return '';
    }
  }

  static ChatCategoryMenuType getType(String menuType) {
    switch (menuType) {
      case 'editChatCategory':
        return ChatCategoryMenuType.editChatCategory;
      case 'addChatRoom':
        return ChatCategoryMenuType.addChatRoom;
      case 'allRead':
        return ChatCategoryMenuType.allRead;
      case 'allMuted':
        return ChatCategoryMenuType.allMuted;
      case 'allUnMuted':
        return ChatCategoryMenuType.allUnMuted;
      case 'deleteChatCategory':
        return ChatCategoryMenuType.deleteChatCategory;
      case 'reorderChatCategory':
        return ChatCategoryMenuType.reorderChatCategory;
      default:
        throw ('No menu type fit to the ChatCategoryMenuType enum');
    }
  }
}

/// 网络诊断相关
enum ConnectionTask {
  connectNetwork,
  shieldConnectNetwork,
  connectServer,
  uploadSpeed,
  downloadSpeed,
}

extension ConnectionTaskExtension on ConnectionTask {
  String get name {
    switch (this) {
      case ConnectionTask.connectNetwork:
        return localized(networkTaskConnection);
      case ConnectionTask.shieldConnectNetwork:
        return localized(networkTaskShield);
      case ConnectionTask.connectServer:
        return localized(networkTaskServer);
      case ConnectionTask.uploadSpeed:
        return localized(networkTaskUpload);
      case ConnectionTask.downloadSpeed:
        return localized(networkTaskDownload);
    }
  }
}

enum ConnectionTaskStatus {
  processing,
  success,
  failure,
}

enum SearchTab {
  chat,
  media,
  link,
  file,
  voice;
  // redPacket;
  // moment,
  // reel;
}

enum MiniAppType {
  recent,
  favorite,
  explore,
  discover,
}

enum MiniAppRecentBtnType {
  idle,
  add,
  delete,
}
