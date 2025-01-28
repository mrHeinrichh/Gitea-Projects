import 'package:flutter/material.dart';
import 'package:im_common/im_common.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

import '../../object/wallet/currency_model.dart';
import '../../utils/color.dart';

import '../../utils/theme/text_styles.dart';
import '../component/no_record_state.dart';

import 'components/recipient_address_tile.dart';
import 'controller/withdraw_controller.dart';
import 'package:get/get.dart';

class WithdrawRecipientBookView extends GetWidget<WithdrawController> {
  const WithdrawRecipientBookView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: backgroundColor,
        centerTitle: false,
        elevation: 0.0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: Get.back,
          ),
        ),
        title: Text(
          localized(walletAddressesBook),
          style: TextStyle(
            fontWeight: MFontWeight.bold6.value,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: JXColors.lightGrey),
              ),
            ),
            alignment: Alignment.centerLeft,
            child: TabBar(
              isScrollable: true,
              controller: controller.tabController,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              labelColor: accentColor,
              labelPadding: const EdgeInsets.symmetric(
                horizontal: 8,
              ),
              indicatorSize: TabBarIndicatorSize.label,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(width: 2, color: accentColor),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              unselectedLabelColor: JXColors.secondaryTextBlack,
              tabs: List.generate(controller.tabController.length, (index) {
                final CurrencyModel currency =
                    controller.cryptoCurrencyList[index];
                return Tab(
                  height: kToolbarHeight + 5,
                  child: Column(
                    children: <Widget>[
                      Image.network(
                        '${currency.iconPath}',
                        width: 30,
                        height: 30,
                        errorBuilder: (_, __, ___) {
                          return Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: Color(
                                0xffF6F6F6,
                              ),
                              shape: BoxShape.circle,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 5),
                      Text(
                        currency.currencyType ?? '',
                        style: const TextStyle(),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Obx(
          () => Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: JXColors.lightGrey),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10.0,
                  ),
                  height: 50,
                  child: TextField(
                    contextMenuBuilder: textMenuBar,
                    controller: controller.filterRecipientController,
                    onChanged: controller.filterRecipient,
                    onSubmitted: controller.submitRecipient,
                    decoration: InputDecoration(
                      hintText: localized(hintSearch),
                      hintStyle: const TextStyle(
                        color: JXColors.mutedDarkPurple,
                        fontSize: 16,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: JXColors.mutedDarkPurple,
                        size: 20,
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () {
                          controller.filterRecipientController.clear();
                          controller.submitRecipient('');
                        },
                        child: const Icon(
                          Icons.close,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10.0,
                      ),
                      filled: true,
                      fillColor: offWhite,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(
                          color: JXColors.lightGrey,
                          width: 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(
                          color: JXColors.lightGrey,
                          width: 1.0,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(
                          color: JXColors.lightGrey,
                          width: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: DefaultTabController(
                  length: controller.cryptoCurrencyList.length,
                  child: Column(
                    children: [
                      Expanded(
                        child: CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: Container(
                                margin: const EdgeInsets.all(16.0),
                                height: 40.0,
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  scrollDirection: Axis.horizontal,
                                  itemCount: controller
                                      .recipientSelectedCurrency
                                      .value
                                      ?.supportNetType
                                      ?.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    final type = controller
                                        .recipientSelectedCurrency
                                        .value
                                        ?.supportNetType?[index];
                                    return GestureDetector(
                                      onTap: () =>
                                          controller.selectNetwork(type),
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(right: 8.0),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0,
                                          vertical: 12.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: controller
                                                      .recipientSelectedCurrency
                                                      .value
                                                      ?.netType ==
                                                  type
                                              ? accentColor
                                              : JXColors.outlineColor,
                                          borderRadius:
                                              BorderRadius.circular(1000000),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          type,
                                          style: TextStyle(
                                            color: controller
                                                        .recipientSelectedCurrency
                                                        .value
                                                        ?.netType ==
                                                    type
                                                ? JXColors.white
                                                : const Color(0x99121212),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            controller.filterRecipientAddressList.isEmpty
                                ? const SliverToBoxAdapter(
                                    child: NoRecordState())
                                : SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (BuildContext _, int index) {
                                        final recipientAddress = controller
                                            .filterRecipientAddressList[index];
                                        return RecipientAddressTile(
                                          address: recipientAddress,
                                          isSelected: controller
                                                  .withdrawModel.addrID ==
                                              controller
                                                  .filterRecipientAddressList[
                                                      index]
                                                  .addrID,
                                        );
                                      },
                                      childCount: controller
                                          .filterRecipientAddressList.length,
                                    ),
                                  ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
