import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/setting/data_storage/data_storage_controller.dart';
import 'package:jxim_client/im/media_detail/media_pre_send_controller.dart';
import 'package:jxim_client/im/media_detail/media_pre_send_view.dart';
import 'package:jxim_client/object/chat/message.dart' as ChatMessage;
import 'package:im_common/im_common.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/home/home_view.dart';
import 'package:jxim_client/home/setting/controller/app_info_controller.dart';
import 'package:jxim_client/home/setting/controller/testPageController.dart';
import 'package:jxim_client/home/setting/testPage.dart';
import 'package:jxim_client/reel/reel_page/reel_controller.dart';
import 'package:jxim_client/home/setting/controller/date_time_controller.dart';
import 'package:jxim_client/home/setting/controller/linked_device_controller.dart';
import 'package:jxim_client/home/setting/setting_controller.dart';
import 'package:jxim_client/home/setting/view/app_info_view.dart';
import 'package:jxim_client/reel/reel_page/reel_view.dart';
import 'package:jxim_client/home/setting/view/linked_device_view.dart';
import 'package:jxim_client/im/chat_info/chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/chat_info_view.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_edit_view.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_view.dart';
import 'package:jxim_client/im/chat_info/group/group_option/group_edit_permission_view.dart';
import 'package:jxim_client/im/chat_info/more_vert/more_setting_controller.dart';
import 'package:jxim_client/im/chat_info/tab_option/member/add_member/group_add_member_controller.dart';
import 'package:jxim_client/im/chat_info/tab_option/member/add_member/group_add_member_view.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/components/task/ctr_task.dart';
import 'package:jxim_client/im/custom_content/components/task/task_page.dart';
import 'package:jxim_client/im/custom_content/red_packet/red_packet_leaderboard.dart';
import 'package:jxim_client/im/custom_content/red_packet/red_packet_leaderboard_controller.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/media/album_view.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/media/selected_album_view.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/im/group_chat/group_chat_view.dart';
import 'package:jxim_client/im/private_chat/single_chat_controller.dart';
import 'package:jxim_client/im/private_chat/single_chat_view.dart';
import 'package:jxim_client/im/services/media/asset_preview_controller.dart';
import 'package:jxim_client/im/services/media/asset_preview_view.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/reel/reel_search/reel_search_controller.dart';
import 'package:jxim_client/reel/reel_search/reel_search_view.dart';
import 'package:jxim_client/reel/upload_reel/add_tag_view.dart';
import 'package:jxim_client/reel/upload_reel/upload_reel_view.dart';
import 'package:jxim_client/setting/Notification/notification_controller.dart';
import 'package:jxim_client/setting/Notification/notification_setting_view.dart';
import 'package:jxim_client/setting/Notification/notification_type_view.dart';
import 'package:jxim_client/setting/Notification/notification_view.dart';
import 'package:jxim_client/setting/user_bio/add_email_page.dart';
import 'package:jxim_client/setting/user_bio/edit_phone_number.dart';
import 'package:jxim_client/setting/user_bio/edit_username.dart';
import 'package:jxim_client/setting/user_bio/user_bio_controller.dart';
import 'package:jxim_client/setting/user_bio/user_bio_view.dart';
import 'package:jxim_client/swipeable_page_route.dart';
import 'package:jxim_client/utils/album/common_album_controller.dart';
import 'package:jxim_client/utils/album/common_album_view.dart';
import 'package:jxim_client/utils/album/common_selected_album_view.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/agora/agora_call_controller.dart';
import 'package:jxim_client/views/agora/agora_call_view.dart';
import 'package:jxim_client/views/apperance/appearance_controller.dart';
import 'package:jxim_client/views/apperance/appearance_view.dart';
import 'package:jxim_client/views/call_log/call_log_controller.dart';
import 'package:jxim_client/views/component/avatar_detail_view.dart';
import 'package:jxim_client/views/contact/contact_controller.dart';
import 'package:jxim_client/views/contact/edit_contact_controller.dart';
import 'package:jxim_client/views/contact/edit_contact_view.dart';
import 'package:jxim_client/views/contact/friend_request_view.dart';
import 'package:jxim_client/views/contact/local_contact_controller.dart';
import 'package:jxim_client/views/contact/local_contact_view.dart';
import 'package:jxim_client/views/contact/qr_code_scanner.dart';
import 'package:jxim_client/views/contact/qr_code_scanner_controller.dart';
import 'package:jxim_client/views/contact/qr_code_view.dart';
import 'package:jxim_client/views/contact/qr_code_view_controller.dart';
import 'package:jxim_client/views/contact/qr_code_without_scan_button_view.dart';
import 'package:jxim_client/views/contact/search_contact_controller.dart';
import 'package:jxim_client/views/contact/searching_view.dart';
import 'package:jxim_client/views/contact/share_controller.dart';
import 'package:jxim_client/views/contact/share_view.dart';
import 'package:jxim_client/views/login/login_controller.dart';
import 'package:jxim_client/views/login/login_view.dart';
import 'package:jxim_client/views/login/onboarding_controller.dart';
import 'package:jxim_client/views/login/onboarding_view.dart';
import 'package:jxim_client/views/login/otp_controller.dart';
import 'package:jxim_client/views/login/otp_view.dart';
import 'package:jxim_client/views/message/chat/custom_text_viewer.dart';
import 'package:jxim_client/views/message/chat/face/edit_sticker_view.dart';
import 'package:jxim_client/views/message/chat/face/manage_sticker.dart';
import 'package:jxim_client/views/message/chat/face/manage_sticker_controller.dart';
import 'package:jxim_client/views/message/share/share_chat_controller.dart';
import 'package:jxim_client/views/message/share/share_chat_view.dart';
import 'package:jxim_client/views/message/webpage/common_webview.dart';
import 'package:jxim_client/views/message/webpage/common_webview_controller.dart';
import 'package:jxim_client/views/mypage/set/lang_setting.dart';
import 'package:jxim_client/views/privacy_security/auth_method/authMethodController.dart';
import 'package:jxim_client/views/privacy_security/auth_method/auth_method_view.dart';
import 'package:jxim_client/views/privacy_security/block_list_controller.dart';
import 'package:jxim_client/views/privacy_security/block_list_view.dart';
import 'package:jxim_client/views/privacy_security/delete_account/delete_account_complete_controller.dart';
import 'package:jxim_client/views/privacy_security/delete_account/delete_account_conplete_view.dart';
import 'package:jxim_client/views/privacy_security/delete_account/delete_account_controller.dart';
import 'package:jxim_client/views/privacy_security/delete_account/delete_account_view.dart';
import 'package:jxim_client/views/privacy_security/limit_secondary_auth/limit_secondary_auth_controller.dart';
import 'package:jxim_client/views/privacy_security/limit_secondary_auth/limit_secondary_auth_view.dart';
import 'package:jxim_client/views/privacy_security/passcode/block_passcode_view.dart';
import 'package:jxim_client/views/privacy_security/passcode/confirm_passcode_controller.dart';
import 'package:jxim_client/views/privacy_security/passcode/confirm_passcode_view.dart';
import 'package:jxim_client/views/privacy_security/passcode/current_passcode_controller.dart';
import 'package:jxim_client/views/privacy_security/passcode/current_passcode_view.dart';
import 'package:jxim_client/views/privacy_security/passcode/passcode_controller.dart';
import 'package:jxim_client/views/privacy_security/passcode/passcode_intro_view.dart';
import 'package:jxim_client/views/privacy_security/passcode/passcode_setting_view.dart';
import 'package:jxim_client/views/privacy_security/passcode/setup_passcode_controller.dart';
import 'package:jxim_client/views/privacy_security/passcode/setup_passcode_view.dart';
import 'package:jxim_client/views/privacy_security/payment_two_factor_auth/PaymentTwoFactorAuthController.dart';
import 'package:jxim_client/views/privacy_security/payment_two_factor_auth/payment_two_factor_auth.dart';
import 'package:jxim_client/views/privacy_security/privacy_security_controller.dart';
import 'package:jxim_client/views/privacy_security/privacy_security_setting_view.dart';
import 'package:jxim_client/views/privacy_security/privacy_security_view.dart';
import 'package:jxim_client/views/register/register_controller.dart';
import 'package:jxim_client/views/register/register_view.dart';
import 'package:jxim_client/views/wallet/add_address_select_crypto_view.dart';
import 'package:jxim_client/views/wallet/add_address_view.dart';
import 'package:jxim_client/views/wallet/address/book/wallet_address_book_controller.dart';
import 'package:jxim_client/views/wallet/address/book/wallet_address_edit_controller.dart';
import 'package:jxim_client/views/wallet/address/book/wallet_address_edit_page.dart';
import 'package:jxim_client/views/wallet/address/safety/address_security_setting_view.dart';
import 'package:jxim_client/views/wallet/controller/add_address_controller.dart';
import 'package:jxim_client/views/wallet/address/safety/address_security_setting_controller.dart';
import 'package:jxim_client/views/wallet/controller/fund_transfer_controller.dart';
import 'package:jxim_client/views/wallet/controller/my_addresses_controller.dart';
import 'package:jxim_client/views/wallet/controller/qr_scanner_controller.dart';
import 'package:jxim_client/views/wallet/controller/transaction_controller.dart';
import 'package:jxim_client/views/wallet/controller/transfer_controller.dart';
import 'package:jxim_client/views/wallet/controller/wallet_binding.dart';
import 'package:jxim_client/views/wallet/controller/withdraw_controller.dart';
import 'package:jxim_client/views/wallet/crypto_view.dart';
import 'package:jxim_client/views/wallet/fund_transfer_veiw.dart';
import 'package:jxim_client/views/wallet/my_address_view.dart';
import 'package:jxim_client/views/wallet/passcode_view.dart';
import 'package:jxim_client/views/wallet/transaction_history_view.dart';
import 'package:jxim_client/views/wallet/transfer_view.dart';
import 'package:jxim_client/views/wallet/address/book/wallet_address_book_page.dart';
import 'package:jxim_client/views/wallet/wallet_qr_scan.dart';
import 'package:jxim_client/views/wallet/wallet_view.dart';
import 'package:jxim_client/views/wallet/withdraw_select_currency_view.dart';
import 'package:jxim_client/views/wallet/withdraw_view.dart';
import 'package:jxim_client/views_desktop/login/desktop_login_loading.dart';
import 'package:jxim_client/views_desktop/login/desktop_login_qr_view.dart';
import 'package:jxim_client/views_desktop/login/desktop_onboard_view.dart';
import 'package:jxim_client/views_desktop/login/desktop_others_login_view.dart';

