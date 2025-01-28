import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:cashier/im_cashier.dart';
import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_diff_plugin/im_diff_plugin.dart';
import 'package:jxim_client/end_to_end_encryption/backup_key/encryption_backup_key_controller.dart';
import 'package:jxim_client/end_to_end_encryption/backup_key/encryption_backup_key_view.dart';
import 'package:jxim_client/end_to_end_encryption/friend_verify/friend_verify_controller.dart';
import 'package:jxim_client/end_to_end_encryption/friend_verify/friend_verify_view.dart';
import 'package:jxim_client/end_to_end_encryption/friend_verify_other/friend_verify_other_controller.dart';
import 'package:jxim_client/end_to_end_encryption/friend_verify_other/friend_verify_other_view.dart';
import 'package:jxim_client/end_to_end_encryption/friend_verify_other_confirm/friend_verify_other_confirm_controller.dart';
import 'package:jxim_client/end_to_end_encryption/friend_verify_other_confirm/friend_verify_other_confirm_view.dart';
import 'package:jxim_client/end_to_end_encryption/friend_verify_setting/friend_verify_setting_controller.dart';
import 'package:jxim_client/end_to_end_encryption/friend_verify_setting/friend_verify_setting_view.dart';
import 'package:jxim_client/end_to_end_encryption/password/encryption_password_controller.dart';
import 'package:jxim_client/end_to_end_encryption/password/encryption_password_view.dart';
import 'package:jxim_client/end_to_end_encryption/pre_setup/encryption_pre_setup_controller.dart';
import 'package:jxim_client/end_to_end_encryption/pre_setup/encryption_pre_setup_view.dart';
import 'package:jxim_client/end_to_end_encryption/private_key_setting/private_key_setting_controller.dart';
import 'package:jxim_client/end_to_end_encryption/private_key_setting/private_key_setting_view.dart';
import 'package:jxim_client/end_to_end_encryption/qr_code/encryption_qr_code_controller.dart';
import 'package:jxim_client/end_to_end_encryption/qr_code/encryption_qr_code_view.dart';
import 'package:jxim_client/end_to_end_encryption/setup_password/encryption_setup_password_controller.dart';
import 'package:jxim_client/end_to_end_encryption/setup_password/encryption_setup_password_view.dart';
import 'package:jxim_client/end_to_end_encryption/verification/encryption_verification_controller.dart';
import 'package:jxim_client/end_to_end_encryption/verification/encryption_verification_view.dart';
import 'package:jxim_client/favourite/edit_note_controller.dart';
import 'package:jxim_client/favourite/edit_note_view.dart';
import 'package:jxim_client/favourite/edit_tag/favourite_edit_tag.dart';
import 'package:jxim_client/favourite/favourite_controller.dart';
import 'package:jxim_client/favourite/favourite_detail_controller.dart';
import 'package:jxim_client/favourite/favourite_detail_view.dart';
import 'package:jxim_client/favourite/favourite_view.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/home/desktop_home_view.dart';
import 'package:jxim_client/home/discover/controllers/im_discover_controller.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/home/home_view.dart';
import 'package:jxim_client/home/setting/controller/app_info_controller.dart';
import 'package:jxim_client/home/setting/controller/date_time_controller.dart';
import 'package:jxim_client/home/setting/controller/linked_device_controller.dart';
import 'package:jxim_client/home/setting/controller/test_page_controller.dart';
import 'package:jxim_client/home/setting/data_storage/data_storage_controller.dart';
import 'package:jxim_client/home/setting/data_storage/data_storage_view.dart';
import 'package:jxim_client/home/setting/setting_controller.dart';
import 'package:jxim_client/home/setting/test_page.dart';
import 'package:jxim_client/home/setting/view/app_info_view.dart';
import 'package:jxim_client/home/setting/view/date_time_view.dart';
import 'package:jxim_client/home/setting/view/feedback/completed_feedback_page.dart';
import 'package:jxim_client/home/setting/view/feedback/ctr_feedback.dart';
import 'package:jxim_client/home/setting/view/feedback/feedback_page.dart';
import 'package:jxim_client/home/setting/view/feedback/gallery_page.dart';
import 'package:jxim_client/home/setting/view/linked_device_view.dart';
import 'package:jxim_client/im/chat_info/chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/chat_info_view.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_edit_controller.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_edit_view.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_view.dart';
import 'package:jxim_client/im/chat_info/group/group_option/group_edit_admin_view.dart';
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
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/im/group_chat/group_chat_mini_app_view.dart';
import 'package:jxim_client/im/group_chat/group_chat_view.dart';
import 'package:jxim_client/im/group_chat/text_selectable_controller.dart';
import 'package:jxim_client/im/group_chat/text_selectable_page.dart';
import 'package:jxim_client/im/media_detail/media_pre_send_controller.dart';
import 'package:jxim_client/im/media_detail/media_pre_send_view.dart';
import 'package:jxim_client/im/private_chat/single_chat_controller.dart';
import 'package:jxim_client/im/private_chat/single_chat_view.dart';
import 'package:jxim_client/im/services/media/album_view.dart';
import 'package:jxim_client/im/services/media/asset_preview_controller.dart';
import 'package:jxim_client/im/services/media/asset_preview_view.dart';
import 'package:jxim_client/im/services/media/selected_album_view.dart';
import 'package:jxim_client/language/language_controller.dart';
import 'package:jxim_client/language/language_view.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/middle_ware.dart';
import 'package:jxim_client/moment/index.dart';
import 'package:jxim_client/moment/moment_detail/moment_detail_controller.dart';
import 'package:jxim_client/moment/moment_detail/moment_detail_view.dart';
import 'package:jxim_client/moment/moment_my_posts/moment_my_posts_controller.dart';
import 'package:jxim_client/moment/moment_my_posts/moment_my_posts_view.dart';
import 'package:jxim_client/moment/moment_notification/moment_notification_controller.dart';
import 'package:jxim_client/moment/moment_notification/moment_notification_view.dart';
import 'package:jxim_client/moment/moment_permission_selection/moment_permission_selection_controller.dart';
import 'package:jxim_client/moment/moment_permission_selection/moment_permission_selection_view.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart' as chat_message;
import 'package:jxim_client/reel/reel_page/reel_controller.dart';
import 'package:jxim_client/reel/reel_page/reel_navigation_mgr.dart';
import 'package:jxim_client/reel/reel_page/reel_view.dart';
import 'package:jxim_client/reel/reel_profile/edit_profile_controller.dart';
import 'package:jxim_client/reel/reel_profile/edit_profile_view.dart';
import 'package:jxim_client/reel/reel_profile/reel_follow_follower_list_view.dart';
import 'package:jxim_client/reel/reel_profile/reel_multi_manage_view.dart';
import 'package:jxim_client/reel/reel_profile/reel_my_profile_controller.dart';
import 'package:jxim_client/reel/reel_profile/reel_my_profile_edit.dart';
import 'package:jxim_client/reel/reel_profile/reel_my_profile_view.dart';
import 'package:jxim_client/reel/reel_profile/reel_profile_controller.dart';
import 'package:jxim_client/reel/reel_profile/reel_profile_view.dart';
import 'package:jxim_client/reel/reel_search/reel_search_controller.dart';
import 'package:jxim_client/reel/reel_search/reel_search_view.dart';
import 'package:jxim_client/reel/upload_reel/add_tag_view.dart';
import 'package:jxim_client/reel/upload_reel/upload_reel_controller.dart';
import 'package:jxim_client/reel/upload_reel/upload_reel_view.dart';
import 'package:jxim_client/setting/chat_category_folder/chat_category_controller.dart';
import 'package:jxim_client/setting/chat_category_folder/chat_category_view.dart';
import 'package:jxim_client/setting/experiment_controller.dart';
import 'package:jxim_client/setting/experiment_view.dart';
import 'package:jxim_client/setting/invite_friends/invite_friends.dart';
import 'package:jxim_client/setting/invite_friends/invite_friends_controller.dart';
import 'package:jxim_client/setting/network_diagnose/network_diagnose_controller.dart';
import 'package:jxim_client/setting/network_diagnose/network_diagnose_view.dart';
import 'package:jxim_client/setting/notification/notification_controller.dart';
import 'package:jxim_client/setting/notification/notification_setting_view.dart';
import 'package:jxim_client/setting/notification/notification_type_view.dart';
import 'package:jxim_client/setting/notification/notification_view.dart';
import 'package:jxim_client/setting/user_bio/add_email_page.dart';
import 'package:jxim_client/setting/user_bio/edit_phone_number.dart';
import 'package:jxim_client/setting/user_bio/edit_username.dart';
import 'package:jxim_client/setting/user_bio/user_bio_controller.dart';
import 'package:jxim_client/setting/user_bio/user_bio_view.dart';
import 'package:jxim_client/sound_setting/ringtone_sound_setting.dart';
import 'package:jxim_client/sound_setting/ringtone_sound_setting_controller.dart';
import 'package:jxim_client/sound_setting/sound_selection_controller.dart';
import 'package:jxim_client/sound_setting/sound_selection_view.dart';
import 'package:jxim_client/swipeable_page_route.dart';
import 'package:jxim_client/tags/tags_management_controller.dart';
import 'package:jxim_client/tags/tags_managment_view.dart';
import 'package:jxim_client/utils/album/common_album_controller.dart';
import 'package:jxim_client/utils/album/common_album_view.dart';
import 'package:jxim_client/utils/album/common_selected_album_view.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/agora/agora_call_view.dart';
import 'package:jxim_client/views/apperance/appearance_controller.dart';
import 'package:jxim_client/views/apperance/appearance_view.dart';
import 'package:jxim_client/views/call_log/call_log_controller.dart';
import 'package:jxim_client/views/call_log/call_log_view.dart';
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
import 'package:jxim_client/views/contact/search_contact_controller.dart';
import 'package:jxim_client/views/contact/searching_view.dart';
import 'package:jxim_client/views/contact/share_controller.dart';
import 'package:jxim_client/views/contact/share_view.dart';
import 'package:jxim_client/views/general_settings/general_settings_controller.dart';
import 'package:jxim_client/views/general_settings/general_settings_view.dart';
import 'package:jxim_client/views/login/login_controller.dart';
import 'package:jxim_client/views/login/login_view.dart';
import 'package:jxim_client/views/login/onboarding_controller.dart';
import 'package:jxim_client/views/login/onboarding_view.dart';
import 'package:jxim_client/views/login/otp_controller.dart';
import 'package:jxim_client/views/login/otp_invite_controller.dart';
import 'package:jxim_client/views/login/otp_invite_view.dart';
import 'package:jxim_client/views/login/otp_view.dart';
import 'package:jxim_client/views/message/chat/custom_text_viewer.dart';
import 'package:jxim_client/views/message/chat/face/edit_sticker_view.dart';
import 'package:jxim_client/views/message/chat/face/manage_sticker.dart';
import 'package:jxim_client/views/message/chat/face/manage_sticker_controller.dart';
import 'package:jxim_client/views/message/share/share_chat_controller.dart';
import 'package:jxim_client/views/message/share/share_chat_view.dart';
import 'package:jxim_client/views/message/webpage/common_webview.dart';
import 'package:jxim_client/views/message/webpage/common_webview_controller.dart';
import 'package:jxim_client/views/privacy_security/auth_method/auth_method_controller.dart';
import 'package:jxim_client/views/privacy_security/auth_method/auth_method_view.dart';
import 'package:jxim_client/views/privacy_security/block_list_controller.dart';
import 'package:jxim_client/views/privacy_security/block_list_view.dart';
import 'package:jxim_client/views/privacy_security/delete_account/delete_account_complete_controller.dart';
import 'package:jxim_client/views/privacy_security/delete_account/delete_account_conplete_view.dart';
import 'package:jxim_client/views/privacy_security/delete_account/delete_account_controller.dart';
import 'package:jxim_client/views/privacy_security/delete_account/delete_account_view.dart';
import 'package:jxim_client/views/privacy_security/limit_secondary_auth/limit_secondary_auth_controller.dart';
import 'package:jxim_client/views/privacy_security/limit_secondary_auth/limit_secondary_auth_view.dart';
import 'package:jxim_client/views/privacy_security/limit_secondary_auth/modify_limit_view.dart';
import 'package:jxim_client/views/privacy_security/moment_privacy/moment_privacy_available_days_view.dart';
import 'package:jxim_client/views/privacy_security/passcode/block_passcode_view.dart';
import 'package:jxim_client/views/privacy_security/passcode/confirm_passcode_controller.dart';
import 'package:jxim_client/views/privacy_security/passcode/confirm_passcode_view.dart';
import 'package:jxim_client/views/privacy_security/passcode/current_passcode_controller.dart';
import 'package:jxim_client/views/privacy_security/passcode/current_passcode_view.dart';
import 'package:jxim_client/views/privacy_security/passcode/passcode_block_contrtoller.dart';
import 'package:jxim_client/views/privacy_security/passcode/passcode_controller.dart';
import 'package:jxim_client/views/privacy_security/passcode/passcode_intro_view.dart';
import 'package:jxim_client/views/privacy_security/passcode/passcode_setting_view.dart';
import 'package:jxim_client/views/privacy_security/passcode/setup_passcode_controller.dart';
import 'package:jxim_client/views/privacy_security/passcode/setup_passcode_view.dart';
import 'package:jxim_client/views/privacy_security/payment_two_factor_auth/payment_two_factor_auth.dart';
import 'package:jxim_client/views/privacy_security/payment_two_factor_auth/payment_two_factor_auth_controller.dart';
import 'package:jxim_client/views/privacy_security/privacy_security_controller.dart';
import 'package:jxim_client/views/privacy_security/privacy_security_setting_view.dart';
import 'package:jxim_client/views/privacy_security/privacy_security_view.dart';
import 'package:jxim_client/views/register/register_controller.dart';
import 'package:jxim_client/views/register/register_view.dart';
import 'package:jxim_client/views/transfer_money/transfer_money.dart';
import 'package:jxim_client/views/transfer_money/transfer_money_controller.dart';
import 'package:jxim_client/views/translation/translate_setting_controller.dart';
import 'package:jxim_client/views/translation/translate_setting_view.dart';
import 'package:jxim_client/views/translation/translate_to_controller.dart';
import 'package:jxim_client/views/translation/translate_to_view.dart';
import 'package:jxim_client/views/translation/translate_visual_controller.dart';
import 'package:jxim_client/views/translation/translate_visual_view.dart';
import 'package:jxim_client/views/wallet/add_address_select_crypto_view.dart';
import 'package:jxim_client/views/wallet/add_address_view.dart';
import 'package:jxim_client/views/wallet/address/book/wallet_address_book_controller.dart';
import 'package:jxim_client/views/wallet/address/book/wallet_address_book_page.dart';
import 'package:jxim_client/views/wallet/address/book/wallet_address_edit_controller.dart';
import 'package:jxim_client/views/wallet/address/book/wallet_address_edit_page.dart';
import 'package:jxim_client/views/wallet/address/safety/address_security_setting_controller.dart';
import 'package:jxim_client/views/wallet/address/safety/address_security_setting_view.dart';
import 'package:jxim_client/views/wallet/controller/add_address_controller.dart';
import 'package:jxim_client/views/wallet/controller/fund_transfer_controller.dart';
import 'package:jxim_client/views/wallet/controller/my_addresses_controller.dart';
import 'package:jxim_client/views/wallet/controller/qr_scanner_controller.dart';
import 'package:jxim_client/views/wallet/controller/transaction_controller.dart';
import 'package:jxim_client/views/wallet/controller/transfer_controller.dart';
import 'package:jxim_client/views/wallet/controller/wallet_binding.dart';
import 'package:jxim_client/views/wallet/controller/wallet_controller.dart';
import 'package:jxim_client/views/wallet/controller/withdraw_controller.dart';
import 'package:jxim_client/views/wallet/crypto_view.dart';
import 'package:jxim_client/views/wallet/fund_transfer_view.dart';
import 'package:jxim_client/views/wallet/my_address_view.dart';
import 'package:jxim_client/views/wallet/passcode_view.dart';
import 'package:jxim_client/views/wallet/transaction_history_view.dart';
import 'package:jxim_client/views/wallet/transfer_view.dart';
import 'package:jxim_client/views/wallet/wallet_qr_scan.dart';
import 'package:jxim_client/views/wallet/wallet_qr_view.dart';
import 'package:jxim_client/views/wallet/wallet_view.dart';
import 'package:jxim_client/views/wallet/withdraw_select_currency_view.dart';
import 'package:jxim_client/views/wallet/withdraw_view.dart';
import 'package:jxim_client/views_desktop/login/desktop_login_loading.dart';
import 'package:jxim_client/views_desktop/login/desktop_login_qr_view.dart';
import 'package:jxim_client/views_desktop/login/desktop_onboard_view.dart';
import 'package:jxim_client/views_desktop/login/desktop_others_login_view.dart';

