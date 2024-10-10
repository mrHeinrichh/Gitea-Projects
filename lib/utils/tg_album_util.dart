import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/message_widget/album_cell.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/message.dart';

///  仿tg算法
class TgAlbumUtil {
  static double spacing = 1.0;
  static double minWidth = 90.0;
  static double minHeight = 81.0;
  static double minTotalHeight = 200.0;

  ///计算图片的宽高组合
  static dynamic buildAlbum({
    required List<AlbumDetailBean> items,
    required Message assetMessage,
    required void Function(int index) onShowAlbum,
    required Size maxSize,
    required ChatContentController controller,
  }) {
    double totalAspectRatio = 1.0;

    /// 图片中存在宽高比大于2 的图片
    bool forceCalc = false;

    /// 获取形状集合
    String proportions = '';

    /// 1.判断list中是否有特殊形状的图片
    for (AlbumDetailBean item in items) {
      bool k = item.forceCalc;
      if (k) {
        forceCalc = true;
      }
      proportions = "$proportions${item.proportion}";
      double aspectRatio = item.aspectRatio;
      totalAspectRatio += aspectRatio;
    }
    if (items.length == 1) {
      return buildColumn1(
        items,
        onShowAlbum,
        assetMessage,
        maxSize: maxSize,
        controller: controller,
      );
    }

    /// 2.获取图片中宽高比例情况
    /// 3.根据情况进行不同的布局

    if (!forceCalc) {
      switch (items.length) {
        case 2:
          return buildAlbum2(
            items: items,
            onShowAlbum: onShowAlbum,
            assetMessage: assetMessage,
            proportions: proportions,
            totalAspectRatio: totalAspectRatio,
            maxSize: maxSize,
            controller: controller,
          );
        case 3:
          return buildAlbum3(
            items: items,
            onShowAlbum: onShowAlbum,
            assetMessage: assetMessage,
            proportions: proportions,
            maxSize: maxSize,
            controller: controller,
          );
        case 4:
          return buildAlbum4(
            items: items,
            onShowAlbum: onShowAlbum,
            assetMessage: assetMessage,
            proportions: proportions,
            maxSize: maxSize,
            controller: controller,
          );
      }
    }

////////////////////////////////////////////////////////////////////////////////
    /// a.有特殊形状的
    /// b.长度大于等于五个的
    /// c. 包含 4个中有特殊形状的图片的
    if (forceCalc || items.length >= 5) {
      return buildForceCalcAlbum(
        items: items,
        onShowAlbum: onShowAlbum,
        assetMessage: assetMessage,
        totalAspectRatio: totalAspectRatio,
        maxSize: maxSize,
        controller: controller,
      );
    }

    return const SizedBox();
  }

  static Widget buildColumn1(
    List<dynamic> items,
    void Function(int index) onShowAlbum,
    Message assetMessage, {
    required Size maxSize,
    required ChatContentController controller,
  }) {
    return _buildCell(
      onShowAlbum: onShowAlbum,
      height: maxSize.height,
      width: maxSize.width,
      index: 0,
      assetMessage: assetMessage,
      controller: controller,
    );
  }

  /// 这个代码还不包括上下两行不按比例分布的布局
  static dynamic buildAlbum2({
    required List<AlbumDetailBean> items,
    required void Function(int index) onShowAlbum,
    required String proportions,
    required double totalAspectRatio,
    required Size maxSize,
    required Message assetMessage,
    required ChatContentController controller,
  }) {
    double maxAspectRatio = maxSize.width / maxSize.height;

    ///  上下排列 宽固定，高度相同
    if (proportions == "ww" &&
        totalAspectRatio > 1.4 * maxAspectRatio &&
        items[1].aspectRatio - items[0].aspectRatio < 0.2) {
      double h = floor(
        min(
          maxSize.width / items[0].aspectRatio,
          min(
            maxSize.width / items[1].aspectRatio,
            (maxSize.height - spacing) / 2.0,
          ),
        ),
      );

      /// tg  外的算法，按照需求特意放大1.5倍
      double tempH = h * 1.5;
      double height = min(tempH, maxSize.height);

      Widget albumWidget = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          expandedCell(
            onShowAlbum: onShowAlbum,
            height: height,
            width: maxSize.width,
            index: 0,
            assetMessage: assetMessage,
            controller: controller,
          ),
          buildHorizontalDivide(),
          expandedCell(
            onShowAlbum: onShowAlbum,
            height: height,
            width: maxSize.width,
            index: 1,
            assetMessage: assetMessage,
            controller: controller,
          ),
        ],
      );

