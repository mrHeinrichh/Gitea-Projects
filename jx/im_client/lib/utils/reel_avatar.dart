import 'package:flutter/cupertino.dart';
import 'package:jxim_client/views/component/avatar/data_provider.dart';
import 'package:jxim_client/views/component/component.dart';


/// 远程图片
/// @src 可为资源id(number)或资源路径(string)
class ReelAvatar extends StatefulWidget {
  const ReelAvatar({
    super.key,
    required this.uid,
    required this.size,
    this.isGroup = false,
    this.headMin,
    this.onTap,
    this.onLongPress,
    this.fontSize,
    this.isShowInitial = false,
    this.withEditEmptyPhoto = false,
    this.shouldAnimate = true,
    this.borderRadius,
  });
  final double size;
  final int uid;
  final bool isGroup;
  final int? headMin;
  final Function()? onTap;
  final Function()? onLongPress;
  final double? fontSize;
  final bool isShowInitial;
  final bool withEditEmptyPhoto; //show camera icon
  final bool shouldAnimate;
  final double? borderRadius;

  @override
  State<ReelAvatar> createState() => _ReelAvatarState();
}

class _ReelAvatarState extends State<ReelAvatar> {
  // @override
  // bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context1) {
    // super.build(context);
    return CustomAvatar(
      key: widget.key,
      dataProvider: DataProvider(uid: widget.uid, isGroup: widget.isGroup),
      size: widget.size,
      headMin: widget.headMin,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      fontSize: widget.fontSize,
      isShowInitial: widget.isShowInitial,
      withEditEmptyPhoto: widget.withEditEmptyPhoto,
      shouldAnimate: widget.shouldAnimate,
      borderRadius: widget.borderRadius,
    );
  }
}
