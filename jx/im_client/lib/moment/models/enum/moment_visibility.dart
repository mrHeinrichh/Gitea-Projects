part of '../../index.dart';

enum MomentVisibility {
  public(1),
  specificFriends(2),
  hideFromSpecificFriends(3),
  private(4),
  specificBest(5),
  specificLabel(6),
  hideBest(7),
  hideLabel(8),
  subLabel(9);

  final int value;

  const MomentVisibility(this.value);

  factory MomentVisibility.fromValue(int value) {
    switch (value) {
      case 1:
        return MomentVisibility.public;
      case 2:
        return MomentVisibility.specificFriends;
      case 3:
        return MomentVisibility.hideFromSpecificFriends;
      case 4:
        return MomentVisibility.private;
      default:
        throw ArgumentError('Invalid value for MomentVisibility: $value');
    }
  }

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
      case MomentVisibility.specificBest:
        return localized(myFriends);
      case MomentVisibility.specificLabel:
        return localized(myEditLabelTitle);
      case MomentVisibility.hideBest:
        return localized(myFriends);
      case MomentVisibility.hideLabel:
        return localized(myEditLabelTitle);
      default:
        return localized(momentPublic);
    }
  }
}
