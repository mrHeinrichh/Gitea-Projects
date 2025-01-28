import 'dart:async';

import 'package:events_widget/event_dispatcher.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/group.dart' as group_api;
import 'package:jxim_client/data/db_chat.dart';
import 'package:jxim_client/data/db_group.dart';
import 'package:jxim_client/data/object_pool.dart';
import 'package:jxim_client/data/shared_remote_db.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/toast.dart';

import '../api/group.dart';
import '../object/chat/chat.dart';
import '../object/user.dart';

/// 表名
const groupTables = {
  kMyGroup: "data_group_me", // 我的
};

const localMyGroupMaster = "my_group_master";

const localMyGroupIds = "my_group_ids";

const templateGroupTag = "tpl_group_tag";

class MyGroupMgr extends EventDispatcher {
  /// 群组群主和管理员变动
  static const eventGroupInfoUpdated = 'eventGroupInfoUpdated';

  //被踢出群
  static const eventGroupForceLeave = 'eventGroupForceLeave';
  static const eventGroupDismiss = 'eventGroupDismiss';
  static const eventGroupLeave = 'eventGroupLeave';

  /// =========================== VARIABLES ====================================
  /// 群聊资料, key : group_id, value: Group
  // Map<int, Group> _myGroupList = <int, Group>{};
  //
  // Map<int, Group> get myGroupList => _myGroupList;

  SharedRemoteDB? _sharedRemoteDB;
  SharedTable? _groupTable;

  Timer? leaveGroupTimer;

  RxBool leaveGroupStatus = RxBool(false);
  String leaveGroupPrefix = '';
  String leaveGroupName = '';
  String leaveGroupSuffix = '';

  /// ============================= 初始化 ======================================
  Future<void> register() async {
    _sharedRemoteDB = objectMgr.sharedRemoteDB;
    registerModel();
  }

  doGroupChange(UpdateBlockBean block) async {
    if (block.ctl == DBGroup.tableName) {
      for (int i = 0; i < block.data.length; i++) {
        final Group group = Group.fromJson(block.data[i]); // 远端的group
        final Group? existGroup = await getLocalGroup(group.id); // 本地目前的group

        if (existGroup == null || group != existGroup) {
          //没有members字段说明members没有变化
          if (!block.data[i].containsKey("members")) {
            group.members = existGroup?.members ?? [];
          }

          //没有admins字段说明admins没有变化
          if (!block.data[i].containsKey("admins")) {
            group.admins = existGroup?.admins ?? [];
          }

          //没有owner字段说明owner没有变化
          if (!block.data[i].containsKey("owner")) {
            group.owner = existGroup?.owner ?? 0;
          }
          objectMgr.chatMgr.updateSlowMode(group: group);

          await _sharedRemoteDB?.applyUpdateBlock(
              UpdateBlockBean.created(
                  block.opt, DBGroup.tableName, [group.toJson()]),
              save: true, // 不需要保存
              notify: true);

          updateGroupChatDetails(group, block.opt);

          event(this, eventGroupInfoUpdated, data: existGroup);
        }
      }
    }
  }

  Future<void> registerModel() async => _sharedRemoteDB?.registerModel(
      DBGroup.tableName, JsonObjectPool<Group>(Group.creator));

  Future<void> init() async {
    _groupTable = _sharedRemoteDB?.getTable(DBGroup.tableName);
    //获取群本地数据
    loadLocalGroup();
  }

  // 退出登录
  Future<void> logout() async {}

  /// ============================= 初始化结束 =================================

  void loadLocalGroup() async {
    final grpData = await objectMgr.localDB.loadGroups();
    if (grpData != null) {
      _sharedRemoteDB?.applyUpdateBlock(
        UpdateBlockBean.created(
          blockOptReplace,
          DBGroup.tableName,
          grpData.map((e) => Group.fromJson(e).toJson()).toList(),
        ),
        save: false,
        notify: false,
      );
    }
  }

