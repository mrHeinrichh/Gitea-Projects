import 'package:cashier/im_cashier.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/enums/enum.dart';

Future<Map<String, String>> goSecondVerification({
  bool phoneAuth = false,
  bool emailAuth = false,
}) async {
  Map<String, String> tokenMap = {};
  sharedDataManager.currentUserEmail = objectMgr.userMgr.mainUser.email;
  sharedDataManager.currentUserCountryCode =
      objectMgr.userMgr.mainUser.countryCode;
  sharedDataManager.currentUserContact = objectMgr.userMgr.mainUser.contact;
  if (phoneAuth && emailAuth) {
    /// 手机认证
    var resultMap1 = await Get.toNamed(
      CashierRoutes.phoneSecondaryAuthView,
      arguments: {
        'from_view': OtpPageType.secondVerification.page,
        "phoneAuth": true,
      },
    );
    if (resultMap1 != null && resultMap1 is Map<String, dynamic>) {
      tokenMap['phoneToken'] = resultMap1['token'];
    } else {
      return {};
    }
    await Future.delayed(const Duration(milliseconds: 100));

    /// 邮箱验证码
    var resultMap2 = await Get.toNamed(
      CashierRoutes.emailSecondaryAuthView,
      arguments: {
        'from_view': OtpPageType.secondVerification.page,
        'emailAuth': true,
      },
    );
    if (resultMap2 != null && resultMap2 is Map<String, dynamic>) {
      tokenMap['emailToken'] = resultMap2['token'];
    } else {
      return {};
    }
  } else {
    if (phoneAuth) {
      var resultMap = await Get.toNamed(
        CashierRoutes.phoneSecondaryAuthView,
        arguments: {
          'from_view': OtpPageType.secondVerification.page,
          "phoneAuth": true,
        },
      );
      if (resultMap != null && resultMap is Map<String, dynamic>) {
        tokenMap['phoneToken'] = resultMap['token'];
      }
    } else {
      var resultMap = await Get.toNamed(
        CashierRoutes.emailSecondaryAuthView,
        arguments: {
          'from_view': OtpPageType.secondVerification.page,
          'emailAuth': true,
        },
      );
      if (resultMap != null && resultMap is Map<String, dynamic>) {
        tokenMap['emailToken'] = resultMap['token'];
      }
    }
  }
  return tokenMap;
}

void showTip() {
  showWarningToast("验证码发送失败");
}
