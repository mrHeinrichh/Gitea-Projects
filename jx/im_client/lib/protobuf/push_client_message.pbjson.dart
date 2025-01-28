//
//  Generated code. Do not modify.
//  source: push_client_message.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use chatDescriptor instead')
const Chat$json = {
  '1': 'Chat',
  '2': [
    {'1': 'auto_delete_interval', '3': 1, '4': 1, '5': 13, '10': 'auto_delete_interval'},
    {'1': 'id', '3': 2, '4': 1, '5': 13, '10': 'id'},
    {'1': 'msg_idx', '3': 3, '4': 1, '5': 13, '10': 'msg_idx'},
    {'1': 'other_read_idx', '3': 4, '4': 1, '5': 13, '10': 'other_read_idx'},
    {'1': 'typ', '3': 5, '4': 1, '5': 13, '10': 'typ'},
    {'1': 'flag_my', '3': 6, '4': 1, '5': 13, '10': 'flag_my'},
    {'1': 'sort', '3': 8, '4': 1, '5': 13, '10': 'sort'},
    {'1': 'pin', '3': 9, '4': 3, '5': 11, '6': '.proto.ChatMessage', '10': 'pin'},
    {'1': 'hide_chat_msg_idx', '3': 10, '4': 1, '5': 13, '10': 'hide_chat_msg_idx'},
    {'1': 'read_chat_msg_idx', '3': 11, '4': 1, '5': 13, '10': 'read_chat_msg_idx'},
    {'1': 'chat_id', '3': 12, '4': 1, '5': 13, '10': 'chat_id'},
    {'1': 'user_id', '3': 13, '4': 1, '5': 13, '10': 'user_id'},
    {'1': 'unread_num', '3': 14, '4': 1, '5': 13, '10': 'unread_num'},
    {'1': 'mute', '3': 15, '4': 1, '5': 4, '10': 'mute'},
    {'1': 'start_idx', '3': 16, '4': 1, '5': 13, '10': 'start_idx'},
    {'1': 'create_time', '3': 17, '4': 1, '5': 13, '10': 'create_time'},
    {'1': 'friend_id', '3': 18, '4': 1, '5': 13, '10': 'friend_id'},
    {'1': 'last_time', '3': 21, '4': 1, '5': 13, '10': 'last_time'},
    {'1': 'verified', '3': 23, '4': 1, '5': 13, '10': 'verified'},
    {'1': 'icon', '3': 24, '4': 1, '5': 9, '10': 'icon'},
    {'1': 'name', '3': 25, '4': 1, '5': 9, '10': 'name'},
    {'1': 'profile', '3': 26, '4': 1, '5': 9, '10': 'profile'},
    {'1': 'icon_gaussian', '3': 27, '4': 1, '5': 9, '10': 'icon_gaussian'},
  ],
};

/// Descriptor for `Chat`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatDescriptor = $convert.base64Decode(
    'CgRDaGF0EjIKFGF1dG9fZGVsZXRlX2ludGVydmFsGAEgASgNUhRhdXRvX2RlbGV0ZV9pbnRlcn'
    'ZhbBIOCgJpZBgCIAEoDVICaWQSGAoHbXNnX2lkeBgDIAEoDVIHbXNnX2lkeBImCg5vdGhlcl9y'
    'ZWFkX2lkeBgEIAEoDVIOb3RoZXJfcmVhZF9pZHgSEAoDdHlwGAUgASgNUgN0eXASGAoHZmxhZ1'
    '9teRgGIAEoDVIHZmxhZ19teRISCgRzb3J0GAggASgNUgRzb3J0EiQKA3BpbhgJIAMoCzISLnBy'
    'b3RvLkNoYXRNZXNzYWdlUgNwaW4SLAoRaGlkZV9jaGF0X21zZ19pZHgYCiABKA1SEWhpZGVfY2'
    'hhdF9tc2dfaWR4EiwKEXJlYWRfY2hhdF9tc2dfaWR4GAsgASgNUhFyZWFkX2NoYXRfbXNnX2lk'
    'eBIYCgdjaGF0X2lkGAwgASgNUgdjaGF0X2lkEhgKB3VzZXJfaWQYDSABKA1SB3VzZXJfaWQSHg'
    'oKdW5yZWFkX251bRgOIAEoDVIKdW5yZWFkX251bRISCgRtdXRlGA8gASgEUgRtdXRlEhwKCXN0'
    'YXJ0X2lkeBgQIAEoDVIJc3RhcnRfaWR4EiAKC2NyZWF0ZV90aW1lGBEgASgNUgtjcmVhdGVfdG'
    'ltZRIcCglmcmllbmRfaWQYEiABKA1SCWZyaWVuZF9pZBIcCglsYXN0X3RpbWUYFSABKA1SCWxh'
    'c3RfdGltZRIaCgh2ZXJpZmllZBgXIAEoDVIIdmVyaWZpZWQSEgoEaWNvbhgYIAEoCVIEaWNvbh'
    'ISCgRuYW1lGBkgASgJUgRuYW1lEhgKB3Byb2ZpbGUYGiABKAlSB3Byb2ZpbGUSJAoNaWNvbl9n'
    'YXVzc2lhbhgbIAEoCVINaWNvbl9nYXVzc2lhbg==');

