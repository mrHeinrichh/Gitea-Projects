import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/object/chat/task_content.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

class TaskCell extends StatelessWidget {
  final TaskContent task;

  const TaskCell({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 16.0),
      child: Row(
        children: <Widget>[
          Stack(
            alignment: Alignment.center,
            children: <Widget>[
              SizedBox(
                height: 44.0,
                width: 44.0,
                child: CircularProgressIndicator(
                  value: task.doneCount / task.totalCount,
                  backgroundColor: accentColor.withOpacity(0.12),
                  color: accentColor.withOpacity(0.48),
                  strokeWidth: 6.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(100000.0),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'assets/svgs/task.svg',
                  width: 18.0,
                  height: 18.0,
                  color: JXColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(bottom: 8.0),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: JXColors.bgTertiaryColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 16.0,
                            color: JXColors.primaryTextBlack,
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            text: '${task.doneCount}/${task.totalCount} ',
                            style: const TextStyle(
                              fontSize: 14.0,
                              color: JXColors.secondaryTextBlack,
                            ),
                            children: <TextSpan>[
                              TextSpan(text: localized(buttonDone)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    FormatTime.chartTime(
                      task.createTime,
                      true,
                      todayShowTime: true,
                    ),
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: JXColors.secondaryTextBlack,
                    ),
                  ),
                  const SizedBox(width: 16.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
