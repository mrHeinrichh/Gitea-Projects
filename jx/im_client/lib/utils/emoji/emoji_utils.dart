


class EmojiUtils{

  static List<String> getEmojiList(){
    List<String> emojiList =List.empty(growable: true);
    ///extra Emojis
    emojiList.addAll(['👍', '❤️', '👎', '🔥']);
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
    return emojiList;
  }
}
