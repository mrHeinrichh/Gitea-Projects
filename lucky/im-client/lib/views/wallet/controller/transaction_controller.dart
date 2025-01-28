import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

import '../../../api/wallet_services.dart';
import '../../../object/wallet/transaction_model.dart';
import "package:collection/collection.dart";
import 'package:intl/intl.dart';

import '../../../utils/lang_util.dart';
import '../../../utils/net/connectivity_mgr.dart';

class TransactionController extends GetxController
    with GetSingleTickerProviderStateMixin {
  TransactionController();
  TransactionController.create(this.selectedCurrencyType);

  final WalletServices walletServices = WalletServices();

  Map<String, List<TransactionModel>> incomingList = {};
  Map<String, List<TransactionModel>> outgoingList = {};

  List<TransactionModel> allTransactionList = [];
  Map<String, List<TransactionModel>> formattedTransactionMap =
      <String, List<TransactionModel>>{}.obs;

  int page = 0;

  ScrollController allScrollController = ScrollController();

  late TabController tabController;

  String tabType = "";

  final isNoMoreData = false.obs;
  final isLoading = true.obs;

  String selectedCurrencyType = "";

  Timer? _debounce;

  final isLostNetwork = false.obs;

  final selectedTType = 'Cryptocurrency'.obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(vsync: this, length: 4);
    tabController.addListener(_handleTabChange);

    Future.delayed(const Duration(milliseconds: 100), () {
      loadMoreData();
    });

    allScrollController.addListener(() {
      if (allScrollController.offset >=
              allScrollController.position.maxScrollExtent &&
          !allScrollController.position.outOfRange) {
        isNoMoreData.value = false;

        loadMoreData();
      }
    });
    ConnectivityResult state = connectivityMgr.connectivityResult;

    if (state == ConnectivityResult.none) {
      isLostNetwork.value = true;
    } else {
      isLostNetwork.value = false;
    }
  }

  @override
  void onClose() {
    tabController.removeListener(_handleTabChange);
    tabController.dispose();
    super.onClose();
  }

  Future<void> _handleTabChange() async {
    if (tabController.indexIsChanging) {
      allTransactionList.clear();
      formattedTransactionMap.clear();
      isLoading.value = true;

      switch (tabController.index) {
        case 0:
          tabType = '';
          break;
        case 1:
          tabType = 'DEBIT';
          break;
        case 2:
          tabType = 'CREDIT';
          break;
        case 3:
          tabType = "";
          break;
      }

      if (_debounce?.isActive ?? false) _debounce?.cancel();

      _debounce = Timer(const Duration(milliseconds: 100), () async {
        loadMoreData(isClear: true);
      });
    }
  }

  Future<void> loadMoreData({bool isClear = false}) async {
    if (isClear) {
      page = 0;
      allTransactionList.clear();
      formattedTransactionMap.clear();
    }
    ConnectivityResult state = connectivityMgr.connectivityResult;

    if (state == ConnectivityResult.none) {
      isLostNetwork.value = true;
      return;
    } else {
      isLostNetwork.value = false;
    }

    page++;
    final data = await walletServices.getTransactionHistory(
      page: page,
      limit: 100,
      currencyType: selectedCurrencyType,
      txFlag: tabType,
      txStatus: tabController.index == 3 ? "PENDING" : "",
    );

    if (data.length > 0) {
      allTransactionList.addAll(data);
    } else {
      page--;
      isNoMoreData.value = true;
      isLoading.value = false;

      return;
    }

    allTransactionList.sort((a, b) {
      DateTime timeA = DateFormat('yyyy-MM-dd HH:mm:ss').parse(a.txTime!);
      DateTime timeB = DateFormat('yyyy-MM-dd HH:mm:ss').parse(b.txTime!);
      return timeB.compareTo(timeA);
    });

    final Map<String, List<TransactionModel>> groupMap = groupBy(
        allTransactionList, (TransactionModel obj) => extractDate(obj.txTime!));

    List<MapEntry<String, List<TransactionModel>>> sortDataList =
        groupMap.entries.toList()
          ..sort((a, b) {
            DateTime timeA = DateFormat('yyyy-MM-dd').parse(a.key);
            DateTime timeB = DateFormat('yyyy-MM-dd').parse(b.key);
            return timeB.compareTo(timeA);
          });

    formattedTransactionMap
        .addAll(Map<String, List<TransactionModel>>.fromEntries(sortDataList));
    isLoading.value = false;
  }

  String extractDate(String input) {
    // Split the input string by spaces
    List<String> parts = input.split(' ');

    // Combine the first three parts (day, month, year)
    String extractedDate = parts[0];

    return extractedDate;
  }

  Future<Map<String, List<TransactionModel>>> getTransactionCryptoHistory(
      String? currencyType,
      {String txFlag = ""}) async {
    final data = await walletServices.getTransactionHistory(
      currencyType: currencyType,
      txFlag: txFlag,
    );

    data.sort((a, b) {
      DateTime timeA = DateFormat('yyyy-MM-dd HH:mm:ss').parse(a.txTime!);
      DateTime timeB = DateFormat('yyyy-MM-dd HH:mm:ss').parse(b.txTime!);
      return timeB.compareTo(timeA);
    });

    final Map<String, List<TransactionModel>> groupMap =
        groupBy(data, (TransactionModel obj) => obj.txTime!.split(' ')[0]);

    List<MapEntry<String, List<TransactionModel>>> sortDataList =
        groupMap.entries.toList()
          ..sort((a, b) {
            DateTime timeA = DateFormat('yyyy-MM-dd').parse(a.key);
            DateTime timeB = DateFormat('yyyy-MM-dd').parse(b.key);
            return timeB.compareTo(timeA);
          });

    return Map<String, List<TransactionModel>>.fromEntries(sortDataList);
  }

  String getDateTitle(String date) {
    DateTime convertedDate = DateFormat("yyyy-MM-dd").parse(date);
    if (convertedDate.isToday) {
      return "${localized(myChatToday)}";
    } else if (convertedDate.isYesterday) {
      return "${localized(myChatYesterday)}";
    } else {
      return '${date}';
    }
  }
}

extension DateTimeExtension on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return this.year == now.year &&
        this.month == now.month &&
        this.day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return this.year == yesterday.year &&
        this.month == yesterday.month &&
        this.day == yesterday.day;
  }
}
