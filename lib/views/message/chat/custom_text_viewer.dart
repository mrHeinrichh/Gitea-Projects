import 'package:flutter/material.dart';
import 'package:jxim_client/views/component/new_appbar.dart';

import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

class CustomTextViewer extends StatelessWidget {
  const CustomTextViewer({super.key});

  @override
  Widget build(BuildContext context) {
    final String? data = ModalRoute.of(context)?.settings.arguments.toString();

    return Scaffold(
      appBar: PrimaryAppBar(
        title: localized(textViewer),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 5,
        ),
        child: data != null
            ? SingleChildScrollView(
                child: Text(
                  data,
                  style: const TextStyle(
                    fontSize: 16.0,
                    color: Colors.black,
                  ),
                ),
              )
            : const SizedBox(),
      ),
    );
  }
}
