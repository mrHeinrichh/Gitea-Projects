import 'package:flutter/material.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/dot_loading_view.dart';

class DesktopLoginLoadingView extends StatelessWidget {
  const DesktopLoginLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  'assets/images/desktop_loading.png',
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 32),
                Text(
                  'Loading',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: MFontWeight.bold5.value,
                  ),
                ),
                const SizedBox(height: 32),
                const SizedBox(
                  width: 30,
                  child: DotLoadingView(
                    size: 8,
                    dotColor: colorTextSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