class RouteName {
  static const String login = '/';
  static const String boarding = '/boarding';
  static const String desktopBoarding = '/desktopBoarding';
  static const String desktopLoginQR = '/desktopLoginQR';
  static const String desktopOthersLogin = '/desktopOthersLogin';
  static const String desktopLoadingView = '/desktopLoadingView';
  static const String desktopChatEmptyView = '/desktopChatEmptyView';
  static const String otpView = '/otpView';
  static const String otpInviteView = '/otpInviteView';
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
  static const String groupAddMember = '/chat/chatInfo/addMember';

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
  static const String languageView = '/settings/languageView';
  static const String appearanceView = '/settings/appearance';

  static const String privacySecurity = '/settings/privacySecurity';
  static const String privacySecuritySetting =
      '/settings/privacySecuritySetting';
  static const String generalSettings = '/settings/generalSettings';

  static const String momentAvailableDaysSetting =
      '/settings/momentAvailableDaysSetting';
  static const String dataStorage = '/settings/dataStorage';
  static const String dataAndStorage = '/settings/dataAndStorage';
  static const String linkedDevice = '/settings/linkedDevice';
  static const String appInfo = '/settings/appInfo';
  static const String dateTime = '/settings/dateTime';
  static const String blockList = '/settings/blockList';
  static const String testPage = '/settings/testPage';

