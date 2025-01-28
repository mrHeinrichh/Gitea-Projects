class FaceUtil {

  final Map<String, String> _faceMap = <String, String>{};

  Map<String, String> get faceMap => _faceMap;

  static FaceUtil? _instance;

  static FaceUtil get instance {
    _instance ??= FaceUtil._();
    return _instance!;
  }

  FaceUtil._() {
    _faceMap['[amazed]'] = 'assets/images/message/face/amazed.png';
    _faceMap['[angry]'] = 'assets/images/message/face/angry.png';
    _faceMap['[beard]'] = 'assets/images/message/face/beard.png';
    _faceMap['[crying]'] = 'assets/images/message/face/crying.png';
    _faceMap['[dead]'] = 'assets/images/message/face/dead.png';
    _faceMap['[disappointed]'] = 'assets/images/message/face/disappointed.png';
    _faceMap['[embarrassed]'] = 'assets/images/message/face/embarrassed.png';
    _faceMap['[evil]'] = 'assets/images/message/face/evil.png';
    _faceMap['[friendly]'] = 'assets/images/message/face/friendly.png';
    _faceMap['[happiness]'] = 'assets/images/message/face/happiness.png';
    _faceMap['[happy]'] = 'assets/images/message/face/happy.png';
    _faceMap['[love]'] = 'assets/images/message/face/love.png';
    _faceMap['[sad]'] = 'assets/images/message/face/sad.png';
    _faceMap['[smile]'] = 'assets/images/message/face/smile.png';
    _faceMap['[grin]'] = 'assets/images/message/face/grin.png';
    _faceMap['[shy]'] = 'assets/images/message/face/shy.png';
    _faceMap['[speechless]'] = 'assets/images/message/face/speechless.png';
  }
}
