import 'package:get/get.dart';

T? getFindOrNull<T>(){
  bool isRegistered = GetInstance().isRegistered<T>();
  if(isRegistered){
    return Get.find<T>();
  }
  return null;
}
T getFindOrPut<T>(T instance){
  if(Get.isRegistered<T>()){
    return Get.find<T>();
  }else{
    Get.put<T>(instance);
    return Get.find<T>();
  }
}
