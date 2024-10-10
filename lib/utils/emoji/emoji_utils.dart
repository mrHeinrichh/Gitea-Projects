


class EmojiUtils{

  static List<String> getEmojiList(){
    List<String> emojiList =List.empty(growable: true);
    ///Smiley Face Emojis
    emojiList.addAll(['🙂','😀','😃','😄','😁','😅','😆','🤣','😂','🙃','😉','😊','😇','😎','🤓','🧐','🥳']);
    ///Emotional Faces Emojis
    emojiList.addAll(['🥰','😍','🤩','😘','😗','☺️','😚','😙','🥲']);
    ///Concerned Faces Emojis
    emojiList.addAll(['😕','😟','🙁','🤐','😮','😯','😲','😳','🥺','😦','😧','😨','😰','😥','😢','😭','😱','😖','😣','😞','😓','😩','😫','🥱']);
    ///Negative Faces Emojis
    // emojiList.addAll(['😤','😠','🤬','😈','👿','💀','👻']);
    ///Monkey Faces Emojis
    emojiList.addAll(['🙈','🙉','🙊']);
    ///extra Emojis
    emojiList.addAll(['👍️','❤️','👎','🔥']);
    return emojiList;
  }
}
