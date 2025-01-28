import 'package:events_widget/event_dispatcher.dart';

class UserPraiseModel extends EventDispatcher{
  int praiseCount = 0;
  int hasPraise = 0;

  applyJson(Map<String, dynamic> json) {
    if (json.containsKey('praise_count')) praiseCount = json['praise_count'];
    if (json.containsKey('has_praise')) hasPraise = json['has_praise'];
   }

   subPraise(int num){
    praiseCount -= num;
    praiseCount = praiseCount < 0? 0 : praiseCount;
   }
}
