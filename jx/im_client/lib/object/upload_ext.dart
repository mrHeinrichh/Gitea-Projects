enum UploadExt {
  image('Image'),
  video('Video'),
  document('Document'),
  reels('Reels'),
  speedTest('Speedtest');

  const UploadExt(this.value);

  final String value;
}

enum StorageType {
  image("image"),
  video("video"),
  document("document"),
  reels("reels"),
  sticker("sticker"),
  admin("admin"),
  moment("moment"),
  avatar("avatar"),
  favorite("favorite"),
  speedTest("speedtest");

  const StorageType(this.value);

  final String value;

  static bool permanentType(StorageType type) =>
      type != image && type != video && type != document;
}
