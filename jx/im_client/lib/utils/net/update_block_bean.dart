import 'dart:convert';

import 'package:jxim_client/data/db_message.dart';
import 'package:jxim_client/protobuf/push_client_message.pb.dart';
import 'package:jxim_client/utils/net/code_define.dart';

//// 自定义特殊表名
/// 订阅命令
const String cmdTopic = 'cmd_topic';

const String clientAction = 'client_action';

/// http
const String http = 'http';

/// 后台通知前端处理业务--提示或者拉新等等
const String sysOprate = 'sys_op';

///已读消息
const String chatReadOprate = 'chat_read_msg';

///删除消息
const String chatDeleteOprate = 'chat_del_msg';

/// 朋友圈长链接
const String momentOpt = 'moment';

const String tagsOpt = 'custom';

/// 历史消息
const String messageHistory = 'message_history';

/// pb格式的历史消息
const String pbMessageHistory = 'message_history_pb';

/// pb实时消息格式消息
const String pbRealTimeMessageHistory = 'message_realtime_pb';

//// 对象更新操作类型
/// 对象更新replace (new)
const blockOptReplace = 'r';

/// 对象更新update
const blockOptUpdate = 'u';

/// 对象更新delete
const blockOptDelete = 'd';

/// 获取数据
/// key 如:data.name
T? _getByPath<T>(dynamic object, String key, {T? def}) {
  var keys = key.split('.');
  dynamic obj = object;
  while (obj != null && keys.isNotEmpty) {
    String key0 = keys.removeAt(0);
    obj = obj[key0];
  }
  if (keys.isNotEmpty) {
    return def;
  }
  if (obj is T) {
    return obj;
  }
  return def;
}

/// http返回对象
class HttpResponseBean {
  //这个包的原始信息

  //源数据
  Map<String, dynamic>? _body;

  Map<String, dynamic>? get body {
    return _body;
  }

  String? _bodyStr;

  String? get bodyStr {
    if (_bodyStr == null && _body != null) {
      _bodyStr = jsonEncode(_body);
    }
    return _bodyStr;
  }

  //返回的代码
  int get code => _body?['code'];

  bool get success => code == CodeDefine.success;

  //风险等级 1 风险用户, 2 禁用这条记录
  int get level => _body?['level'] ?? 0;

  //返回的提示消息
  String get msg => _body?['msg'] ?? '';

  //返回的透传参数
  dynamic get pt => _body?['pt'];

  //data是map
  dynamic get data => _body?['data'];

  //datas是数组HttpResponseBean
  List get datas => _body?['datas'] is List ? (_body?['datas']) : [];

  HttpResponseBean(dynamic value, [String? uri, dynamic params]) {
    if (value is String) {
      _bodyStr = value;
      // 没有空对象的说法， 空对象就是空数组
      value = value.replaceAll("{}", "[]");
      _body = jsonDecode(value);
      if (_body?['code'] == null) {
        _body?['code'] = 0;
      }
    } else if (value is Map<String, dynamic>) {
      _body = value;
    }
  }

  /// 获取数据
  /// key 如:data.name
  T? get<T>(String key) {
    return _getByPath(_body, key);
  }

  /// 子节点遍历功能
  forEach(String key, void Function(dynamic, dynamic) action) {
    var keys = key.split('.');
    var obj = _body;
    while (obj != null && keys.isNotEmpty) {
      obj = obj[keys.removeAt(0)];
    }
    if (obj != null) {
      obj.forEach(action);
    }
  }

  @override
  String toString() {
    return '[$runtimeType] res:$_body';
  }
}

/// 订阅命令
class CmdTopicBean {
  String cmd;

  CmdTopicBean.created(this.cmd);
}

class ClientAction {
  int action;
  String requestId;
  dynamic data;
  int code;
  String message;

  ClientAction.created(
    this.action,
    this.requestId,
    this.data,
    this.code,
    this.message,
  );
}

/// 对象更新块信息
class UpdateBlockBean {
  /// 相关的操作 r/u/d/http
  static String? getOpt(json) => json['opt'];

  /// 相关的控制器/表名/对象名
  static String? getCtl(json) => json["ctl"];

