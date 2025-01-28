enum ResponseContentType {
  audio('audio'),
  document('document'),
  image('image'),
  video('video'),
  text('text');

  const ResponseContentType(this.type);

  final String type;

  static ResponseContentType getType(String contentType) {
    switch (contentType) {
      case 'audio':
      case 'audio/mpeg':
      case 'audio/x-ms-wma':
      case 'audio/vnd.rn-realaudio':
      case 'audio/x-wav':
        return ResponseContentType.audio;
      case 'image/gif':
      case 'image/jpeg':
      case 'image/png':
      case 'image/tiff':
      case 'image/vnd.microsoft.icon':
      case 'image/x-icon':
      case 'image/vnd.djvu':
      case 'image/svg+xml':
        return ResponseContentType.image;
      case 'video/mpeg':
      case 'video/mp4':
      case 'video/quicktime':
      case 'video/x-ms-wmv':
      case 'video/x-msvideo':
      case 'video/x-flv':
      case 'video/webm':
        return ResponseContentType.video;
      default:
        return ResponseContentType.text;
    }
  }
}
