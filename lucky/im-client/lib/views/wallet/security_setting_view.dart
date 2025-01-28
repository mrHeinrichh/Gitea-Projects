import 'package:flutter/material.dart';

import '../component/new_appbar.dart';

class SecuritySettingView extends StatelessWidget {
  const SecuritySettingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PrimaryAppBar(
        title: 'Security Setting',
      ),
    );
  }
}