      return WidgetBean(albumWidget, height, maxSize.width);
    } else if (proportions == "ww" || proportions == "qq") {
      /// 左右排列
      double width = (maxSize.width - spacing) / 2.0;
      double height = floor(
        min(
          width / items[0].aspectRatio,
          min(width / items[1].aspectRatio, maxSize.height),
        ),
      );
      if (height < minTotalHeight) {
        height = minTotalHeight;
      }

      Widget albumWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          expandedCell(
            onShowAlbum: onShowAlbum,
            height: height,
            width: width,
            index: 0,
            assetMessage: assetMessage,
            controller: controller,
          ),
          buildVerticalDivide(),
          expandedCell(
            onShowAlbum: onShowAlbum,
            height: height,
            width: width,
            index: 1,
            assetMessage: assetMessage,
            controller: controller,
          ),
        ],
      );

      return WidgetBean(albumWidget, height, maxSize.width);
    } else {
      // 左右排列
      double secondWidth = max(
        floor(
          min(
            0.5 * (maxSize.width - spacing),
            round(maxSize.width - spacing) /
                items[0].aspectRatio /
                (1.0 / items[0].aspectRatio + 1.0 / items[1].aspectRatio),
          ),
        ),
        minWidth,
      );
      double firstWidth = maxSize.width - secondWidth - spacing;
      double height = floor(
        min(
          maxSize.height,
          round(
            min(
              firstWidth / items[0].aspectRatio,
              secondWidth / items[1].aspectRatio,
            ),
          ),
        ),
      );
      Widget albumWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          expandedCell(
            onShowAlbum: onShowAlbum,
            height: height,
            width: firstWidth,
            index: 0,
            assetMessage: assetMessage,
            controller: controller,
          ),
          buildVerticalDivide(),
          _buildCell(
            onShowAlbum: onShowAlbum,
            height: height,
            width: secondWidth,
            index: 1,
            assetMessage: assetMessage,
            controller: controller,
          ),
        ],
      );
      return WidgetBean(
        albumWidget,
        height,
        firstWidth + secondWidth + spacing,
      );
    }
  }

  /// 上下排列
  static dynamic buildAlbum3({
    required List<AlbumDetailBean> items,
    required void Function(int index) onShowAlbum,
    required String proportions,
    bool fillWidth = true,
    required Message assetMessage,
    required Size maxSize,
    required ChatContentController controller,
  }) {
    if (proportions.hasPrefix("n")) {
      double firstHeight = maxSize.height;
      double thirdHeight = min(
        (maxSize.height - spacing) * 0.5,
        round(
          items[1].aspectRatio *
              (maxSize.width - spacing) /
              (items[2].aspectRatio + items[1].aspectRatio),
        ),
      );
      double secondHeight = maxSize.height - thirdHeight - spacing;
      double rightWidth = max(
        minWidth,
        min(
          (maxSize.width - spacing) * 0.5,
          round(
            min(
              thirdHeight * items[2].aspectRatio,
              secondHeight * items[1].aspectRatio,
            ),
          ),
        ),
      );
      if (fillWidth) {
        rightWidth = (maxSize.width / 2.0)
            .floorToDouble(); // Dart equivalent of `floorToScreenPixels`
      }

      var leftWidth = round(
        min(
          firstHeight * items[0].aspectRatio,
          (maxSize.width - spacing - rightWidth),
        ),
      );
      if (fillWidth) {
        leftWidth = maxSize.width - spacing - rightWidth;
      }
      Widget child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          expandedCell(
            onShowAlbum: onShowAlbum,
            height: firstHeight,
            width: leftWidth,
            index: 0,
            assetMessage: assetMessage,
            controller: controller,
          ),
          buildVerticalDivide(),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCell(
                onShowAlbum: onShowAlbum,
                height: secondHeight,
                width: rightWidth,
                index: 1,
                assetMessage: assetMessage,
                controller: controller,
              ),
              buildHorizontalDivide(),
              _buildCell(
                onShowAlbum: onShowAlbum,
                height: thirdHeight,
                width: rightWidth,
                index: 2,
                assetMessage: assetMessage,
                controller: controller,
              ),
            ],
          ),
        ],
      );
      double totalWidth = leftWidth + rightWidth + spacing;
      return WidgetBean(child, maxSize.height, totalWidth);
    } else {
      double width = maxSize.width;
      double firstHeight = floor(
        min(width / items[0].aspectRatio, (maxSize.height - spacing) * 0.66),
      );

      double secondWidth = (maxSize.width - spacing) / 2.0;
      double secondHeight = min(
        maxSize.height - firstHeight - spacing,
        round(
          min(width / items[1].aspectRatio, width / items[2].aspectRatio),
        ),
      );
      Widget albumWidget = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCell(
            onShowAlbum: onShowAlbum,
            height: firstHeight,
            width: width,
            index: 0,
            assetMessage: assetMessage,
            controller: controller,
          ),
          buildHorizontalDivide(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCell(
                onShowAlbum: onShowAlbum,
                height: secondHeight,
                width: secondWidth,
                index: 1,
                assetMessage: assetMessage,
                controller: controller,
              ),
              buildVerticalDivide(),
              expandedCell(
                onShowAlbum: onShowAlbum,
                height: secondHeight,
                width: secondWidth,
                index: 2,
                assetMessage: assetMessage,
                controller: controller,
              ),
            ],
          ),
        ],
      );

      return WidgetBean(
        albumWidget,
        firstHeight + secondHeight + spacing,
        width,
      );
    }
  }

  static dynamic buildAlbum4({
    required List<AlbumDetailBean> items,
    required void Function(int index) onShowAlbum,
    required String proportions,
    required Message assetMessage,
    required Size maxSize,
    required ChatContentController controller,
  }) {
    if (proportions == "wwww" || proportions.hasPrefix("w")) {
      double w = maxSize.width;
      double h0 = round(
        min(w / items[0].aspectRatio, (maxSize.height - spacing) * 0.66),
      );
      var h = round(
        (maxSize.width - 2 * spacing) /
            (items[1].aspectRatio +
                items[2].aspectRatio +
                items[3].aspectRatio),
      );
      double h1 = max(minHeight, min(maxSize.height - h0 - spacing, h));
      List<double> widths =
          getBestProportionWidth([items[1], items[2], items[3]], h1, w);
      double w0 = widths[0];
      double w1 = widths[1];
      double w2 = widths[2];
      Widget albumWidget = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCell(
            onShowAlbum: onShowAlbum,
            height: h0,
            width: w,
            index: 0,
            assetMessage: assetMessage,
            controller: controller,
          ),
          buildHorizontalDivide(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCell(
                onShowAlbum: onShowAlbum,
                height: h1,
                width: w0,
                index: 1,
                assetMessage: assetMessage,
                controller: controller,
              ),
              buildVerticalDivide(),
              _buildCell(
                onShowAlbum: onShowAlbum,
                height: h1,
                width: w1,
                index: 2,
                assetMessage: assetMessage,
                controller: controller,
              ),
              buildVerticalDivide(),
              expandedCell(
                onShowAlbum: onShowAlbum,
                height: h1,
                width: w2,
                index: 3,
                assetMessage: assetMessage,
                controller: controller,
              ),
            ],
          ),
        ],
      );
      return WidgetBean(albumWidget, h0 + h1 + spacing * 1, w);
    } else {
      double h = maxSize.height;
      double w0 =
          round(min(h * items[0].aspectRatio, (maxSize.width - spacing) * 0.6));
      var w = round(
        (maxSize.height - 2 * spacing) /
            (1.0 / items[1].aspectRatio +
                1.0 / items[2].aspectRatio +
                1.0 / items[3].aspectRatio),
      );
      final h0 = floor(w / items[1].aspectRatio);
      final h1 = floor(w / items[2].aspectRatio);
      final h2 = h - h0 - h1 - spacing * 2;
      final secondW = maxSize.width - w0 - spacing;
      Widget child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          expandedCell(
            onShowAlbum: onShowAlbum,
            height: h,
            width: w0,
            index: 0,
            assetMessage: assetMessage,
            controller: controller,
          ),
          buildVerticalDivide(),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCell(
                onShowAlbum: onShowAlbum,
                height: h0,
                width: secondW,
                index: 1,
                assetMessage: assetMessage,
                controller: controller,
              ),
              buildHorizontalDivide(),
              _buildCell(
                onShowAlbum: onShowAlbum,
                height: h1,
                width: secondW,
                index: 2,
                assetMessage: assetMessage,
                controller: controller,
              ),
              buildHorizontalDivide(),
              _buildCell(
                onShowAlbum: onShowAlbum,
                height: h2,
                width: secondW,
                index: 3,
                assetMessage: assetMessage,
                controller: controller,
              ),
            ],
          ),
        ],
      );
      double totalWidth = secondW + w0 + spacing;
      return WidgetBean(child, h, totalWidth);
    }
  }

  static double getCellHeight(double height) {
    return ObjectMgr.screenMQ!.size.width * height;
  }

  static double getCellWidth(double width) {
    return ObjectMgr.screenMQ!.size.width * width;
  }

  static Expanded expandedCell({
    required double height,
    required double width,
    required int index,
    required void Function(int index) onShowAlbum,
    required Message assetMessage,
    required ChatContentController controller,
  }) {
    return Expanded(
      child: buildContent(
        index,
        height: height,
        width: width,
        onShowAlbum: onShowAlbum,
        assetMessage: assetMessage,
        controller: controller,
      ),
    );
  }

  static Widget _buildCell({
    required double height,
    required double width,
    required int index,
    required void Function(int index) onShowAlbum,
    required Message assetMessage,
    required ChatContentController controller,
  }) {
    return buildContent(
      index,
      height: height,
      width: width,
      onShowAlbum: onShowAlbum,
      assetMessage: assetMessage,
      controller: controller,
    );
  }

  static Widget buildContent(
    int index, {
    required void Function(int index) onShowAlbum,
    required Message assetMessage,
    required double height,
    required double width,
    required ChatContentController controller,
  }) {
    return AlbumCell(
      index: index,
      msg: assetMessage,
      height: height,
      width: width,
      onShowAlbum: onShowAlbum,
      controller: controller,
    );
  }

  static double floor(double value) {
    return value.floorToDouble();
  }

  static double round(double value) {
    return value.roundToDouble();
  }

  static dynamic buildForceCalcAlbum({
    required List<AlbumDetailBean> items,
    required void Function(int index) onShowAlbum,
    required Message assetMessage,
    required double totalAspectRatio,
    required Size maxSize,
    required ChatContentController controller,
  }) {
    List<double> croppedRatios = [];
    for (AlbumDetailBean item in items) {
      final aspectRatio = item.aspectRatio;
      double croppedRatio = aspectRatio;
      if (totalAspectRatio > 1.1) {
        croppedRatio = max(1.0, aspectRatio);
      } else {
        croppedRatio = min(1.0, aspectRatio);
      }
      croppedRatio = max(0.66667, min(1.7, croppedRatio));
      croppedRatios.add(croppedRatio);
    }
    double multiHeight(List<double> ratios) {
      double ratioSum = 0.0;
      for (double ratio in ratios) {
        ratioSum += ratio;
      }
      double k = (maxSize.width - (ratios.length - 1) * spacing) / ratioSum;

      /// 按要求放大
      return k * 1.2;
    }

    List<MosaicLayoutAttempt> attempts = [];
    void addAttempt(
      List<int> lineCounts,
      List<double> heights,
      List<MosaicLayoutAttempt> attempts,
    ) {
      attempts
          .add(MosaicLayoutAttempt(lineCounts: lineCounts, heights: heights));
    }

    for (int firstLine = 1; firstLine < croppedRatios.length; firstLine++) {
      int secondLine = croppedRatios.length - firstLine;
      if (firstLine > 3 || secondLine > 3) {
        continue;
      }
      addAttempt(
        [
          firstLine,
          croppedRatios.length - firstLine,
        ],
        [
          multiHeight(croppedRatios.sublist(0, firstLine)),
          multiHeight(croppedRatios.sublist(firstLine, croppedRatios.length)),
        ],
        attempts,
      );
    }

    for (int firstLine = 1; firstLine < croppedRatios.length - 1; firstLine++) {
      for (int secondLine = 1;
          secondLine < croppedRatios.length - firstLine;
          secondLine++) {
        int thirdLine = croppedRatios.length - firstLine - secondLine;
        if (firstLine > 3 ||
            secondLine > (totalAspectRatio < 0.85 ? 4 : 3) ||
            thirdLine > 3) {
          continue;
        }

        addAttempt(
          [firstLine, secondLine, thirdLine],
          [
            multiHeight(croppedRatios.sublist(0, firstLine)),
            multiHeight(
              croppedRatios.sublist(
                firstLine,
                croppedRatios.length - thirdLine,
              ),
            ),
            multiHeight(
              croppedRatios.sublist(
                firstLine + secondLine,
                croppedRatios.length,
              ),
            ),
          ],
          attempts,
        );
      }
    }

    if (croppedRatios.length - 2 >= 1) {
      outer:
      for (int firstLine = 1;
          firstLine < croppedRatios.length - 2;
          firstLine++) {
        if (croppedRatios.length - firstLine < 1) {
          continue outer;
        }
        for (int secondLine = 1;
            secondLine < croppedRatios.length - firstLine;
            secondLine++) {
          for (int thirdLine = 1;
              thirdLine < croppedRatios.length - firstLine - secondLine;
              thirdLine++) {
            int fourthLine =
                croppedRatios.length - firstLine - secondLine - thirdLine;
            if (firstLine > 3 ||
                secondLine > 3 ||
                thirdLine > 3 ||
                fourthLine > 3) {
              continue;
            }

            addAttempt(
              [
                firstLine,
                secondLine,
                thirdLine,
                fourthLine,
              ],
              [
                multiHeight(croppedRatios.sublist(0, firstLine)),
                multiHeight(
                  croppedRatios.sublist(
                    firstLine,
                    croppedRatios.length - thirdLine - fourthLine,
                  ),
                ),
                multiHeight(
                  croppedRatios.sublist(
                    firstLine + secondLine,
                    croppedRatios.length - fourthLine,
                  ),
                ),
                multiHeight(
                  croppedRatios.sublist(
                    firstLine + secondLine + thirdLine,
                    croppedRatios.length,
                  ),
                ),
              ],
              attempts,
            );
          }
        }
      }
    }

    double maxHeight = (maxSize.width / 3.0 * 4.0).floorToDouble();
    MosaicLayoutAttempt? optimal;
    double optimalDiff = 0.0;

    for (var attempt in attempts) {
      double totalHeight = spacing * (attempt.heights.length - 1);
      double minLineHeight = double.maxFinite;
      double maxLineHeight = 0.0;

      for (var h in attempt.heights) {
        totalHeight += h.floorToDouble();
        if (totalHeight < minLineHeight) {
          minLineHeight = totalHeight;
        }
        if (totalHeight > maxLineHeight) {
          maxLineHeight = totalHeight;
        }
      }

      double diff = (totalHeight - maxHeight).abs();

      if (attempt.lineCounts.length > 1) {
        if ((attempt.lineCounts[0] > attempt.lineCounts[1]) ||
            (attempt.lineCounts.length > 2 &&
                attempt.lineCounts[1] > attempt.lineCounts[2]) ||
            (attempt.lineCounts.length > 3 &&
                attempt.lineCounts[2] > attempt.lineCounts[3])) {
          diff *= 1.5;
        }
      }

      if (minLineHeight < minWidth) {
        diff *= 1.5;
      }

      if (optimal == null || diff < optimalDiff) {
        optimal = attempt;
        optimalDiff = diff;
      }
    }

    int index = 0;
    double y = 0.0;

    double totalHeight = 0;
    if (optimal != null) {
      double tempY = -1;
      for (int i = 0; i < optimal.lineCounts.length; i++) {
        int count = optimal.lineCounts[i];
        double lineHeight = optimal.heights[i].ceilToDouble();
        double x = 0.0;

        Set<MosaicItemPosition> positionFlags = {};

        if (i == 0) {
          positionFlags.add(MosaicItemPosition.top);
        }

        if (i == optimal.lineCounts.length - 1) {
          positionFlags.add(MosaicItemPosition.bottom);
        }

        for (int k = 0; k < count; k++) {
          Set<MosaicItemPosition> innerPositionFlags = {...positionFlags};

          if (k == 0) {
            innerPositionFlags.add(MosaicItemPosition.left);
          }

          if (k == count - 1) {
            innerPositionFlags.add(MosaicItemPosition.right);
          }

          if (positionFlags.isEmpty) {
            innerPositionFlags = {MosaicItemPosition.inside};
          }

          double ratio = croppedRatios[index];

          double width = (ratio * lineHeight).ceilToDouble();

          final xx = x;
          final yy = y;
          final w = width;
          final h = lineHeight;

          items[index].position = innerPositionFlags;
          items[index].index = index;
          if (tempY != y) {
            tempY = y;
            totalHeight += lineHeight;
          }
          AlbumRect aa = AlbumRect(xx, yy, w, h);
          items[index].currentLine = i;
          items[index].setLayoutFrame(aa);
          x += width + spacing;
          index += 1;
        }

        y += lineHeight + spacing;
      }

      index = 0;
      double maxWidth = 0.0;
      for (int i = 0; i < optimal.lineCounts.length; i++) {
        int count = optimal.lineCounts[i];
        for (int k = 0; k < count; k++) {
          if (k == count - 1) {
            maxWidth = max(maxWidth, items[index].layoutFrame.width);
          }
          index += 1;
        }
      }

      index = 0;
      for (int i = 0; i < optimal.lineCounts.length; i++) {
        int count = optimal.lineCounts[i];
        for (int k = 0; k < count; k++) {
          if (k == count - 1) {
            AlbumRect frame = items[index].layoutFrame;
            double frameTotalSpaces = (count - 1) * spacing;
            double minX = (maxWidth - frame.x - frameTotalSpaces) > 0
                ? (maxWidth - frame.x - frameTotalSpaces)
                : 1;
            frame.width = max(frame.width, minX);
          }
          index += 1;
        }
      }
    }

    /// 元素开始分行
    List<List<AlbumDetailBean>> columnList = [];
    List<AlbumDetailBean> tempList = [];
    int currentLine = 0;

    for (AlbumDetailBean bean in items) {
      // 判断是否需要换行
      if (currentLine != bean.currentLine) {
        currentLine = bean.currentLine;
        if (tempList.isNotEmpty) {
          columnList.add(tempList);
        }
        tempList = [];
      }

      // 将当前项添加到 tempList
      tempList.add(bean);
    }

    // 添加最后一行（如果有）
    if (tempList.isNotEmpty) {
      columnList.add(tempList);
    }

    /// 开始组合
    List<Widget> columnListWidget = [];
    for (int k = 0; k < columnList.length; k++) {
      List<AlbumDetailBean> rows = columnList[k];
      Widget rowWidget = getRowWidget(
        rows,
        onShowAlbum: onShowAlbum,
        assetMessage: assetMessage,
        maxSize: maxSize,
        controller: controller,
      );
      columnListWidget.add(rowWidget);
      if (k != columnList.length - 1) {
        columnListWidget.add(buildHorizontalDivide());
      }
    }

    Widget child = Column(
      mainAxisSize: MainAxisSize.min,
      children: columnListWidget,
    );
    return WidgetBean(
      child,
      totalHeight + (columnList.length - 1) * spacing,
      maxSize.width,
    );
  }

  static SizedBox buildHorizontalDivide() => SizedBox(height: spacing);

  static String tg(Set<MosaicItemPosition> innerPositionFlags) {
    String str = "";
    for (MosaicItemPosition item in innerPositionFlags) {
      str += "${item.toString()},";
    }
    return str;
  }

  /// 横排列表
  static Widget getRowWidget(
    List<AlbumDetailBean> rows, {
    required void Function(int index) onShowAlbum,
    required Message assetMessage,
    required Size maxSize,
    required ChatContentController controller,
  }) {
    if (rows.length == 1) {
      AlbumDetailBean bean = rows[0];
      double h0 = bean.layoutFrame.height == 0
          ? bean.layoutFrame.y
          : bean.layoutFrame.height;
      double w = bean.layoutFrame.width == 0
          ? bean.layoutFrame.x
          : bean.layoutFrame.width;
      return _buildCell(
        onShowAlbum: onShowAlbum,
        height: h0,
        width: w,
        index: bean.index,
        assetMessage: assetMessage,
        controller: controller,
      );
    } else {
      /// 这里再次分配下布局
      double h = rows[0].layoutFrame.height == 0
          ? rows[0].layoutFrame.y
          : rows[0].layoutFrame.height;
      List<double> widths = getBestProportionWidth(rows, h, maxSize.width);
      List<Widget> list = [];
      for (int i = 0; i < rows.length; i++) {
        AlbumDetailBean bean = rows[i];
        double h0 = bean.layoutFrame.height == 0
            ? bean.layoutFrame.y
            : bean.layoutFrame.height;
        double w = widths[i];

        if (i != rows.length - 1) {
          list.add(
            _buildCell(
              onShowAlbum: onShowAlbum,
              height: h0,
              width: w,
              index: bean.index,
              assetMessage: assetMessage,
              controller: controller,
            ),
          );
          list.add(buildVerticalDivide());
        } else {
          list.add(
            expandedCell(
              onShowAlbum: onShowAlbum,
              height: h0,
              width: w,
              index: bean.index,
              assetMessage: assetMessage,
              controller: controller,
            ),
          );
        }
      }
      return Row(
        children: list,
      );
    }
  }

  static SizedBox buildVerticalDivide() {
    return SizedBox(
      width: spacing,
    );
  }

  static Size getMaxSize({required double width, required double height}) {
    return Size(width, height.toDouble());
  }

  /// 获取最佳宽度比例
  ///  h1,集合的统一高度
  ///  maxWidth: 总体的最大宽度
  ///  限制最大四张
  static List<double> getBestProportionWidth(
    List<AlbumDetailBean> list,
    double h,
    double maxWidth,
  ) {
    switch (list.length) {
      case 1:
        return [maxWidth];
      case 2:
        return getWidthAspectRatio2(list, h, maxWidth);
      case 3:
        return getWidthAspectRatio3(list, h, maxWidth);
      case 4:
        return getWidthAspectRatio4(list, h, maxWidth);
      default:

        /// 按照宽的比例分配
        return getDefaultAspectRatio(list, h, maxWidth);
    }
  }

  static List<double> getDefaultAspectRatio(
    List<AlbumDetailBean> list,
    double h,
    double maxWidth,
  ) {
    double tempWidth = 0;
    List<double> widths = [];
    double spaces = (list.length - 1) * spacing;
    double unitAspect = getUnitAspectRatio(list, maxWidth);
    for (int index = 0; index < list.length; index++) {
      AlbumDetailBean bean = list[index];
      double width = unitAspect * bean.uiAspectRatio;
      if (index == list.length - 1) {
        width = (maxWidth - spaces) - tempWidth;
      }
      widths.add(width);
      tempWidth += width;
    }
    return widths;
  }

  /// 两个的时候
  static List<double> getWidthAspectRatio2(
    List<AlbumDetailBean> list,
    double h,
    double maxWidth,
  ) {
    double uiAspectRatio1 = list[0].uiAspectRatio;
    double uiAspectRatio2 = list[1].uiAspectRatio;

    ///获取每一份的比例
    double unitWidth = (maxWidth - spacing) / (uiAspectRatio1 + uiAspectRatio2);
    double w1 = max(list[0].getMinWidth(h), unitWidth * uiAspectRatio1);
    double w2 = maxWidth - w1;
    return [w1, w2];
  }

  static List<double> getWidthAspectRatio3(
    List<AlbumDetailBean> list,
    double h,
    double maxWidth,
  ) {
    double uiAspectRatio1 = list[0].uiAspectRatio;
    double uiAspectRatio2 = list[1].uiAspectRatio;
    double uiAspectRatio3 = list[2].uiAspectRatio;

    ///获取每一份的比例
    double unitWidth = (maxWidth - spacing * 2) /
        (uiAspectRatio1 + uiAspectRatio2 + uiAspectRatio3);
    double w1 = max(list[0].getMinWidth(h), unitWidth * uiAspectRatio1);
    double w2 = max(list[1].getMinWidth(h), unitWidth * uiAspectRatio2);
    double w3 = (maxWidth - spacing * 2) - w1 - w2;
    return [w1, w2, w3];
  }

  static List<double> getWidthAspectRatio4(
    List<AlbumDetailBean> list,
    double h,
    double maxWidth,
  ) {
    double uiAspectRatio1 = list[0].uiAspectRatio;
    double uiAspectRatio2 = list[1].uiAspectRatio;
    double uiAspectRatio3 = list[2].uiAspectRatio;
    double uiAspectRatio4 = list[3].uiAspectRatio;
    double unitWidth = (maxWidth - spacing * 3) /
        (uiAspectRatio1 + uiAspectRatio2 + uiAspectRatio3 + uiAspectRatio4);
    double w1 = max(list[0].getMinWidth(h), unitWidth * uiAspectRatio1);
    double w2 = max(list[1].getMinWidth(h), unitWidth * uiAspectRatio2);
    double w3 = max(list[2].getMinWidth(h), unitWidth * uiAspectRatio3);
    double w4 = (maxWidth - spacing * 3) - w1 - w2 - w3;
    return [w1, w2, w3, w4];
  }

  static double getUnitAspectRatio(
    List<AlbumDetailBean> list,
    double maxWidth,
  ) {
    double totalAspectRatio = 0;
    for (AlbumDetailBean bean in list) {
      totalAspectRatio += bean.uiAspectRatio;
    }
    return (maxWidth - (list.length - 1) * spacing) / totalAspectRatio;
  }
}

class MosaicLayoutAttempt {
  final List<int> lineCounts;
  final List<double> heights;

  MosaicLayoutAttempt({
    required this.lineCounts,
    required this.heights,
  });
}

extension SizeExtensions on Size {
  Size fittedToWidthOrSmaller(double maxWidth) {
    double aspectRatio = width / height;
    if (width > maxWidth) {
      return Size(maxWidth, maxWidth / aspectRatio);
    }
    return this;
  }
}

extension StringExtensions on String {
  bool hasPrefix(String prefix) {
    return startsWith(prefix);
  }
}

class WidgetBean {
  Widget albumWidget;
  double maxHeight;
  double maxWidth;

  WidgetBean(
    this.albumWidget,
    this.maxHeight,
    this.maxWidth,
  );
}