@$core.Deprecated('Use chatMessageDescriptor instead')
const ChatMessage$json = {
  '1': 'ChatMessage',
  '2': [
    {'1': 'at_user', '3': 1, '4': 1, '5': 9, '10': 'at_user'},
    {'1': 'chat_id', '3': 2, '4': 1, '5': 13, '10': 'chat_id'},
    {'1': 'chat_idx', '3': 3, '4': 1, '5': 13, '10': 'chat_idx'},
    {'1': 'content', '3': 4, '4': 1, '5': 9, '10': 'content'},
    {'1': 'create_time', '3': 5, '4': 1, '5': 13, '10': 'create_time'},
    {'1': 'delete_time', '3': 6, '4': 1, '5': 13, '10': 'delete_time'},
    {'1': 'deleted', '3': 7, '4': 1, '5': 13, '10': 'deleted'},
    {'1': 'expire_time', '3': 8, '4': 1, '5': 13, '10': 'expire_time'},
    {'1': 'id', '3': 9, '4': 1, '5': 4, '10': 'id'},
    {'1': 'ref_id', '3': 10, '4': 1, '5': 13, '10': 'ref_id'},
    {'1': 'ref_opt', '3': 11, '4': 1, '5': 13, '10': 'ref_opt'},
    {'1': 'ref_typ', '3': 12, '4': 1, '5': 13, '10': 'ref_typ'},
    {'1': 'send_id', '3': 13, '4': 1, '5': 13, '10': 'send_id'},
    {'1': 'seq', '3': 15, '4': 1, '5': 4, '10': 'seq'},
    {'1': 'typ', '3': 16, '4': 1, '5': 13, '10': 'typ'},
    {'1': 'update_time', '3': 17, '4': 1, '5': 13, '10': 'update_time'},
    {'1': 'send_time', '3': 18, '4': 1, '5': 4, '10': 'send_time'},
    {'1': 'cmid', '3': 19, '4': 1, '5': 9, '10': 'cmid'},
  ],
};

/// Descriptor for `ChatMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatMessageDescriptor = $convert.base64Decode(
    'CgtDaGF0TWVzc2FnZRIYCgdhdF91c2VyGAEgASgJUgdhdF91c2VyEhgKB2NoYXRfaWQYAiABKA'
    '1SB2NoYXRfaWQSGgoIY2hhdF9pZHgYAyABKA1SCGNoYXRfaWR4EhgKB2NvbnRlbnQYBCABKAlS'
    'B2NvbnRlbnQSIAoLY3JlYXRlX3RpbWUYBSABKA1SC2NyZWF0ZV90aW1lEiAKC2RlbGV0ZV90aW'
    '1lGAYgASgNUgtkZWxldGVfdGltZRIYCgdkZWxldGVkGAcgASgNUgdkZWxldGVkEiAKC2V4cGly'
    'ZV90aW1lGAggASgNUgtleHBpcmVfdGltZRIOCgJpZBgJIAEoBFICaWQSFgoGcmVmX2lkGAogAS'
    'gNUgZyZWZfaWQSGAoHcmVmX29wdBgLIAEoDVIHcmVmX29wdBIYCgdyZWZfdHlwGAwgASgNUgdy'
    'ZWZfdHlwEhgKB3NlbmRfaWQYDSABKA1SB3NlbmRfaWQSEAoDc2VxGA8gASgEUgNzZXESEAoDdH'
    'lwGBAgASgNUgN0eXASIAoLdXBkYXRlX3RpbWUYESABKA1SC3VwZGF0ZV90aW1lEhwKCXNlbmRf'
    'dGltZRgSIAEoBFIJc2VuZF90aW1lEhIKBGNtaWQYEyABKAlSBGNtaWQ=');

