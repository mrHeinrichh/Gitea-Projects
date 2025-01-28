import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/setting/controller/test_page_controller.dart';

class TestPage extends GetView<TestPageController> {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('"测试页面"')),
      body: const Center(
        child: Text('测试'),
      ),
    );
  }
}
