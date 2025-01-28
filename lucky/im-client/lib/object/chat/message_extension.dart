import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:im/im_plugin.dart';
import 'package:im_common/im_common.dart';
import 'package:im_mini_app_plugin/im_mini_app_plugin.dart';
import 'package:jxim_client/object/chat/message.dart';

import '../../im/model/group/group.dart';
import '../../main.dart';

extension MsgExtra on Message {
  String extractVipGroupContent() {
    MsgExtractModel model = MsgExtractModel.fromMessage(this);

    String content = '群组操作${this.typ}';
    if (model.bean != null) {
      RecordPagingItem bean = model.bean;
      RecordPagingItem? beanSelf = model.beanSelf;
      RecordPagingItem? beanForJumpPage = model.beanForJumpPage;
      Group? group = model.group;
      String callerName =
          '"${objectMgr.userMgr.getUserById(bean!.caller ?? 0)?.nickname ?? ''}"';
      if (bean!.caller == objectMgr.userMgr.mainUser.uid) {
        callerName = '您';
      }
      bool isCallerSelf = bean.caller == objectMgr.userMgr.mainUser.uid;
      String operatorName =
          objectMgr.userMgr.getUserById(bean.operator ?? 0)?.nickname ?? '';
      bool isOperatorSelf = bean.operator == objectMgr.userMgr.mainUser.uid;
      if (this.typ == messageTypeAddShareholders) {
        content = '【${group?.name}群】${isCallerSelf ? '您' : '已邀请' + callerName}成为群组股东，';
      } else if (this.typ == messageTypeKickShareholders) {
        content = '【${group?.name}群】${callerName}已被移出群组股东，';
      } else if (this.typ == messageTypeAddShareholder) {
        content =
            '【${group?.name}群】${isOperatorSelf ? '您' : '股东' + operatorName}已成功购买${bean.getShared()}%股份，支付${bean.amount}${bean.currency}，';
      } else if (this.typ == messageTypeReduceShareholder) {
        content =
            '【${group?.name}群】${isOperatorSelf ? '您' : '股东' + operatorName}已成功减持${bean.getShared()}%股份，收款${bean.amount}${bean.currency}，';
      } else if (this.typ == messageTypeIpo) {
        if (beanForJumpPage != null) {
          if (beanForJumpPage.status == ApiCode.IPO_RECORD_STATUS_FAILED ||
              beanForJumpPage.status == ApiCode.IPO_RECORD_STATUS_CANCLE ||
              beanForJumpPage.status == ApiCode.RECORD_STATUS_TIMEOUT ||
              beanForJumpPage.status == ApiCode.RECORD_STATUS_WALLET_SHY) {
            content = '【${group?.name}群】存在股东未按时追加投资，本次追加投资失败，资金将全额返还，';
          } else if (beanForJumpPage.status ==
              ApiCode.IPO_RECORD_STATUS_PENDING) {
            bool isOwner = beanSelf?.operator == objectMgr.userMgr.mainUser.uid;
            if (isOwner) {
              content =
                  '【${group?.name}群】您已发起投资，共需投资${bean.amount}${bean.currency}，您占股${(beanSelf?.shared ?? 0) / 100}%，已成功支付${beanSelf?.amount}${beanSelf?.currency}，等待${model.otherNum}位股东确认支付，';
            } else {
              if (beanSelf != null) {
                content =
                    '【${group?.name}群】群主发起投资，共需投资${bean.amount}${bean.currency}，您占股${(beanSelf?.shared ?? 0) / 100}%，需支付${beanSelf?.amount}${beanSelf?.currency}，请您尽快确认支付，有效期为15分钟，如超时未确认支付，则本次追加投资失败，';
              } else {
                content =
                    '【${group?.name}群】群主发起投资，共需投资${bean.amount}${bean.currency}，您占股0%，无需支付，';
              }
            }
          } else if (beanForJumpPage.status ==
              ApiCode.IPO_RECORD_STATUS_SUCCESS) {
            content = content =
                '【${group?.name}群】追加投资完成，已成功追加${bean.amount}${bean.currency}到群组钱包，';
          } else {}
        } else {}
      } else if (this.typ == messageTypeIpoUser) {
        content = '【${group?.name}群】${callerName}已同意追加投资，等待其他股东确认，';
      } else if (this.typ == messageTypeProfit) {
        if (beanSelf != null) {
          content =
              '【${group?.name}群】群组发起分红，共分红${bean.amount}${bean.currency}，您占股${(beanSelf?.shared ?? 0) / 100}%，将收到${beanSelf?.amount}${beanSelf?.currency}，稍后您将收到资金。';
        } else {
          content =
              '【${group?.name}群】群组发起分红，共分红${bean.amount}${bean.currency}，您占股0%，不会收到资金。';
        }
      } else if (this.typ == messageTypeTransferToApp) {
        content =
            '【${group?.name}群】群组钱包转入应用${bean.app_name}钱包 ${bean.amount}${bean.currency}成功';
      } else if (this.typ == messageTypeTransferToGroup) {
        content =
            '【${group?.name}群】应用${bean.app_name}钱包转出到群组钱包 ${bean.amount}${bean.currency}成功';
      } else if (this.typ == messageTypeGroupAppStateChange) {
        content = '【${group?.name}群】${bean.remark}。';
      } else if (this.typ == messageTypeGroupMessageChange) {
        content = '【${group?.name}群】${bean.remark}。';
      } else if (this.typ == messageTypeGroupAutoTurnChange) {
        content = '【${group?.name}群】${bean.remark}。';
      } else if (this.typ == messageTypeAddOperator) {
        content = '【${group?.name}群】${bean.remark}。';
      } else if (this.typ == messageTypeDelOperator) {
        content = '【${group?.name}群】${bean.remark}。';
      } else if (this.typ == messageTypeAddFinancier) {
        content = '【${group?.name}群】${bean.remark}。';
      } else if (this.typ == messageTypeDelFinancier) {
        content = '【${group?.name}群】${bean.remark}。';
      }
    }

    return content;
  }