import 'home/chat/controllers/chat_list_controller.dart';
import 'home/desktop_home_view.dart';
import 'home/setting/data_storage/data_storage_view.dart';
import 'home/setting/view/date_time_view.dart';
import 'home/setting/view/feedback/completed_feedback_page.dart';
import 'home/setting/view/feedback/ctr_feedback.dart';
import 'home/setting/view/feedback/feedback_page.dart';
import 'home/setting/view/feedback/gallery_page.dart';
import 'im/chat_info/chat_more_setting_view.dart';
import 'im/chat_info/group/group_chat_edit_controller.dart';
import 'im/chat_info/group/group_chat_game_info_view.dart';
import 'im/chat_info/group/group_option/group_edit_admin_view.dart';
import 'im/chat_info/more_vert/more_vert_controller.dart';
import 'reel/upload_reel/upload_reel_controller.dart';
import 'views/contact/qr_code_without_scan_button_view_controller.dart';
import 'views/privacy_security/limit_secondary_auth/modify_limit_view.dart';
import 'views/privacy_security/passcode/passcode_block_contrtoller.dart';
import 'package:jxim_client/views/discovery/discovery_controller.dart';
import 'package:jxim_client/views/wallet/wallet_qr_view.dart';
import 'views/wallet/controller/wallet_controller.dart';
import 'package:im_diff_plugin/im_diff_plugin.dart';

