import 'package:flutter/cupertino.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';

class CustomAvatarStatic extends StatefulWidget{
  const CustomAvatarStatic({super.key, required this.uid, required this.size});

  final int uid;
  final double size;

  @override
  State<StatefulWidget> createState ()=> _CustomAvatarStaticState();

}

class _CustomAvatarStaticState extends State<CustomAvatarStatic> with AutomaticKeepAliveClientMixin{

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return CustomAvatar.normal(
      widget.uid,
      size: widget.size,
      headMin: Config().messageMin,
      shouldAnimate: false,
    );
  }

  @override
  bool get wantKeepAlive => true;
}