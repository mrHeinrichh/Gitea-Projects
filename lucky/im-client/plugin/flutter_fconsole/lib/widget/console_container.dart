part of 'console.dart';

Widget _consoleBtn() {
  return const ShowFPS(
    alignment: Alignment.topRight,
    visible: true,
    showChart: false,
    borderRadius: BorderRadius.all(Radius.circular(11)),
    child: SizedBox(),
    // Container(
    //   padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
    //   decoration: ShapeDecoration(
    //       shape: RoundedRectangleBorder(
    //         borderRadius: BorderRadius.circular(4),
    //       ),
    //       color: ColorPlate.blue,
    //       shadows: [
    //         BoxShadow(
    //           color: ColorPlate.gray.withOpacity(0.5),
    //           blurRadius: 4,
    //           offset: Offset(0, 2),
    //         )
    //       ]),
    //   child: StText.normal(
    //     'testing',
    //     style: TextStyle(color: ColorPlate.white),
    //   ),
    // ),
  );
}

class ConsoleContainer extends StatefulWidget {
  final Widget? consoleBtn;
  final Alignment? consolePosition;

  const ConsoleContainer({Key? key, this.consoleBtn, this.consolePosition})
      : super(key: key);

  @override
  _ConsoleContainerState createState() => _ConsoleContainerState();
}

class _ConsoleContainerState extends State<ConsoleContainer> {
  GlobalKey _childGK = GlobalKey();
  double xPosition = 0;
  double yPosition = 0;
  double childWidth = 0;
  double childHeight = 0;

  ///是否要计算大小
  bool isCalculateSize = true;
  bool get isShowConsoleBtn =>
      FConsole.instance.status.value == FConsoleStatus.consoleBtn;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((d) {
      Size? childSize = _childGK.currentContext!.size;
      setState(() {
        childWidth = childSize!.width;
        childHeight = childSize.height;
        calculatePosition();
        isCalculateSize = false;
      });
    });
  }

  void calculatePosition() {
    double width = MediaQueryData.fromView(View.of(context)).size.width;
    double height =
        MediaQueryData.fromView(View.of(context)).removePadding().size.height;

    Alignment position = widget.consolePosition!;
    xPosition = position.x * width / 2 + width / 2;
    yPosition = position.y * height / 2 + height / 2;
    if (xPosition < 0) {
      xPosition = 0;
    } else if (xPosition > width - childWidth) {
      xPosition = width - childWidth;
    }
    if (yPosition < 0) {
      yPosition = 0;
    } else if (yPosition > height - childHeight) {
      yPosition = height - childHeight;
    }
    yPosition = yPosition.clamp(20, yPosition);
  }

  @override
  void dispose() {
    FConsole.instance.status.value = FConsoleStatus.hide;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
            child: isCalculateSize
                ? Opacity(
                    opacity: 0.0001,
                    child: Container(
                      key: _childGK,
                      child: widget.consoleBtn ?? _consoleBtn(),
                    ))
                : _TouchMoveView(
                    childWidth: childWidth,
                    childHeight: childHeight,
                    xPosition: xPosition,
                    yPosition: yPosition,
                    child: Visibility(
                      child: widget.consoleBtn ?? _consoleBtn(),
                      visible: isShowConsoleBtn,
                    ),
                    onTap: () {
                      FConsole.instance.status.value = FConsoleStatus.panel;
                      showConsolePanel(() {
                        FConsole.instance.status.value =
                            FConsoleStatus.consoleBtn;
                      });
                    },
                  )),
      ],
    );
  }
}

class _TouchMoveView extends StatefulWidget {
  final Widget child;
  final Function? onTap;

  final double xPosition;

  final double yPosition;

  final double childWidth;

  final double childHeight;

  _TouchMoveView(
      {required this.child,
      this.onTap,
      this.xPosition = 0,
      this.yPosition = 0,
      this.childWidth = 0,
      this.childHeight = 0});

  @override
  State<StatefulWidget> createState() {
    return _TouchMoveState();
  }
}

class _TouchMoveState extends State<_TouchMoveView> {
  double xPosition = 0;
  double yPosition = 0;
  double childWidth = 0;
  double childHeight = 0;

  @override
  void initState() {
    xPosition = widget.xPosition;
    yPosition = widget.yPosition;
    childWidth = widget.childWidth;
    childHeight = widget.childHeight;

    super.initState();
  }

  @override
  void didUpdateWidget(_TouchMoveView oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQueryData.fromView(View.of(context)).size.width;
    double height = MediaQueryData.fromView(View.of(context)).size.height;

    /// keep safe area
    double top = MediaQueryData.fromView(View.of(context)).padding.top;
    double btm = MediaQueryData.fromView(View.of(context)).padding.bottom;
    var _yPosition = yPosition;
    if (_yPosition < top) _yPosition = top;
    if (_yPosition > height - btm) _yPosition = height - btm;

    return Transform.translate(
        offset: Offset(xPosition, _yPosition),
        child: GestureDetector(
          onTap: () {
            widget.onTap?.call();
          },
          onPanUpdate: (detail) {
            setState(() {
              xPosition += detail.delta.dx;
              yPosition += detail.delta.dy;
              if (xPosition < 0) {
                xPosition = 0;
              } else if (xPosition > width - childWidth) {
                xPosition = width - childWidth;
              }
              if (yPosition < 0) {
                yPosition = 0;
              } else if (yPosition > height - childHeight) {
                yPosition = height - childHeight;
              }
            });
          },
          child: widget.child,
        ));
  }
}