@$core.Deprecated('Use cmdTopicDescriptor instead')
const CmdTopic$json = {
  '1': 'CmdTopic',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 13, '10': 'id'},
    {'1': 'cmd', '3': 2, '4': 1, '5': 9, '10': 'cmd'},
  ],
};

/// Descriptor for `CmdTopic`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cmdTopicDescriptor = $convert.base64Decode(
    'CghDbWRUb3BpYxIOCgJpZBgBIAEoDVICaWQSEAoDY21kGAIgASgJUgNjbWQ=');

@$core.Deprecated('Use sysOpDescriptor instead')
const SysOp$json = {
  '1': 'SysOp',
  '2': [
    {'1': 'typ', '3': 1, '4': 1, '5': 13, '10': 'typ'},
    {'1': 'sub_type', '3': 2, '4': 1, '5': 13, '10': 'sub_type'},
    {'1': 'data', '3': 3, '4': 1, '5': 9, '10': 'data'},
  ],
};

/// Descriptor for `SysOp`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sysOpDescriptor = $convert.base64Decode(
    'CgVTeXNPcBIQCgN0eXAYASABKA1SA3R5cBIaCghzdWJfdHlwZRgCIAEoDVIIc3ViX3R5cGUSEg'
    'oEZGF0YRgDIAEoCVIEZGF0YQ==');

@$core.Deprecated('Use chatReadMessageDescriptor instead')
const ChatReadMessage$json = {
  '1': 'ChatReadMessage',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 13, '10': 'id'},
    {'1': 'other_read_idx', '3': 2, '4': 1, '5': 13, '10': 'other_read_idx'},
  ],
};

/// Descriptor for `ChatReadMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatReadMessageDescriptor = $convert.base64Decode(
    'Cg9DaGF0UmVhZE1lc3NhZ2USDgoCaWQYASABKA1SAmlkEiYKDm90aGVyX3JlYWRfaWR4GAIgAS'
    'gNUg5vdGhlcl9yZWFkX2lkeA==');

@$core.Deprecated('Use chatDelMessageDescriptor instead')
const ChatDelMessage$json = {
  '1': 'ChatDelMessage',
  '2': [
    {'1': 'chat_id', '3': 1, '4': 1, '5': 13, '10': 'chat_id'},
    {'1': 'id', '3': 2, '4': 3, '5': 4, '10': 'id'},
  ],
};

/// Descriptor for `ChatDelMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatDelMessageDescriptor = $convert.base64Decode(
    'Cg5DaGF0RGVsTWVzc2FnZRIYCgdjaGF0X2lkGAEgASgNUgdjaGF0X2lkEg4KAmlkGAIgAygEUg'
    'JpZA==');

@$core.Deprecated('Use groupMemberDescriptor instead')
const GroupMember$json = {
  '1': 'GroupMember',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 13, '10': 'user_id'},
    {'1': 'user_name', '3': 2, '4': 1, '5': 9, '10': 'user_name'},
    {'1': 'group_alias', '3': 3, '4': 1, '5': 9, '10': 'group_alias'},
    {'1': 'icon', '3': 4, '4': 1, '5': 9, '10': 'icon'},
    {'1': 'last_online', '3': 5, '4': 1, '5': 13, '10': 'last_online'},
    {'1': 'delete_time', '3': 6, '4': 1, '5': 13, '10': 'delete_time'},
    {'1': 'icon_gaussian', '3': 7, '4': 1, '5': 9, '10': 'icon_gaussian'},
  ],
};

