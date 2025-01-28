import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class MomentHeroWidget extends StatefulWidget {
  final Widget child;
  final SlideArea slideType;
  final Object tag;
  final GlobalKey<PhotoViewSlidePageState> slidePageKey;

  const MomentHeroWidget({
    super.key,
    required this.child,
    required this.tag,
    required this.slidePageKey,
    this.slideType = SlideArea.onlyImage,
  });

  @override
  _MomentHeroWidgetState createState() => _MomentHeroWidgetState();
}

class _MomentHeroWidgetState extends State<MomentHeroWidget> {
  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: widget.tag,
      flightShuttleBuilder: (BuildContext flightContext,
          Animation<double> animation,
          HeroFlightDirection flightDirection,
          BuildContext fromHeroContext,
          BuildContext toHeroContext) {
        Widget? item;
        //The FromHero is the src and to is the dest when the flightDirection is push.
        if (flightDirection == HeroFlightDirection.pop) {
          item = AnimatedBuilder(
            animation: animation,
            builder: (BuildContext buildContext, Widget? child) {
              final toHero = toHeroContext.findRenderObject() as RenderBox;
              // 獲取來源和目標的寬度和高度
              final toSize = toHero.size;
              final Widget toHeroWidget = (toHeroContext.widget as Hero).child;
              final Tween<Offset> offsetTween = Tween<Offset>(
                  begin: Offset.zero,
                  end: widget.slidePageKey.currentState!.offset);
              final Tween<double> scaleTween = Tween<double>(
                  begin: 1.0, end: widget.slidePageKey.currentState!.scale);

              return Transform.translate(
                offset: offsetTween.evaluate(animation),
                child: Transform.scale(
                  scale: scaleTween.evaluate(animation),
                  child: UnconstrainedBox(
                      child: SizedBox(
                    width: toSize.width,
                    height: toSize.height,
                    child: toHeroWidget,
                  )),
                ),
              );
            },
          );
        }

        return item ?? (toHeroContext.widget as Hero).child;
      },
      child: widget.child,
    );
  }
}
