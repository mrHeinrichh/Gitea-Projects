import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/im/chat_info/group/profile_controller.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';
import 'package:jxim_client/utils/im_toast/im_color.dart';

class FullScreenPicture extends StatefulWidget {
  const FullScreenPicture(
      {super.key,
      this.img,
      required this.defaultImg,
      required this.paddingTop});

  final String? img;
  final Widget defaultImg;
  final double paddingTop;

  @override
  State<FullScreenPicture> createState() => _FullScreenPictureState();
}

class _FullScreenPictureState extends State<FullScreenPicture> {
  double _top = 0;
  late double center;
  late double min;
  late double max;
  double percentage = 0.99;
  late double mapped;
  final double imgHeight = 370;

  @override
  void initState() {
    center = ((ScreenUtil().screenHeight - imgHeight) / 2);
    max = center + 80.w;
    min = center - 80.w;
    _top = center;
    super.initState();
  }

  bool get maxPosition => _top < max;

  bool get minPosition => _top > min;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      child: Container(
        color: ImColor.black.withOpacity(percentage),
        child: Stack(
          children: [
            Positioned(
              top: 5 + widget.paddingTop,
              left: 0,
              width: MediaQuery.of(context).size.width,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: (maxPosition && minPosition)
                              ? ImColor.white
                              : ImColor.black,
                        ),
                      ),
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                    child: GestureDetector(
                  onPanUpdate: (details) {
                    mapped = (_top - min) / (max - min);
                    if (mapped > 0.0 && mapped < 1) {
                      percentage = mapped;
                      percentage += 0.4;
                      if (_top > center) {
                        percentage = 1.7 - percentage;
                      } else {
                        percentage -= 0.3;
                      }
                    } else {
                      percentage = 0;
                    }
                    setState(() {
                      _top += details.delta.dy;
                    });
                  },
                  onPanEnd: (_) {
                    setState(() {
                      if (maxPosition && minPosition) {
                        _top = center;
                        percentage = 0.99;
                      } else {
                        Navigator.pop(context);
                      }
                    });
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 100),
                        curve: Curves.linear,
                        top: _top,
                        child: Container(
                          margin: EdgeInsets.only(bottom: 50.w),
                          height: imgHeight.w,
                          width: ProfileController.screenWidth,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10000000),
                            child: widget.img!.isEmpty
                                ? widget.defaultImg
                                : RemoteImage(
                                    src: widget.img!,
                                    fit: BoxFit.fill,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
              ],
            ),
          ],
        ),
      ),
    );
  }
}