/// Descriptor for `GroupMember`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List groupMemberDescriptor = $convert.base64Decode(
    'CgtHcm91cE1lbWJlchIYCgd1c2VyX2lkGAEgASgNUgd1c2VyX2lkEhwKCXVzZXJfbmFtZRgCIA'
    'EoCVIJdXNlcl9uYW1lEiAKC2dyb3VwX2FsaWFzGAMgASgJUgtncm91cF9hbGlhcxISCgRpY29u'
    'GAQgASgJUgRpY29uEiAKC2xhc3Rfb25saW5lGAUgASgNUgtsYXN0X29ubGluZRIgCgtkZWxldG'
    'VfdGltZRgGIAEoDVILZGVsZXRlX3RpbWUSJAoNaWNvbl9nYXVzc2lhbhgHIAEoCVINaWNvbl9n'
    'YXVzc2lhbg==');

@$core.Deprecated('Use chatGroupDescriptor instead')
const ChatGroup$json = {
  '1': 'ChatGroup',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 13, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'profile', '3': 3, '4': 1, '5': 9, '10': 'profile'},
    {'1': 'icon', '3': 4, '4': 1, '5': 9, '10': 'icon'},
    {'1': 'permission', '3': 5, '4': 1, '5': 13, '10': 'permission'},
    {'1': 'speak_interval', '3': 6, '4': 1, '5': 13, '10': 'speak_interval'},
    {'1': 'visible', '3': 7, '4': 1, '5': 13, '10': 'visible'},
    {'1': 'group_type', '3': 8, '4': 1, '5': 13, '10': 'group_type'},
    {'1': 'room_type', '3': 9, '4': 1, '5': 13, '10': 'room_type'},
    {'1': 'max_member', '3': 10, '4': 1, '5': 13, '10': 'max_member'},
    {'1': 'create_time', '3': 11, '4': 1, '5': 13, '10': 'create_time'},
    {'1': 'update_time', '3': 12, '4': 1, '5': 13, '10': 'update_time'},
    {'1': 'owner', '3': 13, '4': 1, '5': 13, '10': 'owner'},
    {'1': 'admins', '3': 14, '4': 3, '5': 13, '10': 'admins'},
    {'1': 'members', '3': 15, '4': 3, '5': 11, '6': '.proto.GroupMember', '10': 'members'},
    {'1': 'icon_gaussian', '3': 16, '4': 1, '5': 9, '10': 'icon_gaussian'},
  ],
};

/// Descriptor for `ChatGroup`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatGroupDescriptor = $convert.base64Decode(
    'CglDaGF0R3JvdXASDgoCaWQYASABKA1SAmlkEhIKBG5hbWUYAiABKAlSBG5hbWUSGAoHcHJvZm'
    'lsZRgDIAEoCVIHcHJvZmlsZRISCgRpY29uGAQgASgJUgRpY29uEh4KCnBlcm1pc3Npb24YBSAB'
    'KA1SCnBlcm1pc3Npb24SJgoOc3BlYWtfaW50ZXJ2YWwYBiABKA1SDnNwZWFrX2ludGVydmFsEh'
    'gKB3Zpc2libGUYByABKA1SB3Zpc2libGUSHgoKZ3JvdXBfdHlwZRgIIAEoDVIKZ3JvdXBfdHlw'
    'ZRIcCglyb29tX3R5cGUYCSABKA1SCXJvb21fdHlwZRIeCgptYXhfbWVtYmVyGAogASgNUgptYX'
    'hfbWVtYmVyEiAKC2NyZWF0ZV90aW1lGAsgASgNUgtjcmVhdGVfdGltZRIgCgt1cGRhdGVfdGlt'
    'ZRgMIAEoDVILdXBkYXRlX3RpbWUSFAoFb3duZXIYDSABKA1SBW93bmVyEhYKBmFkbWlucxgOIA'
    'MoDVIGYWRtaW5zEiwKB21lbWJlcnMYDyADKAsyEi5wcm90by5Hcm91cE1lbWJlclIHbWVtYmVy'
    'cxIkCg1pY29uX2dhdXNzaWFuGBAgASgJUg1pY29uX2dhdXNzaWFu');

