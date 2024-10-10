import 'package:country_list_pick/support/code_country.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/managers/object_mgr.dart';

class CountryPicker extends StatelessWidget {
  final TextEditingController countryController;
  final Function(String value) searchCountry;
  final Function(int index) selectCountry;
  final List<Country> updatedCountryList;

  const CountryPicker({
    super.key,
    required this.countryController,
    required this.searchCountry,
    required this.selectCountry,
    required this.updatedCountryList,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 16,
            ),
            child: Container(
              height: 36,
              decoration: const BoxDecoration(
                color: colorBorder,
                borderRadius: BorderRadius.all(
                  Radius.circular(12),
                ),
              ),
              child: TextFormField(
                contextMenuBuilder: textMenuBar,
                controller: countryController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: UnconstrainedBox(
                    child: SvgPicture.asset(
                      'assets/svgs/Search_thin.svg',
                      height: 25,
                      width: 25,
                      colorFilter: const ColorFilter.mode(
                        colorTextSupporting,
                        BlendMode.srcIn,
                      ),
                      //fit: BoxFit.,
                    ),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  hintText: localized(searchCountryText),
                  hintStyle: const TextStyle(
                    color: colorTextSupporting,
                  ),
                ),
                cursorColor: themeColor,
                textAlignVertical: TextAlignVertical.center,
                style: jxTextStyle.textStyle16(),
                onChanged: (value) {
                  searchCountry(value);
                },
              ),
            ),
          ),
          const Divider(
            height: 5,
            thickness: 1,
            color: colorBorder,
          ),
          Expanded(
            flex: 6,
            child: Obx(
              () => ListView.separated(
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int index) {
                  final countryItem = updatedCountryList[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: GestureDetector(
                      onTap: () {
                        selectCountry(index);
                      },
                      child: SizedBox(
                        height: 40,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Container(
                                  width: 40,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      width: 1,
                                      color: colorBorder,
                                    ),
                                  ),
                                  child: Image.asset(
                                    countryItem.flagUri!,
                                    package: 'country_list_pick',
                                    width: 40,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  AppLocalizations(
                                    objectMgr.langMgr.currLocale,
                                  ).isMandarin()
                                      ? countryItem.zhName!
                                      : countryItem.name!,
                                  style: jxTextStyle.textStyleBold16(
                                    fontWeight: MFontWeight.bold6.value,
                                  ),
                                ),
                              ),
                              Text(
                                countryItem.dialCode!,
                                textAlign: TextAlign.right,
                                style: jxTextStyle.textStyleBold16(
                                  color: colorTextSecondary,
                                  fontWeight: MFontWeight.bold6.value,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  return const Padding(
                    padding: EdgeInsets.only(
                      left: 68,
                    ),
                    child: Divider(
                      height: 5,
                      thickness: 1,
                      color: colorBorder,
                    ),
                  );
                },
                itemCount: updatedCountryList.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
