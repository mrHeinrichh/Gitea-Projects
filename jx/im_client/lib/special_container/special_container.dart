import 'package:flutter/material.dart';
import 'package:jxim_client/special_container/special_container_util.dart';
import 'package:jxim_client/special_container/spexial_container_title.dart';

class SpecialContainer extends StatelessWidget {
  const SpecialContainer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return _getView(context);
  }

  Widget _getView(BuildContext context) {
    return SpecialContainerTitle(
      type: SpecialContainerType.fromIndex(scType.value),
    );
  }
}