  /// 相关的新数据
  static dynamic getData(json) => json['data'];

  static String printString(json) {
    return 'opt:${getOpt(json)}, ctl:${getCtl(json)}, json:$json';
  }

  /// 相关的操作 r/u/d/http
  late String opt;
  late String ctl;
  late dynamic data;

  UpdateBlockBean.created(this.opt, this.ctl, this.data);

  @override
  String toString() {
    return 'opt:$opt, ctl:$ctl, data:$data';
  }
}

/// 模拟短链接
class HttpUpdateBlockBean {
  final int seq;
  final int status;
  late dynamic body;

  HttpUpdateBlockBean.created(this.seq, this.status, this.body);
}

/// 通知行为
class SysOprate {
  final int type;
  final int subType;
  final String data;

  SysOprate.created(this.type, this.subType, this.data);

  @override
  String toString() {
    return 'type:$type, subType:$subType, data:$data';
  }
}

/// 对象更新解析
class UpdateBlockParser {
  final List<ClientAction> clientActions = [];

  /// 订阅命令
  final List<CmdTopicBean> cmdTopicBeans = [];

  /// 短连接返回
  final List<HttpUpdateBlockBean> httpUpdateBlockBeans = [];

  /// 对象更新的
  final List<UpdateBlockBean> updateBlockBeans = [];

  /// 通知行为
  final List<SysOprate> updateOprateBeans = [];

  /// 已读消息对象更新
  final List<UpdateBlockBean> updateChatReadBeans = [];

  /// 删除消息对象更新
  final List<UpdateBlockBean> updateChatDeleteBeans = [];

  /// 删除消息对象更新
  final List<UpdateBlockBean> updateMomentBeans = [];

  final List<UpdateBlockBean> messageHistoryBeans = [];

  final List<UpdateBlockBean> updateTagsBeans = [];

  final List<UpdateBlockBean> updateMomentVisibilityBeans = [];

  late Map<String, dynamic> data;

