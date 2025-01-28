import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/favourite/component/favourite_cell/favourite_factory.dart';
import 'package:jxim_client/favourite/favourite_controller.dart';
import 'package:jxim_client/favourite/model/favourite_model.dart';

class FavouriteCellView extends GetView<FavouriteController> {
  final FavouriteData favouriteData;
  final int index;

  const FavouriteCellView({
    super.key,
    required this.favouriteData,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return FavouriteFactory.createComponent(
      favouriteData: favouriteData,
      index: index,
      controller: controller,
    );
  }
}