  // 短视频路由
  static const String reel = '/reel';
  static const String reelTempVideo = '/reel/tempVideo';
  static const String uploadReel = '/reel/uploadReel';
  static const String reelProfileView = '/reel/reelProfile';
  static const String reelMyProfileView = '/reel/reelMyProfile';
  static const String reelSearch = '/reel/reelSearch';
  static const String addTag = '/reel/addTag';
  static const String reelPreview = '/reel/reelSearch/reelPreview';
  static const String reelFollowFollower = '/reel/reelFollowFollower';
  static const String reelMultiManage = '/reel/reelMultiManage';

  // 朋友圈
  static const String moment = '/moment';
  static const String uploadMoment = '/moment/uploadMoment';
  static const String momentDetail = '/moment/momentDetail';
  static const String momentAssetPreview = '/moment/assetPreview';
  static const String momentNotification = '/moment/momentNotification';
  static const String momentMyPosts = '/moment/momentMyPosts';
  static const String momentMyPostsNested = '/moment/momentMyPostsNested';
  static const String momentPermission = '/moment/momentPermission';

  // 標籤管理
  static const String tagsManagementPage = '/tagsManagementPage';

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
  static const String networkDiagnose = '/settings/networkDiagnose';

//Permissions
  static const String permissions = '/permissions';

