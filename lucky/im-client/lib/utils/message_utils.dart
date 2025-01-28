import '../object/chat/message.dart';

final SearchableMessageType = [
  messageTypeText,
  messageTypeReply,
  messageTypeImage,
  messageTypeFile,
  messageTypeLink
];

String getMessageText(Message message) {
  switch (message.typ) {
    case messageTypeImage:
      return message.decodeContent(cl: MessageImage.creator).caption;
    case messageTypeFile:
      return message.decodeContent(cl: MessageFile.creator).caption;
    default:
      return message.decodeContent(cl: MessageText.creator).text;
  }
}

String getMediaMessagePath(Message message) {
  switch (message.typ) {
    case messageTypeImage:
      return message.decodeContent(cl: MessageImage.creator).url;
    case messageTypeVideo:
    case messageTypeReel:
      return message.decodeContent(cl: MessageVideo.creator).url;
    case messageTypeVoice:
      return message.decodeContent(cl: MessageVoice.creator).url;
    case messageTypeFile:
      return message.decodeContent(cl: MessageFile.creator).url;
    default:
      throw const FormatException('Invalid File Type');
  }
}
