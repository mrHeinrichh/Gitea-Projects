import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/setting/controller/testPageController.dart';

class TestPage extends GetView<TestPageController> {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('"测试页面"')),
      body: Center(
        child: const Text('测试'),
      ),
    );
  }
}
