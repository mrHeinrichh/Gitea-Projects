
import 'package:events_widget/events_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/message/share_image.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/list_nodata_view.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/message/chat/at/chat_search_bar.dart';
import 'package:jxim_client/views/message/share/share_chat_data.dart';
import 'package:jxim_client/views/message/share/share_chat_item.dart';
import 'package:jxim_client/views/message/share/share_message_pop.dart';

class ShareChatRoute extends StatefulWidget {
  const ShareChatRoute({
    Key? key,
    required this.shareImage,
    required this.chatList,
  }) : super(key: key);
  final ShareImage shareImage;
  final List<Chat> chatList;

  @override
  _ShareChatRouteState createState() => _ShareChatRouteState();
}

class _ShareChatRouteState extends State<ShareChatRoute> {
  final List<Chat> _chatList = [];
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _editingController = TextEditingController();
  final ShareChatData _shareChatData = ShareChatData();
  final ScrollController _controller = ScrollController();

  String _alertTitle = '';

  _onSend() async {
    if (_shareChatData.selectChatList.isEmpty) return;

    Toast.showAlert(
      context: context,
      container: ShareMessagePop(
        title: _alertTitle,
        chatList: _shareChatData.selectChatList,
        onSend: (leaveMsg) async {
          goBack();
          for (final chat in _shareChatData.selectChatList) {
            if (chat.isSingle) {
              User? user =
                  await objectMgr.userMgr.loadUserById2(chat.friend_id);
              if (user != null && user.deletedAt > 0) continue;
            }

            widget.shareImage.chatId = chat.id;
            objectMgr.shareMgr.shareDataToChat(widget.shareImage,
                openChatRoom: _shareChatData.selectChatList.length == 1);
          }
          objectMgr.shareMgr.clearShare;

          Toast.showToast("分享成功");
        },
      ),
    );
  }

  goBack() {
    objectMgr.shareMgr.clearShare;
    Get.back();
  }

  _onChange() {
    _checkChatList();
  }

  _onSearch() {}

  @override
  void initState() {
    super.initState();
    _checkChatList();
    _alertTitle = _showAlertTitle();
    _controller.addListener(() {
      if (_controller.position.pixels > 50 && _focusNode.hasFocus) {
        _focusNode.unfocus();
      }
    });
  }

  String _showAlertTitle() {
    if (widget.shareImage != null) {
      return '${localized(shareSingle)}${localized(shareSingleMessage)}';
    }
    return '';
  }

  _checkChatList() async {
    _chatList.clear();

    for (Chat item in widget.chatList) {
      if (item.typ <= chatTypeSaved) {
        if (_editingController.text.isEmpty ||
            item.name.contains(_editingController.text)) {
          _chatList.add(item);
        }
      }
    }
    objectMgr.shareMgr.clearShare;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
        appBar: PrimaryAppBar(
          title: localized(share),
          onPressedBackBtn: () => goBack(),
          trailing: [
            EventsWidget(
              data: _shareChatData,
              eventTypes: const [ShareChatData.eventSelectChat],
              builder: (context) {
                return GestureDetector(
                  onTap: _onSend,
                  child: Container(
                    height: double.infinity,
                    padding: EdgeInsets.only(right: 16.w),
                    color: Colors.transparent,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      localized(chatCardSendSend),
                      style: TextStyle(
                        color: _shareChatData.selectChatList.isEmpty
                            ? colorCCCCCC
                            : accentColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        backgroundColor: Colors.white,
        body: Column(
          children: [
            searchMember(),
            Expanded(
              child: _chatList.isNotEmpty
                  ? ListView.builder(
                      controller: _controller,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _chatList.length,
                      itemBuilder: (context, index) {
                        return ShareChatItem(
                          data: _chatList[index],
                          shareChatData: _shareChatData,
                        );
                      },
                    )
                  : ListNodataView(
                      type: ListNodataView.listTypeDefault,
                      tips: localized(myFriendsEmptySimple),
                      showBtn: false,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget searchMember() {
    return Container(
      margin: EdgeInsets.only(left: 15.w, right: 15.w, top: 12.w, bottom: 4.w),
      child: ChatSearchBar(
          focusNode: _focusNode,
          editingController: _editingController,
          hintText: localized(hintSearch),
          onChange: _onChange,
          onSearch: _onSearch),
    );
  }
}
