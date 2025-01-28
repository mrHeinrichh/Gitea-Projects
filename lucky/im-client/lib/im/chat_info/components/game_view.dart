import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:im/im_plugin.dart';
import 'package:im/model/ws_group_game.dart';
import 'package:im/src/game_collect_manager.dart';
import 'package:im/widget/bet_panel/bet_game_tabs.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/lang_util.dart';

class GameView extends StatefulWidget {
  final Chat chat;

  const GameView({
    super.key,
    required this.chat,
  });

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  final gameList = GameManager.shared.gameNameList;
  final gameCollections = <String>{}.obs;

  Widget _buildEmptyRecord() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ImGap.vGap(150),
        Image.asset(
          'assets/images/common/empty-norecord.png',
          width: 148.w,
          height: 148.w,
        ),
        ImGap.vGap20,
        ImText(
          localized(noAppAvailable),
          fontWeight: FontWeight.w500,
          fontSize: ImFontSize.large,
        ),
        ImGap.vGap4,
        ImText(
          localized(needOfficialCertification),
          color: ImColor.black60,
        ),
      ],
    );
  }

  Widget _buildGameItem(GameCollectManager gameCollectMgr, Game game) {
    final key = "${widget.chat.chat_id}_${game.gameId}";
    return Container(
      margin: const EdgeInsets.only(bottom: 12).w,
      child: Row(
        children: [
          Image.network(
            game.iconUrl ?? '',
            width: 52.w,
            height: 52.w,
            fit: BoxFit.fill,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 52.w,
                height: 52.w,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image:
                        AssetImage('assets/images/common/picture_loading.png'),
                    fit: BoxFit.fill,
                  ),
                ),
              );
            },
          ),
          ImGap.hGap12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ImText(
                  game.gameName ?? '',
                  fontWeight: FontWeight.w600,
                ),
                ImGap.vGap4,
                ImText(
                  game.appName ?? '',
                  fontSize: ImFontSize.small,
                  color: ImColor.black48,
                )
              ],
            ),
          ),
          ImGap.hGap12,
          GestureDetector(
            onTap: () {
              if (gameCollections.add(key)) {
                gameCollectMgr.collectAdd(
                    widget.chat.chat_id,
                    fetchError: (msg) {
                      ToastManager.showErrorToast(msg);
                      gameCollections.assignAll(gameCollectMgr.collectMap.keys);
                    },);
              } else {
                gameCollectMgr.collectDel(
                    widget.chat.chat_id,
                    fetchError: (msg) {
                      ToastManager.showErrorToast(msg);
                      gameCollections.assignAll(gameCollectMgr.collectMap.keys);
                    },);
                gameCollections.remove(key);
              }
            },
            child: ObxValue(
              (p0) => SvgPicture.asset(
                'assets/svgs/game_star.svg',
                width: 17.w,
                height: 17.w,
                color: p0.contains(key) ? ImColor.accentColor : ImColor.black24,
              ),
              gameCollections,
            ),
          ),
          ImGap.hGap12,
          GestureDetector(
            onTap: () {
              final callback = () {
                if (game.appId == null) return;
                if (game.gameId == null) return;
                if (game.gameName == null) return;
                if (game.appId == ImConstants.league) {
                  onTapToLeagueGamePage(context, game.gameId!);
                  return;
                }

                gameManager.osFromCollection = true;
                GameManager.shared.onChangeGameUIClick.call();
                GameManager.shared.buildGameConnecting(game.gameId!, name: game.gameName!);
                GameManager.shared
                    .panelController(entrance: ImConstants.gameKeyboard, control: true);
              };
              Get.back(result: callback);
            },
            child: Container(
              width: 80.w,
              height: 32.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ImColor.grey4,
                borderRadius: ImBorderRadius.all(30),
              ),
              child: ImText(
                localized(playNow),
                color: ImColor.accentColor,
                fontSize: ImFontSize.small,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(int amount) {
    final gameCollectMgr = GameCollectManager();
    gameCollections.assignAll(gameCollectMgr.collectMap.keys);
    return Padding(
      padding: const EdgeInsets.all(16).w,
      child: Column(children: [
        for (final game in gameList) _buildGameItem(gameCollectMgr, game),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final apps = GameManager.shared.totalRemoteGame;
    return CustomScrollView(slivers: <Widget>[
      SliverToBoxAdapter(
        child: apps > 0 ? _buildList(apps) : _buildEmptyRecord(),
      ),
    ]);
  }
}
