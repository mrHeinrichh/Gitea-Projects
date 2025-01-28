import 'package:country_list_pick/support/code_country.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

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
      height: MediaQuery.of(context).size.height * 0.94,
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
          CustomSearchBar(
            autofocus: true,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            controller: countryController,
            onChanged: searchCountry,
            onClearClick: () => searchCountry(''),
            onCancelClick: () => Get.back(id: objectMgr.loginMgr.isDesktop ? 3 : null),
          ),
          const CustomDivider(),
          Expanded(
            flex: 6,
            child: Obx(
              () => ListView.separated(
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int index) {
                  final countryItem = updatedCountryList[index];
                  return GestureDetector(
                    onTap: () {
                      selectCountry(index);
                    },
                    child: ForegroundOverlayEffect(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: SizedBox(
                          height: 40,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: SizedBox(
                                    width: 40,
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
                                    style: jxTextStyle.headerText(),
                                  ),
                                ),
                                Text(
                                  countryItem.dialCode!,
                                  textAlign: TextAlign.right,
                                  style: jxTextStyle.headerText(
                                    color: colorTextSecondary,
                                  ),
                                ),
                              ],
                            ),
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
                      child: CustomDivider());
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
