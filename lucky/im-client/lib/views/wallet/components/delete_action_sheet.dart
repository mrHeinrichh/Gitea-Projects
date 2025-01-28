import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

class DeleteActionSheet extends StatelessWidget {
  const DeleteActionSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      return CupertinoActionSheet(
        title: Text('${localized(areYouSureYouWantToDeleteAddress)}?'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: Text(
              localized(buttonDelete),
              style: TextStyle(color: JXColors.red, fontSize: 16.sp),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: Text(localized(buttonCancel),
              style:
                  TextStyle(color: const Color(0xFF243BB2), fontSize: 16.sp)),
        ),
      );
    });
  }
}
