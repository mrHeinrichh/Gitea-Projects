import 'package:get/get.dart';
import 'package:jxim_client/moment/index.dart';
import 'package:jxim_client/object/tags.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';

class MomentLabelController extends GetxController {
  static const int LABEL_IS_NOT_EXIST = -999;

  final RxList<Tags> tagsList = <Tags>[].obs;

  final RxMap<int,List<User>> allTagByGroup = <int,List<User>>{}.obs;

  RxList<User> userList = <User>[].obs;

  Rx<MomentVisibility> viewPermission = MomentVisibility.public.obs;

  RxList<User> selectedFriends = <User>[].obs;

  RxList<User> selectLabelFriends = <User>[].obs;

  RxList<Tags> selectedLabel = <Tags>[].obs;

  bool isChange = false;

  void onPermissionSelect(Function changeCallback) {
    Get.toNamed(
      RouteName.momentPermission,
      arguments: {
        'momentVisibility': viewPermission.value,
        'selectFriends': userList,
        'selectLabel': tagsList.where((element) => element.uid!=LABEL_IS_NOT_EXIST).toList(),
      },
      preventDuplicates: false,
    )?.then((value) {
      if (value != null) {
        if (value is Map) {
          viewPermission.value = value['momentVisibility'];
          selectedFriends.value = value['selectFriends'] ?? [];
          selectedLabel.value = value['selectLabel'] ?? [];
          selectLabelFriends.value = value['selectLabelFriends'] ?? [];
          changeCallback.call(viewPermission.value,selectedFriends,selectedLabel,selectLabelFriends);
        }
      }
    });
  }
}