  UpdateBlockParser.created(String content) {
    data = jsonDecode(content);
    for (var tableName in data.keys) {
      if (tableName == cmdTopic) {
        // {"cmd_topic":{"r":[{"cmd":"+chat#785","id":2}]}}
        var obj = {tableName: data[tableName]};

        cmdTopicBeans.add(CmdTopicBean.created(jsonEncode(obj)));
      } else if (tableName == clientAction) {
        var obj = data[clientAction];
        List rows = obj['r'];
        for (var row in rows) {
          clientActions.add(
            ClientAction.created(
              row['action'],
              row['request_Id'],
              row['data'],
              row['code'],
              row['message'],
            ),
          );
        }
      } else if (tableName == http) {
        // // 模拟短连接
        List table = data[tableName];
        for (var item in table) {
          var body = item['body'];
          if (body is! String) {
            body = "{}";
          }
          httpUpdateBlockBeans.add(
            HttpUpdateBlockBean.created(
              item['seq'],
              item['status'],
              jsonDecode(body),
            ),
          );
        }
      } else if (tableName == sysOprate) {
        // // 模拟短连接
        // if (data[tableName] is! List) {
        //   pdebug('模拟短连接 http 数据结构不匹配');
        //   break;
        // }
        Map<String, dynamic> table = data[tableName];
        for (var opt in table.keys) {
          List rows = table[opt];
          for (var item in rows) {
            // 是否需要合并
            updateOprateBeans.add(
              SysOprate.created(
                item['type'],
                item['sub_type'],
                item['data'],
              ),
            );
          }
        }
      } else if (tableName == chatReadOprate) {
        Map<String, dynamic> table = data[tableName];
        for (var opt in table.keys) {
          List rows = table[opt];
          for (var item in rows) {
            updateChatReadBeans.add(
              UpdateBlockBean.created(
                opt,
                tableName,
                opt == blockOptReplace ? [item] : item,
              ),
            );
          }
        }
      } else if (tableName == chatDeleteOprate) {
        Map<String, dynamic> table = data[tableName];
        for (var opt in table.keys) {
          List rows = table[opt];
          for (var item in rows) {
            updateChatDeleteBeans.add(
              UpdateBlockBean.created(
                opt,
                tableName,
                opt == blockOptDelete ? [item] : item,
              ),
            );
          }
        }
      } else if (tableName == momentOpt) {
        Map<String, dynamic> table = data[tableName];
        for (var opt in table.keys) {
          List rows = table[opt];
          for (var item in rows) {
            updateMomentBeans.add(
              UpdateBlockBean.created(
                opt,
                tableName,
                opt == blockOptReplace ? [item] : item,
              ),
            );
          }
        }
      } else if (tableName == messageHistory) {
        Map<String, dynamic> table = data[tableName];
        for (var opt in table.keys) {
          List rows = table[opt];
          for (var item in rows) {
            messageHistoryBeans.add(
              UpdateBlockBean.created(
                opt,
                DBMessage.tableName,
                opt == blockOptReplace ? [item] : item,
              ),
            );
          }
        }
      } else if (tableName == pbMessageHistory) {
        Map<String, dynamic> table = data[tableName];
        for (var opt in table.keys) {
          List rows = table[opt];
          for (var item in rows) {
            item = parsePbMessage(item);
            messageHistoryBeans.add(
              UpdateBlockBean.created(
                opt,
                DBMessage.tableName,
                opt == blockOptReplace ? [item] : item,
              ),
            );
          }
        }
      } else if (tableName == pbRealTimeMessageHistory) {
        Map<String, dynamic> table = data[tableName];
        for (var opt in table.keys) {
          List rows = table[opt];
          for (var item in rows) {
            item = parsePbMessage(item);
            updateBlockBeans.add(
              UpdateBlockBean.created(
                opt,
                tableName,
                opt == blockOptReplace ? [item] : item,
              ),
            );
          }
        }
      } else if (tableName == tagsOpt) {
        Map<String, dynamic> table = data[tableName];
        for (var opt in table.keys) {
          List rows = table[opt];
          for (var item in rows) {
            if(item is Map && item.containsKey("channel") && item["channel"] == "moment"){
              updateMomentVisibilityBeans.add(
                UpdateBlockBean.created(
                  opt,
                  tableName,
                  opt == blockOptReplace ? [item] : item,
                ),
              );
            }else{
              updateTagsBeans.add(
                UpdateBlockBean.created(
                  opt,
                  tableName,
                  opt == blockOptReplace ? [item] : item,
                ),
              );
            }
          }
        }
      }
      else if (tableName != "message") {
        //实时消息改为 message_realtime_pb字段，之后message字段的内容将会被删除， 删除后改为else即可
        // 对象更新
        Map<String, dynamic> table = data[tableName];
        for (var opt in table.keys) {
          List rows = table[opt];
          for (var item in rows) {
            updateBlockBeans.add(
              UpdateBlockBean.created(
                opt,
                tableName,
                opt == blockOptReplace ? [item] : item,
              ),
            );
          }
        }
      }
    }
  }

  Map<String, dynamic> parsePbMessage(dynamic item) {
    ChatMessage chatMessage = ChatMessage.fromBuffer(base64.decode(item));
    Map<String, dynamic> message = {};
    message["id"] = chatMessage.id.toInt();
    message["chat_id"] = chatMessage.chatId.toInt();
    message["chat_idx"] = chatMessage.chatIdx.toInt();
    message["send_id"] = chatMessage.sendId.toInt();
    message["content"] = chatMessage.content;
    message["typ"] = chatMessage.typ.toInt();
    message["seq"] = chatMessage.seq.toInt();
    message["ref_id"] = chatMessage.refId.toInt();
    message["ref_typ"] = chatMessage.refTyp.toInt();
    message["ref_opt"] = chatMessage.refOpt.toInt();
    message["send_time"] = chatMessage.sendTime.toInt();
    message["expire_time"] = chatMessage.expireTime.toInt();
    message["create_time"] = chatMessage.createTime.toInt();
    message["update_time"] = chatMessage.updateTime.toInt();
    message["delete_time"] = chatMessage.deleted.toInt();
    message["deleted"] = chatMessage.deleted.toInt();
    message["at_user"] = chatMessage.atUser;
    message["cmid"] = chatMessage.cmid;
    return message;
  }
}
