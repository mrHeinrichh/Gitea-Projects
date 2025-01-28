import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/views/component/new_appbar.dart';

import '../../utils/theme/text_styles.dart';
import 'dark_mode_tile.dart';

class AppearanceView extends StatelessWidget {
  const AppearanceView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PrimaryAppBar(
        title: 'Appearance',
        elevation: 2.0,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              height: 200.sp,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/chat_bg.png'),
                ),
              ),
            ),
            Container(
                height: 100,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(width: 1, color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 80.sp,
                      width: 70.sp,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(width: 20.sp),
                    Container(
                      height: 80.sp,
                      width: 70.sp,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(width: 20.sp),
                    Container(
                      height: 80.sp,
                      width: 70.sp,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(width: 20.sp),
                    Container(
                      height: 80.sp,
                      width: 70.sp,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                    ),
                  ],
                )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(width: 1, color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: const [
                  Text('Chat Themes'),
                  Spacer(),
                  Icon(Icons.arrow_forward_ios),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(width: 1, color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Chat Background'),
                      const SizedBox(height: 40),
                      Text(
                        'Appearance Setting',
                        style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight:MFontWeight.bold4.value,
                            color: Color(0xFF999999)),
                      )
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios),
                ],
              ),
            ),
            const DarkModeTile(),
          ],
        ),
      ),
    );
  }
}
