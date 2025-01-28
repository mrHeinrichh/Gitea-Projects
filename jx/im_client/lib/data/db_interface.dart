// 持久化数据接口
import 'package:jxim_client/object/call.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/user.dart';

/// 数据库接口
abstract class DBInterface
    implements
        ChatInterface,
        MessageInterface,
        UserInterface,
        GroupInterface,
        RedPacketInterface,
        /* ReactEmojiInterface */
        CallLogInterface,
        SoundInterface,
        TagsInterface,
        FavouriteInterface,
        FavouriteDetailInterface,
        RetryInterface,
        ChatCategoryInterface,
        ExploreMiniAppInterface,
        RecentMiniAppInterface,
        DiscoverMiniAppInterface,
        FavoriteMiniAppInterface {
  /// 初始化
  Future<void> init(int userID, bool clean);

  /// 注册创建表sql语句
  void registerTable(String? sql);

  /// 插入数据
  Future<int?> replace(String table, Map<String, Object?> values);

  /// 更新数据
  Future<int?> update(String table, Map<String, Object?> values);

  /// 批量插入数据
  // Future<int?> batchInsert(String table, List<Map<String, Object?>> addValueList, List<Map<String, Object?>> updateValueList);

  /// 删除数据
  Future<int?> delete(String table, {String? where, List<Object?>? whereArgs});

  /// 数据是否存在
  Future<int> exist(String table, int id);

  /// 释放
  Future<void> destroy();

  Future<void> reset();
}

/// 会话数据库操作接口
abstract class ChatInterface {
  void initChatDB(void Function(String? p1) registerTableFunc);

  /// 加载会话数据
  Future<List<Map<String, dynamic>>> loadChatList();

  Future<bool> isChatEmpty();

  /// 删除会话
  Future<int?> clearChat(int chatID);

  Future<Map<String, dynamic>?> getChatById(int chatID);

  Future<Map<String, dynamic>?> getChatByFriendId(int friendId);

  Future<void> updateChatMsgIdx(int chatId, int msgIdx);

  Future<void> updateChatTranslation(Chat chat);
}

/// 消息数据库操作接口
abstract class MessageInterface {
  void initMessageDB(void Function(String? p1) registerTableFunc);

  /// 加载消息数据
  Future<List<Map<String, dynamic>>> loadMessages(
    int chatID,
    int? chatIdx,
    int? count,
    int? hideMsgIdx,
  );

  /// 加载单条消息
  Future<Map<String, dynamic>?> loadMessage(int chatId, int messageId);

  /// 清理消息数据
  Future<int?> clearMessages(int chatID, {int? chatIdx});

  /// 搜索消息内容
  Future<List<Map<String, dynamic>>> searchMessage(
    String content, {
    String tbname = "",
    int chat_id = -1,
  });

  /// 搜索消息内容
  Future<List<Map<String, dynamic>>> searchUserMessage(
    int userId, {
    String tbname = "",
    int chat_id = -1,
  });

  /// 根据类型搜索消息
  Future<List<Map<String, dynamic>>> findMessage(int type);

  /// 获取最新一条消息
  Future<Map<String, dynamic>?> findLatestMessage(int chatId, int hideChatIdx);

  Future<List<Map<String, dynamic>>> findLatestMessages();

  /// 获取chat_idx之后的信息
  Future<List<Map<String, dynamic>>> findMessagesAfter(int chatId, int chatIdx);

  /// 获取未读消息的idx总和
  Future<List<Map<String, dynamic>>> loadMessagesByWhereClause(
    String where,
    List clauses,
    String? order,
    int? limit,
    int? offset, {
    String tbname = "",
    String orderBy = "",
  });

  Future<List<Map<String, dynamic>>> loadReSendMessage(int uid, int reSendTime);

  /// 获取自己最后发的消息
  Future<Map<String, dynamic>?> getMyLastSendMessage(int chatId);

  Future<int> getUnreadNum(int chatId, int lastReadIdx);

  Future<List<Map<String, dynamic>>> getListOfUnreadChats();

  Future<List<Map<String, dynamic>>> getChatMentionChatIdx();

  String getColdMessageTableName(int createTime);

  String getNextColdMessageTableName(String coldMessageTableName);

  Future<bool> isTableExists(String codeTableName);

  Future<List<String>> getColdMessageTables(int fromTime, int forward);

  Future<void> adjustHotMessageTable(
    int chatId,
    int readChatMsgIdx,
    int hideChatMsgIdx,
    int count,
  );

  Future<int> saveMessage(Message message);

  Future<List<Map<String, dynamic>>> getChatExpireMessages(int expire);

  Future<int> updateMessageContent(Message message);

  Future<int> getMessageCount(List<int> types,String? searchText);
}

/// 用户数据库操作接口
abstract class UserInterface {
  void initUserDB(void Function(String? p1) registerTableFunc);

  /// 加载消息数据
  Future<Map<String, dynamic>?> loadUser(int id);

  Future<List<Map<String, dynamic>>> loadAllUsers();

  updateUsers(List<Map<String, dynamic>> users);

  /// 清理消息数据
  Future<int?> clearUser();
}

abstract class GroupInterface {
  void initGroupDB(void Function(String?) registerTableFunc);

  /// 加载群组信息
  Future<List<Map<String, dynamic>>?> loadGroups();

  /// 清理群组数据
  Future<int?> clearGroup();

