import 'package:flutter/material.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

class NumberPad extends StatelessWidget {
  /// showDot 是代表是否要展示小数点
  /// bottomColor 是底部有个10高度的UI的颜色
  const NumberPad({
    super.key,
    required this.onNumTap,
    required this.onDeleteTap,
    this.showDot = false,
    this.bottomColor = colorWhite,
    this.noNumberBackgroundColor = colorBackground,
  });
  final void Function(String num) onNumTap;
  final void Function() onDeleteTap;
  final bool showDot;
  final Color bottomColor;
  final Color noNumberBackgroundColor;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: colorBackground,
      child: Column(
        children: [
          const SizedBox(height: 1),
          Row(
            children: [
              _buildNumberButton('1'),
              _buildNumberButton('2'),
              _buildNumberButton('3'),
            ],
          ),
          Row(
            children: [
              _buildNumberButton('4'),
              _buildNumberButton('5'),
              _buildNumberButton('6'),
            ],
          ),
          Row(
            children: [
              _buildNumberButton('7'),
              _buildNumberButton('8'),
              _buildNumberButton('9'),
            ],
          ),
          Row(
            children: [
              _buildNumberButton(showDot ? '.' : '', color: colorBackground),
              _buildNumberButton('0'),
              _buildNumberButton('', isDelete: true),
            ],
          ),
          const SizedBox(height: 1),
          Container(
            color: bottomColor,
            height: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(
    String number, {
    bool isDelete = false,
    Color color = colorWhite,
  }) {
    return Expanded(
      child: isDelete
          ? Container(
              color: noNumberBackgroundColor,
              child: TextButton(
                onPressed: () => onDeleteTap(),
                child: const Icon(
                  Icons.backspace_outlined,
                  color: colorTextPrimary,
                ),
              ),
            )
          : Container(
              margin: const EdgeInsets.all(1),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: color,
                boxShadow: (number.isEmpty || showDot)
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 1,
                          spreadRadius: 1,
                        ),
                      ],
              ),
              child: TextButton(
                onPressed: () => onNumTap(number),
                child: Text(
                  number,
                  style: const TextStyle(color: colorTextPrimary, fontSize: 20),
                ),
              ),
            ),
    );
  }
}
