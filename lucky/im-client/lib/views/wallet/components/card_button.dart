import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../utils/color.dart';

class WalletCardButton extends StatelessWidget {
  const WalletCardButton(
      {Key? key, this.onTap, required this.title, required this.iconPath})
      : super(key: key);
  final GestureTapCallback? onTap;
  final String title;
  final String iconPath;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            SvgPicture.asset(
              iconPath,
              width: 24,
              height: 24,
              color: JXColors.white,
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(
                color: JXColors.white,
              ),
            ),
          ],
        ),
      ),

      // GestureDetector(
      //   onTap: onTap,
      //   child: Container(
      //     alignment: Alignment.center,
      //     decoration: BoxDecoration(
      //         color: JXColors.accentPurple,
      //         borderRadius: BorderRadius.all(Radius.circular(10))),
      //     padding: EdgeInsets.symmetric(
      //       vertical: 10,
      //     ),
      //     child: Text(
      //       '${title}',
      //       style: TextStyle(
      //         fontSize: 14.sp,
      //         color: Colors.white,
      //       ),
      //     ),
      //   ),
      // ),
    );
  }
}
