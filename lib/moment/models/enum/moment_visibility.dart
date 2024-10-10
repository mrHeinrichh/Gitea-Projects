part of '../../index.dart';

enum MomentVisibility {
  public(1),
  specificFriends(2),
  hideFromSpecificFriends(3),
  private(4),
  best(5),
  label(6),
  subLabel(7);

  const MomentVisibility(this.value);

  final int value;

  String get title {
    switch (this) {
      case MomentVisibility.public:
        return localized(momentPublic);
      case MomentVisibility.specificFriends:
        return localized(momentPermissionPartiallyVisible);
      case MomentVisibility.hideFromSpecificFriends:
        return localized(momentPermissionHiddenFrom);
      case MomentVisibility.private:
        return localized(momentPrivate);
      case MomentVisibility.best:
        return localized(myFriends);
      case MomentVisibility.label:
        return localized(myEditLabelTitle);
      default:
        return localized(momentPublic);
    }
  }
}
