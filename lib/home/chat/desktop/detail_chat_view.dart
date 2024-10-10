import 'package:flutter/material.dart';
import 'package:jxim_client/utils/file_type_util.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

// class DesktopDetailChatView extends GetView<ChatController> {
//   DesktopDetailChatView({
//     Key? key,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Obx(
//       () {
//         if (controller.selectedChat.value != null) {
//           return Container(
//             child: DropTarget(
//               onDragDone: (value) async {
//                 await controller.dropDesktopFile(value, context);
//               },
//               onDragEntered: (value) {
//                 controller.onHover(true);
//                 controller.checkFileType(value.files);
//               },
//               onDragExited: (_) => controller.onHover(false),
//               child: Stack(
//                 children: <Widget>[
//                   getChatRoom(controller.selectedChat.value!),
//                   Visibility(
//                     visible: controller.onHover.value,
//                     child: Padding(
//                       padding: const EdgeInsets.only(
//                         top: 75,
//                         bottom: 65,
//                         left: 20,
//                         right: 20,
//                       ),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: [
//                           controller.allImage || controller.allVideo
//                               ? DropZoneContainer(
//                                   fileType: FileType.document,
//                                   globalKey: controller.upperDropAreaKey,
//                                 )
//                               : const Spacer(),
//                           Visibility(
//                             visible: controller.allVideo || controller.allImage,
//                             child: const SizedBox(
//                               height: 10,
//                             ),
//                           ),
//                           DropZoneContainer(
//                             fileType: controller.allVideo
//                                 ? FileType.video
//                                 : controller.allImage
//                                     ? FileType.image
//                                     : FileType.document,
//                             globalKey: controller.lowerDropAreaKey,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         } else {
//           return Container(
//             decoration: const BoxDecoration(
//               color: Color(0xFFE4DBD8),
//               image: DecorationImage(
//                 image: AssetImage(
//                   "assets/images/chat_bg.png",
//                 ),
//                 fit: BoxFit.none,
//                 opacity: 0.4,
//                 repeat: ImageRepeat.repeat,
//               ),
//             ),
//             child: Center(
//               child: Material(
//                 color: Colors.white,
//                 elevation: 1.0,
//                 borderRadius: BorderRadius.circular(12),
//                 child: Container(
//                   width: 330,
//                   height: 175,
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.only(top: 20, bottom: 20),
//                         child: SvgPicture.asset(
//                           'assets/svgs/welcome_image.svg',
//                           width: 74,
//                           height: 74,
//                         ),
//                       ),
//                       Text(
//                         localized(welcomeToHeyTalkDesktop),
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: MFontWeight.bold5.value,
//                         ),
//                       ),
//                       const SizedBox(height: 10),
//                       Text(
//                         localized(clickOnChatToStartMessaging),
//                         style: const TextStyle(
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           );
//         }
//       },
//     );
//   }
//
//   Widget getChatRoom(Chat selectedChat) {
//     final String tag = selectedChat.id.toString();
//     return selectedChat.typ == chatTypeGroup
//         ? GroupChatView(tag: tag)
//         : SingleChatView(tag: tag);
//   }
// }

class DropZoneContainer extends StatelessWidget {
  const DropZoneContainer({
    super.key,
    required this.fileType,
    required this.globalKey,
  });
  final FileType fileType;
  final GlobalKey globalKey;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        key: globalKey,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 255, 255, 0.9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: CustomPaint(
            painter: DottedLinePainter(),
            child: ClipRRect(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    getFileIcon(fileType),
                    color: Colors.grey,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    '${localized(dropItemHereToSendAs)}${getFileGenre(fileType)}',
                    style: jxTextStyle.dropAreaTitle(),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    localized(inAQuickWay),
                    style: jxTextStyle.dropAreaSubTitle(),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  final double strokeWidth;
  final Color color;
  final double borderRadius;
  final double dashLength;
  final double dashSpace;

  DottedLinePainter({
    this.strokeWidth = 1.5,
    this.color = Colors.grey,
    this.borderRadius = 5.0,
    this.dashLength = 5,
    this.dashSpace = 15,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = borderRadius;

    final path = Path();
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ),
    );

    final dashPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      final length = metric.length;
      var distance = 0.0;
      while (distance < length) {
        final space = distance + dashSpace;
        final dashEnd = space > length ? length : space;
        final segment = metric.extractPath(distance, dashEnd);
        canvas.drawPath(segment, dashPaint);
        distance += dashSpace + dashLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

IconData getFileIcon(FileType fileType) {
  switch (fileType) {
    case FileType.image:
      return Icons.image_outlined;
    case FileType.video:
      return Icons.video_camera_back_outlined;
    default:
      return Icons.file_copy_outlined;
  }
}

String getFileGenre(FileType fileType) {
  switch (fileType) {
    case FileType.image:
      return localized(image);
    case FileType.video:
      return localized(video);
    default:
      return localized(documents);
  }
}
