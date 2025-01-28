import 'dart:io';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:im_common/im_common.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jxim_client/utils/file_type_util.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/utils/file_utils.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/views_desktop/component/attach_file_controller.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_button.dart';

import 'package:path/path.dart' as path;

class AttachFileDialog extends StatelessWidget {
  const AttachFileDialog({
    super.key,
    required this.title,
    required this.file,
    required this.chatId,
    this.fileType = FileType.allMedia,
  });

  final String title;
  final List<XFile> file;
  final int chatId;
  final FileType fileType;

  @override
  Widget build(BuildContext context) {
    final AttachFileController controller = Get.put(AttachFileController());
    controller.files.assignAll(file);
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 400,
          height: 350,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '${localized(send)} $title',
                              style: jxTextStyle.imagePopupTitle(),
                            ),
                          ),
                          DesktopGeneralButton(
                            horizontalPadding: 0,
                            child: const Icon(
                              Icons.close,
                              color: Colors.black,
                            ),
                            onPressed: () => Get.back(),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              right: 10,
                              left: 10,
                              top: 5,
                            ),
                            child: GetDialogContent(
                              fileType: fileType,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  right: 20,
                  left: 20,
                  bottom: 10,
                ),
                child: DesktopGeneralButton(
                  onPressed: () {
                    controller.addMoreItems(fileType);
                  },
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.add_circle,
                        color: themeColor,
                        size: 18,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Text(
                        '${localized(addMore)}$title',
                        style: TextStyle(
                          color: themeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(
                height: 0,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 3,
                          top: 2,
                          bottom: 2,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: RawKeyboardListener(
                            focusNode: FocusNode(),
                            onKey: (RawKeyEvent event) {
                              controller.checkDesktopKeyStroke(
                                event,
                                () => controller.onSend(
                                  fileType: fileType,
                                  chatId: chatId,
                                ),
                              );
                            },
                            child: TextFormField(
                              contextMenuBuilder: textMenuBar,
                              autofocus: true,
                              focusNode: controller.focusNode,
                              controller: controller.captionController,
                              cursorColor: Colors.black,
                              textAlignVertical: TextAlignVertical.top,
                              style: jxTextStyle.imagePopupTextField(
                                color: Colors.black,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                hoverColor: Colors.white,
                                contentPadding: const EdgeInsets.all(3),
                                hintText: 'Add a caption...',
                                hintStyle: jxTextStyle.imagePopupTextField(),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: themeColor,
                        borderRadius: BorderRadius.circular(1000),
                      ),
                      child: DesktopGeneralButton(
                        horizontalPadding: 0,
                        onPressed: () => controller.onSend(
                          chatId: chatId,
                          fileType: fileType,
                        ),
                        child: Text(
                          String.fromCharCode(
                            Icons.arrow_upward_outlined.codePoint,
                          ),
                          style: TextStyle(
                            fontSize: 25,
                            color: Colors.white,
                            fontFamily: Icons.arrow_upward_outlined.fontFamily,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GetDialogContent extends StatelessWidget {
  const GetDialogContent({
    super.key,
    required this.fileType,
  });
  final FileType fileType;

  @override
  Widget build(BuildContext context) {
    final AttachFileController controller = Get.find<AttachFileController>();
    return Obx(
      () {
        if (controller.files.length > 1) {
          return fileType == FileType.document
              ? const ContentListView()
              : const ContentGridView();
        } else if (controller.files.length == 1) {
          if (fileType == FileType.document) {
            return documentItem();
          } else if (fileType == FileType.image) {
            return imageItem();
          } else if (fileType == FileType.video) {
            return videoItem();
          } else if (fileType == FileType.allMedia) {
            final FileType mediaType = getFileType(controller.files.first.path);
            if (mediaType == FileType.image) {
              return imageItem();
            } else if (mediaType == FileType.video) {
              return videoItem();
            }
          }
        }
        Get.back();
        return const SizedBox();
      },
    );
  }
}

///Grid view for more than one media item
class ContentGridView extends StatelessWidget {
  const ContentGridView({super.key});

  @override
  Widget build(BuildContext context) {
    final AttachFileController controller = Get.find<AttachFileController>();
    return Obx(
      () => GridView.builder(
        shrinkWrap: true,
        itemCount: controller.files.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          final FileType fileType = getFileType(controller.files[index].path);
          return ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: fileType == FileType.image
                ? imageItem(index: index)
                : videoItem(index: index),
          );
        },
      ),
    );
  }
}

///List view or more than one file item
class ContentListView extends StatelessWidget {
  const ContentListView({super.key});

  @override
  Widget build(BuildContext context) {
    final AttachFileController controller = Get.find<AttachFileController>();
    return Obx(
      () => ListView.builder(
        shrinkWrap: true,
        itemCount: controller.files.length,
        itemBuilder: (context, index) {
          return documentItem(index: index);
        },
      ),
    );
  }
}

///Photo image display
Widget imageItem({int index = 0}) {
  final AttachFileController controller = Get.find<AttachFileController>();
  return MouseRegion(
    onEnter: (_) {
      controller.isMediaOnHover.value = true;
      controller.onHoverIndex = index;
    },
    onExit: (_) {
      controller.isMediaOnHover.value = false;
      controller.onHoverIndex = -1;
    },
    child: Stack(
      children: [
        Center(
          child: Container(
            color: Colors.grey.shade100,
            child: Image.file(
              File(controller.files[index].path),
              key: ValueKey(controller.files[index].path),
              width: 275,
              height: 275,
              fit: BoxFit.scaleDown,
            ),
          ),
        ),
        Obx(
          () => Visibility(
            visible: controller.isMediaOnHover.value &&
                controller.onHoverIndex == index,
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: DesktopGeneralButton(
                  horizontalPadding: 0,
                  onPressed: () => controller.deleteFileFromList(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 0, 0, 0.95),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(2.5),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

///Video thumbnail display
Widget videoItem({int index = 0}) {
  final AttachFileController controller = Get.find<AttachFileController>();
  return FutureBuilder(
    future: generateThumbnailWithPath(
      controller.files[index].path,
      savePath:
          '${path.basenameWithoutExtension(controller.files[index].path)}.jpeg',
      sub: 'cover',
    ),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(
          child: SizedBox(
            width: 50,
            height: 50,
            child: BallCircleLoading(
              radius: 15,
              ballStyle: BallStyle(
                size: 5,
                color: themeColor,
                ballType: BallType.solid,
                borderWidth: 1,
                borderColor: themeColor,
              ),
            ),
          ),
        );
      } else if (snapshot.connectionState == ConnectionState.done &&
          snapshot.hasData) {
        return MouseRegion(
          onEnter: (_) {
            controller.isMediaOnHover.value = true;
            controller.onHoverIndex = index;
          },
          onExit: (_) {
            controller.isMediaOnHover.value = false;
            controller.onHoverIndex = -1;
          },
          child: Stack(
            children: [
              Center(
                child: Container(
                  color: Colors.grey.shade100,
                  child: Image.file(
                    snapshot.data!,
                    key: ValueKey(snapshot.data!),
                    width: 275,
                    height: 275,
                    fit: BoxFit.scaleDown,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 255, 255, 0.95),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(2.5),
                      child: Icon(
                        Icons.ondemand_video_rounded,
                        color: Colors.black,
                        size: 15,
                      ),
                    ),
                  ),
                ),
              ),
              Obx(
                () => Visibility(
                  visible: controller.isMediaOnHover.value &&
                      controller.onHoverIndex == index,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: DesktopGeneralButton(
                        horizontalPadding: 0,
                        onPressed: () => controller.deleteFileFromList(index),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(255, 0, 0, 0.95),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(2.5),
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return const SizedBox();
    },
  );
}

Widget documentItem({int index = 0}) {
  final AttachFileController controller = Get.find<AttachFileController>();
  return Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 5,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  shape: const CircleBorder(),
                  color: bubblePrimary,
                ),
                padding: const EdgeInsets.all(10),
                child: SvgPicture.asset(
                  'assets/svgs/file_icon.svg',
                  width: 20,
                  height: 20,
                  fit: BoxFit.fill,
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      getFileNameWithExtension(controller.files[index].path),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: MFontWeight.bold5.value,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    FutureBuilder<String>(
                      future: getFileSizeWithFormat(
                        File(controller.files[index].path),
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done &&
                            snapshot.hasData) {
                          return Text(
                            snapshot.data!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: MFontWeight.bold4.value,
                              letterSpacing: 0.5,
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        DesktopGeneralButton(
          onPressed: () => controller.deleteFileFromList(index),
          child: Container(
            height: 25,
            width: 25,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.delete_outline,
              color: Colors.white,
              size: 15,
            ),
          ),
        ),
      ],
    ),
  );
}
