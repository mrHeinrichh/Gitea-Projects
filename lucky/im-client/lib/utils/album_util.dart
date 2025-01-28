import 'package:flutter/material.dart';
import '../../../utils/config.dart';
import '../managers/object_mgr.dart';
import '../object/chat/message.dart';
import 'cache_image.dart';

/// 1 1
/// 1 2
/// 3 2
/// 4 2或3
/// 5 3
/// 6 3
///7 3
/// 8 4
/// 9 3
///  分横向排列 和纵项排列 高度固定
///  先全部排列
///  实际根据图片的宽高来采用不同的布局
class AlbumUtil {
  ///ObjectMgr.screenMQ!.size.height * 0.4 * maxWidthRatio
  /// 等比例缩放
  static getMaxHeight(List assetList1, double maxWidthRatio) {
    // double baseHeight = ObjectMgr.screenMQ!.size.height * 0.2 * maxWidthRatio;
    // double maxHeight = baseHeight * 2;
    // if (assetList1.length < 4) {
    //   return maxHeight;
    // } else {
    //   int k = (assetList1.length / 2).ceil();
    //   return (k * baseHeight + (k - 1) * 2).toDouble();
    // }
    int length = assetList1.length;
    switch (length) {
      case 1:
      case 2:
        return ObjectMgr.screenMQ!.size.width * (294 / _height);
      case 3:
      case 4: // 294 153 153
      case 5: //223
      case 6: //256 191
      case 7:
      case 8:
      case 9:
      case 10:
      case 11:
      case 12:
        return ObjectMgr.screenMQ!.size.width * (448 / _height);
    }
    return ObjectMgr.screenMQ!.size.width * (448 / _height);
  }