  /// 联系人
  static const String contactView = '/contact';
  static const String searchUserView = '/searchUser';
  static const String friendRequestView = '/contact/friendRequest';
  static const String qrCodeView = '/contact/qrCodeView';
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

  /// 好友转帐
  static const String chatTransferMoney = '/chat/transferMoney';

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

  /// 分享
  static const String shareChat = '/shareChat';

  static const String avatarDetail = '/avatarDetail';

  /// 翻译
  static const String translateSettingView = '/translateSetting';
  static const String translateToView = '/translateTo';
  static const String translateVisualView = '/translateVisual';

  static const String experimentView = '/settings/experiment';
  static const String reelMyProfileEdit = '/reelMyProfileEdit';
  static const String reelEditPage = '/reelEditPage';
  static const String settingRecentCall = '/settingRecentCall';

  /// 文字放大
  static const String textSelectablePage = '/textSelectablePage';

  /// 声音设置
  static const String ringtoneSoundSetting = '/ringtoneSoundSetting';
  static const String soundSelection = '/soundSelection';

  /// 收藏
  static const String favouritePage = '/favourite';
  static const String editNotePage = '/favourite/editNote';
  static const String favouriteDetailPage = '/favourite/detail';
  static const String favouriteAssetPreview = '/favourite/detail/assetPreview';
  static const String favouriteEditTag = '/favourite/editTag';

