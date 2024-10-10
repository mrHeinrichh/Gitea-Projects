part of '../../index.dart';

enum MomentNotificationType {
  postNotificationType(1),
  commentNotificationType(2),
  likeNotificationType(3),
  commentMentionNotificationType(4),
  deletePostNotificationType(5),
  deleteCommentNotificationType(6),
  deleteLikeNotificationType(7),
  postMentionNotificationType(8),
  reLikeLikeNotificationType(9);

  const MomentNotificationType(this.value);

  final int value;

  static MomentNotificationType fromValue(int value) {
    switch (value) {
      case 1:
        return MomentNotificationType.postNotificationType;
      case 2:
        return MomentNotificationType.commentNotificationType;
      case 3:
        return MomentNotificationType.likeNotificationType;
      case 4:
        return MomentNotificationType.commentMentionNotificationType;
      case 5:
        return MomentNotificationType.deletePostNotificationType;
      case 6:
        return MomentNotificationType.deleteCommentNotificationType;
      case 7:
        return MomentNotificationType.deleteLikeNotificationType;
      case 8:
        return MomentNotificationType.postMentionNotificationType;
      case 9:
        return MomentNotificationType.reLikeLikeNotificationType;
      default:
        throw ArgumentError(value);
    }
  }
}
