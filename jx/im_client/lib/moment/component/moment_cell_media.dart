part of '../index.dart';

class MomentCellMedia extends StatefulWidget {
  final String url;
  final String? gausPath;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const MomentCellMedia({
    super.key,
    required this.url,
    this.gausPath,
    this.width,
    this.height,
    this.fit,
  });

  @override
  State<MomentCellMedia> createState() => _MomentCellMediaState();
}

class _MomentCellMediaState extends State<MomentCellMedia> {
  final RxString source = ''.obs;

  @override
  void initState() {
    super.initState();
    _preloadImageSync();
  }

  void _preloadImageSync() {
    if (notBlank(widget.gausPath)) {
      source.value = imageMgr.getBlurHashSavePath(widget.url);
    }

    String? thumbPath = downloadMgrV2.getLocalPath(
      widget.url,
    );

    if (thumbPath != null) {
      source.value = widget.url;
      return;
    }

    _preloadImageAsync();
  }

  void _preloadImageAsync() async {
    DownloadResult result = await downloadMgrV2.download(
      widget.url,
      mini: Config().dynamicMin,
    );
    final thumbPath = result.localPath;

    if (thumbPath != null) {
      source.value = widget.url;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => RemoteImageV2(
        src: source.value,
        width: widget.width,
        height: widget.height,
        mini: source.value == imageMgr.getBlurHashSavePath(widget.url)
            ? null
            : Config().dynamicMin,
        fit: widget.fit,
        enableShimmer: true,
      ),
    );
  }
}
