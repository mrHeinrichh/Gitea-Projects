import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_edit_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/views/component/custom_expansion_tile.dart';

class GroupEditPermissionView extends GetView<GroupChatEditController> {
  const GroupEditPermissionView({super.key});

  @override
  Widget build(BuildContext context) {
    List<int> timeValue = controller.slowMode.values.toList();
    return Scaffold(
      appBar: PrimaryAppBar(
        title: localized(permissions),
        onPressedBackBtn: () => controller.permissionPageBackTrigger(context),
        trailing: [
          GestureDetector(
            onTap: () => controller.updatePermission(),
            child: OpacityEffect(
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  localized(buttonDone),
                  style: jxTextStyle.textStyle17(color: themeColor),
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: colorBackground,
      body: CustomScrollableListView(
        children: [
          // Member View Chat History Setting
          Column(
            children: [
              header(memberAreAbleTo),
              roundContainer(
                  child: ListTile(
                      title: Text(
                        localized(viewChatHistory),
                        style: const TextStyle(fontSize: 16.0),
                      ),
                      subtitle: Text(
                          localized(allowNewMembersViewTheLatest100Messages),
                          style: const TextStyle(
                            fontSize: 12,
                            color: colorTextSecondary,
                          )),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Obx(
                            () => FlutterSwitch(
                              value: controller.viewHistoryEnabled.value,
                              onToggle: (_) => controller.doChangeViewHistory(),
                              activeColor: themeColor,
                              width: 52.0,
                              height: 32.0,
                              toggleSize: 24,
                            ),
                          )
                        ],
                      ))),
            ],
          ),

          // Group Member Permission Setting
          Column(
            children: [
              header(groupMemberCan),
              roundContainer(
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: controller.permissionList.length,
                  itemBuilder: (BuildContext _, int index) {
                    return Container(
                      decoration: BoxDecoration(
                        border: index != controller.permissionList.length - 1
                            ? customBorder
                            : null,
                      ),
                      padding:
                          const EdgeInsets.only(top: 8, bottom: 8, right: 16),
                      margin: const EdgeInsets.only(left: 16),
                      child: Obx(
                        () => Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                localized(controller.permissionList.keys
                                    .elementAt(index)),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            FlutterSwitch(
                              activeColor: themeColor,
                              width: 48.0,
                              height: 28.0,
                              toggleSize: 24,
                              value: controller.permissionList[controller
                                  .permissionList.keys
                                  .elementAt(index)],
                              onToggle: (_) =>
                                  controller.onPermissionSelected(index, false),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Send Permissions Setting
          Column(
            children: [
              header(send),
              roundContainer(
                child: Obx(
                  () {
                    return CustomExpansionTile(
                      childPadding: EdgeInsets.zero,
                      isExpanded: controller.isExpanded.value,
                      //initial
                      onExpansionChanged: (bool value) {
                        controller.batchSendMessagePermission(value);
                      },
                      title: Text(
                        '${localized(sendMessagePermission)} (${controller.totalSendMsgPermission.value}/${controller.sendMsgPermissionList.length})',
                        style: const TextStyle(fontSize: 16.0),
                      ),
                      children: [
                        ListView.builder(
                            shrinkWrap: true,
                            physics: const ScrollPhysics(),
                            itemCount: controller.sendMsgPermissionList.length,
                            itemBuilder: (BuildContext _, int index) {
                              return Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: colorTextPrimary.withOpacity(0.2),
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                padding: const EdgeInsets.only(
                                    top: 8, bottom: 8, right: 16),
                                margin: const EdgeInsets.only(left: 16),
                                child: Obx(
                                  () => Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          localized(controller
                                              .sendMsgPermissionList.keys
                                              .elementAt(index)),
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                      FlutterSwitch(
                                        value: controller.sendMsgPermissionList[
                                            controller
                                                .sendMsgPermissionList.keys
                                                .elementAt(index)],
                                        onToggle: (_) => controller
                                            .onPermissionSelected(index, true),
                                        activeColor: themeColor,
                                        width: 48.0,
                                        height: 28.0,
                                        toggleSize: 24,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            })
                      ],
                    );
                  },
                ),
              ),
            ],
          ),

          // Slow Mode Slider
          Column(
            children: [
              header(slowMode),
              roundContainer(
                  child: Column(
                children: [
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (int i = 0; i < controller.slowMode.length; i++)
                        Expanded(
                            child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              controller.slowMode.keys.elementAt(i),
                              style: jxTextStyle.textStyle10(
                                  color: colorTextSecondary),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                          ),
                        ))
                    ],
                  ),
                  SlowModeSlider(
                    selectedValue:
                        timeValue.indexOf(controller.speakInterval.value),
                    data: controller.slowMode,
                    callBack: (value) {
                      controller.setSlowMode(controller.slowMode.values
                          .elementAt(int.parse(value.toStringAsFixed(0))));
                    },
                  ),
                ],
              )),
              const SizedBox(height: 4),
              header(
                  membersMustWaitUntilTheCoolDownTimerExpiresBeforeSendingANewMessage)
            ],
          ),

          // Divider(color: Colors.grey.shade400, thickness: 0.5,),
          // ListTile(
          //   title: Text(
          //     localized(slowMode),
          //     style: const TextStyle(
          //       fontSize: 16,
          //     ),
          //   ),
          //   subtitle: Text(
          //       localized(membersMustWaitUntilTheCoolDownTimerExpiresBeforeSendingANewMessage),
          //       style: const TextStyle(
          //         fontSize: 12,
          //         color: colorTextSecondary,
          //       )),
          //   // isThreeLine: true,
          //   trailing: Row(
          //     mainAxisSize: MainAxisSize.min,
          //     children: [
          //       Obx(() {
          //         return Text(controller.slowModeText.value,
          //           style: TextStyle(color: themeColor, fontSize: 16),);
          //       }),
          //       const SizedBox(width: 10),
          //       Icon(
          //         Icons.arrow_forward_ios, color: themeColor, size: 18,),
          //     ],
          //   ),
          //   onTap: () {
          //     showModalBottomSheet(
          //         context: context,
          //         shape: RoundedRectangleBorder(
          //           borderRadius: BorderRadius.circular(18),
          //         ),
          //         builder: (context) {
          //           return Column(
          //               crossAxisAlignment: CrossAxisAlignment.start,
          //               children: [
          //                 Container(
          //                   decoration:const BoxDecoration(
          //                     color: colorBorder,
          //                     borderRadius: BorderRadius.only(
          //                       topRight: Radius.circular(18),
          //                       topLeft: Radius.circular(18),
          //                     ),
          //                   ),
          //                   child: Row(
          //                     mainAxisSize: MainAxisSize.max,
          //                     children: [
          //                       Expanded(
          //                         flex: 1,
          //                         child: TextButton(
          //                             onPressed:() => Get.back(),
          //                             child: Text(localized(buttonCancel),style: TextStyle(color: themeColor,fontSize: 16))
          //                         ),
          //                       ),
          //                       Expanded(
          //                         flex: 3,
          //                         child: Align(
          //                             alignment:Alignment.center,
          //                             child: Text(localized(slowMode),style: const TextStyle(fontWeight: MFontWeight.bold5.value,fontSize: 16))),
          //                       ),
          //                       const Spacer()
          //                     ],
          //                   ),
          //                 ),
          //                 Expanded(
          //                   child: ListView.builder(
          //                       shrinkWrap: true,
          //                       itemCount: controller.slowMode.length,
          //                       itemBuilder: (BuildContext _, int index) {
          //                         final slowModeValue = controller.slowMode.values.elementAt(index);
          //                         final slowModeLabel = controller.slowMode.keys.elementAt(index);
          //                         return Container(
          //                           decoration: BoxDecoration(
          //                             border: customBorder,
          //                           ),
          //                           padding:const EdgeInsets.all(5.0),
          //                           child: Obx(() {
          //                             return ListTile(
          //                               leading: Radio<int>(
          //                                 value: slowModeValue,
          //                                 groupValue: controller.speakInterval.value,
          //                                 onChanged: (value) {
          //                                   controller.setSlowMode(slowModeValue);
          //                                 },
          //                                 toggleable: true,
          //                                 fillColor: MaterialStateColor.resolveWith((states) => themeColor),
          //                                 activeColor: themeColor,
          //                               ),
          //                               title: Text(slowModeLabel),
          //                               onTap: (){
          //                                 controller.setSlowMode(slowModeValue);
          //                               },
          //                             );
          //                           }),
          //                         );
          //                       }),
          //                 ),
          //               ]
          //           );
          //         }
          //     );
          //   },
          // ),
        ],
      ),
    );
  }

  Widget header(value) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(bottom: 4, left: 16),
      child: Text(
        localized(value),
        style: jxTextStyle.textStyle14(color: colorTextSecondary),
      ),
    );
  }

  Widget roundContainer({child}) {
    return BorderContainer(
        verticalPadding: 6,
        horizontalPadding: 0,
        borderRadius: objectMgr.loginMgr.isDesktop ? 3 : null,
        child: child);
  }
}

class SlowModeSlider extends StatefulWidget {
  const SlowModeSlider(
      {super.key,
      required this.data,
      required this.selectedValue,
      required this.callBack});

  final Map<String, int> data;
  final int selectedValue;
  final Function(double) callBack;

  @override
  State<SlowModeSlider> createState() => _SlowModeSliderState();
}

class _SlowModeSliderState extends State<SlowModeSlider> {
  late Future<ui.Image> img;
  late double _value;

  Future<ui.Image> getImage() async {
    final data = await rootBundle
        .load('assets/images/new_resources/slider_indicator.png');
    final bytes = data.buffer.asUint8List();
    final image = await decodeImageFromList(bytes);
    return image;
  }

  @override
  void initState() {
    super.initState();
    img = getImage();
    _value = widget.selectedValue.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.Image>(
        future: img,
        builder: (_, snapshot) {
          if (snapshot.hasData || snapshot.data != null) {
            return SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                // thumbShape: SliderThumbImage(snapshot.data!),
                thumbColor: themeColor,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                activeTrackColor: const Color(0xFFD9D9D9),
                inactiveTrackColor: const Color(0xFFD9D9D9),
                tickMarkShape: LineSliderTickMarkShape(),
                overlayColor: Colors.transparent,
              ),
              child: Slider(
                value: _value,
                max: widget.data.length - 1,
                divisions: widget.data.length - 1,
                onChanged: (double value) {
                  setState(() {
                    widget.callBack(value);
                    _value = value;
                  });
                },
              ),
            );
          }
          return Container();
        });
  }
}

class LineSliderTickMarkShape extends SliderTickMarkShape {
  @override
  Size getPreferredSize({
    required SliderThemeData sliderTheme,
    required bool isEnabled,
  }) {
    return Size.fromRadius(sliderTheme.trackHeight! / 4);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    required bool isEnabled,
  }) {
    final Paint paint = Paint()
      ..color = const Color(0xFFD9D9D9)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    context.canvas.drawLine(Offset(center.dx, center.dy - 5.5),
        Offset(center.dx, center.dy + 5.5), paint);
  }
}

class SliderThumbImage extends SliderComponentShape {
  final ui.Image image;

  SliderThumbImage(this.image);

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(0, 0);
  }

  void paintImage(
      ui.Image image, Rect outputRect, Canvas canvas, Paint paint, BoxFit fit) {
    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());
    final FittedSizes sizes = applyBoxFit(fit, imageSize, outputRect.size);
    final Rect inputSubrect =
        Alignment.center.inscribe(sizes.source, Offset.zero & imageSize);
    final Rect outputSubrect =
        Alignment.center.inscribe(sizes.destination, outputRect);
    canvas.drawImageRect(image, inputSubrect, outputSubrect, paint);
  }

  @override
  void paint(PaintingContext context, Offset center,
      {required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextPainter labelPainter,
      required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required double value,
      required double textScaleFactor,
      required Size sizeWithOverflow}) {
    var imgSize = 24.0;
    var rect = Rect.fromCenter(
        center: Offset(center.dx, center.dy), width: imgSize, height: imgSize);
    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());
    final FittedSizes sizes = applyBoxFit(BoxFit.cover, imageSize, rect.size);
    final Rect inputSubrect =
        Alignment.center.inscribe(sizes.source, Offset.zero & imageSize);
    final Rect outputSubrect =
        Alignment.center.inscribe(sizes.destination, rect);

    context.canvas.drawImageRect(image, inputSubrect, outputSubrect, Paint());
    // context.canvas.drawImage(image, Offset(center.dx,0), new Paint());
  }
}