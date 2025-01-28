import 'package:flutter/material.dart';

import '../../../utils/color.dart';

class NumberPad extends StatelessWidget {
  const NumberPad({Key? key, required this.onNumTap, required this.onDeleteTap})
      : super(key: key);
  final void Function(String num) onNumTap;
  final void Function() onDeleteTap;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
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
              _buildNumberButton('', color: backgroundColor),
              _buildNumberButton('0'),
              _buildNumberButton('', isDelete: true),
            ],
          ),
          const SizedBox(height: 1),
          Container(
            color: JXColors.white,
            height: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(String number,
      {bool isDelete = false, Color color = JXColors.white}) {
    return Expanded(
      child: isDelete
          ? Container(
              color: backgroundColor,
              child: TextButton(
                onPressed: () => onDeleteTap(),
                child: const Icon(
                  Icons.backspace_outlined,
                  color: JXColors.black,
                ),
              ),
            )
          : Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: color,
                boxShadow: number.isEmpty
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
                  style: const TextStyle(color: JXColors.black, fontSize: 20),
                ),
              ),
            ),
    );
  }
}
