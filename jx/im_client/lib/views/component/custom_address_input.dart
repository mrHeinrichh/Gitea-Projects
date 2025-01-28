import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/object/wallet/address_model.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/custom_image.dart';
import 'package:jxim_client/views/wallet/controller/withdraw_controller.dart';
import 'package:jxim_client/views/wallet/recipient_address_book_bottom_sheet.dart';

class CustomAddressInput extends StatefulWidget {
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final void Function(String)? onChanged;
  final void Function(String)? onAddressChanged;
  final void Function()? onTapInput;
  final void Function()? onAddressInput;
  final void Function()? onScanInput;
  final void Function()? onTapClearButton;
  final String? title;
  final String? hintText;
  final String? netType;
  final bool withAddressField;
  final bool isEnabled;
  final bool readOnly;
  final int? maxLines;

  const CustomAddressInput({
    super.key,
    required this.controller,
    this.focusNode,
    this.onChanged,
    this.onAddressChanged,
    this.title,
    this.netType,
    this.onTapInput,
    this.onTapClearButton,
    this.withAddressField = true,
    this.onAddressInput,
    this.onScanInput,
    this.isEnabled = true,
    this.readOnly = false,
    this.keyboardType,
    this.maxLines,
    this.hintText,
  });
  @override
  State<CustomAddressInput> createState() => _CustomAddressInputState();
}

class _CustomAddressInputState extends State<CustomAddressInput> {
  late WithdrawController controller = WithdrawController();
  bool _hasFocus = false;

  @override
  void initState() {
    widget.controller.addListener(_updateClearIconVisibility);
    Get.put(WithdrawController());
    super.initState();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateClearIconVisibility);
    super.dispose();
  }

  void _updateClearIconVisibility() => setState(() {});

  Future showAddressBookBottomSheet(BuildContext context) {
    final controller = this.controller.getRecipientController();

    controller.getRecipientAddressList(
      currencyType: 'USDT',
      netType: widget.netType,
    );

    return showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) => const RecipientAddressBookBottomSheet(),
    ).then(
      (value) {
        controller.clearSearch();
        return value;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() => _hasFocus = hasFocus);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(),
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextfield(),
                _buildIcons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, left: 16),
      child: Text(
        widget.title ?? '',
        style: jxTextStyle.textStyle13(
          color: colorTextSecondary,
        ),
      ),
    );
  }

  Widget _buildTextfield() {
    return Expanded(
      child: TextFormField(
        readOnly: widget.readOnly,
        onTap: widget.onTapInput,
        contextMenuBuilder: textMenuBar,
        cursorColor: themeColor,
        textInputAction: TextInputAction.done,
        keyboardType: widget.keyboardType,
        controller: widget.controller,
        focusNode: widget.focusNode,
        onChanged: widget.onChanged,
        enabled: widget.isEnabled,
        style: jxTextStyle.textStyle16(color: colorTextPrimary),
        maxLines: widget.maxLines ?? 2,
        minLines: 1,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.zero,
          hintText: widget.hintText ?? localized(addressAddressHint),
          hintStyle: jxTextStyle.textStyle17(color: colorTextPlaceholder),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildIcons() {
    return Row(
      children: [
        if (widget.controller.text.isNotEmpty && _hasFocus)
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: CustomImage(
              'assets/svgs/close_round_icon.svg',
              size: 20,
              color: colorTextSecondary,
              onClick: () {
                widget.controller.clear();
                if (widget.onTapClearButton != null) {
                  widget.onTapClearButton!();
                }
              },
            ),
          ),
        if (widget.withAddressField)
          Padding(
            padding: const EdgeInsets.only(right: 12.0, left: 12),
            child: CustomImage(
              'assets/svgs/wallet/contact1.svg',
              size: 24,
              color: colorTextPrimary,
              onClick: widget.onAddressInput ??
                  () async {
                    showAddressBookBottomSheet(context).then((value) {
                      if (value is AddressModel) {
                        widget.onAddressChanged?.call(value.address);
                      }
                    });
                  },
            ),
          ),
        if (widget.isEnabled)
          CustomImage(
            'assets/svgs/wallet/scan1.svg',
            size: 24,
            color: colorTextPrimary,
            onClick: widget.onScanInput ??
                () async {
                  Get.find<ChatListController>().scanQRCode(
                    didGetText: (text) {
                      widget.onAddressChanged?.call(text);
                      widget.focusNode?.unfocus();
                    },
                  );
                },
          ),
      ],
    );
  }
}
