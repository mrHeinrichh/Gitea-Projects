import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/utils/color.dart';

class FaceBottomTab extends StatefulWidget {
  const FaceBottomTab({
    Key? key,
    required this.currentPage,
    required this.onTab,
    required this.onDelete,
  }) : super(key: key);
  final int currentPage;
  final VoidCallback onDelete;
  final Function(int index) onTab;

  @override
  _FaceBottomTabState createState() => _FaceBottomTabState();
}

class _FaceBottomTabState extends State<FaceBottomTab> {
  final List<String> _images = [
    'assets/images/message/icon_sticker.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 45.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            width: 0.5,
            color: colorF2F2F2,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        left: 18.w,
        right: 16.w,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        // children: [_buildItem(0), _buildItem(1), _buildItem(2)],
        children: [_buildItem(0)],
      ),
    );
  }

  Widget _buildItem(int index) {
    return Padding(
      padding: EdgeInsets.only(right: 18.w),
      child: GestureDetector(
        onTap: () => widget.onTab(index),
        child: Container(
          width: 32.w,
          height: 32.w,
          decoration: BoxDecoration(
            color:
                widget.currentPage == index ? hexColor(0xF5F5F5) : Colors.white,
            borderRadius: BorderRadius.circular(8.r),
          ),
          alignment: Alignment.center,
          child: Image.asset(
            _images[index],
            width: 24.w,
            height: 24.w,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
