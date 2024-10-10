import 'package:flutter/material.dart';
import 'package:im_common/im_common.dart' as common;
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

class CustomInputTags extends StatefulWidget {
  final List<User> selectedUsers;
  final ScrollController? scrollController;
  final TextEditingController searchController;
  final String? hintText;
  final VoidCallback? onSearchTap;
  final Function(int) onUserTagTap;
  final Function(String)? onSearchChanged;

  const CustomInputTags({
    super.key,
    required this.selectedUsers,
    this.scrollController,
    required this.searchController,
    this.hintText,
    this.onSearchTap,
    required this.onUserTagTap,
    this.onSearchChanged,
  });

  @override
  State<CustomInputTags> createState() => _CustomInputTagsState();
}

class _CustomInputTagsState extends State<CustomInputTags> {
  final FocusNode _searchFocusNode = FocusNode();
  int _selectedUserUid = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        _searchFocusNode.requestFocus();
        if (widget.onSearchTap != null) widget.onSearchTap!();
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: colorBackground,
            border: Border.symmetric(
              horizontal: BorderSide(color: colorBorder),
            ),
          ),
          constraints: const BoxConstraints(
            minHeight: 40,
            maxHeight: 120,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            controller: widget.scrollController,
            physics: const ClampingScrollPhysics(),
            child: Wrap(
              children: [
                ...List.generate(widget.selectedUsers.length, (index) {
                  final int uid = widget.selectedUsers[index].uid;

                  return GestureDetector(
                    key: ValueKey(uid),
                    onTap: () {
                      setState(() {
                        if (_selectedUserUid != uid) {
                          _selectedUserUid = uid;
                        } else {
                          widget.onUserTagTap(index);
                          _selectedUserUid = 0;
                        }
                      });
                    },
                    child: _buildUserTag(uid),
                  );
                }),
                IntrinsicWidth(
                  child: TextField(
                    contextMenuBuilder: common.textMenuBar,
                    controller: widget.searchController,
                    focusNode: _searchFocusNode,
                    onChanged: widget.onSearchChanged,
                    cursorRadius: const Radius.circular(2),
                    cursorColor: themeColor,
                    style: TextStyle(
                      fontSize: MFontSize.size14.value,
                      color: colorTextPrimary,
                      decorationThickness: 0,
                    ),
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      hintText: widget.hintText ?? localized(contactSearchHint),
                      hintStyle: jxTextStyle.textStyle14(
                        color: colorTextPlaceholder,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTag(int uid) {
    final bool isSelected = _selectedUserUid == uid;

    return OpacityEffect(
      child: Container(
        key: ValueKey(uid),
        margin: const EdgeInsets.only(top: 4, right: 4, bottom: 4),
        constraints: const BoxConstraints(maxWidth: 150, minHeight: 24),
        padding: const EdgeInsets.fromLTRB(1, 1, 8, 1),
        decoration: ShapeDecoration(
          color: isSelected ? themeColor : colorBorder,
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            isSelected
                ? const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.close,
                      color: colorWhite,
                      size: 16,
                    ),
                  )
                : CustomAvatar.normal(
                    uid,
                    size: 22,
                    headMin: Config().headMin,
                  ),
            const SizedBox(width: 4),
            Flexible(
              child: NicknameText(
                uid: uid,
                fontSize: MFontSize.size14.value,
                overflow: TextOverflow.ellipsis,
                isTappable: false,
                color: isSelected ? colorWhite : colorTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
