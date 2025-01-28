import 'package:get/get.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CallSetBottomSheet extends StatelessWidget {
  const CallSetBottomSheet({
    Key? key,
    required this.actions,
    required this.onClick,
    required this.title,
    this.onKnow,
  }) : super(key: key);
  final String title;
  final List<String> actions;
  final Function(int index) onClick;
  final VoidCallback? onKnow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _buildList(context),
      ),
    );
  }

  List<Widget> _buildList(BuildContext context) {
    List<Widget> list = [];
    list.add(Padding(
      padding: EdgeInsets.only(top: 20.w, bottom: 12.w),
      child: Text(
        title,
        style: TextStyle(
          color: color1A1A1A,
          fontSize: 15.sp,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
    ));
    list.add(Padding(
      padding: EdgeInsets.only(bottom: 20.w),
      child: RichText(
        text: TextSpan(
          text: '',
          style: TextStyle(
            color: color999999,
            fontSize: 12.sp,
          ),
          children: [
            TextSpan(
              text: localized(popupCallPriceText1),
            ),
            WidgetSpan(
              child: GestureDetector(
                child: Text(
                  localized(popupCallPriceText2),
                  style: TextStyle(
                    color: colorE5454D,
                    fontSize: 12.sp,
                  ),
                ),
                onTap: () {
                  if (onKnow != null) {
                    onKnow!();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    ));
    list.addAll(List<Widget>.generate(actions.length, (int index) {
      return _buildItem(actions[index], index, context);
    }));
    list.add(_buildCancel(context));
    return list;
  }

  Widget _buildItem(String title, int index, BuildContext context) {
    _onClick(int index) {
      Get.back();
      onClick(index);
    }

    return GestureDetector(
      onTap: () => _onClick(index),
      child: Container(
          width: double.infinity,
          height: 46.w,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: hexColor(0xF0F0F0), width: 0.5),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: color1A1A1A,
              fontSize: 14.sp,
              fontWeight: FontWeight.normal,
              decoration: TextDecoration.none,
            ),
          )),
    );
  }

  Widget _buildCancel(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: SafeArea(
        top: false,
        bottom: true,
        child: GestureDetector(
          onTap: () {
            Get.back();
          },
          child: Container(
            width: double.infinity,
            height: 46.w,
            color: Colors.transparent,
            alignment: Alignment.center,
            child: Text(
              localized(popupCancel),
              style: TextStyle(
                color: color1A1A1A,
                fontSize: 14.sp,
                fontWeight: FontWeight.normal,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
