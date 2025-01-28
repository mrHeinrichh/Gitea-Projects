import 'package:flutter/material.dart';
import 'package:jxim_client/views_desktop/component/desktop_custom_dialog.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class DesktopTermServiceDialog extends StatelessWidget {
  final void Function()? agreeCallBack;

  const DesktopTermServiceDialog({
    super.key,
    this.agreeCallBack,
  });

  @override
  Widget build(BuildContext context) {
    return DesktopCustomDialog(
      title: localized(termOfService),
      buttonName: localized(termsReadAgreement),
      buttonClick: agreeCallBack,
      height: MediaQuery.of(context).size.height * 0.92,
      boxConstraints: const BoxConstraints(maxHeight: 500),
      contentWidget: _buildContent(),
    );
  }

  Widget _buildContent(){
    return Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
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
                  style: jxTextStyle.supportText(
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
                        style: jxTextStyle.supportText(
                          fontWeight: MFontWeight.bold5.value,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        localized(termServiceContent1),
                        style: jxTextStyle.supportText(
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
                        style: jxTextStyle.supportText(
                          fontWeight: MFontWeight.bold5.value,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        localized(termServiceContent2),
                        style: jxTextStyle.supportText(
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
                        style: jxTextStyle.supportText(
                          fontWeight: MFontWeight.bold5.value,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        localized(
                          termServiceContent3,
                          params: [Config().appName],
                        ),
                        style: jxTextStyle.supportText(
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
                        style: jxTextStyle.supportText(
                          fontWeight: MFontWeight.bold5.value,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        localized(termServiceContent4),
                        style: jxTextStyle.supportText(
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
                        style: jxTextStyle.supportText(
                          fontWeight: MFontWeight.bold5.value,
                        ),
                      ),
                    ),
                    Text(
                      localized(termServiceContent5),
                      style: jxTextStyle.supportText(
                        color: colorTextSecondary,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          "\u2022",
                          style: jxTextStyle.supportText(
                            color: colorTextSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            localized(termServiceContent51),
                            style: jxTextStyle.supportText(
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
                          style: jxTextStyle.supportText(
                            color: colorTextSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            localized(termServiceContent52),
                            style: jxTextStyle.supportText(
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
                          style: jxTextStyle.supportText(
                            color: colorTextSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            localized(termServiceContent53),
                            style: jxTextStyle.supportText(
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
                        style: jxTextStyle.supportText(
                          fontWeight: MFontWeight.bold5.value,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        localized(termServiceContent6),
                        style: jxTextStyle.supportText(
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
                        style: jxTextStyle.supportText(
                          fontWeight: MFontWeight.bold5.value,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        localized(termServiceContent7),
                        style: jxTextStyle.supportText(
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
                        style: jxTextStyle.supportText(
                          fontWeight: MFontWeight.bold5.value,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        localized(termServiceContent8),
                        style: jxTextStyle.supportText(
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
                        style: jxTextStyle.supportText(
                          fontWeight: MFontWeight.bold5.value,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        localized(
                          termServiceContent9,
                          params: [Config().appName],
                        ),
                        style: jxTextStyle.supportText(
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
                        style: jxTextStyle.supportText(
                          fontWeight: MFontWeight.bold5.value,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        localized(termServiceContent10),
                        style: jxTextStyle.supportText(
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
                    style: jxTextStyle.supportText(
                      color: colorTextSecondary,
                    ),
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