  Group? getGroupById(int groupId) {
    final data = _groupTable?.getRow(groupId);
    if (data is Group) {
      return data;
    }
    return null;
  }

  Future<Group?> loadDBGroupById(int groupId) async {
    final grpData = await objectMgr.localDB.loadGroupById(groupId);
    if (grpData != null) {
      _sharedRemoteDB?.applyUpdateBlock(
          UpdateBlockBean.created(blockOptReplace, DBGroup.tableName,
              [Group.fromJson(grpData).toJson()]),
          save: false,
          notify: false);
      Group? group = _groupTable?.getRow<Group>(groupId);
      return group;
    }
    return null;
  }

  Future<Group?> loadGroupById(int groupId) async {
    Group? group = await loadDBGroupById(groupId);
    if (group == null) {
      group = await getGroupByRemote(groupId, notify: false);
    }
    return group;
  }

  /// 获取table映射对象
  Future<Group?> getLocalGroup(int groupId) async {
    Group? group = _groupTable?.getRow(groupId);
    if (group == null) {
      /// 从本地数据库获取
      final grpData = await objectMgr.localDB.loadGroupById(groupId);
      if (grpData != null) {
        /// 装载到_userTable里面
        _sharedRemoteDB?.applyUpdateBlock(
            UpdateBlockBean.created(blockOptReplace, DBGroup.tableName,
                [Group.fromJson(grpData).toJson()]),
            save: false,
            notify: false);
        group = _groupTable?.getRow(groupId);
      }
    }
    return group;
  }

  /// 群资料
  Future<Group?> getGroupByRemote(int groupId, {bool notify = false}) async {
    try {
      var rep = await group_api.getGroupInfo(groupId);
      updateChatFlagKicked(groupId, rep.data["members"]);

      await _sharedRemoteDB?.applyUpdateBlock(
        UpdateBlockBean.created(blockOptReplace, DBGroup.tableName, [rep.data]),
        save: true, // 不需要保存
        notify: notify,
      );

      final group = Group()..init(rep.data);
      if (group.id != 0) {
        updateGroupMember(group.members.map<Map<String, dynamic>>((e) {
          return <String, dynamic>{
            'id': e['user_id'],
            ...e,
          };
        }).toList());
      }

      return getLocalGroup(groupId);
    } on AppException catch (e) {
      pdebug(e.toString());
    }
    return null;
  }