  static Widget buildGrid(
      {required List items,
      required bool isDesktop,
      bool isSender = false,
      bool isForwardMessage = false,
      bool isBorderRadius = false,
      required void Function(int index) onShowAlbum,
      required double maxWidthRatio}) {
    bool isRow = getArrayType(items);
    if (isRow) {
      return Row(
        children: buildRow(
          items: items,
          isDesktop: isDesktop,
          isSender: isSender,
          isForwardMessage: isForwardMessage,
          isBorderRadius: isBorderRadius,
          onShowAlbum: onShowAlbum,
          maxWidthRatio: maxWidthRatio,
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: buildColumn(
        items: items,
        isDesktop: isDesktop,
        isSender: isSender,
        isForwardMessage: isForwardMessage,
        isBorderRadius: isBorderRadius,
        onShowAlbum: onShowAlbum,
        maxWidthRatio: maxWidthRatio,
      ),
    );
  }

  /// 根据后台返回的宽高，采用横向或者纵向的布局
  /// todo 这里采用算法 算出排列方式 后面做优化
  static bool getArrayType(List items) {
    if (items.length == 2) {
      return true;
    }
    return false;
  }

  static List<Widget> buildRow(
      {required List items,
      required bool isDesktop,
      bool isSender = false,
      bool isForwardMessage = false,
      bool isBorderRadius = false,
      required void Function(int index) onShowAlbum,
      required double maxWidthRatio}) {
    if (items.length == 2) {
      return buildRow2(items, isBorderRadius, isSender, isForwardMessage,
          isDesktop, onShowAlbum, maxWidthRatio);
    }
    return [const SizedBox()];
  }

  /// 纵向排列
  static List<Widget> buildColumn(
      {required List items,
      required bool isDesktop,
      bool isSender = false,
      bool isForwardMessage = false,
      bool isBorderRadius = false,
      required void Function(int index) onShowAlbum,
      required double maxWidthRatio}) {
    int length = items.length;
    switch (length) {
      case 1:
        return buildColumn1(items, isDesktop, isSender, isForwardMessage,
            isBorderRadius, onShowAlbum, maxWidthRatio);
      case 3:
        return buildColumn3(items, isDesktop, isSender, isForwardMessage,
            isBorderRadius, onShowAlbum, maxWidthRatio);
      case 4:
        return buildColumn4(
            items,
            isDesktop,
            isSender,
            isForwardMessage,
            isBorderRadius,
            onShowAlbum,
            maxWidthRatio,
            [CellSize.cell4, CellSize.cell4]);
      case 5:
        return buildColumn5(items, isDesktop, isSender, isForwardMessage,
            isBorderRadius, onShowAlbum, maxWidthRatio);
      case 6:
        return buildColumn4(
            items,
            isDesktop,
            isSender,
            isForwardMessage,
            isBorderRadius,
            onShowAlbum,
            maxWidthRatio,
            [CellSize.cell6, CellSize.cell6]);
      case 7:
        return buildColumn7(items, isDesktop, isSender, isForwardMessage,
            isBorderRadius, onShowAlbum, maxWidthRatio);
      case 8:
        return buildColumn8(items, isDesktop, isSender, isForwardMessage,
            isBorderRadius, onShowAlbum, maxWidthRatio);
      case 9:
        return buildColumn9(items, isDesktop, isSender, isForwardMessage,
            isBorderRadius, onShowAlbum, maxWidthRatio);
      case 10:
        return buildColumn10(items, isDesktop, isSender, isForwardMessage,
            isBorderRadius, onShowAlbum, maxWidthRatio);
      default:
    }

    if (items.length % 2 == 0) {
      return buildColumnEven(items, isDesktop, maxWidthRatio, isBorderRadius,
          isSender, isForwardMessage, onShowAlbum);
    } else {
      return buildColumnOdd(items, isDesktop, maxWidthRatio, isBorderRadius,
          isSender, isForwardMessage, onShowAlbum);
    }
  }

  static List<Widget> buildColumn1(
      List<dynamic> items,
      bool isDesktop,
      bool isSender,
      bool isForwardMessage,
      bool isBorderRadius,
      void onShowAlbum(int index),
      double maxWidthRatio) {
    return [
      expandedCell(
        data: items[0],
        isDesktop: isDesktop,
        isSender: isSender,
        isForwardMessage: isForwardMessage,
        isBorderRadius: isBorderRadius,
        onShowAlbum: onShowAlbum,
        maxWidthRatio: maxWidthRatio,
        borderRadius: getBorderRadius(BorderRadiusType.all,
            isSender: isSender, isForwardMessage: isForwardMessage),
        height: getCellHeight(CellSize.cell1),
        width: getCellWidth(CellSize.cell1),
        index: 0,
      ),
    ];
  }

  /// 两个的排列
  static List<Widget> buildRow2(
      List<dynamic> items,
      bool isBorderRadius,
      bool isSender,
      bool isForwardMessage,
      bool isDesktop,
      void onShowAlbum(int index),
      double maxWidthRatio) {
    return [
      expandedCell(
        data: items[0],
        isDesktop: isDesktop,
        isSender: isSender,
        isForwardMessage: isForwardMessage,
        isBorderRadius: isBorderRadius,
        onShowAlbum: onShowAlbum,
        maxWidthRatio: maxWidthRatio,
        borderRadius:  borderRadiusLeft(
            isSender: isSender, isForwardMessage: isForwardMessage),
        height: getCellHeight(CellSize.cell2),
        width: getCellWidth(CellSize.cell2),
        index: 0,
      ),
      const SizedBox(width: 2),
      expandedCell(
        data: items[1],
        isDesktop: isDesktop,
        isSender: isSender,
        isForwardMessage: isForwardMessage,
        isBorderRadius: isBorderRadius,
        onShowAlbum: onShowAlbum,
        maxWidthRatio: maxWidthRatio,
        borderRadius: borderRadiusRight(
            isSender: isSender, isForwardMessage: isForwardMessage),
        height: getCellHeight(CellSize.cell2),
        width: getCellWidth(CellSize.cell2),
        index: 1,
      ),
    ];
  }

  static Expanded expandedCell(
      {required final data,
      required bool isDesktop,
      bool isSender = false,
      bool isForwardMessage = false,
      bool isBorderRadius = false,
      required BorderRadius borderRadius,
      required double height,
      required double width,
      required int index,
      required void Function(int index) onShowAlbum,
      required double maxWidthRatio}) {
    return Expanded(
      child: buildContent(
        data,
        index,
        height: height,
        width: width,
        borderRadius: borderRadius,
        isDesktop: isDesktop,
        isSender: isSender,
        isForwardMessage: isForwardMessage,
        isBorderRadius: isBorderRadius,
        onShowAlbum: onShowAlbum,
        maxWidthRatio: maxWidthRatio,
      ),
    );
  }

  static String getClearPic(String _imageUrl) {
    String? _fullLink;
    if (_imageUrl != null) {
      if (_imageUrl.contains('x${Config().messageMin}')) {
        _fullLink = _imageUrl.replaceAll('x${Config().messageMin}', '');
      } else if (_imageUrl.contains('x${Config().dynamicMin}')) {
        _fullLink = _imageUrl.replaceAll('x${Config().dynamicMin}', '');
      } else if (_imageUrl.contains('x${Config().headMin}')) {
        _fullLink = _imageUrl.replaceAll('x${Config().headMin}', '');
      }
    }
    return _fullLink ?? _imageUrl;
  }

  static Widget buildContent(final data, int index,
      {required bool isDesktop,
      bool isSender = false,
      bool isForwardMessage = false,
      bool isBorderRadius = false,
      required void Function(int index) onShowAlbum,
      required double maxWidthRatio,
      double? height,
      double? width,
      BorderRadius borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(4),
        topRight: Radius.circular(4),
        bottomLeft: Radius.circular(4),
        bottomRight: Radius.circular(4),
      )}) {
    return GestureDetector(
      onTap: () => onShowAlbum(index),
      child: data is MessageImage
          ? ClipRRect(
              borderRadius: borderRadius,
              child: RemoteImage(
                src: data.url,
                width: width ??
                    (isDesktop
                        ? 200
                        : ObjectMgr.screenMQ!.size.width * (maxWidthRatio / 2)),
                height: height != null
                    ? height
                    : ObjectMgr.screenMQ!.size.height * 0.4,
                fit: BoxFit.cover,
              ),
            )
          : Stack(
              children: <Widget>[
                Center(
                    child: RemoteImage(
                  src: data.cover,
                  width: isDesktop
                      ? 200
                      : width != null
                          ? width
                          : ObjectMgr.screenMQ!.size.width *
                              (maxWidthRatio / 2),
                  height: height != null
                      ? height
                      : ObjectMgr.screenMQ!.size.height * 0.4,
                  fit: BoxFit.fitWidth,
                )),
                Positioned.fill(child: _buildCover()),
              ],
            ),
    );
  }

  static Widget _buildCover() {
    return Container(
      color: Colors.black.withAlpha(130),
      alignment: Alignment.center,
      child: Image.asset(
        'assets/images/message/video_play.png',
        width: 30,
        height: 30,
      ),
    );
  }

  static BorderRadius getBorderRadius(BorderRadiusType type,
      {bool isSender = false, bool isForwardMessage = false}) {
    switch (type) {
      case BorderRadiusType.middle:
        return BorderRadius.zero;
      case BorderRadiusType.leftTop:
        return borderRadiusTopRight(
            isSender: isSender, isForwardMessage: isForwardMessage);
      case BorderRadiusType.rightTop:
        return borderRadiusTopRight(
            isSender: isSender, isForwardMessage: isForwardMessage);
      case BorderRadiusType.leftBottom:
        return borderRadiusBottomLeft(
            isSender: isSender, isForwardMessage: isForwardMessage);
      case BorderRadiusType.rightBottom:
        return borderRadiusBottomRight(
            isSender: isSender, isForwardMessage: isForwardMessage);
      case BorderRadiusType.top:
        return borderRadiusTop(
            isSender: isSender, isForwardMessage: isForwardMessage);
      case BorderRadiusType.bottom:
        return borderRadiusBottom(
            isSender: isSender, isForwardMessage: isForwardMessage);
      case BorderRadiusType.left:
        return borderRadiusLeft(
            isSender: isSender, isForwardMessage: isForwardMessage);
      case BorderRadiusType.right:
        return borderRadiusRight(
            isSender: isSender, isForwardMessage: isForwardMessage);
      case BorderRadiusType.all:
        return borderRadiusAll(
            isSender: isSender, isForwardMessage: isForwardMessage);
    }
  }

  static BorderRadius borderRadiusBottom({
    bool isSender = false,
    bool isForwardMessage = false,
  }) {
    return BorderRadius.only(
      bottomLeft: Radius.circular(isBigRadius(isForwardMessage, isSender,isLeft: true)),
      bottomRight: Radius.circular(isBigRadius(isForwardMessage, isSender)),
    );
  }

  static BorderRadius borderRadiusTop({
    bool isSender = false,
    bool isForwardMessage = false,
  }) {
    return BorderRadius.only(
      topLeft: Radius.circular(isBigRadius(isForwardMessage, isSender,isLeft: true)),
      topRight: Radius.circular(isBigRadius(isForwardMessage, isSender)),
    );
  }

  static BorderRadius borderRadiusBottomLeft({
    bool isSender = false,
    bool isForwardMessage = false,
  }) {
    return BorderRadius.only(
      bottomLeft: Radius.circular(
          isBigRadius(isForwardMessage, isSender, isLeft: true)),
    );
  }

  static BorderRadius borderRadiusBottomRight({
    bool isSender = false,
    bool isForwardMessage = false,
  }) {
    return BorderRadius.only(
      bottomRight: Radius.circular(isBigRadius(isForwardMessage, isSender)),
    );
  }

  static double isBigRadius(bool isForwardMessage, bool isSender,
      {bool isLeft = false}) {
    if (!isLeft) {
      return isForwardMessage || !isSender ? 4 : 16;
    } else {
      return !isSender ? 16 : 4;
    }
  }

  static BorderRadius borderRadiusTopRight({
    bool isSender = false,
    bool isForwardMessage = false,
  }) {
    return BorderRadius.only(
      topRight: Radius.circular(isBigRadius(isForwardMessage, isSender)),
    );
  }

  static BorderRadius borderRadiusTopLeft({
    bool isSender = false,
    bool isForwardMessage = false,
  }) {
    return BorderRadius.only(
      topLeft: Radius.circular(isBigRadius(isForwardMessage, isSender,isLeft: true)),
    );
  }

  static BorderRadius borderRadiusLeft({
    bool isSender = false,
    bool isForwardMessage = false,
  }) {
    return BorderRadius.only(
      topLeft: Radius.circular(isBigRadius(isForwardMessage, isSender,isLeft: true)),
      bottomLeft: Radius.circular(isBigRadius(isForwardMessage, isSender,isLeft: true)),
    );
  }

  static BorderRadius borderRadiusRight({
    bool isSender = false,
    bool isForwardMessage = false,
  }) {
    return BorderRadius.only(
      topRight: Radius.circular(isBigRadius(isForwardMessage, isSender)),
      bottomRight: Radius.circular(isBigRadius(isForwardMessage, isSender)),
    );
  }

  static BorderRadius borderRadiusAll({
    bool isSender = false,
    bool isForwardMessage = false,
  }) {
    return BorderRadius.only(
      topLeft: Radius.circular(isBigRadius(isForwardMessage, isSender,isLeft: true)),
      topRight: Radius.circular(isBigRadius(isForwardMessage, isSender)),
      bottomLeft: Radius.circular(isBigRadius(isForwardMessage, isSender,isLeft: true)),
      bottomRight: Radius.circular(isBigRadius(isForwardMessage, isSender)),
    );
  }

  static AlbumType type = AlbumType.unknown;

  AlbumType getType(List assetList1) {
    for (Message msg in assetList1) {
      if (msg.deleted != 1) {
        if (msg.typ == messageTypeImage) {
          return AlbumType.image;
        } else {
          return AlbumType.video;
        }
      }
    }
    return AlbumType.unknown;
  }

  static List<Widget> buildColumnEven(
      List items,
      bool isDesktop,
      double maxWidthRatio,
      bool isBorderRadius,
      bool isSender,
      bool isForwardMessage,
      void Function(int index) onShowAlbum) {
    List<Widget> list = [];
    int size = items.length ~/ 2;
    for (int i = 0; i < size; i++) {
      BorderRadius borderRadius1 = BorderRadius.zero;
      BorderRadius borderRadius2 = BorderRadius.zero;
      if (i == 0) {
        borderRadius1 = borderRadiusTopLeft(
            isSender: isSender, isForwardMessage: isForwardMessage);
        borderRadius2 = borderRadiusTopRight(
            isSender: isSender, isForwardMessage: isForwardMessage);
      } else if (size - 1 == i) {
        borderRadius1 = borderRadiusBottomLeft(
            isSender: isSender, isForwardMessage: isForwardMessage);
        borderRadius2 = borderRadiusBottomRight(
            isSender: isSender, isForwardMessage: isForwardMessage);
      }
      list.add(Row(
        children: [
          Expanded(
            child: buildContent(
              items[i * 2],
              i * 2,
              height: ObjectMgr.screenMQ!.size.height * 0.2 * maxWidthRatio,
              width: ObjectMgr.screenMQ!.size.width * (maxWidthRatio),
              isDesktop: isDesktop,
              isSender: isSender,
              isForwardMessage: isForwardMessage,
              isBorderRadius: isBorderRadius,
              onShowAlbum: onShowAlbum,
              maxWidthRatio: maxWidthRatio,
              borderRadius: borderRadius1,
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: buildContent(
              items[i * 2 + 1],
              i * 2 + 1,
              height: ObjectMgr.screenMQ!.size.height * 0.2 * maxWidthRatio,
              width: ObjectMgr.screenMQ!.size.width * (maxWidthRatio),
              isDesktop: isDesktop,
              isSender: isSender,
              isForwardMessage: isForwardMessage,
              isBorderRadius: isBorderRadius,
              onShowAlbum: onShowAlbum,
              maxWidthRatio: maxWidthRatio,
              borderRadius: borderRadius2,
            ),
          ),
        ],
      ));
      if (i != size - 1) {
        list.add(const SizedBox(height: 2));
      }
    }
    return list;
  }

  static List<Widget> buildColumnOdd(
      List items,
      bool isDesktop,
      double maxWidthRatio,
      bool isBorderRadius,
      bool isSender,
      bool isForwardMessage,
      void Function(int index) onShowAlbum) {
    List<Widget> list = [];
    int size = items.length ~/ 2 + 1;
    for (int i = 0; i < size; i++) {
      BorderRadius borderRadius1 = BorderRadius.zero;
      BorderRadius borderRadius2 = BorderRadius.zero;
      if (i == 0) {
        borderRadius1 = borderRadiusTopLeft(
            isSender: isSender, isForwardMessage: isForwardMessage);
        borderRadius2 = borderRadiusTopRight(
            isSender: isSender, isForwardMessage: isForwardMessage);
      } else if (items.length - 1 == i) {
        borderRadius1 = borderRadiusBottom(
            isSender: isSender, isForwardMessage: isForwardMessage);
      }

      list.add(const SizedBox(height: 2));
      if (i != size - 1) {
        list.add(Row(
          children: [
            Expanded(
              child: buildContent(
                items[i * 2],
                i * 2,
                height: ObjectMgr.screenMQ!.size.height * 0.2 * maxWidthRatio,
                width: ObjectMgr.screenMQ!.size.width * (maxWidthRatio),
                isDesktop: isDesktop,
                isSender: isSender,
                isForwardMessage: isForwardMessage,
                isBorderRadius: isBorderRadius,
                onShowAlbum: onShowAlbum,
                maxWidthRatio: maxWidthRatio,
                borderRadius: borderRadius1,
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: buildContent(
                items[i * 2 + 1],
                i * 2 + 1,
                height: ObjectMgr.screenMQ!.size.height * 0.2 * maxWidthRatio,
                width: ObjectMgr.screenMQ!.size.width * (maxWidthRatio),
                isDesktop: isDesktop,
                isSender: isSender,
                isForwardMessage: isForwardMessage,
                isBorderRadius: isBorderRadius,
                onShowAlbum: onShowAlbum,
                maxWidthRatio: maxWidthRatio,
                borderRadius: borderRadius2,
              ),
            ),
          ],
        ));
      } else {
        list.add(Expanded(
          child: buildContent(
            items[i * 2],
            i * 2,
            height: ObjectMgr.screenMQ!.size.height * 0.2 * maxWidthRatio,
            width: ObjectMgr.screenMQ!.size.width * (maxWidthRatio),
            isDesktop: isDesktop,
            isSender: isSender,
            isForwardMessage: isForwardMessage,
            isBorderRadius: isBorderRadius,
            onShowAlbum: onShowAlbum,
            maxWidthRatio: maxWidthRatio,
            borderRadius: borderRadius1,
          ),
        ));
      }
    }
    return list;
  }

  static double getCellHeight(CellSize cellSize) {
    return ObjectMgr.screenMQ!.size.width * cellSize.height;
  }

  static double getCellWidth(CellSize cellSize) {
    return ObjectMgr.screenMQ!.size.width * cellSize.width;
  }

  static List<Widget> buildColumn3(
      List<dynamic> items,
      bool isDesktop,
      bool isSender,
      bool isForwardMessage,
      bool isBorderRadius,
      void Function(int index) onShowAlbum,
      double maxWidthRatio) {
    return [
      expandedCell(
        data: items[0],
        isDesktop: isDesktop,
        isSender: isSender,
        isForwardMessage: isForwardMessage,
        isBorderRadius: isBorderRadius,
        onShowAlbum: onShowAlbum,
        maxWidthRatio: maxWidthRatio,
        borderRadius: borderRadiusTop(
            isSender: isSender, isForwardMessage: isForwardMessage),
        height: getCellHeight(CellSize.cell3_1),
        width: getCellWidth(CellSize.cell3_1),
        index: 0,
      ),
      const SizedBox(width: 2),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          expandedCell(
            data: items[1],
            isDesktop: isDesktop,
            isSender: isSender,
            isForwardMessage: isForwardMessage,
            isBorderRadius: isBorderRadius,
            onShowAlbum: onShowAlbum,
            maxWidthRatio: maxWidthRatio,
            borderRadius: borderRadiusBottomLeft(
                isSender: isSender, isForwardMessage: isForwardMessage),
            height: getCellHeight(CellSize.cell3_2),
            width: getCellWidth(CellSize.cell3_2),
            index: 1,
          ),
          const SizedBox(width: 2),
          expandedCell(
            data: items[2],
            isDesktop: isDesktop,
            isSender: isSender,
            isForwardMessage: isForwardMessage,
            isBorderRadius: isBorderRadius,
            onShowAlbum: onShowAlbum,
            maxWidthRatio: maxWidthRatio,
            borderRadius: borderRadiusBottomRight(
                isSender: isSender, isForwardMessage: isForwardMessage),
            height: getCellHeight(CellSize.cell3_2),
            width: getCellWidth(CellSize.cell3_2),
            index: 2,
          ),
        ],
      ),
    ];
  }

  static List<Widget> buildColumn4(
      List<dynamic> items,
      bool isDesktop,
      bool isSender,
      bool isForwardMessage,
      bool isBorderRadius,
      void Function(int index) onShowAlbum,
      double maxWidthRatio,
      List<CellSize> cellSizedList) {
    List<Widget> list = [];
    int size = items.length ~/ 2;
    for (int i = 0; i < size; i++) {
      BorderRadius borderRadius1 = BorderRadius.zero;
      BorderRadius borderRadius2 = BorderRadius.zero;
      if (i == 0) {
        borderRadius1 = borderRadiusTopLeft(
            isSender: isSender, isForwardMessage: isForwardMessage);
        borderRadius2 = borderRadiusTopRight(
            isSender: isSender, isForwardMessage: isForwardMessage);
      } else if (size - 1 == i) {
        borderRadius1 = borderRadiusBottomLeft(
            isSender: isSender, isForwardMessage: isForwardMessage);
        borderRadius2 = borderRadiusBottomRight(
            isSender: isSender, isForwardMessage: isForwardMessage);
      }
      list.add(Row(
        children: addRow(
          data: [items[i * 2], items[i * 2 + 1]],
          indexList: [i * 2, i * 2 + 1],
          borderRadiusList: [borderRadius1, borderRadius2],
          cellSizeList: cellSizedList,
          isDesktop: isDesktop,
          isSender: isSender,
          isForwardMessage: isForwardMessage,
          isBorderRadius: isBorderRadius,
          onShowAlbum: onShowAlbum,
          maxWidthRatio: maxWidthRatio,
        ),
      ));
      if (i != size - 1) {
        list.add(const SizedBox(height: 1));
      }
    }
    return list;
  }

  /// 横向一排
  static List<Widget> addRow({
    required List<dynamic> data,
    required List<int> indexList,
    bool isDesktop = false,
    bool isSender = false,
    bool isForwardMessage = false,
    bool isBorderRadius = false,
    required void onShowAlbum(int index),
    required double maxWidthRatio,
    required List<BorderRadius> borderRadiusList,
    required List<CellSize> cellSizeList,
  }) {
    List<Widget> list = [];
    for (int i = 0; i < data.length; i++) {
      list.add(expandedCell(
        data: data[i],
        isDesktop: isDesktop,
        isSender: isSender,
        isForwardMessage: isForwardMessage,
        isBorderRadius: isBorderRadius,
        onShowAlbum: onShowAlbum,
        maxWidthRatio: maxWidthRatio,
        borderRadius: borderRadiusList[i],
        height: getCellHeight(cellSizeList[i]),
        width: getCellWidth(cellSizeList[i]),
        index: indexList[i],
      ));
      if (i != data.length - 1) {
        list.add(const SizedBox(width: 2));
      }
    }
    return list;
  }

  static List<Widget> buildColumn5(
      List<dynamic> items,
      bool isDesktop,
      bool isSender,
      bool isForwardMessage,
      bool isBorderRadius,
      void Function(int index) onShowAlbum,
      double maxWidthRatio) {
    List<Widget> list = [];
    int size = 2;
    for (int i = 0; i < size; i++) {
      List<int> indexList = [];
      List<dynamic> data = [];
      List<CellSize> cellSizeList = [];
      List<BorderRadius> borderRadiusList = [];
      BorderRadius borderRadius1 = BorderRadius.zero;
      BorderRadius borderRadius2 = BorderRadius.zero;
      BorderRadius borderRadius3 = BorderRadius.zero;
      BorderRadius borderRadius4 = BorderRadius.zero;
      if (i == 0) {
        indexList = [0, 1];
        data = [items[0], items[1]];
        cellSizeList = [CellSize.cell5_1, CellSize.cell5_1];
        borderRadius1 = borderRadiusTopLeft(
            isSender: isSender, isForwardMessage: isForwardMessage);
        borderRadius2 = borderRadiusTopRight(
            isSender: isSender, isForwardMessage: isForwardMessage);
        borderRadiusList = [borderRadius1, borderRadius2];
      } else {
        borderRadius3 = borderRadiusBottomLeft(
            isSender: isSender, isForwardMessage: isForwardMessage);
        borderRadius4 = borderRadiusBottomRight(
            isSender: isSender, isForwardMessage: isForwardMessage);
        indexList = [2, 3, 4];
        data = [items[2], items[3], items[4]];
        cellSizeList = [CellSize.cell5_2, CellSize.cell5_2, CellSize.cell5_2];
        borderRadiusList = [borderRadius3, BorderRadius.zero, borderRadius4];
      }
      list.add(Row(
        children: addRow(
          data: data,
          indexList: indexList,
          borderRadiusList: borderRadiusList,
          cellSizeList: cellSizeList,
          isDesktop: isDesktop,
          isSender: isSender,
          isForwardMessage: isForwardMessage,
          isBorderRadius: isBorderRadius,
          onShowAlbum: onShowAlbum,
          maxWidthRatio: maxWidthRatio,
        ),
      ));
      if (i != size - 1) {
        list.add(const SizedBox(
          height: 1,
        ));
      }
    }
    return list;
  }

  static List<Widget> buildColumn7(
    List<dynamic> items,
    bool isDesktop,
    bool isSender,
    bool isForwardMessage,
    bool isBorderRadius,
    void Function(int index) onShowAlbum,
    double maxWidthRatio,
  ) {
    List<Widget> list = [];
    int size = items.length ~/ 2;
    for (int i = 0; i < size; i++) {
      List<int> indexList = [];
      List<dynamic> data = [];
      List<CellSize> cellSizeList = [];
      List<BorderRadius> borderRadiusList = [];
      BorderRadius borderRadius1 = BorderRadius.zero;
      BorderRadius borderRadius2 = BorderRadius.zero;
      if (i == 0) {
        borderRadius1 = borderRadiusTopLeft(
            isSender: isSender, isForwardMessage: isForwardMessage);
        borderRadius2 = borderRadiusTopRight(
            isSender: isSender, isForwardMessage: isForwardMessage);
      }
      if (size - 1 == i) {
        borderRadius1 = borderRadiusBottomLeft(
            isSender: isSender, isForwardMessage: isForwardMessage);
        borderRadius2 = borderRadiusBottomRight(
            isSender: isSender, isForwardMessage: isForwardMessage);
        indexList = [i * 2, i * 2 + 1, i * 3];
        data = [items[i * 2], items[i * 2 + 1], items[i * 3]];
        cellSizeList = [CellSize.cell7_2, CellSize.cell7_2, CellSize.cell7_2];
        borderRadiusList = [borderRadius1, BorderRadius.zero, borderRadius2];
      } else {
        indexList = [i * 2, i * 2 + 1];
        data = [items[i * 2], items[i * 2 + 1]];
        cellSizeList = [CellSize.cell7_1, CellSize.cell7_1];
        borderRadiusList = [borderRadius1, borderRadius2];
      }
      list.add(Row(
          children: addRow(
        data: data,
        indexList: indexList,
        borderRadiusList: borderRadiusList,
        cellSizeList: cellSizeList,
        isDesktop: isDesktop,
        isSender: isSender,
        isForwardMessage: isForwardMessage,
        isBorderRadius: isBorderRadius,
        onShowAlbum: onShowAlbum,
        maxWidthRatio: maxWidthRatio,
      )));
      if (i != size - 1) {
        list.add(const SizedBox(height: 1));
      }
    }
    return list;
  }

  static List<Widget> buildColumn8(
      List<dynamic> items,
      bool isDesktop,
      bool isSender,
      bool isForwardMessage,
      bool isBorderRadius,
      void Function(int index) onShowAlbum,
      double maxWidthRatio) {
    List<Widget> list = [];
    int size = 3;
    for (int i = 0; i < size; i++) {
      BorderRadius borderRadius1 = BorderRadius.zero;
      BorderRadius borderRadius2 = BorderRadius.zero;
      List<int> indexList = [];
      List<dynamic> data = [];
      List<CellSize> cellSizeList = [];
      List<BorderRadius> borderRadiusList = [];
      if (i == 0) {
        borderRadius1 = borderRadiusTopLeft(
            isSender: isSender, isForwardMessage: isForwardMessage);
        borderRadius2 = borderRadiusTopRight(
            isSender: isSender, isForwardMessage: isForwardMessage);
        indexList = [0, 1];
        data = [items[0], items[1]];
        cellSizeList = [CellSize.cell8_1, CellSize.cell8_1];
        borderRadiusList = [borderRadius1, borderRadius2];
      } else if (i == size - 1) {
        borderRadius1 = borderRadiusBottomLeft(
            isSender: isSender, isForwardMessage: isForwardMessage);
        borderRadius2 = borderRadiusBottomRight(
            isSender: isSender, isForwardMessage: isForwardMessage);
        indexList = [5, 6, 7];
        data = [items[5], items[6], items[7]];
      } else {
        indexList = [2, 3, 4];
        data = [items[2], items[3], items[4]];
      }
      cellSizeList = [CellSize.cell8_2, CellSize.cell8_2, CellSize.cell8_2];
      borderRadiusList = [borderRadius1, BorderRadius.zero, borderRadius2];
      list.add(Row(
          children: addRow(
        data: data,
        indexList: indexList,
        borderRadiusList: borderRadiusList,
        cellSizeList: cellSizeList,
        isDesktop: isDesktop,
        isSender: isSender,
        isForwardMessage: isForwardMessage,
        isBorderRadius: isBorderRadius,
        onShowAlbum: onShowAlbum,
        maxWidthRatio: maxWidthRatio,
      )));
      if (i != size - 1) {
        list.add(const SizedBox(height: 2));
      }
    }
    return list;
  }

  static List<Widget> buildColumn9(
      List items,
      bool isDesktop,
      bool isSender,
      bool isForwardMessage,
      bool isBorderRadius,
      void Function(int index) onShowAlbum,
      double maxWidthRatio) {
    List<Widget> list = [];
    int size = items.length ~/ 3;
    for (int i = 0; i < size; i++) {
      List<int> indexList = [i * 3, i * 3 + 1, i * 3 + 2];
      List<dynamic> data = [items[i * 3], items[i * 3 + 1], items[i * 3 + 2]];
      List<CellSize> cellSizeList = [
        CellSize.cell9,
        CellSize.cell9,
        CellSize.cell9
      ];
      List<BorderRadius> borderRadiusList = [];
      BorderRadius borderRadius1 = BorderRadius.zero;
      BorderRadius borderRadius2 = BorderRadius.zero;
      if (i == 0) {
        borderRadius1 = borderRadiusTopLeft(
            isSender: isSender, isForwardMessage: isForwardMessage);
        borderRadius2 = borderRadiusTopRight(
            isSender: isSender, isForwardMessage: isForwardMessage);
        borderRadiusList = [borderRadius1, BorderRadius.zero, borderRadius2];
      } else {
        if (i == size - 1) {
          borderRadius1 = borderRadiusBottomLeft(
              isSender: isSender, isForwardMessage: isForwardMessage);
          borderRadius2 = borderRadiusBottomRight(
              isSender: isSender, isForwardMessage: isForwardMessage);
        }
        borderRadiusList = [borderRadius1, BorderRadius.zero, borderRadius2];
      }
      list.add(Row(
          children: addRow(
        data: data,
        indexList: indexList,
        borderRadiusList: borderRadiusList,
        cellSizeList: cellSizeList,
        isDesktop: isDesktop,
        isSender: isSender,
        isForwardMessage: isForwardMessage,
        isBorderRadius: isBorderRadius,
        onShowAlbum: onShowAlbum,
        maxWidthRatio: maxWidthRatio,
      )));
      if (i != size - 1) {
        list.add(const SizedBox(height: 1.5));
      }
    }
    return list;
  }

  static List<Widget> buildColumn10(
      List<dynamic> items,
      bool isDesktop,
      bool isSender,
      bool isForwardMessage,
      bool isBorderRadius,
      void Function(int index) onShowAlbum,
      double maxWidthRatio) {
    List<Widget> list = [];
    int size = items.length ~/ 3;
    for (int i = 0; i < size; i++) {
      BorderRadius borderRadius1 = BorderRadius.zero;
      BorderRadius borderRadius2 = BorderRadius.zero;
      List<int> indexList = [];
      List<dynamic> data = [];
      List<CellSize> cellSizeList = [];
      List<BorderRadius> borderRadiusList = [];
      if (i == 0) {
        borderRadius1 = borderRadiusTopLeft(
            isSender: isSender, isForwardMessage: isForwardMessage);
        borderRadius2 = borderRadiusTopRight(
            isSender: isSender, isForwardMessage: isForwardMessage);
      }

      if (i == size - 1) {
        indexList = [i * 3, i * 3 + 1, i * 3 + 2, (i + 1) * 3];
        data = [
          items[i * 3],
          items[i * 3 + 1],
          items[i * 3 + 2],
          items[(i + 1) * 3]
        ];
        cellSizeList = [
          CellSize.cell10_2,
          CellSize.cell10_2,
          CellSize.cell10_2,
          CellSize.cell10_2
        ];
        borderRadius1 = borderRadiusBottomLeft(
            isSender: isSender, isForwardMessage: isForwardMessage);
        borderRadius2 = borderRadiusBottomRight(
            isSender: isSender, isForwardMessage: isForwardMessage);
        borderRadiusList = [
          borderRadius1,
          BorderRadius.zero,
          BorderRadius.zero,
          borderRadius2
        ];
      } else {
        indexList = [i * 3, i * 3 + 1, i * 3 + 2];
        data = [items[i * 3], items[i * 3 + 1], items[i * 3 + 2]];
        cellSizeList = [
          CellSize.cell10_1,
          CellSize.cell10_1,
          CellSize.cell10_1
        ];
        borderRadiusList = [borderRadius1, BorderRadius.zero, borderRadius2];
      }
      list.add(Row(
          children: addRow(
        data: data,
        indexList: indexList,
        borderRadiusList: borderRadiusList,
        cellSizeList: cellSizeList,
        isDesktop: isDesktop,
        isSender: isSender,
        isForwardMessage: isForwardMessage,
        isBorderRadius: isBorderRadius,
        onShowAlbum: onShowAlbum,
        maxWidthRatio: maxWidthRatio,
      )));
      if (i != size - 1) {
        list.add(const SizedBox(height: 1));
      }
    }
    return list;
  }
}

enum BorderRadiusType {
  leftTop(1),
  rightTop(2),
  leftBottom(3),
  rightBottom(4),
  middle(5),
  top(6),
  bottom(7),
  left(8),
  right(9),
  all(10);

