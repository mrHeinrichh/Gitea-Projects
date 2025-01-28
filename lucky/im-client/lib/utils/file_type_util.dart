const List<String> documentExtension = <String>[
  'pdf',
  'ppt',
  'pptx',
  'doc',
  'docx',
  'docm',
  'csv',
  'xlsx',
  'xlsm',
  'xlsb',
];

const List<String> videoExtension = <String>[
  'avi',
  'mp4',
  'mov',
  'webm',
  'flv',
  'wmv',
  'm4v',
  'mpeg',
];

const List<String> imageExtension = <String>[
  'jpg',
  'jpeg',
  'png',
  'bmp',
  'webp',
  'tiff',
  'psd',
  'raw',
  'heif',
  'heic',
  'indd',
  'svg',
  'eps',
  'gif',
  "tgs"
];

const List<String> audioExtension = <String>[
  'mp3',
  'wav',
  'aac',
  'ogg',
  'flac',
  'm4a',
  'wma',
  'aiff',
  'alac',
  'amr',
  'au',
  'm4r',
  'mid',
  'midi',
  'mpa',
  'ra',
  'rm',
  'wv',
];

const List<String> animatedExtension = <String>[
  'gif',
];

const List<String> readableText = <String>[
  'txt', //Plain text files.
  'html', //HTML files (for web development).
  'css', //Cascading Style Sheets files (for web styling).
  'json', //JSON files (for data interchange).
  'js', //JavaScript files (for web scripting).
  'ts', //TypeScript files (a typed superset of JavaScript).
  'xml', //XML files (for data structure and configuration).
  'php', //PHP source code files (for server-side scripting).
  'py', //Python source code files (for general-purpose programming).
  'java', //Java source code files (for cross-platform applications).
  'c', //C source code files (for system-level programming).
  'cpp', //C++ source code files (for C++ programming).
  'css', //Cascading Style Sheets files (for web styling).
  'scss', //SCSS (Sass) style sheets (a CSS extension).
  'md', //Markdown files (for documentation and writing).
  'yaml', //YAML configuration files (for configuration management).
  'sql', //SQL database scripts (for database management).
  'sh', //Shell scripts (for automation and system tasks).
  'log', //Log files
];

enum FileType {
  document,
  video,
  image,
  gif,
  audio,
  allMedia,
  readableText,
  notFound,
}

FileType getFileType(String url) {
  String extensionName = url.split('.').last;
  if (documentExtension.contains(extensionName)) {
    return FileType.document;
  } else if (videoExtension.contains(extensionName)) {
    return FileType.video;
  } else if (imageExtension.contains(extensionName)) {
    return FileType.image;
  } else if (animatedExtension.contains(extensionName)) {
    // extensionName == 'gif'
    return FileType.gif;
  } else if (audioExtension.contains(extensionName)) {
    return FileType.audio;
  }
  // } else if (readableText.contains(extensionName)) {
  //   return FileType.readableText;
  // }

  return FileType.notFound;
}

String getFileNameWithExtension(String url) {
  return url.split('/').last;
}

String getFileExtension(String url) {
  return url.split('.').last;
}

String getFileName(String url) {
  List<String> parts = url.split("/");
  String lastPart = parts.last;

  int lastDotIndex = lastPart.lastIndexOf('.');

  if (lastDotIndex != -1) {
    // File has an extension
    return lastPart.substring(0, lastDotIndex);
  } else {
    // File does not have an extension
    return lastPart;
  }
}
