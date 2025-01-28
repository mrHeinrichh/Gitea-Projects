class VolumeModel {
  String path = '';
  int second = 0;
  List<double> decibels = List.empty(growable: true);

  VolumeModel({
    required this.path,
    required this.second,
    required this.decibels,
  });
}