@$core.Deprecated('Use friendDescriptor instead')
const Friend$json = {
  '1': 'Friend',
  '2': [
    {'1': 'uid', '3': 1, '4': 1, '5': 13, '10': 'uid'},
    {'1': 'chat_id', '3': 2, '4': 1, '5': 13, '10': 'chat_id'},
    {'1': 'profile_pic', '3': 3, '4': 1, '5': 9, '10': 'profile_pic'},
    {'1': 'is_acceptor', '3': 4, '4': 1, '5': 8, '10': 'is_acceptor'},
  ],
};

/// Descriptor for `Friend`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List friendDescriptor = $convert.base64Decode(
    'CgZGcmllbmQSEAoDdWlkGAEgASgNUgN1aWQSGAoHY2hhdF9pZBgCIAEoDVIHY2hhdF9pZBIgCg'
    'twcm9maWxlX3BpYxgDIAEoCVILcHJvZmlsZV9waWMSIAoLaXNfYWNjZXB0b3IYBCABKAhSC2lz'
    'X2FjY2VwdG9y');

@$core.Deprecated('Use friendRequestDescriptor instead')
const FriendRequest$json = {
  '1': 'FriendRequest',
  '2': [
    {'1': 'uid', '3': 1, '4': 1, '5': 13, '10': 'uid'},
  ],
};

/// Descriptor for `FriendRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List friendRequestDescriptor = $convert.base64Decode(
    'Cg1GcmllbmRSZXF1ZXN0EhAKA3VpZBgBIAEoDVIDdWlk');

@$core.Deprecated('Use authDescriptor instead')
const Auth$json = {
  '1': 'Auth',
  '2': [
    {'1': 'uid', '3': 1, '4': 1, '5': 13, '10': 'uid'},
    {'1': 'action', '3': 2, '4': 1, '5': 9, '10': 'action'},
    {'1': 'session_id', '3': 3, '4': 1, '5': 9, '10': 'session_id'},
    {'1': 'code', '3': 4, '4': 1, '5': 9, '10': 'code'},
  ],
};

/// Descriptor for `Auth`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List authDescriptor = $convert.base64Decode(
    'CgRBdXRoEhAKA3VpZBgBIAEoDVIDdWlkEhYKBmFjdGlvbhgCIAEoCVIGYWN0aW9uEh4KCnNlc3'
    'Npb25faWQYAyABKAlSCnNlc3Npb25faWQSEgoEY29kZRgEIAEoCVIEY29kZQ==');

@$core.Deprecated('Use notificationDescriptor instead')
const Notification$json = {
  '1': 'Notification',
  '2': [
    {'1': 'recipient_ids', '3': 1, '4': 3, '5': 13, '10': 'recipient_ids'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
    {'1': 'hidden_message', '3': 4, '4': 1, '5': 9, '10': 'hidden_message'},
    {'1': 'group_key', '3': 5, '4': 1, '5': 9, '10': 'group_key'},
  ],
};

/// Descriptor for `Notification`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List notificationDescriptor = $convert.base64Decode(
    'CgxOb3RpZmljYXRpb24SJAoNcmVjaXBpZW50X2lkcxgBIAMoDVINcmVjaXBpZW50X2lkcxIUCg'
    'V0aXRsZRgCIAEoCVIFdGl0bGUSGAoHbWVzc2FnZRgDIAEoCVIHbWVzc2FnZRImCg5oaWRkZW5f'
    'bWVzc2FnZRgEIAEoCVIOaGlkZGVuX21lc3NhZ2USHAoJZ3JvdXBfa2V5GAUgASgJUglncm91cF'
    '9rZXk=');

