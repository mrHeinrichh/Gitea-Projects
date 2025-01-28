import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/user.dart';

class DataProvider {
  final bool isGroup;
  int uid = 0;
  User? user;
  Group? group;
  Chat? chat;

  DataProvider(
      {this.uid = 0, this.isGroup = false, this.user, this.group, this.chat}) {
    assert(user != null || (group != null && isGroup) || uid > 0,
        "One of the user, group and uid parameters must be have");

    if (user != null) {
      uid = user?.uid ?? 0;
    } else if (group != null) {
      uid = group?.uid ?? 0;
    }
  }

  User? getUserSync() {
    user ??= objectMgr.userMgr.getUserById(uid);
    return user;
  }

  Future<User?> getUserAsync() async {
    User? user = await objectMgr.userMgr.loadUserById(uid);
    return user;
  }

  Group? getGroupSync() {
    group ??= objectMgr.myGroupMgr.getGroupById(uid);
    return group;
  }

  Future<Group?> getGroupAsync() async {
    Group? group = await objectMgr.myGroupMgr.loadGroupById(uid);
    return group;
  }

  Chat? getChatSync() {
    chat ??= objectMgr.chatMgr.getChatById(uid);
    return chat;
  }
}
