enum UploadExt {
  image('Image'),
  video('Video'),
  document('Document'),
  reels('Reels');

  const UploadExt(this.value);

  final String value;
}
