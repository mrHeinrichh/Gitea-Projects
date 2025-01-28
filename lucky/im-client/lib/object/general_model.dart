
import 'package:flutter/material.dart';

class ErrorModel {
  final bool isError;
  final String errorMessage;
  final Color color;

  ErrorModel({
    this.isError = false,
    this.errorMessage = "",
    this.color = Colors.red,
  });
}
