import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/wallet/address_model.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/wallet/address/book/wallet_address_book_controller.dart';
import 'package:jxim_client/views/wallet/address/book/wallet_address_edit_page_argument.dart';

import '../../../component/check_tick_item.dart';

class WalletAddressBookPage extends GetView<WalletAddressBookController> {
  const WalletAddressBookPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: backgroundColor,
        appBar: PrimaryAppBar(
          title: '地址薄',
          trailing: [
            Visibility(
              visible: controller.hasData,
              child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: controller.setEditMode,
                    child: Text(
                      controller.isEditMode ? '完成' : '编辑',
                      style: TextStyle(
                        fontSize: objectMgr.loginMgr.isDesktop
                            ? MFontSize.size13.value
                            : MFontSize.size17.value,
                        color: accentColor,
                        height: 1.2,
                      ),
                    ),
                  )),
            )
          ],
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: controller.hasData
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: ImBorderRadius.borderRadius8,
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: controller.addressList.length,
                            itemBuilder: (ctx, index) {
                              final model = controller.addressList[index];
                              return WalletAddressBookItem(
                                model: model,
                                onRightArrowTap: controller.isEditMode
                                    ? null
                                    : () {
                                        Get.toNamed(
                                          RouteName.addressEditView,
                                          arguments: WalletAddressArguments(
                                            addrName: model.addrName,
                                            addrID: model.addrID,
                                            address: model.address,
                                            netType: model.netType,
                                          ).toJson(),
                                        );
                                      },
                                enableCheckBtn: controller.isEditMode,
                              );
                            },
                            separatorBuilder:
                                (BuildContext context, int index) => Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: Divider(
                                color: ImColor.black20,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: const EmptyWidget(
                        title: '暂无地址',
                        subTitle: '将常用地址保存在地址博,可以在将来直接使用!',
                      ),
                    ),
            ),
            if (!controller.isEditMode)
              Padding(
                padding: const EdgeInsets.all(16),
                child: PrimaryButton(
                  fontSize: 16,
                  bgColor: accentColor,
                  title: '添加新地址',
                  width: double.infinity,
                  onPressed: () {
                    Get.toNamed(RouteName.addressEditView);
                  },
                ),
              ),
            // editMode
            if (controller.isEditMode)
              Container(
                height: 49.w,
                decoration: const BoxDecoration(
                  border:
                      Border(top: BorderSide(color: Colors.grey, width: 0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                          onTap: () {
                            controller.addSelectedAll();
                          },
                          child: ImText(
                            '全选',
                            fontSize: 17,
                            color: ImColor.accentColor,
                          )),
                      GestureDetector(
                        onTap: controller.onDeleteAddress,
                        child: ImText(
                          '删除',
                          fontSize: 17,
                          color: false ? ImColor.black48 : ImColor.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class WalletAddressBookItem extends StatelessWidget {
  WalletAddressBookItem({
    super.key,
    required this.model,
    this.enableCheckBtn = false,
    this.onRightArrowTap,
    this.rightWidget,
  });

  final AddressModel model;
  final bool enableCheckBtn;
  final Function? onRightArrowTap;
  final Widget? rightWidget;

  @override
  Widget build(BuildContext context) {
    final tokenType = model.addrName;
    final tokenTypePrefix = model.netType;
    final tokenAddress = model.address;
    final controller = Get.find<WalletAddressBookController>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Row(
              children: [
                Visibility(
                  visible: enableCheckBtn,
                  child: Obx(
                    () => ClipRRect(
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 350),
                        alignment: Alignment.centerLeft,
                        curve: Curves.easeInOutCubic,
                        child: GestureDetector(
                          onTap: () {
                            final value =
                                controller.selectedAddressList.contains(model);
                            if (!value) {
                              controller.addSelected(model);
                            } else {
                              controller.removeSelected(model);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.only(right: 8),
                            child: CheckTickItem(
                              isCheck: controller.selectedAddressList.contains(model),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          ImText(
                            tokenType,
                          ),
                          ImGap.hGap4,
                          Container(
                              decoration: BoxDecoration(
                                  color: ImColor.grey4,
                                  borderRadius: ImBorderRadius.borderRadius4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              child: ImText(
                                tokenTypePrefix,
                                color: ImColor.black48,
                                fontWeight: MFontWeight.bold5.value,
                                fontSize: ImFontSize.small,
                              )),
                        ],
                      ),
                      ImGap.vGap4,
                      ImText(
                        tokenAddress,
                        color: ImColor.black48,
                        fontSize: ImFontSize.small,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ...[
            if (rightWidget != null) rightWidget!,
            if (onRightArrowTap != null)
              GestureDetector(
                onTap: () {
                  onRightArrowTap!();
                },
                child: ImSvgIcon(
                  icon: 'icon_arrow_right',
                  color: ImColor.black48,
                ),
              ),
          ]
        ],
      ),
    );
  }

  Column buildWalletAddressSideCurrency({payment, total}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ImText(
          payment,
          color: ImColor.green,
          fontSize: ImFontSize.small,
        ),
        ImGap.vGap4,
        ImText(
          total,
          color: ImColor.black48,
          fontSize: ImFontSize.small,
        )
      ],
    );
  }
}
