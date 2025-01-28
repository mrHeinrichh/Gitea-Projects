import 'package:jxim_client/im/chat_info/tool_option_model.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/lang_util.dart';

extension ToolExtension on MessagePopupOption {
  String get title {
    switch (this) {
      case MessagePopupOption.showInChat:
        return localized(showInChat);
      case MessagePopupOption.edit:
        return localized(edit);
      case MessagePopupOption.saveToGallery:
        return localized(saveToGallery);
      case MessagePopupOption.forward:
        return localized(forward);
      case MessagePopupOption.delete:
        return localized(delete);
      case MessagePopupOption.forward10sec:
        return localized(forward10sec);
      case MessagePopupOption.backward10sec:
        return localized(backward10sec);
      case MessagePopupOption.play:
        return localized(play);
      case MessagePopupOption.pause:
        return localized(pause);
      case MessagePopupOption.mute:
        return localized(mute);
      case MessagePopupOption.unmute:
        return localized(unmute);
      case MessagePopupOption.speed:
        return localized(speed);
      case MessagePopupOption.minimize:
        return localized(minimize);
      case MessagePopupOption.more:
        return localized(more);
      default:
        return ""; // not supported
    }
  }

  String get imagePath {
    switch (this) {
      case MessagePopupOption.showInChat:
        return 'assets/svgs/find_in_chat_icon.svg';
      case MessagePopupOption.saveToGallery:
        return 'assets/svgs/save_gallery_icon.svg';
      case MessagePopupOption.forward:
        return 'assets/svgs/forward_icon.svg';
      case MessagePopupOption.delete:
        return 'assets/svgs/delete_icon.svg';
      case MessagePopupOption.forward10sec:
        return 'assets/svgs/vid_forward.svg';
      case MessagePopupOption.backward10sec:
        return 'assets/svgs/vid_rewind.svg';
      case MessagePopupOption.play:
        return 'assets/icons/play.svg';
      case MessagePopupOption.pause:
        return 'assets/svgs/Pause.svg';
      case MessagePopupOption.mute:
        return 'assets/svgs/unmute.svg';
      case MessagePopupOption.unmute:
        return 'assets/svgs/mute.svg';
      case MessagePopupOption.minimize:
        return 'assets/svgs/Minimise.svg';
      case MessagePopupOption.more:
        return 'assets/svgs/menu_horizontal_white.svg';
      case MessagePopupOption.edit:
        return 'assets/svgs/pen_edit.svg';
      case MessagePopupOption.speed:
      default:
        return ""; // not supported
    }
  }

  ToolOptionModel get toolOption {
    switch (this) {
      case MessagePopupOption.play:
        return ToolOptionModel(
          title: this.title,
          optionType: this.optionType,
          isShow: true,
          tabBelonging: 1,
          checkImageUrl: MessagePopupOption.pause.imagePath,
          unCheckImageUrl: this.imagePath,
        );
      case MessagePopupOption.mute:
        return ToolOptionModel(
          title: this.title,
          optionType: this.optionType,
          isShow: true,
          tabBelonging: 1,
          checkImageUrl: MessagePopupOption.unmute.imagePath,
          unCheckImageUrl: this.imagePath,
        );
      default:
        return ToolOptionModel(
          title: this.title,
          optionType: this.optionType,
          imageUrl: this.imagePath,
          isShow: true,
          tabBelonging: 1,
        );
    }
  }
}

// const showInChat = ToolOptionModel(
// title: localized(showInChat),
// optionType: MessagePopupOption.showInChat.optionType,
// imageUrl: 'assets/svgs/find_in_chat_icon.svg',
// isShow: true,
// tabBelonging: 1,
// ),
// ToolOptionModel(
// title: localized(edit),
// optionType: MessagePopupOption.edit.optionType,
// icon: Icons.edit_outlined,
// color: Colors.white,
// isShow: true,
// tabBelonging: 1,
// ),
// ToolOptionModel(
// title: localized(saveToGallery),
// optionType: MessagePopupOption.saveToGallery.optionType,
// imageUrl: 'assets/svgs/save_gallery_icon.svg',
// isShow: true,
// tabBelonging: 1,
// ),
// ToolOptionModel(
// title: localized(forward),
// optionType: MessagePopupOption.forward.optionType,
// imageUrl: 'assets/svgs/forward_icon.svg',
// isShow: true,
// tabBelonging: 1,
// ),
// ToolOptionModel(
// title: localized(delete),
// optionType: MessagePopupOption.delete.optionType,
// imageUrl: 'assets/svgs/delete_icon.svg',
// isShow: true,
// tabBelonging: 1,
// ),