  //有可点击的高亮文字 才可能有点击事件
  String extractTapAbleText() {
    MsgExtractModel model = MsgExtractModel.fromMessage(this);
    if (model.bean == null) return '';
    if (this.typ == messageTypeAddShareholders ||
        this.typ == messageTypeKickShareholders ||
        this.typ == messageTypeAddShareholder ||
        this.typ == messageTypeReduceShareholder) {
      return '股东管理';
    }

    if (this.typ == messageTypeIpo || this.typ == messageTypeIpoUser) {
      return '追加投资详情';
    }
    return '';
  }

  onDetailTapEvent(BuildContext context) {
    MsgExtractModel model = MsgExtractModel.fromMessage(this);
    if (model.bean == null) return;
    sharedDataManager.setGid(model.bean.gid ?? 0);
    if (model.group != null) {
      sharedDataManager.saveGroupInfo(model.group!.toJson());
    }

    if (this.typ == messageTypeAddShareholders ||
        this.typ == messageTypeKickShareholders ||
        this.typ == messageTypeAddShareholder ||
        this.typ == messageTypeReduceShareholder) {
      Navigator.of(context)
          .push(MaterialPageRoute(
              builder: (context) => ShareholderList.providerPage()))
          .then((value) {
        gameManager.onGameEnter(false);
      });
    }

    if (this.typ == messageTypeIpo) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) =>
                  AddInvestmentDetails.providerPageWithParams(
                      model.beanForJumpPage.toJson()))).then((value) {
        gameManager.onGameEnter(false);
      });
    }
    if (this.typ == messageTypeIpoUser) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) =>
                  AddInvestmentDetails.providerPageWithParams(
                      model.bean.toJson()))).then((value) {
        gameManager.onGameEnter(false);
      });
    }
  }
}

class MsgExtractModel {
  dynamic bean;
  dynamic beanForJumpPage;
  dynamic beanSelf; //分红的关于自己的bean
  int otherNum = 0;
  Group? group;

  MsgExtractModel.fromMessage(Message message) {
    String msg = message.content;
    Map<String, dynamic> map = {};
    try {
      map = jsonDecode(msg);

      RecordPagingItem beanTmp = RecordPagingItem.fromJson(map);
      bean = beanTmp;

      if (message.typ == messageTypeProfit || message.typ == messageTypeIpo) {
        if (map['rs'] != null && map['rs'].length > 0) {
          otherNum = map['rs'].length - 3;
          for (var value in map['rs']) {
            RecordPagingItem beanTmp = RecordPagingItem.fromJson(value);
            if (beanTmp.caller == objectMgr.userMgr.mainUser.uid) {
              beanSelf = beanTmp;
            }
          }
        }
        if (map['r'] != null && map['r'].length > 0) {
          var value = map['r'];
          RecordPagingItem beanTmp = RecordPagingItem.fromJson(value);
          beanForJumpPage = beanTmp;
        }
      }
    } catch (e) {
      print(e);
    }

    if (bean != null) {
      group = objectMgr.myGroupMgr.getGroupById(bean.gid ?? 0);
    }
  }
}
