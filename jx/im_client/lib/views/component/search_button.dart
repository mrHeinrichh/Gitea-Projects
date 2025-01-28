import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SearchButton extends StatelessWidget {
  final VoidCallback callback;
  const SearchButton({ super.key,required this.callback});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: callback,
      child: Container(
        padding: EdgeInsets.all(16.w),
        width: 20.w,
        height: 20.w,
        color: Colors.transparent,
        child: Image.asset('assets/images/square_new/search_black.png',fit: BoxFit.contain),
      ),
    );
  }
}