  /// 加密
  static const String encryptionPasswordPage = '/encryptionPasswordPage';
  static const String encryptionPreSetupPage = '/encryptionPreSetupPage';
  static const String encryptionSetupPage = '/encryptionSetupPage';
  static const String encryptionVerificationPage =
      '/encryptionVerificationPage';
  static const String encryptionBackupKeyPage = '/encryptionBackupKeyPage';
  static const String encryptionForgetPwPage = '/encryptionForgetPwPage';
  static const String encryptionPrivateKeySettingPage =
      '/encryptionPrivateKeySettingPage';
  static const String encryptionQrCodePage = '/encryptionQrCodePage';
  static const String encryptionFriendVerifySettingPage =
      '/encryptionFriendVerifySettingPage';
  static const String encryptionFriendVerifyOtherPage =
      '/encryptionFriendVerifyOtherPage';
  static const String encryptionFriendVerifyOtherConfirmPage =
      '/encryptionFriendVerifyOtherConfirmPage';
  static const String inviteFriends = '/inviteFriends';

  /// 聊天室文件夹
  static const String chatCategoryFolderPage = '/chatCategoryFolderPage';
}

class Routes {
  static showNavigatorCall({
    required Widget container,
    required String groupKey,
  }) {
    BotToast.showWidget(
      groupKey: groupKey,
      toastBuilder: (cancelFunc) {
        return container;
      },
    );
  }

  static final List<GetPage> _cacheRoute = [];

