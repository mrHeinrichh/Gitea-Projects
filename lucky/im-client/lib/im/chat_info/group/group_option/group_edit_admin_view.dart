import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_edit_controller.dart';


class GroupEditAdminView extends GetView<GroupChatEditController> {
  const GroupEditAdminView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Administrators'),
        centerTitle: true,
        leading: GestureDetector(
          onTap: Get.back,
          child: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).iconTheme.color,
          ),
        ),
        elevation: 0.0,
        backgroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [],
      ),
    );
  }
}
