import 'package:get/get.dart';

const kSheetTitleHeight = 44.0;
const kSheetHeightMin = 44.0 + 34.0;
const kSheetHeightMax = 339.0;
const kSheetHeightFix = 339.0;

const kAnimationTime = Duration(milliseconds: 233);

final sheetHeight = kSheetHeightMax.obs;

final scStatus = 0.obs;
final scType = 1.obs;

enum SpecialContainerType {
  fix(),
  full();

  const SpecialContainerType();

  static SpecialContainerType fromIndex(
    int index,
  ) {
    return values.firstWhere((v) {
      return v.index == index;
    }, orElse: () {
      return SpecialContainerType.full;
    });
  }
}

enum SpecialContainerStatus {
  none(),
  min(),
  max();

  const SpecialContainerStatus();

  static SpecialContainerStatus fromIndex(
    int index,
  ) {
    return values.firstWhere((v) {
      return v.index == index;
    }, orElse: () {
      return SpecialContainerStatus.none;
    });
  }
}