  Future<Group?> setHistoryVisible(int groupId, int visible) async {
    try {
      var rep = await group_api.viewHistory(groupId, visible);
      if (rep.success()) {
        await _sharedRemoteDB?.applyUpdateBlock(
          UpdateBlockBean.created(blockOptReplace, DBGroup.tableName, [
            {
              'id': groupId,
              'visible': visible,
            }
          ]),
          save: true,
          notify: false,
        );
        return getLocalGroup(groupId);
      } else {
        throw AppException(localized(errorSettingFailed));
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 群资料
  Future<List<Map<String, dynamic>>> getCommonGroupByRemote(int userId) async {
    ResponseData? rep;
    try {
      rep = await group_api.getCommonGroup(userId);

      if (rep.success() && rep.data != null) {
        List<Map<String, dynamic>> commonGrpList = [];
        for (final data in rep.data) {
          commonGrpList.add(data);
        }

        return commonGrpList;
      }
      return [];
    } catch (e) {
      pdebug(e);
      throw e;
    }
  }

  addMember(int groupId, List<User> users) async {
    try {
      final res = await addGroupMember(
          groupId: groupId, userIds: users.map((e) => e.uid).toList());
      if (res == "OK") {
        Group? group = await getGroupByRemote(groupId, notify: false);
        event(this, eventGroupInfoUpdated, data: group);
      }
      return res;
    } catch (e) {
      rethrow;
    }
  }

  onKicked(int groupId) async {
    final group = await getLocalGroup(groupId);
    if (group != null) {
      group.removeMembers([objectMgr.userMgr.mainUser.id]);
      _sharedRemoteDB?.applyUpdateBlock(
          UpdateBlockBean.created(
              blockOptReplace, DBGroup.tableName, [group.toJson()]),
          save: true,
          notify: false);
      event(this, eventGroupInfoUpdated, data: group);
    }
  }

  /// 移除成员
  Future<bool> kickMembers(int groupId, List<int> members) async {
    try {
      final ResponseData res =
          await group_api.kickMembers(groupId: groupId, members: members);
      if (res.success()) {
        Toast.showToast(localized(chatInfoRemoveMemberSuccessfully));
        return true;
      } else {
        Toast.showToast(localized(chatInfoRemoveMemberFailed));
        throw AppException(res.message);
      }
    } catch (e) {
      pdebug('Remove member exception: ${e}');
      if (e is AppException) {
        Toast.showToast(e.getMessage());
      }
      return false;
    }
  }

  Future<bool> isGroupMember(int groupId, int userId) async {
    bool isJoined = false;
    if (isGroupValid(groupId)) {
      final Group? group = await getLocalGroup(groupId);
      if (group != null) {
        isJoined = group.members.firstWhereOrNull(
                (e) => e is Group ? e.id == userId : e["user_id"] == userId) !=
            null;
      }
    }
    return isJoined;
  }

  bool isGroupValid(int groupId) {
    bool isValid = false;
    Chat? chat = objectMgr.chatMgr.getChatById(groupId);
    if (chat != null) {
      if (chat.isValid) {
        isValid = true;
      }
    }

    return isValid;
  }

  /// 添加管理员
  Future<bool> addAdmin(int groupId, List<int> userId) async {
    try {
      final ResponseData res =
          await group_api.addAdmins(groupId: groupId, admins: userId);
      if (res.success()) {
        Toast.showToast(localized(chatInfoAddAdminSuccessfully));
        Group? group = await getLocalGroup(groupId);
        if (group != null) {
          group.admins.addAll(userId);

          event(
            this,
            eventGroupInfoUpdated,
            data: group,
          );
        }
        return true;
      } else {
        Toast.showToast(localized(chatInfoAddAdminFailed));
        throw AppException(res.message);
      }
    } catch (e) {
      pdebug('add admin exception: ${e}');
      if (e is AppException) {
        Toast.showToast(e.getMessage());
      }
      return false;
    }
  }

  /// 移除管理员
  Future<bool> removeAdmin(int groupId, List<int> userIds) async {
    try {
      final ResponseData res =
          await group_api.deleteAdmins(groupId: groupId, admins: userIds);
      if (res.success()) {
        Toast.showToast(localized(chatInfoDeleteAdminSuccessfully));
        Group? group = await getLocalGroup(groupId);
        if (group != null) {
          userIds.forEach((userId) => group.admins.remove(userId));
          event(this, eventGroupInfoUpdated, data: group);
        }
        return true;
      } else {
        Toast.showToast(localized(chatInfoDeleteAdminFailed));
        throw AppException(res.message);
      }
    } catch (e) {
      pdebug('Delete admin exception: ${e}');
      if (e is AppException) {
        Toast.showToast(e.getMessage());
      }
      return false;
    }
  }

  /// 退出群
  leaveGroup(int id) async {
    await group_api.leaveGroup(groupId: id);
    onLeaveGroup(id);
  }

  ///离开群（退出、被踢）
  onLeaveGroup(int id, [bool isForce = false]) async {
    onCreateTimer();
  }

  onDismissGroup(int id) async {
    try {
      final res = await group_api.dismissGroup(groupId: id);
      if (res.success()) {
        onCloseLeaveGroup();
        Toast.showToast(localized(chatInfoDisbandGroupSuccessful));
      } else {
        Toast.showToast(res.message);
        Get.back();
      }
    } on AppException catch (e) {
      Toast.showToast(e.getMessage());
      rethrow;
    }
  }

  updateGroupChatDetails(Group group, String option) {
    ///更新Chat里的头像以及名字
    final Chat? chat = objectMgr.chatMgr.getChatById(group.id);
    if (chat == null || chat.icon == group.icon && chat.name == group.name)
      return;

    chat.icon = group.icon;
    chat.name = group.name;
    _sharedRemoteDB?.applyUpdateBlock(
      UpdateBlockBean.created(option, DBChat.tableName, [chat.toJson()]),
      save: true,
      notify: false,
    );
  }

  ///转移群主
  Future<bool> transferOwnership(int groupId, int userId) async {
    try {
      final ResponseData res =
          await group_api.transferOwnership(groupId: groupId, userId: userId);
      if (res.success()) {
        Toast.showToast(localized(chatInfoTransferGroupOwnerSuccessfully));
        return true;
      } else {
        Toast.showToast(localized(chatInfoTransferGroupOwnerFailed));
        throw AppException(res.message);
      }
    } catch (e) {
      pdebug('Transfer group owner exception: ${e}');
      if (e is AppException) {
        Toast.showToast(e.getMessage());
      }
      return false;
    }
  }

  ///判断是否是群主 1.管理员 2.群主 0.普通
  int judgeGroupManager({
    required int groupId,
  }) {
    return 0;
  }

  ///是否重复进入群详情
  int needPopGroupId = 0;

  updateGroupToSingle(dynamic obj) {}

  /// ============================== 工具类 ====================================

  //清理时间
  String getTimeName(int time) {
    switch (time) {
      case 0:
        return localized(timeNever);
      case 600:
        return localized(timeTenMinutes);
      case 3600:
        return localized(timeOneHour);
      case 86400:
        return localized(timeOneDay);
      case 604800:
        return localized(timeOneWeek);
      case 259200:
        return localized(timeOneMonth);
      default:
        return '${time ~/ 60}${localized(timeMinutes)}';
    }
  }

  /// =============================== 特殊函数逻辑 ===============================
  void onCreateTimer() {
    leaveGroupStatus.value = true;
    final timer = Timer(const Duration(seconds: 2), () {
      leaveGroupStatus.value = false;
      leaveGroupPrefix = '';
      leaveGroupName = '';
      leaveGroupSuffix = '';
      leaveGroupTimer?.cancel();
    });
    leaveGroupTimer = timer;
  }

  void onCloseTimer() {
    leaveGroupTimer?.cancel();
    leaveGroupTimer = null;
  }

  void onCloseLeaveGroup() {
    leaveGroupStatus.value = false;
    leaveGroupPrefix = '';
    leaveGroupName = '';
    leaveGroupSuffix = '';
  }

  void updateGroupMember(List<Map<String, dynamic>> userList) =>
      objectMgr.userMgr.onUserUpdate(userList);

  void updateChatFlagKicked(int groupId, dynamic members) async {
    /// check user exist in members list
    int userExistCount = 0;
    for (int i = 0; i < members.length; i++) {
      if (members[i]['user_id'] == objectMgr.userMgr.mainUser.uid) {
        userExistCount++;
      }
    }

    if (userExistCount == 0) {
      /// Get chat by group id to send eventChatKicked
      Chat? chat = await objectMgr.chatMgr.getGroupChatById(groupId);
      if (chat != null) {
        await _sharedRemoteDB?.applyUpdateBlock(
          UpdateBlockBean.created(
            blockOptReplace,
            DBChat.tableName,
            [
              {
                'id': chat.id,
                'flag_my': ChatStatus.MyChatFlagKicked.value,
              }
            ],
          ),
          save: true, // 不需要保存
          notify: false,
        );
        objectMgr.chatMgr.event(
          objectMgr.chatMgr,
          ChatMgr.eventChatKicked,
          data: chat,
        );
      }
    }
  }
}
