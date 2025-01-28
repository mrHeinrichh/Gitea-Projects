import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/object/selection_option_model.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class CustomBottomSheet extends StatelessWidget {
  const CustomBottomSheet({
    Key? key,
    required this.context,
    required this.title,
    this.subTitle = "",
    required this.selectionOptionModelList,
    required this.callback,
    this.isShowCheckbox = true,
  }) : super(key: key);

  final BuildContext context;
  final String title;
  final String? subTitle;
  final List<SelectionOptionModel> selectionOptionModelList;
  final Function(int index) callback;
  final bool isShowCheckbox;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceBrightColor,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          topLeft: Radius.circular(20),
        ),
      ),
      // height: MediaQuery.of(context).size.height * 0.5,
      child: Wrap(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 0.0,
                ),
                child: Text(
                  title,
                  style: jxTextStyle.textStyleBold16(),
                ),
              ),
              const CustomDivider(),
              if (subTitle != "")
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, left: 16.0),
                  child: Text(
                    subTitle ?? "",
                    style: jxTextStyle.textStyle12(
                      color: JXColors.secondaryTextBlack,
                    ),
                  ),
                ),
              ListView.separated(
                shrinkWrap: true,
                itemCount: selectionOptionModelList.length,
                itemBuilder: (BuildContext _, int index) {
                  final optionTitle =
                      selectionOptionModelList.elementAt(index).title;
                  final optionStatus =
                      selectionOptionModelList.elementAt(index).isSelected;

                  return GestureDetector(
                    onTap: () {
                      callback(index);
                    },
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 48,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      child: Row(
                        children: [
                          Visibility(
                            visible: isShowCheckbox,
                            child: optionStatus
                                ? SvgPicture.asset(
                                    'assets/svgs/radio_selected.svg',
                                    width: 24,
                                    height: 24,
                                    color: accentColor,
                                  )
                                : SvgPicture.asset(
                                    'assets/svgs/radio_unselected.svg',
                                    width: 24,
                                    height: 24,
                                    color: JXColors.supportingTextBlack,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(optionTitle!),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  return const CustomDivider();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