@$core.Deprecated('Use groupMemberChangeDescriptor instead')
const GroupMemberChange$json = {
  '1': 'GroupMemberChange',
  '2': [
    {'1': 'gid', '3': 1, '4': 1, '5': 13, '10': 'gid'},
    {'1': 'uid', '3': 2, '4': 1, '5': 13, '10': 'uid'},
    {'1': 'change_type', '3': 3, '4': 1, '5': 13, '10': 'change_type'},
    {'1': 'operator', '3': 4, '4': 1, '5': 13, '10': 'operator'},
  ],
};

/// Descriptor for `GroupMemberChange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List groupMemberChangeDescriptor = $convert.base64Decode(
    'ChFHcm91cE1lbWJlckNoYW5nZRIQCgNnaWQYASABKA1SA2dpZBIQCgN1aWQYAiABKA1SA3VpZB'
    'IgCgtjaGFuZ2VfdHlwZRgDIAEoDVILY2hhbmdlX3R5cGUSGgoIb3BlcmF0b3IYBCABKA1SCG9w'
    'ZXJhdG9y');

@$core.Deprecated('Use clientActionDescriptor instead')
const ClientAction$json = {
  '1': 'ClientAction',
  '2': [
    {'1': 'action', '3': 1, '4': 1, '5': 13, '10': 'action'},
    {'1': 'request_Id', '3': 2, '4': 1, '5': 9, '10': 'request_Id'},
    {'1': 'code', '3': 3, '4': 1, '5': 13, '10': 'code'},
    {'1': 'message', '3': 4, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `ClientAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientActionDescriptor = $convert.base64Decode(
    'CgxDbGllbnRBY3Rpb24SFgoGYWN0aW9uGAEgASgNUgZhY3Rpb24SHgoKcmVxdWVzdF9JZBgCIA'
    'EoCVIKcmVxdWVzdF9JZBISCgRjb2RlGAMgASgNUgRjb2RlEhgKB21lc3NhZ2UYBCABKAlSB21l'
    'c3NhZ2U=');

@$core.Deprecated('Use videoCallDescriptor instead')
const VideoCall$json = {
  '1': 'VideoCall',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `VideoCall`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List videoCallDescriptor = $convert.base64Decode(
    'CglWaWRlb0NhbGwSGAoHbWVzc2FnZRgBIAEoCVIHbWVzc2FnZQ==');

@$core.Deprecated('Use leaveChatDescriptor instead')
const LeaveChat$json = {
  '1': 'LeaveChat',
  '2': [
    {'1': 'chat_id', '3': 1, '4': 1, '5': 13, '10': 'chat_id'},
  ],
};

/// Descriptor for `LeaveChat`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List leaveChatDescriptor = $convert.base64Decode(
    'CglMZWF2ZUNoYXQSGAoHY2hhdF9pZBgBIAEoDVIHY2hhdF9pZA==');

@$core.Deprecated('Use pushClientMessageDescriptor instead')
const PushClientMessage$json = {
  '1': 'PushClientMessage',
  '2': [
    {'1': 'chat', '3': 1, '4': 1, '5': 11, '6': '.proto.Chat', '10': 'chat'},
    {'1': 'message', '3': 2, '4': 1, '5': 11, '6': '.proto.ChatMessage', '10': 'message'},
    {'1': 'cmd_topic', '3': 3, '4': 1, '5': 11, '6': '.proto.CmdTopic', '10': 'cmd_topic'},
    {'1': 'sys_op', '3': 4, '4': 1, '5': 11, '6': '.proto.SysOp', '10': 'sys_op'},
    {'1': 'chat_read_msg', '3': 5, '4': 1, '5': 11, '6': '.proto.ChatReadMessage', '10': 'chat_read_msg'},
    {'1': 'chat_del_msg', '3': 6, '4': 1, '5': 11, '6': '.proto.ChatDelMessage', '10': 'chat_del_msg'},
    {'1': 'chat_group', '3': 7, '4': 1, '5': 11, '6': '.proto.ChatGroup', '10': 'chat_group'},
    {'1': 'friend', '3': 8, '4': 1, '5': 11, '6': '.proto.Friend', '10': 'friend'},
    {'1': 'friend_request', '3': 9, '4': 1, '5': 11, '6': '.proto.FriendRequest', '10': 'friend_request'},
    {'1': 'auth', '3': 10, '4': 1, '5': 11, '6': '.proto.Auth', '10': 'auth'},
    {'1': 'notification', '3': 11, '4': 1, '5': 11, '6': '.proto.Notification', '10': 'notification'},
    {'1': 'group_member_change', '3': 12, '4': 1, '5': 11, '6': '.proto.GroupMemberChange', '10': 'group_member_change'},
    {'1': 'message_history', '3': 13, '4': 3, '5': 11, '6': '.proto.ChatMessage', '10': 'message_history'},
    {'1': 'client_action', '3': 14, '4': 1, '5': 11, '6': '.proto.ClientAction', '10': 'client_action'},
    {'1': 'video_call', '3': 15, '4': 1, '5': 11, '6': '.proto.VideoCall', '10': 'video_call'},
    {'1': 'leave_chat', '3': 16, '4': 1, '5': 11, '6': '.proto.LeaveChat', '10': 'leave_chat'},
  ],
};

/// Descriptor for `PushClientMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pushClientMessageDescriptor = $convert.base64Decode(
    'ChFQdXNoQ2xpZW50TWVzc2FnZRIfCgRjaGF0GAEgASgLMgsucHJvdG8uQ2hhdFIEY2hhdBIsCg'
    'dtZXNzYWdlGAIgASgLMhIucHJvdG8uQ2hhdE1lc3NhZ2VSB21lc3NhZ2USLQoJY21kX3RvcGlj'
    'GAMgASgLMg8ucHJvdG8uQ21kVG9waWNSCWNtZF90b3BpYxIkCgZzeXNfb3AYBCABKAsyDC5wcm'
    '90by5TeXNPcFIGc3lzX29wEjwKDWNoYXRfcmVhZF9tc2cYBSABKAsyFi5wcm90by5DaGF0UmVh'
    'ZE1lc3NhZ2VSDWNoYXRfcmVhZF9tc2cSOQoMY2hhdF9kZWxfbXNnGAYgASgLMhUucHJvdG8uQ2'
    'hhdERlbE1lc3NhZ2VSDGNoYXRfZGVsX21zZxIwCgpjaGF0X2dyb3VwGAcgASgLMhAucHJvdG8u'
    'Q2hhdEdyb3VwUgpjaGF0X2dyb3VwEiUKBmZyaWVuZBgIIAEoCzINLnByb3RvLkZyaWVuZFIGZn'
    'JpZW5kEjwKDmZyaWVuZF9yZXF1ZXN0GAkgASgLMhQucHJvdG8uRnJpZW5kUmVxdWVzdFIOZnJp'
    'ZW5kX3JlcXVlc3QSHwoEYXV0aBgKIAEoCzILLnByb3RvLkF1dGhSBGF1dGgSNwoMbm90aWZpY2'
    'F0aW9uGAsgASgLMhMucHJvdG8uTm90aWZpY2F0aW9uUgxub3RpZmljYXRpb24SSgoTZ3JvdXBf'
    'bWVtYmVyX2NoYW5nZRgMIAEoCzIYLnByb3RvLkdyb3VwTWVtYmVyQ2hhbmdlUhNncm91cF9tZW'
    '1iZXJfY2hhbmdlEjwKD21lc3NhZ2VfaGlzdG9yeRgNIAMoCzISLnByb3RvLkNoYXRNZXNzYWdl'
    'Ug9tZXNzYWdlX2hpc3RvcnkSOQoNY2xpZW50X2FjdGlvbhgOIAEoCzITLnByb3RvLkNsaWVudE'
    'FjdGlvblINY2xpZW50X2FjdGlvbhIwCgp2aWRlb19jYWxsGA8gASgLMhAucHJvdG8uVmlkZW9D'
    'YWxsUgp2aWRlb19jYWxsEjAKCmxlYXZlX2NoYXQYECABKAsyEC5wcm90by5MZWF2ZUNoYXRSCm'
    'xlYXZlX2NoYXQ=');

