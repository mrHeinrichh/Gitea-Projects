
/// 批量上传接口
class MultipleFileUploadBean {
 late List<String> keys;

  MultipleFileUploadBean({required this.keys});

  MultipleFileUploadBean.fromJson(Map<String, dynamic> json) {
    List<String> list=List.empty(growable: true);
    if(json.containsKey('keys')){
      for(var item in json['keys']){
        list.add(item);
      }
    }
    keys = list;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['keys'] = this.keys;
    return data;
  }
}

