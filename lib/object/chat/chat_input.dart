import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

class ChatInput {
  ChatInputState state = ChatInputState.noTyping;
  int sendId = 0;
  int chatId = 0;
  String username = '';
  int currentTimestamp = 0;

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('state')) {
      state = ChatInputState.getType(json['state']);
    }
    if (json.containsKey('send_id')) sendId = json['send_id'];
    if (json.containsKey('chat_id')) chatId = json['chat_id'];
    if (json.containsKey('username')) username = json['username'];
  }

  Map<String, dynamic> toJson() {
    return {
      'state': state,
      'send_id': sendId,
      'chat_id': chatId,
      'username': username,
    };
  }
}

enum ChatInputState {
  typing(1),
  noTyping(2),
  sendImage(3),
  sendVideo(4),
  sendDocument(5),
  sendAlbum(6),
  sendVoice(7);

  const ChatInputState(this.value);

  final int value;

  static ChatInputState getType(int value) {
    switch (value) {
      case 1:
        return typing;
      case 2:
        return noTyping;
      case 3:
        return sendImage;
      case 4:
        return sendVideo;
      case 5:
        return sendDocument;
      case 6:
        return sendAlbum;
      case 7:
        return sendVoice;
      default:
        return noTyping;
    }
  }

  bool get isSendingMedia =>
      value == sendImage.value ||
      value == sendVideo.value ||
      value == sendDocument.value ||
      value == sendAlbum.value ||
      value == sendVoice.value;

  @override
  String toString() {
    switch (this) {
      case typing:
        return localized(chatTyping);
      case noTyping:
        return '';
      case sendImage:
        return localized(chatTagPhoto);
      case sendVideo:
        return localized(chatTagVideoCall);
      case sendDocument:
        return localized(chatTagFile);
      case sendAlbum:
        return localized(chatTagAlbum);
      case sendVoice:
        return localized(chatTagVoiceCall);
      default:
        return '';
    }
  }
}
