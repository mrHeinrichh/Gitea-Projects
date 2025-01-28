import 'package:flutter/material.dart';
import 'package:flutter_fconsole/delegate/custom_card_delegate.dart';

class ConsoleCardDelegate extends FConsoleCardDelegate {
  @override
  List<FConsoleCard> cardsBuilder(DefaultCards defaultCards) {
    return [
      defaultCards.logCard,
      defaultCards.flowCard,
      defaultCards.sysInfoCard,
      FConsoleCard(
        name: "Custom",
        builder: (ctx) => CustomLogPage(),
      ),
    ];
  }
}

class CustomLogPage extends StatelessWidget {
  const CustomLogPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Text('custom page content'),
    );
  }
}
