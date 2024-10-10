import 'package:flutter/material.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/new_appbar.dart';

import 'package:jxim_client/home/component/custom_divider.dart';

class TermServiceBottomSheet extends StatefulWidget {
  const TermServiceBottomSheet({
    super.key,
    required this.agreeCallback,
    required this.declineCallback,
  });

  final Function() agreeCallback;
  final Function() declineCallback;

  @override
  TermServiceBottomSheetState createState() => TermServiceBottomSheetState();
}

class TermServiceBottomSheetState extends State<TermServiceBottomSheet> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        top: 12,
        bottom: 16,
      ),
      height: MediaQuery.of(context).size.height * 0.95,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 26,
            child: NavigationToolbar(
              leading: SizedBox(
                width: 74,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => Navigator.of(context).pop(),
                  child: const CustomLeadingIcon(),
                ),
              ),
              middle: Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  localized(termOfService),
                  style: jxTextStyle.textStyleBold17(),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 12.0, bottom: 8.0),
            child: CustomDivider(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        localized(
                          termServiceMain,
                          params: [Config().appName, Config().appName],
                        ),
                        style: jxTextStyle.textStyle12(
                          color: colorTextSecondary,
                        ),
                      ),
                    ),

                    /// content 1
                    Container(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              localized(termServiceTitle1),
                              style: jxTextStyle.textStyleBold12(),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              localized(termServiceContent1),
                              style: jxTextStyle.textStyle12(
                                color: colorTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// content 2
                    Container(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              localized(termServiceTitle2),
                              style: jxTextStyle.textStyleBold12(),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              localized(termServiceContent2),
                              style: jxTextStyle.textStyle12(
                                color: colorTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// content 3
                    Container(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              localized(termServiceTitle3),
                              style: jxTextStyle.textStyleBold12(),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              localized(
                                termServiceContent3,
                                params: [Config().appName],
                              ),
                              style: jxTextStyle.textStyle12(
                                color: colorTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// content 4
                    Container(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              localized(termServiceTitle4),
                              style: jxTextStyle.textStyleBold12(),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              localized(termServiceContent4),
                              style: jxTextStyle.textStyle12(
                                color: colorTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// content 5
                    Container(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              localized(termServiceTitle5),
                              style: jxTextStyle.textStyleBold12(),
                            ),
                          ),
                          Text(
                            localized(termServiceContent5),
                            style: jxTextStyle.textStyle12(
                              color: colorTextSecondary,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                "\u2022",
                                style: jxTextStyle.textStyle12(
                                  color: colorTextSecondary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  localized(termServiceContent51),
                                  style: jxTextStyle.textStyle12(
                                    color: colorTextSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                "\u2022",
                                style: jxTextStyle.textStyle12(
                                  color: colorTextSecondary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  localized(termServiceContent52),
                                  style: jxTextStyle.textStyle12(
                                    color: colorTextSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                "\u2022",
                                style: jxTextStyle.textStyle12(
                                  color: colorTextSecondary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  localized(termServiceContent53),
                                  style: jxTextStyle.textStyle12(
                                    color: colorTextSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    /// content 6
                    Container(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              localized(termServiceTitle6),
                              style: jxTextStyle.textStyleBold12(),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              localized(termServiceContent6),
                              style: jxTextStyle.textStyle12(
                                color: colorTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// content 7
                    Container(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              localized(termServiceTitle7),
                              style: jxTextStyle.textStyleBold12(),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              localized(termServiceContent7),
                              style: jxTextStyle.textStyle12(
                                color: colorTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// content 8
                    Container(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              localized(termServiceTitle8),
                              style: jxTextStyle.textStyleBold12(),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              localized(termServiceContent8),
                              style: jxTextStyle.textStyle12(
                                color: colorTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// content 9
                    Container(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              localized(termServiceTitle9),
                              style: jxTextStyle.textStyleBold12(),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              localized(
                                termServiceContent9,
                                params: [Config().appName],
                              ),
                              style: jxTextStyle.textStyle12(
                                color: colorTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// content 10
                    Container(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              localized(termServiceTitle10),
                              style: jxTextStyle.textStyleBold12(),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              localized(termServiceContent10),
                              style: jxTextStyle.textStyle12(
                                color: colorTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// content 11
                    Container(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          localized(
                            termServiceContent11,
                            params: [Config().email],
                          ),
                          style: jxTextStyle.textStyle12(
                            color: colorTextSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              top: 12.0,
              bottom: MediaQuery.of(context).padding.bottom,
              left: 16,
              right: 16,
            ),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colorBorder,
                  width: 0.75,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorBorder,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: const BorderSide(color: colorBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      splashFactory: NoSplash.splashFactory,
                      animationDuration: const Duration(milliseconds: 1),
                    ),
                    onPressed: () => widget.declineCallback(),
                    child: Text(
                      localized(buttonDecline),
                      style: jxTextStyle
                          .textStyleBold16(
                            color: colorTextPrimary,
                            fontWeight: MFontWeight.bold6.value,
                          )
                          .copyWith(height: 1.2),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      elevation: 0,
                      foregroundColor: colorBorder,
                      backgroundColor: themeColor,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      splashFactory: NoSplash.splashFactory,
                      animationDuration: const Duration(milliseconds: 1),
                    ),
                    onPressed: () => widget.agreeCallback(),
                    child: Text(
                      localized(buttonAgree),
                      style: jxTextStyle
                          .textStyleBold16(
                            color: colorWhite,
                            fontWeight: MFontWeight.bold6.value,
                          )
                          .copyWith(height: 1.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
