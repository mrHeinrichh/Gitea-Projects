import 'package:country_list_pick/country_selection_theme.dart';
import 'package:country_list_pick/selection_list.dart';
import 'package:country_list_pick/support/code_countries_en.dart';
import 'package:country_list_pick/support/code_country.dart';
import 'package:country_list_pick/support/code_countrys.dart';
import 'package:flutter/material.dart';

export 'support/code_country.dart';

export 'country_selection_theme.dart';

class CountryListPick extends StatefulWidget {
  const CountryListPick(
      {Key? key,
      this.onChanged,
      this.initialSelection,
      this.appBar,
      this.pickerBuilder,
      this.countryBuilder,
      this.theme,
      this.isMandarin = false,
      this.useUiOverlay = true,
      this.useSafeArea = false})
      : super(key: key);

  final String? initialSelection;
  final ValueChanged<Country?>? onChanged;
  final PreferredSizeWidget? appBar;
  final Widget Function(BuildContext context, Country? countryCode)?
      pickerBuilder;
  final CountryTheme? theme;
  final Widget Function(BuildContext context, Country countryCode)?
      countryBuilder;
  final bool useUiOverlay;
  final bool useSafeArea;
  final bool isMandarin;

  @override
  State<StatefulWidget> createState() => CountryListPickState();
}

class CountryListPickState extends State<CountryListPick> {
  Country? selectedItem;
  List elements = [];

  CountryListPickState();

  @override
  void initState() {
    super.initState();

    List<Map> jsonList = widget.isMandarin ? countriesEnglish : codes;

    elements = jsonList
        .map((s) => Country(
              isMandarin: widget.isMandarin,
              name: s['name'],
              code: s['code'],
              dialCode: s['dial_code'],
              flagUri: 'flags/${s['code'].toLowerCase()}.png',
            ))
        .toList();

    if (widget.initialSelection != null) {
      selectedItem = elements.firstWhere(
          (e) =>
              (e.code.toUpperCase() ==
                  widget.initialSelection!.toUpperCase()) ||
              (e.dialCode == widget.initialSelection),
          orElse: () => elements[0] as Country);
    } else {
      selectedItem = elements[0];
    }
  }

  void _awaitFromSelectScreen(BuildContext context, PreferredSizeWidget? appBar,
      CountryTheme? theme) async {
    final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SelectionList(
            elements,
            selectedItem,
            appBar: widget.appBar ??
                AppBar(
                  backgroundColor:
                      Theme.of(context).appBarTheme.backgroundColor,
                  title: const Text("Select Country"),
                ),
            theme: theme,
            countryBuilder: widget.countryBuilder,
            useUiOverlay: widget.useUiOverlay,
            useSafeArea: widget.useSafeArea,
          ),
        ));

    setState(() {
      selectedItem = result ?? selectedItem;
      widget.onChanged!(result ?? selectedItem);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        _awaitFromSelectScreen(context, widget.appBar, widget.theme);
      },
      child: widget.pickerBuilder != null
          ? widget.pickerBuilder!(context, selectedItem)
          : Flex(
              direction: Axis.horizontal,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (widget.theme?.isShowFlag ?? true == true)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: Image.asset(
                        selectedItem!.flagUri!,
                        package: 'country_list_pick',
                        width: 32.0,
                      ),
                    ),
                  ),
                if (widget.theme?.isShowCode ?? true == true)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: Text(selectedItem.toString()),
                    ),
                  ),
                if (widget.theme?.isShowTitle ?? true == true)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: Text(selectedItem!.toCountryStringOnly()),
                    ),
                  ),
                if (widget.theme?.isDownIcon ?? true == true)
                  const Flexible(
                    child: Icon(Icons.keyboard_arrow_down),
                  )
              ],
            ),
    );
  }
}
