import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/color.dart';
import '../../utils/theme/text_styles.dart';
import 'component/media_selector_view.dart';

class SheetTitleBar extends StatelessWidget {
  const SheetTitleBar({
    super.key,
    this.rightMenu,
    required this.title,
    this.divider,
  });

  final Widget? rightMenu;
  final String title;
  final bool? divider;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
       decoration: BoxDecoration(
             color: sheetTitleBarColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.w),
                topRight: Radius.circular(12.w),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.transparent,
                  blurRadius: 0.0.w,
                  offset: const Offset(0.0, -1.0),
                ),
              ],
            ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          cancelWidget(context),
          Center(
            child: Text(
              title,
              style: jxTextStyle.appTitleStyle(
                  color: JXColors.primaryTextBlack),
            ),
          ),
          if (rightMenu != null)
            Positioned(
              right: 16,
              child: rightMenu!,
            ),
          if(divider!=null&&divider!)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Divider(
              height: 0.33,
              color: JXColors.borderPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
