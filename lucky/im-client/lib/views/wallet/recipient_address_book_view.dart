import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/object/wallet/address_model.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/no_record_state.dart';

import '../../object/wallet/currency_model.dart';
import '../../utils/color.dart';
import 'package:get/get.dart';

import '../../utils/theme/text_styles.dart';
import '../../utils/utility.dart';
import '../component/new_appbar.dart';
import 'controller/recipient_address_book_controller.dart';

class RecipientAddressBookView extends GetView<RecipientAddressBookController> {
  const RecipientAddressBookView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RecipientAddressBookController>(
      init: controller,
      builder: (_) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: PrimaryAppBar(
            title: localized(walletAddressesBook),
            trailing: [
              GestureDetector(
                onTap: () async {
                  final result = await Get.toNamed(
                    RouteName.addAddressView,
                    arguments: {
                      'crypto': controller.selectedCurrency.value,
                      'chain': '${controller.selectedChain.value}',
                    },
                  );
                  if (result is AddressModel) {
                    controller.addRecipient(result);
                    Toast.showToast(localized(walletAddAddressSuccess));

                    final index = controller.cryptoCurrencyList.indexWhere(
                        (element) =>
                            element.currencyType == result.currencyType);

                    controller.tabController.index = index;
                    controller.selectChain(result.netType);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SvgPicture.asset(
                    'assets/svgs/add.svg',
                    width: 24,
                    height: 24,
                    color: JXColors.primaryTextBlack,
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  border: const Border(
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
              Container(
                margin: const EdgeInsets.all(16.0),
                height: 40.0,
                child: Obx(
                  () => ListView.builder(
                    padding: EdgeInsets.zero,
                    scrollDirection: Axis.horizontal,
                    itemCount: controller
                        .selectedCurrency.value.supportNetType?.length,
                    itemBuilder: (BuildContext context, int index) {
                      final type = controller
                          .selectedCurrency.value.supportNetType?[index];
                      return Obx(
                        () => GestureDetector(
                          onTap: () => controller.selectChain(type),
                          child: Container(
                            margin: const EdgeInsets.only(right: 16.0),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                            decoration: BoxDecoration(
                              color: controller.selectedChain.value == type
                                  ? accentColor
                                  : JXColors.outlineColor,
                              borderRadius: BorderRadius.circular(1000000),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              type,
                              style: TextStyle(
                                color: controller.selectedChain == type
                                    ? JXColors.white
                                    : JXColors.secondaryTextBlack,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Obx(
                () => AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: controller.isMultiSelect.value
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild: Container(
                    color: backgroundColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 10.0,
                    ),
                    child: Row(
                      children: <Widget>[
                        GestureDetector(
                          onTap: () {
                            controller.isMultiSelect.value = false;
                            controller.selectedAddressList.clear();
                          },
                          child: const Icon(Icons.close, size: 24.0),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Text(
                            controller.selectedAddressList.length.toString(),
                            style: TextStyle(
                              fontWeight: MFontWeight.bold5.value,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => controller.showDeletePrompt(context),
                          child: Image.asset(
                            'assets/images/home/search_delete.png',
                            width: 24.0,
                            height: 24.0,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  secondChild: controller.allRecipientList.isNotEmpty
                      ? Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16.0),
                          decoration: BoxDecoration(
                            color: JXColors.outlineColor,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          height: 40,
                          child: Center(
                            child: TextField(
                              contextMenuBuilder: textMenuBar,
                              controller: controller.filterRecipientController,
                              onChanged: controller.filterRecipient,
                              onSubmitted: controller.submitRecipient,
                              decoration: InputDecoration(
                                hintText: localized(hintSearch),
                                isDense: true,
                                hintStyle: const TextStyle(
                                  color: JXColors.supportingTextBlack,
                                  fontSize: 16,
                                ),
                                prefixIconConstraints:
                                    const BoxConstraints(maxHeight: 40),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: SvgPicture.asset(
                                    'assets/svgs/Search.svg',
                                    width: 20,
                                    height: 20,
                                    color: JXColors.supportingTextBlack,
                                  ),
                                ),
                                contentPadding: EdgeInsets.zero,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: BorderSide.none,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(),
                ),
              ),
              Obx(
                () => controller.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : Expanded(
                        child: controller.allRecipientList.isNotEmpty
                            ? controller.filterRecipientAddressList.isNotEmpty
                                ? Container(
                                    margin: const EdgeInsets.only(
                                      left: 16.0,
                                      right: 4,
                                    ),
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: ListView.builder(
                                      itemCount: controller
                                          .filterRecipientAddressList.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        final model = controller
                                            .filterRecipientAddressList[index];
                                        return GestureDetector(
                                          onTap: () =>
                                              controller.onTapAddress(model),
                                          onLongPress: () => controller
                                              .onLongPressAddress(model),
                                          child: AddressItem(
                                            model: model,
                                            controller: controller,
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : const NoRecordState()
                            : Container(
                                child: Column(
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 20.0),
                                      child: Image.asset(
                                        'assets/images/common/empty_address_book.png',
                                        width: 148,
                                        height: 148,
                                      ),
                                    ),
                                    Text(
                                      localized(walletAddAddress),
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: MFontWeight.bold5.value,
                                      ),
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      localized(walletAddAddressContent),
                                      style: const TextStyle(
                                        fontSize: 12.0,
                                        color: JXColors.secondaryTextBlack,
                                      ),
                                    ),
                                    const SizedBox(height: 16.0),
                                    GestureDetector(
                                      onTap: () async {
                                        final result = await Get.toNamed(
                                          RouteName.addAddressView,
                                          arguments: {
                                            'crypto': controller
                                                .selectedCurrency.value,
                                            'chain':
                                                '${controller.selectedChain.value}',
                                          },
                                        );
                                        if (result is AddressModel) {
                                          controller.addRecipient(result);
                                          Toast.showToast(localized(
                                              walletAddAddressSuccess));

                                          final index = controller
                                              .cryptoCurrencyList
                                              .indexWhere((element) =>
                                                  element.currencyType ==
                                                  result.currencyType);

                                          controller.tabController.index =
                                              index;
                                          controller
                                              .selectChain(result.netType);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24.0,
                                          vertical: 17.0,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: JXColors.lightGrey,
                                            width: 1.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                        ),
                                        child: Text(
                                          localized(walletAddAddress),
                                          style: TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: MFontWeight.bold5.value,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
              )
            ],
          ),
        );
      },
    );
  }
}

class AddressItem extends StatelessWidget {
  final RecipientAddressBookController controller;
  final AddressModel model;

  const AddressItem({
    super.key,
    required this.model,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8.0),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: JXColors.lightGrey, width: 1.0),
        ),
      ),
      child: Row(
        children: <Widget>[
          Obx(() {
            if (controller.isMultiSelect.value) {
              return Checkbox(
                value: controller.selectedAddressList.contains(model),
                onChanged: (bool? _) => controller.onTapAddress(model),
                checkColor: Colors.white,
                fillColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return accentColor;
                  }
                  return accentColor;
                }),
                side: MaterialStateBorderSide.resolveWith(
                    (Set<MaterialState> states) {
                  return const BorderSide(
                      width: 1.5, color: JXColors.outlineColor);
                }),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              );
            } else {
              return const SizedBox();
            }
          }),
          Expanded(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOutCubic,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      model.addrName,
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight:MFontWeight.bold6.value,
                        color: JXColors.black,
                        letterSpacing: 0.15,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    model.address,
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: JXColors.secondaryTextBlack,
                      letterSpacing: 0.25,
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => copyToClipboard(model.address),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: SvgPicture.asset(
                'assets/svgs/wallet/Copy.svg',
                width: 24,
                height: 24,
                color: JXColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
