import 'package:events_widget/event_dispatcher.dart';
import 'package:jxim_client/utils/utility.dart';

class PhotoViewEvent extends EventDispatcher {

  static const String eventPoint= "eventPoint";
  static const String eventChangePage= "eventChangePage";
  static const String eventScale= "eventScale";

  onPointEvent(int type, dynamic details,int index){
    event(this, eventPoint ,data: [type,index,details]);
  }

  onPageChnageEvent(dynamic index){
    event(this, eventChangePage ,data: index);
  }

  onScaleEvent(dynamic index,[double toScale = 1.0]){
    event(this, eventScale ,data: [index,toScale]);
  }

  int _nextTime = 0;
  doVibrate(){
    int curTime = DateTime.now().millisecondsSinceEpoch;
    if(_nextTime > 0 && _nextTime - curTime > 0) return;
    _nextTime = curTime + 50;
    littleVibrate();
  }
}