class RouteName {
  static const String login = '/';
  static const String boarding = '/boarding';
  static const String desktopBoarding = '/desktopBoarding';
  static const String desktopLoginQR = '/desktopLoginQR';
  static const String desktopOthersLogin = '/desktopOthersLogin';
  static const String desktopLoadingView = '/desktopLoadingView';
  static const String desktopChatEmptyView = '/desktopChatEmptyView';
  static const String otpView = '/otpView';
  static const String register = '/login/register_select_sex';
  static const String setPage = '/mypage/set';
  static const String registerProfile = '/registerProfile';

  /// 主页路径
  static const String home = '/home';
  static const String desktopHome = '/desktopHome';

  static const String albumView = '/chat/albumView';
  static const String selectedAlbumView = '/chat/selectedAlbumView';

  /// 图片详情预览
  static const String mediaDetailView = '/chat/mediaDetailView';

  /// 预览详情
  static const String mediaPreviewView = '/chat/mediaPreviewView';
  static const String mediaPreSendView = '/chat/mediaPreSendView';

  static const String taskDetail = '/chat/taskDetail';

  /// 聊天室详情
  static const String chatInfo = '/chat/chatInfo';
  static const String groupChatInfo = '/chat/groupChatInfo';
  static const String groupChatGameInfo = '/chat/groupChatGameInfo';
  static const String groupAddMember = '/chat/chatInfo/addMember';
  static const String chatMoreSetting = '/chat/chatMoreSetting';

  // static const String menu = '/chat/menu';

  /// 设定界面
  /// 个人资料
  static const String userBioSetting = '/settings/userBioSetting';
  static const String groupChatEdit = '/chat/groupChatInfo/groupChatEdit';
  static const String groupChatEditPermission =
      '/chat/groupChatInfo/groupChatEdit/permission';
  static const String groupChatEditAdmin =
      '/chat/groupChatInfo/groupChatEdit/admin';
  static const String groupManagement = "/chat/groupChatInfo/groupManagement";
  static const String editUsername = '/setting/userBioSetting/editUsername';
  static const String editPhoneNumber =
      '/setting/userBioSetting/editPhoneNumber';
  static const addEmail = '/setting/accountInfo/addEmail';

  /// Settings
  static const String languageView = '/settings/language';
  static const String appearanceView = '/settings/appearance';

  static const String privacySecurity = '/settings/privacySecurity';
  static const String privacySecuritySetting =
      '/settings/privacySecuritySetting';
  static const String dataStorage = '/settings/dataStorage';
  static const String dataAndStorage = '/settings/dataAndStorage';
  static const String linkedDevice = '/settings/linkedDevice';
  static const String appInfo = '/settings/appInfo';
  static const String dateTime = '/settings/dateTime';
  static const String blockList = '/settings/blockList';
  static const String testPage = '/settings/testPage';

  // 短视频路由
  static const String reel = '/reel';
  static const String uploadReel = '/reel/uploadReel';
  static const String reelProfile = '/reel/reelProfile';
  static const String reelSearch = '/reel/reelSearch';
  static const String addTag = '/reel/addTag';
  static const String reelPreview = '/reel/reelSearch/reelPreview';

  static const String notification = '/settings/notification';
  static const String notificationSetting = '/settings/notificationSetting';
  static const String notificationType = '/settings/notificationType';

  static const String passcodeSetting =
      '/settings/privacySecurity/passcodeView';
  static const String passcodeIntroSetting =
      '/settings/privacySecurity/passcodeIntroSetting';
  static const String currentPasscodeView =
      '/settings/privacySecurity/passcodeIntroSetting/currentPasscodeView';
  static const String setupPasscodeView =
      '/settings/privacySecurity/passcodeIntroSetting/setupPasscodeView';
  static const String confirmPasscodeView =
      '/settings/privacySecurity/passcodeIntroSetting/setupPasscodeView/confirmPasscodeView';
  static const String blockPasscodeView =
      '/settings/privacySecurity/passcodeIntroSetting/blockPasscodeView';
  static const String deleteAccountView =
      '/settings/privacySecurity/deleteAccountView';
  static const String deleteAccountCompleteView =
      '/settings/privacySecurity/deleteAccountCompleteView';
  static const String paymentTwoFactorAuthView =
      '/settings/privacySecurity/paymentTwoFactorAuthView';
  static const String authMethodView =
      '/settings/privacySecurity/authMethodView';
  static const String limitSecondaryAuthView =
      '/settings/privacySecurity/limitSecondaryAuthView';
  static const String modifyLimitView =
      '/settings/privacySecurity/modifyLimitView';

//Permissions
  static const String permissions = '/permissions';

