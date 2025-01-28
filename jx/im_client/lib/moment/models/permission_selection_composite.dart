import 'package:jxim_client/moment/index.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/debug_info.dart';

///用於測試PermissionSelectionComposite邏輯.
void main() {
  ///所有权限
  var permissionSelection = PermissionSelection();

  PermissionSelection specificFriends = PermissionSelection();
  specificFriends.momentVisibility = MomentVisibility.specificFriends;

  PermissionItem best = PermissionItem(MomentVisibility.specificBest);
  best.addFriend(User()..uid = 9999);
  best.addFriend(User()..uid = 12345678);

  PermissionSelection label = PermissionSelection();
  label.momentVisibility = MomentVisibility.specificLabel;

  PermissionItem label1 = PermissionItem(MomentVisibility.specificLabel);
  PermissionItem label2 = PermissionItem(MomentVisibility.specificLabel);

  label1.addFriend(User()..uid = 3345678);
  label2.addFriend(User()..uid = 22);

  label.addPermissionSelectionComponent(label1);
  label.addPermissionSelectionComponent(label2);

  specificFriends.addPermissionSelectionComponent(best);
  specificFriends.addPermissionSelectionComponent(label);

  PermissionSelection hideFromSpecificFriends = PermissionSelection();
  hideFromSpecificFriends.momentVisibility =
      MomentVisibility.hideFromSpecificFriends;

  permissionSelection
      .addPermissionSelectionComponent(PermissionItem(MomentVisibility.public));
  permissionSelection.addPermissionSelectionComponent(specificFriends);
  permissionSelection.addPermissionSelectionComponent(hideFromSpecificFriends);
  permissionSelection.addPermissionSelectionComponent(
    PermissionItem(MomentVisibility.private),
  );

  List<User> list = permissionSelection.getSelectFriends();

  for (var user in list) {
    pdebug("Select user: ${user.uid}");
  }
}

///Composite:
///1.有子Composite->PermissionSelectionComposite
///2.子Composite->PermissionItems.
///3.getSelectFriends()->遞迴取得所有選擇的朋友.
abstract class PermissionSelectionComposite {
  MomentVisibility momentVisibility = MomentVisibility.public;
  List<User> selectedFriends = [];
  List<String> selectedNames = [];
  getPermissionTitle();
  getType();
  List<User> getSelectFriends();
  List<String> getSelectLabel();

  getPermissionItem();
}

class PermissionSelection extends PermissionSelectionComposite {
  List<PermissionSelectionComposite> components = [];

  @override
  String getPermissionTitle() {
    return momentVisibility.title;
  }

  @override
  int getType() {
    return momentVisibility.value;
  }

  void addPermissionSelectionComponent(PermissionSelectionComposite permissionSelectionComponent,) {
    components.add(permissionSelectionComponent);
  }

  @override
  List<User> getSelectFriends() {
    List<User> users = [];
    for (var component in components) {
      users.addAll(component.getSelectFriends());
    }
    return users;
  }

  @override
  List<String> getSelectLabel() {
    List<String> labels = [];
    for (var component in components) {
      labels.addAll(component.getSelectLabel());
    }
    return labels;
  }

  @override
  List<PermissionSelectionComposite> getPermissionItem() {
    List<PermissionSelectionComposite> items = [];
    for (var component in components) {
      items.addAll(component.getPermissionItem());
    }
    return items;
  }
}

class PermissionItem extends PermissionSelectionComposite
{
  PermissionItem(MomentVisibility momentVisibility) {
    this.momentVisibility = momentVisibility;
  }

  @override
  List<PermissionItem> getPermissionItem() {
    return [this];
  }

  void addName(String name) {
    selectedNames.add(name);
  }

  @override
  String getPermissionTitle() {
    return momentVisibility.title;
  }

  @override
  int getType() {
    return momentVisibility.value;
  }

  addFriend(User user) {
    selectedFriends.add(user);
  }

  deleteFriend(User user) {
    selectedFriends.remove(user);
  }

  @override
  List<User> getSelectFriends() {
    return selectedFriends;
  }

  @override
  List<String> getSelectLabel() {
    return selectedNames;
  }
}
