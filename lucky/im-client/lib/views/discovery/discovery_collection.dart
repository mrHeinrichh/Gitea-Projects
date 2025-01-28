import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/views/discovery/discovery_empty.dart';
import '../../im/model/group/group.dart';
import '../../main.dart';
import 'discovery_controller.dart';
import 'package:im/src/object/game_collect_bean.dart';

class DiscoveryCollection extends StatelessWidget {
  const DiscoveryCollection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DiscoveryController controller = Get.find<DiscoveryController>();
    return Container(
      child: Obx(() {
        if (controller.tagIndexCollection.value != 0 ||
            controller.collectGameList.isEmpty) {
          return const Center(child: DiscoveryEmpty(isRecommend: false));
        }
        return _buildList(context);
      }),
    );
  }

  Future<String> fetchGroupName(int gid) async {
    Group? group = objectMgr.myGroupMgr.getGroupById(gid);
    if (group == null) {
      //本地沒有再重新撈一次
      group = await objectMgr.myGroupMgr.loadGroupById(gid);
    }
    return group?.name ?? '';
  }

  defaultName() {
    return const Text("");
  }

  _buildList(BuildContext context) {
    final DiscoveryController controller = Get.find<DiscoveryController>();
    List<GameCollectBean> gameList =
        controller.tagIndexCollection.value == 0 ? controller.collectGameList : [];
    return ListView.builder(
      itemCount: gameList.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (ctx, index) {
        GameCollectBean game = gameList[index];
        return Column(
          key: ValueKey('${game.gid}_${game.gameId}'),
          children: [
            Row(children: [
              ExtendedImage.network(
                game.gameIcon,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                shape: BoxShape.circle,
                cache: true,
                loadStateChanged: (ExtendedImageState state) {
                  switch (state.extendedImageLoadState) {
                    case LoadState.loading:
                    case LoadState.failed:
                      return const SizedBox();
                    case LoadState.completed:
                      break;
                  }
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 10,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.groupName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff121212),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(game.gameName,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0x7a121212))),
                    ]),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => controller.requestCollectDel(game),
                child: Container(
                  width: 17,
                  height: 17,
                  child: SvgPicture.asset(
                    'assets/svgs/game_star.svg',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () async {
                  final gid = game.gid;
                  ChatListController chatController = Get.find<ChatListController>();
                  Chat _chat;
                  for (Chat chatItem in chatController.chatList) {
                    if ("${chatItem.id}" == "${gid}") {
                      _chat = chatItem;
                      Routes.toChat(
                        // context: context,
                        chat: _chat,
                        fromCollection: true,
                        appId: game.appId,
                        gameId: game.gameId,
                        gameName: game.gameName,
                      );
                    }
                  }
                },
                child: Container(
                  width: 80,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0x0a121212),
                  ),
                  child: const Center(
                    child: Text('立即游戏',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff007aff))),
                  ),
                ),
              )
            ]),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}
