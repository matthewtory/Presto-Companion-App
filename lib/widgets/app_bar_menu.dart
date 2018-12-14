import 'package:flutter/material.dart';
import 'package:presto/widgets/sliver_app_bar_menu.dart';
import 'package:flutter/rendering.dart';

import 'dart:async';
import 'package:rxdart/rxdart.dart';

typedef Widget AppBarMenuBuilder(BuildContext context, double scrollStateTransitionValue);

class BottomAppBarMenuCard extends StatelessWidget {

  double value;
  Widget child;

  BottomAppBarMenuCard({@required this.child, @required this.value});

  @override
  Widget build(BuildContext context) {
    double borderRadius = 18.0 * value;
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0.0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(borderRadius), topRight: Radius.circular(borderRadius)),
      ),
      child: child,
    );
  }
}


class AppBarMenu extends StatefulWidget {

  final AppBarMenuBuilder builder;

  AppBarMenu({@required this.builder});

  @override
  _AppBarMenuState createState() => _AppBarMenuState();
}

class _AppBarMenuState extends State<AppBarMenu> with SingleTickerProviderStateMixin {
  final GlobalKey _scrollerContainerKey = GlobalKey();
  final GlobalKey _boxAdapterKey = GlobalKey();

  AnimationController _showHideController;

  ScrollController _scrollController;

  BehaviorSubject<double> _scrollTransitionStreamController;

  @override
  void initState() {
    super.initState();
    _scrollTransitionStreamController = BehaviorSubject<double>();
    _scrollTransitionStreamController.add(0.0);

    _showHideController = new AnimationController(vsync: this, value: 1.0, duration: Duration(seconds: 4));
    _showHideController.fling(velocity: -1.0);
    _showHideController.addListener(() {
      _boxAdapterKey.currentContext.findRenderObject().markNeedsLayout();
      setState(() {

      });
    });
    _showHideController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.of(context).pop();
      }
    });
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      ScrollPosition position = _scrollController.position;
      double start = position.viewportDimension * 0.2;
      double end = position.viewportDimension * 0.3;

      if (position.pixels >= start * 0.8 && position.pixels <= end * 1.2) {
        _scrollTransitionStreamController.sink
            .add(Tween<double>(begin: 0.0, end: 1.0).lerp((position.pixels - start) / (end - start)).clamp(0.0, 1.0));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBarMenuController(
      onHide: () {
        return _showHideController.fling(velocity: 2.0);
      },
      child: NotificationListener<ScrollUpdateNotification>(
        onNotification: (notification) {
          if (((notification.dragDetails == null &&
                      notification.scrollDelta < 0 &&
                      notification.metrics.pixels < -MediaQuery.of(context, nullOk: false).size.height * 0.05) ||
                  (notification.dragDetails == null &&
                      notification.scrollDelta > 0 &&
                      notification.metrics.pixels < -MediaQuery.of(context, nullOk: false).size.height * 0.5)) &&
              !_showHideController.isAnimating) {
            _showHideController.fling(velocity: 0.5 * notification.scrollDelta.abs());
          }
        },
        child: _buildAnimations(
          context: context,
          child: _buildScroller(
            context: context,
            child: Container(
              key: _scrollerContainerKey,
              child: StreamBuilder(
                  stream: _scrollTransitionStreamController.stream,
                  builder: (context, snapshot) {
                    double scrollStateTransitionValue = 1.0;
                    if (snapshot.hasData) {
                      scrollStateTransitionValue = 1.0 - snapshot.data;
                    }
                    return widget.builder(context, scrollStateTransitionValue);
                  }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimations({BuildContext context, Widget child}) {
    return Container(
      color: ColorTween(begin: Colors.black54, end: Colors.transparent).evaluate(_showHideController),
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset.zero, end: Offset(0.0, 0.35)).animate(_showHideController),
        child: child,
      ),
    );
  }

  Widget _buildScroller({BuildContext context, Widget child}) {
    return CustomScrollView(
      reverse: false,
      controller: _scrollController,
      physics: BouncingScrollPhysics(),
      slivers: <Widget>[
        SliverFlexibleBox(
          key: _boxAdapterKey,
          scrollerContainerKey: _scrollerContainerKey,
          child: GestureDetector(
            onTap: () {
              _showHideController.fling(velocity: 2.0);
            },
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        SliverToBoxAdapter(child: child),
        SliverOverscrollFill(
          child: Container(
            color: Theme.of(context).cardColor,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _showHideController.dispose();
    _scrollTransitionStreamController.close();

    super.dispose();
  }
}

typedef Future AppBarMenuHideCallback();

class AppBarMenuController extends InheritedWidget {

  final AppBarMenuHideCallback onHide;

  AppBarMenuController({Key key, Widget child, @required this.onHide}) : super(key: key, child: child);

  Future hideAppBarMenu() => onHide();

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return true;
  }

  static AppBarMenuController of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(AppBarMenuController) as AppBarMenuController;
  }
}
