import 'package:flutter/material.dart';

import 'package:jxim_client/views/component/new_appbar.dart';

class SecuritySettingView extends StatelessWidget {
  const SecuritySettingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: PrimaryAppBar(
        title: 'Security Setting',
      ),
    );
  }
}