  Future<Map<String, dynamic>?> loadGroupById(int id);

  Future<List<Map<String, dynamic>>?> getGroupWithSlowMode();
}

abstract class ReactEmojiInterface {
  void initReactEmojiDB(
    void Function(String?) registerTableFunc,
  );

  /// 加载表情信息
  Future<List<Map<String, dynamic>>?> loadEmojis(int messageId, int chatId);
}

abstract class RedPacketInterface {
  void initRedPacketDB(void Function(String?) registerTableFunc);

  Future<List<Map<String, dynamic>>?> loadRedPacketStatus(int chatId);

  Future<Map<String, dynamic>> getSingleRedPacketStatus(String rpId);
}

abstract class CallLogInterface {
  void initCallLogDB(void Function(String? p1) registerTableFunc);

  Future<List<Map<String, dynamic>>> loadCallLogs({String rtcId});

  Future<int> getUnreadCall();

  Future<int> saveCallLog(Call call);

  Future<int?> removeCallLog(String id);

  Future<bool> isExist(String channelID);

  Future<int> updateCallRead();
}

abstract class SoundInterface {
  void initSoundDB(void Function(String?) registerTableFunc);

  Future<List<Map<String, dynamic>>?> loadSoundTrackList();

  Future<int?> clearSoundTable();
}

abstract class TagsInterface {
  void initTagsDB(void Function(String? p1) registerTableFunc);

  Future<int?> addTags(List<Map<String, dynamic>> tags);

  Future<Map<String, dynamic>?> loadTags(int id);

  Future<List<Map<String, dynamic>>> loadAllTags({int type = -1});

  Future<Map<int, List<dynamic>>> loadAllTagsByGroup({int type = -1});

  Future<List<User>> loadFriendsBindingTag({required int tagUid});

  Future<int?> deleteAllTags({int type = -1});

  Future<int?> clearTags();
}

abstract class FavouriteInterface {
  void initFavouriteDB(void Function(String?) registerTableFunc);

  Future<List<Map<String, dynamic>>> loadFavouriteList();

  Future<List<Map<String, dynamic>>> getNotUploadedFavourites();

  Future<List<Map<String, dynamic>>> getDataByID(int id);
}

abstract class FavouriteDetailInterface {
  void initFavouriteDetailDB(
    void Function(String?) registerTableFunc,
  );

  Future<int?> getLatestFavouriteDetailId();

  Future<List<Map<String, dynamic>>?> loadFavouriteDetailList();

  Future<int?> getSingleFavouriteDetail(int relatedId, String url);

  Future<List<Map<String, dynamic>>?> getFavouriteDetailList({
    int? typ,
    String? content,
  });

  Future<int?> deleteFavouriteDetailsByParentId(String parentId);

  Future<int?> deleteOldFavouriteDetails(String parentId, List<int> ids);

  Future<int?> deleteFavouriteDetailsById(List<int> ids);

  Future<int?> insertFavouriteDetailAndGetId(Map<String, dynamic> data);
}

abstract class RetryInterface {
  void initRetryDB(void Function(String? p1) registerTableFunc);

  Future<Map<String, dynamic>?> loadRetryItem(int id);

  Future<List<Map<String, dynamic>>> loadRetryItemByEndPoint(String endPoint);

  Future<List<Map<String, dynamic>>> loadAllRetryItems(int synced);

  Future<int?> deleteFinishRetry();

  Future<int?> clearRetryItems();
}

abstract class ChatCategoryInterface {
  void initChatCategoryDB(
    void Function(String?) registerTableFunc,
  );

  Future<bool> isChatCategoryEmpty();

  Future<List<Map<String, dynamic>>> getChatCategoryList();
}

abstract class ExploreMiniAppInterface {
  void initExploreMiniAppDB(void Function(String?) registerTableFunc);

  Future<int?> insertExploreMiniApp(Map<String, dynamic> data);

  Future<Map<String, dynamic>?> findExploreMiniAppById(String id);

  Future<List<Map<String, dynamic>>?> loadExploreMiniApps();

  Future<int?> clearExploreMiniAppTable();
}

abstract class RecentMiniAppInterface {
  void initRecentMiniAppDB(void Function(String?) registerTableFunc);

  Future<int?> insertRecentMiniApp(Map<String, dynamic> data);

  Future<Map<String, dynamic>?> findRecentMiniAppById(String id);

  Future<int?> removeRecentMiniApp(String id);

  Future<List<Map<String, dynamic>>?> loadRecentMiniApps();

  Future<int?> clearRecentMiniAppTable();
}

abstract class FavoriteMiniAppInterface {
  void initFavoriteMiniAppDB(void Function(String?) registerTableFunc);

  Future<int?> insertFavoriteMiniApp(Map<String, dynamic> data);

  Future<int?> removeFavoriteMiniApp(String id);

  Future<Map<String, dynamic>?> findFavoriteMiniAppById(String id);

  Future<List<Map<String, dynamic>>?> loadFavoriteMiniApps();

  Future<int?> clearFavoriteMiniAppTable();
}


abstract class DiscoverMiniAppInterface {
  void initDiscoverMiniAppDB(void Function(String?) registerTableFunc);

  Future<int?> insertDiscoverMiniApp(Map<String, dynamic> data);

  Future<List<Map<String, dynamic>>?> loadDiscoverMiniApps();

  Future<int?> clearDiscoverMiniAppTable();
}
