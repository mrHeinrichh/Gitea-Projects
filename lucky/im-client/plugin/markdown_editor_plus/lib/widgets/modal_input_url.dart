import 'package:flutter/material.dart';
import 'package:markdown_editor_plus/src/toolbar.dart';

class ModalInputUrl extends StatefulWidget {
  const ModalInputUrl({
    Key? key,
    required this.toolbar,
    required this.defaultDescText,
    required this.selection,
    this.onActionCompleted,
    this.isMention = false,
    this.isImage = false,
  }) : super(key: key);

  final Toolbar toolbar;
  final String defaultDescText;
  final TextSelection selection;
  final VoidCallback? onActionCompleted;
  final bool isMention;
  final bool isImage;

  @override
  State<ModalInputUrl> createState() => _ModalInputUrlState();
}

class _ModalInputUrlState extends State<ModalInputUrl> {

  late Toolbar toolbar;
  late String leftText;
  late TextSelection selection;
  late VoidCallback? onActionCompleted;
  late bool isMention;
  late bool isImage;

  TextEditingController descEditingController = TextEditingController();

  @override
  void initState() {
    toolbar = widget.toolbar;
    selection = widget.selection;
    onActionCompleted = widget.onActionCompleted;
    isMention = widget.isMention;
    isImage = widget.isImage;
    super.initState();
  }

  @override
  void dispose() {
    descEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      padding: const EdgeInsets.all(30),
      width: double.maxFinite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
           Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              !isMention ? "Please provide a URL here."
                  : "Please provide a mention here.",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextField(
            controller: descEditingController,
            autocorrect: false,
            autofocus: true,
            cursorRadius: const Radius.circular(16),
            decoration: InputDecoration(
              hintText: "Input your description",
              helperText: isMention ? "example: @123456" : "",
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16.0)),
              ),
            ),
            style: const TextStyle(fontSize: 16),
            enableInteractiveSelection: true,
          ),
          const SizedBox(height: 2,),
          TextField(
            autocorrect: false,
            autofocus: true,
            cursorRadius: const Radius.circular(16),
            decoration: InputDecoration(
              hintText: !isMention ? "Input your url." : "Input your mention username",
              helperText: !isMention ? "example: https://example.com" : "",
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16.0)),
              ),
            ),
            style: const TextStyle(fontSize: 16),
            enableInteractiveSelection: true,
            onSubmitted: (String value) {
              Navigator.pop(context);
              String descText = descEditingController.text == ""
                  ? widget.defaultDescText : descEditingController.text;

              /// check if the user entered an empty input
              if (value.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      !isMention ? "Please input url" : "Please input mention",
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: Colors.red.withOpacity(0.8),
                    duration: const Duration(milliseconds: 700),
                  ),
                );
              } else {
                if (!isMention && !value.contains(RegExp(r'https?:\/\/(www.)?([^\s]+)'))) {
                  value = "http://$value";
                }
                if (isMention) {
                  if (!descText.startsWith('@')) {
                    descText = "\\@$descText";
                  } else {
                    descText = "\\$descText";
                  }
                }
                leftText = isImage ? "![$descText](" : "[$descText](";
                toolbar.action(
                  "$leftText$value)",
                  "",
                  textSelection: selection,
                );
              }

              onActionCompleted?.call();
            },
          ),
        ],
      ),
    );
  }
}