  static routes() {
    if (_cacheRoute.isNotEmpty) return _cacheRoute;
    _cacheRoute.addAll([
      ..._routes,
      ...RouteNameDiff.routes,
      ...CashierRoutes.routes,
    ]);

    // 添加测试页面
    if (Config().isDebug) {
      _cacheRoute.add(
        GetPage(
          name: RouteName.testPage,
          page: () => const TestPage(),
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
      }),
    ),
    GetPage(
      name: RouteName.desktopBoarding,
      page: () => DesktopOnboardView(),
      binding: BindingsBuilder(() {
        Get.put(OnBoardingController());
      }),
    ),
    GetPage(
      name: RouteName.login,
      page: () => const LoginView(),
      binding: BindingsBuilder(() {
        Get.put(LoginController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.desktopLoginQR,
      page: () => const DesktopLoginQrView(),
      binding: BindingsBuilder(() {
        Get.put(LoginController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.desktopOthersLogin,
      page: () => const DesktopOthersLoginView(),
      binding: BindingsBuilder(() {
        Get.put(LoginController());
      }),
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
        Get.put(LoginController());
        Get.put(OtpController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.otpInviteView,
      page: () => const OTPInviteView(),
      binding: BindingsBuilder(() {
        Get.put(OtpInviteController());
      }),
      transition: Transition.downToUp,
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
        Get.put(IMDiscoverController());
        Get.put(SettingController());
        Get.put(ContactController());
      }),
      transition: Transition.noTransition,
      middlewares: [HomeGetMiddleware()],
    ),
    GetPage(
        name: RouteName.desktopHome,
        page: () => const DesktopHomeView(),
        binding: BindingsBuilder(() {
          Get.lazyPut(() => CustomPopupMenuController());
          Get.put(HomeController());
          Get.put(ChatListController());
          Get.put(IMDiscoverController());
          Get.put(SettingController());
          Get.put(ContactController());
        }),
        middlewares: [HomeGetMiddleware()]),
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
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
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
        Get.put(UserBioController());
      }),
      transition: Transition.fadeIn,
      popGesture: false,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.languageView,
      page: () => const LanguageView(),
      binding: BindingsBuilder(() {
        Get.put(LanguageController());
      }),
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
      name: RouteName.generalSettings,
      page: () => const GeneralSettingsView(),
      binding: BindingsBuilder(
        () {
          Get.put(GeneralSettingsController());
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
      name: RouteName.momentAvailableDaysSetting,
      page: () => const MomentPrivacyAvailableDaysView(),
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
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.reelProfileView,
      page: () {
        var args = Get.arguments;
        ReelProfileController controller =
            reelNavigationMgr.addProfile(args['userId']);
        return ReelProfileView(
          onBack: args['onBack'],
          controller: controller,
        );
      },
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.reelMyProfileView,
      preventDuplicates: false,
      page: () {
        var args = Get.arguments;
        ReelMyProfileController controller = reelNavigationMgr.addMyProfile();
        if (args['selectedTab'] != null) {
          controller.selectedTab = args['selectedTab'];
        }
        final bool showBack = args['showBack'] ?? true;
        return ReelMyProfileView(
          controller: controller,
          onBack: args['onBack'],
          showBack: showBack,
        );
      },
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.reelFollowFollower,
      page: () {
        final args = Get.arguments;
        return ReelFollowFollowerListView(initTabIndex: args['initTabIndex']);
      },
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
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.reelSearch,
      page: () {
        final args = Get.arguments ?? {};
        final searchTag = args['searchTag'] ?? '';
        ReelTagBackFromEnum? fromTagPage = args['fromTagPage'];
        return ReelSearchView(
          searchTag: searchTag,
          fromTagPage: fromTagPage,
          onBack: args['onBack'],
        );
      },
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
      name: RouteName.moment,
      page: () => const MomentHomeView(),
      binding: BindingsBuilder(
        () {
          Get.put(MomentHomeController());
        },
      ),
      preventDuplicates: false,
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.uploadMoment,
      page: () => const MomentCreateView(),
      binding: BindingsBuilder(
        () {
          Get.put(MomentCreateController());
        },
      ),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.momentDetail,
      page: () => const MomentDetailView(),
      binding: BindingsBuilder(
        () {
          Get.put(MomentDetailController());
        },
      ),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.momentNotification,
      page: () => const MomentNotificationView(),
      binding: BindingsBuilder(
        () {
          Get.put(MomentNotificationController());
        },
      ),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.momentMyPosts,
      page: () => const MomentMyPostsView(),
      binding: BindingsBuilder(
        () {
          final args = Get.arguments;
          Get.put(MomentMyPostsController(userId: args['userId']));
        },
      ),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.momentPermission,
      page: () => const MomentPermissionSelectionView(),
      binding: BindingsBuilder(
        () {
          final args = Get.arguments;
          Get.put(MomentPermissionSelectionController(args["momentVisibility"],
              args["selectFriends"], args["selectLabel"]));
        },
      ),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.tagsManagementPage,
      page: () => const TagsManagementView(),
      binding: BindingsBuilder(() {
        Get.put(TagsManagementController());
      }),
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
      transition: Transition.rightToLeftWithFade,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.fundTransferView,
      page: () => const FundTransferView(),
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
        return const TransferView();
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
        Get.lazyPut(() => QRScannerController());
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
        Get.lazyPut(() => QRCodeViewController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.qrCodeScanner,
      page: () => const QRCodeScanner(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => QRCodeScannerController());
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
      }),
    ),
    GetPage(
      name: RouteName.editSticker,
      page: () => const EditStickerView(),
    ),
    GetPage(
      name: RouteName.chatTransferMoney,
      page: () => const TransferMoney(),
      binding: BindingsBuilder(() {
        Get.put(TransferMoneyController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
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
      page: () => GalleryPage(),
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
      name: RouteName.modifyLimitView,
      page: () => const ModifyLimitView(),
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
      page: () => const ShareChatView(),
      binding: BindingsBuilder(() {
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
          isGroup: args['isGroup'],
        );
      },
      // popGesture: false,
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.translateToView,
      page: () => const TranslateToView(),
      binding: BindingsBuilder(() {
        Get.put(TranslateToController());
      }),
      // popGesture: false,
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.translateSettingView,
      page: () => const TranslateSettingView(),
      binding: BindingsBuilder(() {
        Get.put(TranslateSettingController());
      }),
      // popGesture: false,
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.translateVisualView,
      page: () => const TranslateVisualView(),
      binding: BindingsBuilder(() {
        Get.put(TranslateVisualController());
      }),
      // popGesture: false,
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.experimentView,
      page: () => const ExperimentView(),
      binding: BindingsBuilder(() {
        Get.put(ExperimentController());
      }),
      // popGesture: false,
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.reelMyProfileEdit,
      page: () {
        final args = Get.arguments;
        return ReelMyProfileEdit(controller: args['controller']);
      },
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.reelEditPage,
      page: () {
        final args = Get.arguments;
        return EditProfileView(
          type: args['type'],
        );
      },
      binding: BindingsBuilder(() {
        final args = Get.arguments;
        Get.put(EditProfileController(parentController: args['controller']));
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.settingRecentCall,
      page: () => const CallLogView(),
      binding: BindingsBuilder(() {
        Get.put(CallLogController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.reelMultiManage,
      page: () {
        final args = Get.arguments;
        return ReelMultiManageView(
          profileController: args['controller'],
          type: args['type'],
        );
      },
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.textSelectablePage,
      page: () => const TextSelectablePage(),
      binding: BindingsBuilder(
        () {
          Get.put(TextSelectableController());
        },
      ),
      transition: Transition.noTransition,
      transitionDuration: const Duration(milliseconds: 0),
    ),
    GetPage(
      name: RouteName.soundSelection,
      page: () => const SoundSelectionView(),
      binding: BindingsBuilder(() {
        Get.put(SoundSelectionController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.ringtoneSoundSetting,
      page: () => const RingtoneSoundSetting(),
      binding: BindingsBuilder(() {
        Get.put(RingtoneSoundSettingController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.favouritePage,
      page: () => const FavouriteView(),
      binding: BindingsBuilder(() {
        Get.put(FavouriteController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.editNotePage,
      page: () => const EditNoteView(),
      binding: BindingsBuilder(() {
        Get.put(EditNoteController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.favouriteDetailPage,
      page: () => const FavouriteDetailView(),
      binding: BindingsBuilder(() {
        Get.put(FavouriteDetailController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.favouriteEditTag,
      page: () {
        final args = Get.arguments;
        return FavouriteEditTag(
          tagDataList: args['tagDataList'],
        );
      },
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.encryptionPasswordPage,
      page: () => const EncryptionPasswordView(),
      binding: BindingsBuilder(() {
        Get.put(EncryptionPasswordController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.encryptionPreSetupPage,
      page: () => const EncryptionPreSetupView(),
      binding: BindingsBuilder(() {
        Get.put(EncryptionPreSetupController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.encryptionSetupPage,
      page: () => const EncryptionSetupPasswordView(),
      binding: BindingsBuilder(() {
        Get.put(EncryptionSetupPasswordController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.encryptionVerificationPage,
      page: () => const EncryptionVerificationView(),
      binding: BindingsBuilder(() {
        Get.put(EncryptionVerificationController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.encryptionBackupKeyPage,
      page: () => const EncryptionBackupKeyView(),
      binding: BindingsBuilder(() {
        Get.put(EncryptionBackupKeyController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.encryptionForgetPwPage,
      page: () => const FriendVerifyView(),
      binding: BindingsBuilder(() {
        Get.put(FriendVerifyController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.encryptionPrivateKeySettingPage,
      page: () => const PrivateKeySettingView(),
      binding: BindingsBuilder(() {
        Get.put(PrivateKeySettingController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.encryptionQrCodePage,
      page: () => const EncryptionQrCodeView(),
      binding: BindingsBuilder(() {
        Get.put(EncryptionQrCodeController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.encryptionFriendVerifySettingPage,
      page: () => const FriendVerifySettingView(),
      binding: BindingsBuilder(() {
        Get.put(FriendVerifySettingController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.encryptionFriendVerifyOtherPage,
      page: () => const FriendVerifyOtherView(),
      binding: BindingsBuilder(() {
        Get.put(FriendVerifyOtherController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.encryptionFriendVerifyOtherConfirmPage,
      page: () => const FriendVerifyOtherConfirmView(),
      binding: BindingsBuilder(() {
        Get.put(FriendVerifyOtherConfirmController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.inviteFriends,
      page: () => const InviteFriends(),
      binding: BindingsBuilder(() {
        Get.put(InviteFriendsController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.chatCategoryFolderPage,
      page: () => const ChatCategoryView(),
      binding: BindingsBuilder(() {
        Get.put(ChatCategoryController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: RouteName.networkDiagnose,
      page: () => const NetworkDiagnoseView(),
      binding: BindingsBuilder(() {
        Get.put(NetworkDiagnoseController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    )
  ];

  static Future<void> toChat({
    required Chat chat,
    bool searching = false,
    bool popCurrent = false,
    List<chat_message.Message>? selectedMsgIds,
    bool fromNotification = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));

    if (objectMgr.loginMgr.isDesktop) {
      _toChatDesktop(chat: chat, selectedMsgIds: selectedMsgIds);
    } else {
      _toChat(
        chat: chat,
        searching: searching,
        popCurrent: popCurrent,
        selectedMsgIds: selectedMsgIds,
        fromNotification: fromNotification,
        tryAttempts: 0,
      );
    }
  }

  ///进入聊天
  static Future<void> _toChat({
    required Chat chat,
    bool searching = false,
    bool popCurrent = false,
    List<chat_message.Message>? selectedMsgIds,
    bool fromNotification = false,
    int tryAttempts = 0,
  }) async {
    if (chat.chat_id == 0) {
      if (chat.isGroup) {
        objectMgr.chatMgr.getGroupChatById(chat.id);
      } else {
        objectMgr.userMgr.loadUserById2(chat.id);
      }
      Toast.showToast(localized(chatInfoPleaseTryAgainLater));
      return;
    }
    final bool controllerRegistered =
        Get.isRegistered<ChatContentController>(tag: chat.id.toString());
    if (controllerRegistered && tryAttempts < 3) {
      Future.delayed(
        const Duration(milliseconds: 50),
        () => _toChat(
          chat: chat,
          searching: searching,
          popCurrent: popCurrent,
          selectedMsgIds: selectedMsgIds,
          fromNotification: fromNotification,
          tryAttempts: tryAttempts + 1,
        ),
      );
      return;
    }

    if (tryAttempts >= 3) return;

    if (!popCurrent) Get.until((route) => Get.currentRoute == RouteName.home);
    if (chat.isSingle ||
        chat.typ == chatTypeSmallSecretary ||
        chat.typ == chatTypeSaved ||
        chat.typ == chatTypeSystem) {
      if (popCurrent) {
        Get.off(
          curve: Curves.linear,
          transition: Transition.cupertino,
          duration: const Duration(milliseconds: 200),
          () => SingleChatView(
            key: ValueKey(chat.id.toString()),
            tag: chat.id.toString(),
          ),
          routeName: 'chat/private_chat/${chat.id.toString()}',
          arguments: {
            'chat': chat,
          },
          binding: BindingsBuilder(() {
            Get.put(SingleChatController(), tag: chat.id.toString())
                .isSearching(searching);
            Get.put(CustomInputController(), tag: chat.id.toString());
            Get.put(ChatContentController(), tag: chat.id.toString());
          }),
          popGesture: true,
          preventDuplicates: false,
        );
      } else {
        if (Platform.isIOS) {
          Get.key.currentState!.push(
            SwipeCustomPageRoute(
              curve: Curves.linear,
              transitionDuration: const Duration(milliseconds: 450),
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
                  'fromNotification': fromNotification,
                },
              ),
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
            curve: Curves.linear,
            transition: Transition.rightToLeft,
            duration: const Duration(milliseconds: 250),
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
              'fromNotification': fromNotification,
            },
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
            curve: Curves.linear,
            transitionDuration: const Duration(milliseconds: 450),
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
              },
            ),
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
          curve: Curves.linear,
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 250),
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
          },
          binding: BindingsBuilder(() {
            Get.put(GroupChatController(), tag: chat.id.toString())
                .isSearching(searching);
            Get.put(CustomInputController(), tag: chat.id.toString());
            Get.put(ChatContentController(), tag: chat.id.toString());
          }),
          preventDuplicates: false,
        );
      }
    }else if(chat.isChatTypeMiniApp){
      ///小程序
      if (Platform.isIOS) {
        Get.key.currentState!.push(
          SwipeCustomPageRoute(
            curve: Curves.linear,
            transitionDuration: const Duration(milliseconds: 450),
            opaque: true,
            page: () => GroupChatMiniAppView(
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
                'fromNotification': fromNotification,
              },
            ),
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
          curve: Curves.linear,
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 250),
              () => GroupChatMiniAppView(
            key: ValueKey(chat.id.toString()),
            tag: chat.id.toString(),
          ),
          routeName: 'chat/private_chat/${chat.id.toString()}',
          arguments: {
            'chat': chat,
            'selectedMsgIds': selectedMsgIds,
            'isGroup': chat.isGroup,
            'uid': chat.friend_id,
            'fromNotification': fromNotification,
          },
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
    objectMgr.pushMgr.cancelExcludeIncomingCall();
  }

  static void _toChatDesktop({
    required Chat chat,
    List<chat_message.Message>? selectedMsgIds,
  }) {
    if (Get.find<ChatListController>().desktopSelectedChatID.value == chat.id &&
        selectedMsgIds == null) {
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
      if (controllerRegistered && selectedMsgIds == null) {
        return;
      }
    }
    if (chat.isSingle || chat.isSaveMsg || chat.isSystem) {
      final bool controllerRegistered =
          Get.isRegistered<SingleChatController>(tag: chat.id.toString());
      if (controllerRegistered && selectedMsgIds == null) {
        return;
      }
    }

    if (chat.isSingle ||
        chat.typ == chatTypeSmallSecretary ||
        chat.typ == chatTypeSaved ||
        chat.typ == chatTypeSystem) {
      Get.offAllNamed(RouteName.desktopChatEmptyView, id: 1);
      Get.toNamed(
        '/singleChat',
        arguments: {
          'chat': chat,
          'selectedMsgIds': selectedMsgIds,
        },
        id: 1,
      );
    } else if (chat.isGroup) {
      Get.offAllNamed(RouteName.desktopChatEmptyView, id: 1);
      Get.toNamed(
        '/groupChat',
        arguments: {
          'chat': chat,
          'selectedMsgIds': selectedMsgIds,
        },
        id: 1,
      );
    }
    objectMgr.pushMgr.cancelExcludeIncomingCall();
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
