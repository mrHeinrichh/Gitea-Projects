import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../src/toolbar.dart';
import 'modal_select_emoji.dart';
import 'modal_input_url.dart';
import 'toolbar_item.dart';

class MarkdownToolbar extends StatelessWidget {
  /// Preview/Eye button
  final VoidCallback? onPreviewChanged;
  final TextEditingController controller;
  final UndoHistoryController undoController;
  final VoidCallback? unfocus;
  final bool emojiConvert;
  final bool autoCloseAfterSelectEmoji;
  final Toolbar toolbar;
  final Color? toolbarBackground;
  final Color? expandableBackground;
  final bool showPreviewButton;
  final bool showEmojiSelection;
  final VoidCallback? onActionCompleted;
  final String? markdownSyntax;

  const MarkdownToolbar({
    Key? key,
    this.onPreviewChanged,
    this.markdownSyntax,
    required this.controller,
    required this.undoController,
    this.emojiConvert = true,
    this.unfocus,
    required this.toolbar,
    this.autoCloseAfterSelectEmoji = true,
    this.toolbarBackground,
    this.expandableBackground,
    this.onActionCompleted,
    this.showPreviewButton = true,
    this.showEmojiSelection = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: toolbarBackground ?? Colors.grey[200],
      width: double.maxFinite,
      height: 45,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // preview
            // if (showPreviewButton)
            //   ToolbarItem(
            //     key: const ValueKey<String>("toolbar_view_item"),
            //     icon: FontAwesomeIcons.eye,
            //     onPressedButton: onPreviewChanged,
            //     tooltip: 'Show/Hide markdown preview',
            //   ),

            // Clear the field
            ToolbarItem(
              key: const ValueKey<String>("toolbar_clear_action"),
              icon: FontAwesomeIcons.trashCan,
              onPressedButton: () {
                controller.clear();
                onActionCompleted?.call();
              },
              tooltip: 'Clear the text field',
            ),

            // Undo the text field
            // ValueListenableBuilder<UndoHistoryValue>(
            //   valueListenable: undoController,
            //   builder: (BuildContext context, UndoHistoryValue value,
            //       Widget? child) {
            //     return ToolbarItem(
            //       key: const ValueKey<String>("toolbar_reset_action"),
            //       icon: FontAwesomeIcons.arrowRotateLeft,
            //       onPressedButton: () {
            //         undoController.undo();
            //       },
            //       tooltip: 'Reset the text field to specified format',
            //     );
            //   },
            // ),

            // select single line
            // ToolbarItem(
            //   key: const ValueKey<String>("toolbar_selection_action"),
            //   icon: FontAwesomeIcons.textWidth,
            //   onPressedButton: () {
            //     toolbar.selectSingleLine.call();
            //     onActionCompleted?.call();
            //   },
            //   tooltip: 'Select single line',
            // ),
            // bold
            // ToolbarItem(
            //   key: const ValueKey<String>("toolbar_bold_action"),
            //   icon: FontAwesomeIcons.bold,
            //   tooltip: 'Make text bold',
            //   onPressedButton: () {
            //     toolbar.action("**", "**");
            //     onActionCompleted?.call();
            //   },
            // ),
            // italic
            // ToolbarItem(
            //   key: const ValueKey<String>("toolbar_italic_action"),
            //   icon: FontAwesomeIcons.italic,
            //   tooltip: 'Make text italic',
            //   onPressedButton: () {
            //     toolbar.action(" _", "_ ");
            //     onActionCompleted?.call();
            //   },
            // ),
            // strikethrough
            // ToolbarItem(
            //   key: const ValueKey<String>("toolbar_strikethrough_action"),
            //   icon: FontAwesomeIcons.strikethrough,
            //   tooltip: 'Strikethrough',
            //   onPressedButton: () {
            //     toolbar.action("~~", "~~");
            //     onActionCompleted?.call();
            //   },
            // ),
            // heading
            // ToolbarItem(
            //   key: const ValueKey<String>("toolbar_heading_action"),
            //   icon: FontAwesomeIcons.heading,
            //   isExpandable: true,
            //   tooltip: 'Insert Heading',
            //   expandableBackground: expandableBackground,
            //   items: [
            //     ToolbarItem(
            //       key: const ValueKey<String>("h1"),
            //       icon: "H1",
            //       tooltip: 'Insert Heading 1',
            //       onPressedButton: () {
            //         String headingStr = "# ";
            //         //check if auto break line
            //         if (checkIsNeedNewLine()) {
            //           headingStr = "\n$headingStr";
            //         }
            //         toolbar.action(headingStr, "");
            //         onActionCompleted?.call();
            //       },
            //     ),
            //     ToolbarItem(
            //       key: const ValueKey<String>("h2"),
            //       icon: "H2",
            //       tooltip: 'Insert Heading 2',
            //       onPressedButton: () {
            //         String headingStr = "## ";
            //         //check if auto break line
            //         if (checkIsNeedNewLine()) {
            //           headingStr = "\n$headingStr";
            //         }
            //         toolbar.action(headingStr, "");
            //         onActionCompleted?.call();
            //       },
            //     ),
            //     ToolbarItem(
            //       key: const ValueKey<String>("h3"),
            //       icon: "H3",
            //       tooltip: 'Insert Heading 3',
            //       onPressedButton: () {
            //         String headingStr = "### ";
            //         //check if auto break line
            //         if (checkIsNeedNewLine()) {
            //           headingStr = "\n$headingStr";
            //         }
            //         toolbar.action(headingStr, "");
            //         onActionCompleted?.call();
            //       },
            //     ),
            //     ToolbarItem(
            //       key: const ValueKey<String>("h4"),
            //       icon: "H4",
            //       tooltip: 'Insert Heading 4',
            //       onPressedButton: () {
            //         String headingStr = "#### ";
            //         //check if auto break line
            //         if (checkIsNeedNewLine()) {
            //           headingStr = "\n$headingStr";
            //         }
            //         toolbar.action(headingStr, "");
            //         onActionCompleted?.call();
            //       },
            //     ),
            //     // Heading 5 onwards has same font
            //   ],
            // ),
            // unorder list
            // ToolbarItem(
            //   key: const ValueKey<String>("toolbar_unorder_list_action"),
            //   icon: FontAwesomeIcons.listUl,
            //   tooltip: 'Unordered list',
            //   onPressedButton: () {
            //     String starStr = "* ";
            //     //check if auto break line
            //     if (checkIsNeedNewLine()) {
            //       starStr = "\n$starStr";
            //     }
            //     toolbar.action(starStr, "");
            //     onActionCompleted?.call();
            //   },
            // ),
            // checkbox list
            // ToolbarItem(
            //   key: const ValueKey<String>("toolbar_checkbox_list_action"),
            //   icon: FontAwesomeIcons.listCheck,
            //   isExpandable: true,
            //   expandableBackground: expandableBackground,
            //   items: [
            //     ToolbarItem(
            //       key: const ValueKey<String>("checkbox"),
            //       icon: FontAwesomeIcons.solidSquareCheck,
            //       tooltip: 'Checked checkbox',
            //       onPressedButton: () {
            //         String checkStr = "- [x] ";
            //         //check if auto break line
            //         if (checkIsNeedNewLine()) {
            //           checkStr = "\n$checkStr";
            //         }
            //         toolbar.action(checkStr, "");
            //         onActionCompleted?.call();
            //       },
            //     ),
            //     ToolbarItem(
            //       key: const ValueKey<String>("uncheckbox"),
            //       icon: FontAwesomeIcons.square,
            //       tooltip: 'Unchecked checkbox',
            //       onPressedButton: () {
            //         String checkStr = "- [ ] ";
            //         //check if auto break line
            //         if (checkIsNeedNewLine()) {
            //           checkStr = "\n$checkStr";
            //         }
            //         toolbar.action(checkStr, "");
            //         onActionCompleted?.call();
            //       },
            //     )
            //   ],
            // ),
            // emoji
            // if (showEmojiSelection)
            //   ToolbarItem(
            //     key: const ValueKey<String>("toolbar_emoji_action"),
            //     icon: FontAwesomeIcons.faceSmile,
            //     tooltip: 'Select emoji',
            //     onPressedButton: () async {
            //       await _showModalSelectEmoji(context, controller.selection);
            //     },
            //   ),
            // link
            ToolbarItem(
              key: const ValueKey<String>("toolbar_link_action"),
              icon: FontAwesomeIcons.link,
              tooltip: 'Add hyperlink',
              onPressedButton: () async {
                if (toolbar.hasSelection) {
                  toolbar.action("[enter link description here](", ")");
                } else {
                  await _showModalInputUrl(context,
                      "enter link description here", controller.selection);
                }

                onActionCompleted?.call();
              },
            ),
            // mention
            ToolbarItem(
              key: const ValueKey<String>("toolbar_mention_action"),
              icon: FontAwesomeIcons.at,
              tooltip: 'Add mention',
              onPressedButton: () async {
                if (toolbar.hasSelection) {
                  toolbar.action("[enter mention here](", ")");
                } else {
                  await _showModalInputUrl(context,
                      "enter mention here", controller.selection, isMention: true);
                }

                onActionCompleted?.call();
              },
            ),
            // image
            // ToolbarItem(
            //   key: const ValueKey<String>("toolbar_image_action"),
            //   icon: FontAwesomeIcons.image,
            //   tooltip: 'Add image',
            //   onPressedButton: () async {
            //     if (toolbar.hasSelection) {
            //       toolbar.action("![enter image description here](", ")");
            //     } else {
            //       await _showModalInputUrl(
            //         context,
            //         "enter image description here",
            //         controller.selection,
            //         isImage: true,
            //       );
            //     }
            //
            //     onActionCompleted?.call();
            //   },
            // ),
            // blockquote
            // ToolbarItem(
            //   key: const ValueKey<String>("toolbar_blockquote_action"),
            //   icon: FontAwesomeIcons.quoteLeft,
            //   tooltip: 'Blockquote',
            //   onPressedButton: () {
            //     String checkStr = "> ";
            //     //check if auto break line
            //     if (checkIsNeedNewLine()) {
            //       checkStr = "\n$checkStr";
            //     }
            //     toolbar.action(checkStr, "");
            //     onActionCompleted?.call();
            //   },
            // ),
            // code
            // ToolbarItem(
            //   key: const ValueKey<String>("toolbar_code_action"),
            //   icon: FontAwesomeIcons.code,
            //   tooltip: 'Code syntax/font',
            //   onPressedButton: () {
            //     toolbar.action("`", "`");
            //     onActionCompleted?.call();
            //   },
            // ),
            // line
            // ToolbarItem(
            //   key: const ValueKey<String>("toolbar_line_action"),
            //   icon: FontAwesomeIcons.rulerHorizontal,
            //   tooltip: 'Add line',
            //   onPressedButton: () {
            //     toolbar.action("\n___\n", "");
            //     onActionCompleted?.call();
            //   },
            // ),
          ],
        ),
      ),
    );
  }

  // check is auto break new line
  bool checkIsNeedNewLine() {
    int cursorPos = controller.selection.base.offset;
    if (cursorPos > 0 && controller.text.substring(cursorPos - 1, cursorPos) != "\n") {
      return true;
    }
    return false;
  }

  // Show modal to select emoji
  Future<dynamic> _showModalSelectEmoji(
      BuildContext context, TextSelection selection) {
    return showModalBottomSheet(
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      context: context,
      builder: (context) {
        return ModalSelectEmoji(
          emojiConvert: emojiConvert,
          onChanged: (String emot) {
            if (autoCloseAfterSelectEmoji) Navigator.pop(context);
            final newSelection = toolbar.getSelection(selection);

            toolbar.action(emot, "", textSelection: newSelection);
            // change selection baseoffset if not auto close emoji
            if (!autoCloseAfterSelectEmoji) {
              selection = TextSelection.collapsed(
                offset: newSelection.baseOffset + emot.length,
              );
              unfocus?.call();
            }
            onActionCompleted?.call();
          },
        );
      },
    );
  }

  // show modal input
  Future<dynamic> _showModalInputUrl(
    BuildContext context,
    String defaultDescText,
    TextSelection selection,
    {bool isMention = false,
      bool isImage = false}
  ) {
    return showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return ModalInputUrl(
          toolbar: toolbar,
          defaultDescText: defaultDescText,
          selection: selection,
          onActionCompleted: onActionCompleted,
          isMention: isMention,
          isImage: isImage,
        );
      },
    );
  }
}