  /// 联系人
  static const String contactView = '/contact';
  static const String searchUserView = '/searchUser';
  static const String friendRequestView = '/contact/friendRequest';
  static const String qrCodeView = '/contact/qrCodeView';
  static const String qrCodeWithoutScanButtonView =
      '/contact/qrCodeWithoutScanButtonView';
  static const String qrCodeScanner = '/contact/qrCodeScanner';
  static const String walletQRCodeScanner = '/contact/walletQRCodeScanner';
  static const String profileInfo = '/contact/profileInfo';
  static const String editContact = '/contact/edit';
  static const String contactProfile = '/contact/contactProfile';
  static const String localContactView = '/contact/localContactView';
  static const String shareView = '/share';

  static const String feedback = '/settings/appInfo/feedback';
  static const String galleryPage = '/settings/appInfo/feedback/gallery';
  static const String completedFeedback =
      '/settings/appInfo/feedback/gallery/completedFeedback';

  /// Wallet
  static const String walletView = '/settings/wallet';
  static const String withdrawSelectCurrency =
      '/settings/wallet/withdrawSelectCurrency';
  static const String transactionHistoryView =
      '/settings/wallet/transactionHistoryView';
  static const String myAddressView = '/settings/wallet/myAddress';
  static const String addressBookView = '/settings/wallet/addressBook';
  static const String addAddressView =
      '/settings/wallet/addressBook/addAddressView';
  static const String addAddressSelectCryptoView =
      '/settings/wallet/addressBook/addAddressView/addAddressSelectCryptoView';
  static const String withdrawView = '/settings/wallet/withdraw';
  static const String myWalletQRView = '/settings/wallet/myWalletQR';
  static const String cryptoView = '/settings/wallet/cryptoView';

  static const String selectRecipientView =
      '/settings/wallet/withdraw/selectRecipient';
  static const String confirmWithdrawView =
      '/settings/wallet/withdraw/selectRecipient/confirmWithdrawView';
  static const String passcodeView =
      '/settings/wallet/withdraw/selectRecipient/confirmWithdrawView/passcode';
  static const String fundTransferView = '/settings/wallet/fund_transfer_view';
  static const String transferView = '/settings/wallet/transfer_view';
  static const String addressSecuritySettingView =
      '/settings/wallet/addressSecuritySettingView';
  static const String addressEditView = '/settings/wallet/addressBook/edit';

  /// 红包 页面
  static const String redPacketLeaderboard = '/chat/redPacketLeaderboard';

  /// 贴纸页面
  static const String manageSticker = '/message/face/manageSticker';
  static const String editSticker = '/message/face/editSticker';

  /// 查看文本
  static const String textViewer = '/message/textViewer';

  static const String agoraCallView = '/agoraCallView';

  static const String phoneNumSettingView =
      '/settings/privacySecurity/phoneNumSettingView';

  static const String usernameSettingView =
      '/settings/privacySecurity/usernameSettingView';
  static const String profilePicSettingView =
      '/settings/privacySecurity/profilePicSettingView';

  static const String lastSeenSettingView =
      '/settings/privacySecurity/lastSeenSettingView';

  static const String usernameSearchView =
      '/settings/privacySecurity/usernameSearchView';
  static const String phoneNumSearchView =
      '/settings/privacySecurity/phoneNumSearchView';

  /// 共用相冊
  static const String commonAlbumView = '/album/commonAlbumView';
  static const String commonSelectedAlbumView =
      '/album/commonSelectedAlbumView';

  static const String webView = '/webView';

  /// 分享
  static const String shareChat = '/shareChat';

  static const String avatarDetail = '/avatarDetail';
}

class Routes {
  static final navigatorKey = new GlobalKey<NavigatorState>();

  static showNavigatorCall(
      {required Widget container, required String groupKey}) {
    BotToast.showWidget(
      groupKey: groupKey,
      toastBuilder: (cancelFunc) {
        return container;
      },
    );
  }

  static var _cacheRoute = null;
  static routes(){
    if (_cacheRoute != null) {
      return _cacheRoute;
    }
    _cacheRoute = [..._routes,...RouteNameDiff.routes];
    // 添加测试页面
    if (Config().isDebug) {
      _cacheRoute.add(
        GetPage(
        name: RouteName.testPage,
        page: () => TestPage(),
        binding: BindingsBuilder(() {
          Get.put(TestPageController());
        }),
        transition: Transition.rightToLeft,
        ),
      );
    }
    return _cacheRoute;
  }