  const BorderRadiusType(this.value);

  final int value;
}

enum AlbumType {
  image,
  video,
  unknown,
}

enum CellSize {
  cell1(_cellHeight1, _cellWidth1),
  cell2(_cellHeight1, _cellWidth2),
  cell3_1(_cellHeight1, _cellWidth3_1),
  cell3_2(_cellHeight2, _cellWidth3_2),
  cell4(_cellHeight3, _cellWidth4),
  cell5_1(_cellHeight5_1, _cellWidth5_1),
  cell5_2(_cellHeight5_2, _cellWidth5_2),
  cell6(_cellHeight6, _cellWidth6),
  cell7_1(_cellHeight7_1, _cellWidth7_1),
  cell7_2(_cellHeight7_2, _cellWidth7_2),
  cell8_1(_cellHeight8_1, _cellWidth8_1),
  cell8_2(_cellHeight8_2, _cellWidth8_2),
  cell9(_cellHeight9, _cellWidth9),
  cell10_1(_cellHeight10_1, _cellWidth10_1),
  cell10_2(_cellHeight10_2, _cellWidth10_2);

  const CellSize(this.height, this.width);

  final double height;
  final double width;
}

const _width = 390;
const _height = 390;
const double _cellHeight1 = 294 / _height;
const double _cellHeight2 = 153 / _height;
const double _cellHeight3 = 223 / _height;
const double _cellHeight5_1 = 256 / _height;
const double _cellHeight5_2 = 190 / _height;
const double _cellHeight6 = 148 / _height;
const double _cellHeight7_1 = 167 / _height;
const double _cellHeight7_2 = 110 / _height;
const double _cellHeight8_1 = 193 / _height;
const double _cellHeight8_2 = 127 / _height;
const double _cellHeight9 = 148 / _height;
const double _cellHeight10_1 = 161 / _height;
const double _cellHeight10_2 = 122 / _height;

const double _cellWidth1 = 308 / _width;
const double _cellWidth2 = 152 / _width;
const double _cellWidth3_1 = 304 / _width;
const double _cellWidth3_2 = 152 / _width;
const double _cellWidth4 = 152 / _width;
const double _cellWidth5_1 = 152 / _width;
const double _cellWidth5_2 = 102 / _width;
const double _cellWidth6 = 152 / _width;
const double _cellWidth7_1 = 152 / _width;
const double _cellWidth7_2 = 102 / _width;
const double _cellWidth8_1 = 152 / _width;
const double _cellWidth8_2 = 102 / _width;
const double _cellWidth9 = 102 / _width;
const double _cellWidth10_1 = 102 / _width;
const double _cellWidth10_2 = 77 / _width;