  static final List<GetPage> _routes = [
    GetPage(
        name: RouteName.boarding,
        page: () => OnBoardingView(),
        binding: BindingsBuilder(() {
          Get.put(OnBoardingController());
        })),
    GetPage(
        name: RouteName.desktopBoarding,
        page: () => DesktopOnboardView(),
        binding: BindingsBuilder(() {
          Get.put(OnBoardingController());
        })),
    GetPage(
      name: RouteName.login,
      page: () => LoginView(),
      binding: BindingsBuilder(() {
        Get.put(LoginController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.desktopLoginQR,
      page: () => DesktopLoginQrView(),
      binding: BindingsBuilder(() {
        Get.put(LoginController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.desktopOthersLogin,
      page: () => const DesktopOthersLoginView(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.desktopLoadingView,
      page: () => const DesktopLoginLoadingView(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.otpView,
      page: () => const OTPView(),
      binding: BindingsBuilder(() {
        Get.put(OtpController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.registerProfile,
      page: () => const NewProfileView(),
      binding: BindingsBuilder(() {
        Get.put(NewProfileController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.home,
      page: () => const HomeView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => CustomPopupMenuController());
        Get.put(HomeController());
        Get.put(ChatListController());
        Get.put(DiscoveryController());
        Get.put(CallLogController());
        Get.put(SettingController());
        Get.put(ContactController());
      }),
      transition: Transition.noTransition,
      // transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
        name: RouteName.desktopHome,
        page: () => const DesktopHomeView(),
        binding: BindingsBuilder(() {
          Get.lazyPut(() => CustomPopupMenuController());
          Get.put(HomeController());
          Get.put(ChatListController());
          Get.put(DiscoveryController());
          Get.put(CallLogController());
          Get.put(SettingController());
          Get.put(ContactController());
        })),
    // GetPage(
    //   name: RouteName.createChat,
    //   page: () => const CreateChatView(),
    //   binding: BindingsBuilder(() {
    //     Get.put(CreateChatController());
    //   }),
    //   transition: Transition.rightToLeft,
    //   transitionDuration: const Duration(milliseconds: 200),
    // ),
    // GetPage(
    //   name: RouteName.createGroup,
    //   page: () => const CreateGroupView(),
    //   binding: BindingsBuilder(() {
    //     Get.put(CreateGroupController());
    //   }),
    //   transition: Transition.rightToLeft,
    //   transitionDuration: const Duration(milliseconds: 200),
    // ),
    // GetPage(
    //   name: RouteName.createGroupInfo,
    //   page: () => const CreateGroupInfoView(),
    //   binding: BindingsBuilder(() {}),
    //   transition: Transition.rightToLeft,
    //   transitionDuration: const Duration(milliseconds: 200),
    // ),
    GetPage(
      name: RouteName.albumView,
      page: () => const AlbumView(),
    ),
    GetPage(
      name: RouteName.selectedAlbumView,
      page: () => const SelectedAlbumView(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.mediaPreviewView,
      page: () => const AssetPreviewView(),
      binding: BindingsBuilder(() {
        Get.put(AssetPreviewController());
      }),
      preventDuplicates: false,
      popGesture: false,
      transition: Transition.noTransition,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: RouteName.mediaPreSendView,
      page: () => const MediaPreSendView(),
      binding: BindingsBuilder(() {
        Get.put(MediaPreSendViewController());
      }),
      preventDuplicates: false,
      popGesture: false,
      transition: Transition.noTransition,
      transitionDuration: Duration.zero,
    ),
    GetPage(
      name: RouteName.commonAlbumView,
      page: () => const CommonAlbumView(),
    ),
    GetPage(
      name: RouteName.commonSelectedAlbumView,
      page: () => const CommonSelectedAlbumView(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.chatInfo,
      page: () => ChatInfoView(),
      binding: BindingsBuilder(() {
        Get.put(ChatInfoController());
        Get.put(MoreSettingController());
        Get.put(MoreVertController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.groupChatInfo,
      page: () => GroupChatInfoView(),
      binding: BindingsBuilder(() {
        Get.put(GroupChatInfoController());
        Get.put(MoreSettingController());
        Get.put(MoreVertController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.groupChatGameInfo,
      page: () => GroupChatGameInfoView(),
      binding: BindingsBuilder(() {
        Get.put(GroupChatInfoController());
        Get.put(MoreSettingController());
        Get.put(MoreVertController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.chatMoreSetting,
      page: () => const ChatMoreSettingView(),
      binding: BindingsBuilder(() {
        Get.put(MoreSettingController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    // GetPage(
    //   name: RouteName.menu,
    //   page: () => const MenuView(),
    //   binding: BindingsBuilder(() {
    //     Get.put(MenuViewController());
    //   }),
    //   transition: Transition.rightToLeft,
    //   transitionDuration: const Duration(milliseconds: 200),
    // ),
    GetPage(
      name: RouteName.groupAddMember,
      page: () => const GroupAddMemberView(),
      binding: BindingsBuilder(() {
        Get.put(GroupAddMemberController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.groupChatEdit,
      page: () => const GroupChatEditView(),
      binding: BindingsBuilder(() {
        Get.put(GroupChatEditController());
      }),
      popGesture: false,
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.groupChatEditPermission,
      page: () => const GroupEditPermissionView(),
      binding: BindingsBuilder(() {
        Get.put(GroupChatEditController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.groupChatEditAdmin,
      page: () => const GroupEditAdminView(),
      binding: BindingsBuilder(() {}),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.userBioSetting,
      page: () => const UserBioView(),
      binding: BindingsBuilder(() {
        Get.put(CommonAlbumController(), tag: commonAlbumTag);
        Get.put(UserBioController());
      }),
      transition: Transition.fadeIn,
      popGesture: false,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.languageView,
      page: () => LangSetting(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.privacySecurity,
      page: () => const PrivacySecurityView(),
      binding: BindingsBuilder(
        () {
          Get.put(PrivacySecurityController());
          Get.put(PasscodeController());
        },
      ),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.privacySecuritySetting,
      page: () => const PrivacySecuritySettingView(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.dataAndStorage,
      page: () => const DataAndStorageView(),
      binding: BindingsBuilder(
            () {
          Get.put(DataAndStorageController());
        },
      ),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.linkedDevice,
      page: () => const LinkedDeviceView(),
      binding: BindingsBuilder(
        () {
          Get.put(LinkedDeviceController());
        },
      ),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.appInfo,
      page: () => const AppInfoView(),
      binding: BindingsBuilder(
        () {
          Get.put(AppInfoController());
        },
      ),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.dateTime,
      page: () => const DateTimeView(),
      binding: BindingsBuilder(
        () {
          Get.put(DateTimeController());
        },
      ),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.reel,
      page: () => const ReelView(),
      binding: BindingsBuilder(
        () {
          Get.put(ReelController());
        },
      ),
      popGesture: false,
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.uploadReel,
      page: () => const UploadReelView(),
      binding: BindingsBuilder(
        () {
          Get.put(UploadReelController());
        },
      ),
      popGesture: false,
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.reelSearch,
      page: () => const ReelSearchView(),
      binding: BindingsBuilder(
        () {
          Get.put(ReelSearchController());
        },
      ),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.addTag,
      page: () => const AddTagView(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.blockList,
      page: () => const BlockListView(),
      binding: BindingsBuilder(
        () {
          Get.put(BlockListController());
        },
      ),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.notification,
      page: () => const NotificationView(),
      binding: BindingsBuilder(
        () {
          Get.put(NotificationController());
        },
      ),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.notificationSetting,
      page: () => const NotificationSettingView(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.notificationType,
      page: () => const NotificationTypeView(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.appearanceView,
      page: () => const AppearanceView(),
      binding: BindingsBuilder(() {
        Get.put(AppearanceController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.walletView,
      page: () => const WalletView(),
      binding: WalletBindings(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.fundTransferView,
      page: () => FundTransferView(),
      binding: BindingsBuilder(
        () {
          final args = Get.arguments;
          Get.put(FundTransferController(args['currencyType']));
        },
      ),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.transferView,
      page: () {
        final args = Get.arguments;
        return TransferView(
          accountId: args['accountId'],
          userId: args['userId'],
          nickName: args['nickName'],
          phoneCode: args['phoneCode'],
          phone: args['phone'],
          userName: args['userName'],
        );
      },
      binding: BindingsBuilder(
        () {
          final args = Get.arguments;
          Get.put(TransferController(args['isFromQRCode']));
        },
      ),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.transactionHistoryView,
      page: () => const TransactionHistoryView(),
      binding: BindingsBuilder(() {
        Get.put(TransactionController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.cryptoView,
      page: () => const CryptoView(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.passcodeSetting,
      page: () => const PasscodeSettingView(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.passcodeIntroSetting,
      page: () => PasscodeIntroView(),
      binding: BindingsBuilder(() {
        Get.put(PasscodeController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.currentPasscodeView,
      page: () => const CurrentPasscodeView(),
      binding: BindingsBuilder(() {
        Get.put(CurrentPasscodeController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.setupPasscodeView,
      page: () => const SetupPasscodeView(),
      binding: BindingsBuilder(() {
        Get.put(SetupPasscodeController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.confirmPasscodeView,
      page: () => const ConfirmPasscodeView(),
      binding: BindingsBuilder(() {
        Get.put(ConfirmPasscodeController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.blockPasscodeView,
      page: () => const BlockPasscodeView(),
      binding: BindingsBuilder(() {
        Get.put(PasscodeBlockController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.deleteAccountView,
      page: () => const DeleteAccountView(),
      binding: BindingsBuilder(() {
        Get.put(DeleteAccountController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.deleteAccountCompleteView,
      page: () => const DeleteAccountCompleteView(),
      binding: BindingsBuilder(() {
        Get.put(DeleteAccountCompleteController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.friendRequestView,
      page: () => const FriendRequestView(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.searchUserView,
      page: () => const SearchingView(),
      binding: BindingsBuilder(() {
        Get.put(SearchContactController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.addressBookView,
      // page: () => const RecipientAddressBookView(),
      page: () => const WalletAddressBookPage(),
      binding: BindingsBuilder(() {
        // Get.put(RecipientAddressBookController());
        Get.put(WalletAddressBookController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.addAddressView,
      page: () => const AddAddressView(),
      binding: BindingsBuilder(() {
        Get.put(AddAddressController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.addAddressSelectCryptoView,
      page: () => const AddAddressSelectCryptoView(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.myAddressView,
      page: () => const MyAddressView(),
      binding: BindingsBuilder(() {
        Get.put(MyAddressesController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.withdrawSelectCurrency,
      page: () => const WithdrawSelectCurrencyView(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.withdrawView,
      page: () => const WithdrawView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => WithdrawController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),

    GetPage(
      name: RouteName.myWalletQRView,
      page: () => const WalletQRView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => WalletController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),

    GetPage(
      name: RouteName.walletQRCodeScanner,
      page: () => const WalletQrScanner(),
      binding: BindingsBuilder(() {
        Get.put(QRScannerController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.passcodeView,
      page: () => const PasscodeView(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.qrCodeView,
      page: () => const QRCodeView(),
      binding: BindingsBuilder(() {
        Get.put(QRCodeViewController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.qrCodeWithoutScanButtonView,
      page: () => const QRCodeWithoutScanButtonView(),
      binding: BindingsBuilder(() {
        Get.put(QRCodeWithoutScanButtonViewController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.qrCodeScanner,
      page: () => const QRCodeScanner(),
      binding: BindingsBuilder(() {
        Get.put(QRCodeScannerController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.editContact,
      page: () => const EditContactView(),
      binding: BindingsBuilder(() {
        Get.put(EditContactController());
      }),
      popGesture: false,
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.editUsername,
      page: () => const EditUsername(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.editPhoneNumber,
      page: () => const EditPhoneNumber(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.localContactView,
      page: () => const LocalContactView(),
      binding: BindingsBuilder(() {
        Get.put(LocalContactController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
        name: RouteName.manageSticker,
        page: () => const ManageStickers(),
        binding: BindingsBuilder(() {
          Get.put(ManageStickerController());
        })),
    GetPage(
      name: RouteName.editSticker,
      page: () => const EditStickerView(),
    ),
    GetPage(
      name: RouteName.redPacketLeaderboard,
      page: () => const RedPacketLeaderboard(),
      binding: BindingsBuilder(() {
        Get.put(RedPacketLeaderboardController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.groupManagement,
      page: () => const CommonWebViewPage(),
      binding: BindingsBuilder(() {
        Get.put(CommonWebViewController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.textViewer,
      page: () => const CustomTextViewer(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.agoraCallView,
      page: () => AgoraCallView(),
      binding: BindingsBuilder(() {
        Get.put(AgoraCallController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.shareView,
      page: () => const ShareView(),
      binding: BindingsBuilder(() {
        Get.put(ShareController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.taskDetail,
      page: () => const TaskPage(),
      binding: BindingsBuilder(() {
        Get.put(CtrTask());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),

    GetPage(
      name: RouteName.feedback,
      page: () => const FeedbackPage(),
      binding: BindingsBuilder(() {
        Get.put(CtrFeedback());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),

    GetPage(
      name: RouteName.galleryPage,
      page: () => const GalleryPage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),

    GetPage(
      name: RouteName.completedFeedback,
      page: () => const CompletedFeedbackPage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 0),
    ),
    GetPage(
      name: RouteName.addEmail,
      page: () => const AddEmailPage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.paymentTwoFactorAuthView,
      page: () => const PaymentTwoFactorAuthView(),
      binding: BindingsBuilder(() {
        Get.put(PaymentTwoFactorAuthController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.authMethodView,
      page: () => const AuthMethodView(),
      binding: BindingsBuilder(() {
        Get.put(CommonAlbumController(), tag: commonAlbumTag);
        Get.put(UserBioController());
        Get.put(AuthMethodController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.limitSecondaryAuthView,
      page: () => const LimitSecondaryAuthView(),
      binding: BindingsBuilder(() {
        Get.put(LimitSecondaryAuthController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.webView,
      page: () {
        final args = Get.arguments;
        return IMWebView(url: args['url'], title: args['title']);
      },
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
      ),
      GetPage(
      name: RouteName.modifyLimitView,
      page: () => ModifyLimitView(),
      binding: BindingsBuilder(() {
        Get.put(LimitSecondaryAuthController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.addressSecuritySettingView,
      page: () => const AddressSecuritySettingView(),
      binding: BindingsBuilder(() {
        Get.put(AddressSecuritySettingController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.addressEditView,
      page: () => const WalletAddressEditPage(),
      binding: BindingsBuilder(() {
        Get.put(WalletAddressEditController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.shareChat,
      page: () => ShareChatView(),
      binding: BindingsBuilder((){
        Get.put(ShareChatController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.avatarDetail,
      page: () {
        final args = Get.arguments;
        return AvatarDetailView(
          nicknameId: args['nicknameId'],
          avatarId: args['avatarId'],
          isGroup:args['isGroup'],
        );
      },
      // popGesture: false,
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
    ),
  ];

  ///进入聊天
  static void toChat(
      {required Chat chat,
      bool searching = false,
      bool popCurrent = false,
      List<ChatMessage.Message>? selectedMsgIds,
      bool fromNotification = false,
      bool fromCollection = false,
      String appId = "",
      String gameId = "",
      String gameName = ""}) {
    if (chat.chat_id == 0) {
      if (chat.isGroup) {
        objectMgr.chatMgr.getGroupChatById(chat.id);
      } else {
        objectMgr.userMgr.loadUserById2(chat.id);
      }
      Toast.showToast(localized(chatInfoPleaseTryAgainLater));
      return;
    }
    if (chat.isGroup) {
      final bool controllerRegistered =
          Get.isRegistered<GroupChatController>(tag: chat.id.toString());
      if (controllerRegistered) return;
    }
    if (chat.isSingle || chat.isSaveMsg || chat.isSystem) {
      final bool controllerRegistered =
          Get.isRegistered<SingleChatController>(tag: chat.id.toString());
      if (controllerRegistered) return;
    }

    if (!popCurrent) Get.until((route) => Get.currentRoute == RouteName.home);
    if (chat.isSingle ||
        chat.typ == chatTypeSmallSecretary ||
        chat.typ == chatTypeSaved ||
        chat.typ == chatTypeSystem) {
      if (popCurrent)
        Get.off(
          () => SingleChatView(
            key: ValueKey(chat.id.toString()),
            tag: chat.id.toString(),
          ),
          routeName: 'chat/private_chat/${chat.id.toString()}',
          arguments: {
            'chat': chat,
          },
          transition: Transition.cupertino,
          binding: BindingsBuilder(() {
            Get.put(SingleChatController(), tag: chat.id.toString())
                .isSearching(searching);
            Get.put(CustomInputController(), tag: chat.id.toString());
            Get.put(ChatContentController(), tag: chat.id.toString());
          }),
          popGesture: true,
          preventDuplicates: false,
        );
      else {
        if (Platform.isIOS) {
          Get.key.currentState!.push(
            SwipeCustomPageRoute(
              opaque: true,
              page: () => SingleChatView(
                key: ValueKey(chat.id.toString()),
                tag: chat.id.toString(),
              ),
              routeName: 'chat/private_chat/${chat.id.toString()}',
              settings: RouteSettings(
                name: 'chat/private_chat/${chat.id.toString()}',
                arguments: {
                  'chat': chat,
                  'selectedMsgIds': selectedMsgIds,
                  'isGroup': chat.isGroup,
                  'uid': chat.friend_id,
                  'fromNotification': fromNotification
                },
              ),
              curve: Curves.easeOutQuad,
              fullscreenDialog: false,
              binding: BindingsBuilder(() {
                Get.put(SingleChatController(), tag: chat.id.toString())
                    .isSearching(searching);
                Get.put(CustomInputController(), tag: chat.id.toString());
                Get.put(ChatContentController(), tag: chat.id.toString());
                Get.put(MoreSettingController());
              }),
              popGesture: true,
            ),
          );
        } else {
          Get.to(
            () => SingleChatView(
              key: ValueKey(chat.id.toString()),
              tag: chat.id.toString(),
            ),
            routeName: 'chat/private_chat/${chat.id.toString()}',
            arguments: {
              'chat': chat,
              'selectedMsgIds': selectedMsgIds,
              'isGroup': chat.isGroup,
              'uid': chat.friend_id,
              'fromNotification': fromNotification
            },
            curve: Curves.easeInOutCubic,
            transition: Transition.rightToLeft,
            duration: const Duration(milliseconds: 200),
            binding: BindingsBuilder(() {
              Get.put(SingleChatController(), tag: chat.id.toString())
                  .isSearching(searching);
              Get.put(CustomInputController(), tag: chat.id.toString());
              Get.put(ChatContentController(), tag: chat.id.toString());
              Get.put(MoreSettingController());
            }),
            preventDuplicates: false,
          );
        }
      }
    } else if (chat.isGroup) {
      if (Platform.isIOS) {
        Get.key.currentState!.push(
          SwipeCustomPageRoute(
            opaque: true,
            page: () => GroupChatView(
              key: ValueKey(chat.id.toString()),
              tag: chat.id.toString(),
            ),
            routeName: 'chat/group_chat/${chat.id.toString()}',
            settings: RouteSettings(
              name: 'chat/group_chat/${chat.id.toString()}',
              arguments: {
                'chat': chat,
                'selectedMsgIds': selectedMsgIds,
                'isGroup': chat.isGroup,
                'id': objectMgr.userMgr.mainUser.id,
                'groupId': chat.id,
                'fromNotification': fromNotification,
                'fromCollection': fromCollection,
                'appId': appId,
                'gameId': gameId,
                'gameName': gameName
              },
            ),
            curve: Curves.easeOutQuad,
            fullscreenDialog: false,
            binding: BindingsBuilder(() {
              Get.put(GroupChatController(), tag: chat.id.toString())
                  .isSearching(searching);
              Get.put(CustomInputController(), tag: chat.id.toString());
              Get.put(ChatContentController(), tag: chat.id.toString());
              Get.put(MoreSettingController());
            }),
            popGesture: true,
          ),
        );
      } else {
        Get.to(
          () => GroupChatView(
            key: ValueKey(chat.id.toString()),
            tag: chat.id.toString(),
          ),
          routeName: 'chat/group_chat/${chat.id.toString()}',
          arguments: {
            'chat': chat,
            'selectedMsgIds': selectedMsgIds,
            'isGroup': chat.isGroup,
            'id': objectMgr.userMgr.mainUser.id,
            'groupId': chat.id,
            'fromNotification': fromNotification,
            'fromCollection': fromCollection,
            'appId': appId,
            'gameId': gameId,
            'gameName': gameName
          },
          curve: Curves.easeInOutCubic,
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 200),
          binding: BindingsBuilder(() {
            Get.put(GroupChatController(), tag: chat.id.toString())
                .isSearching(searching);
            Get.put(CustomInputController(), tag: chat.id.toString());
            Get.put(ChatContentController(), tag: chat.id.toString());
          }),
          preventDuplicates: false,
        );
      }
    }
    FlutterLocalNotificationsPlugin().cancelAll();
  }

  static void toChatDesktop({
    BuildContext? context,
    required Chat chat,
    bool searching = false,
    bool popCurrent = false,
    List<ChatMessage.Message>? selectedMsgIds,
  }) {
    if (Get.find<ChatListController>().desktopSelectedChatID.value == chat.id && selectedMsgIds == null) {
      return;
    } else {
      Get.find<ChatListController>().desktopSelectedChatID.value = chat.id;
    }

    if (chat.chat_id == 0) {
      if (chat.isGroup) {
        objectMgr.chatMgr.getGroupChatById(chat.id);
      } else {
        objectMgr.userMgr.loadUserById2(chat.id);
      }
      Toast.showToast(localized(chatInfoPleaseTryAgainLater));
      return;
    }
    if (chat.isGroup) {
      final bool controllerRegistered =
          Get.isRegistered<GroupChatController>(tag: chat.id.toString());
      if (controllerRegistered && selectedMsgIds == null){
          return;
      }
    }
    if (chat.isSingle || chat.isSaveMsg || chat.isSystem) {
      final bool controllerRegistered =
          Get.isRegistered<SingleChatController>(tag: chat.id.toString());
      if (controllerRegistered && selectedMsgIds == null){
          return;
      }
    }

    if (chat.isSingle ||
        chat.typ == chatTypeSmallSecretary ||
        chat.typ == chatTypeSaved ||
        chat.typ == chatTypeSystem) {
      Get.offAllNamed(RouteName.desktopChatEmptyView, id: 1);
      Get.toNamed('/singleChat',
          arguments: {
            'chat': chat,
            'selectedMsgIds':selectedMsgIds,
          },
          id: 1);
    } else if (chat.isGroup) {
      Get.offAllNamed(RouteName.desktopChatEmptyView, id: 1);
      Get.toNamed('/groupChat',
          arguments: {
            'chat': chat,
            'selectedMsgIds':selectedMsgIds,
          },
          id: 1);
    }
    FlutterLocalNotificationsPlugin().cancelAll();
  }

  static Future<T?> iOSToPage<T>(
    String routeName, {
    String? tag,
    Key? key,
    Object? arguments,
    Bindings? bindings,
    curve = Curves.easeOut,
    bool? fullscreenDialog,
  }) async {
    return Get.key.currentState!.push<T>(
      SwipeCustomPageRoute(
        opaque: true,
        page: Routes.routes()
            .where((element) => element.name == routeName)
            .first
            .page,
        routeName: routeName,
        settings: RouteSettings(
          name: routeName,
          arguments: arguments,
        ),
        curve: curve,
        fullscreenDialog: false,
        binding: bindings,
        popGesture: true,
      ),
    );
  }
}
