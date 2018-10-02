import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:math' as math;

class SliverAppBarMenu extends SingleChildRenderObjectWidget {

  Widget child;
  FloatingHeaderSnapConfiguration snapConfig;

  SliverAppBarMenu({Key key, this.child, this.snapConfig}) : super(key: key, child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSliverAppBarMenu();
  }
}

class _RenderSliverAppBarMenu extends RenderSliverSingleBoxAdapter {

  double extent;
  @override
  void performLayout() {
    extent = extent == null ? constraints.remainingPaintExtent : extent;
    if (child != null) {
      child.layout(constraints.asBoxConstraints(minExtent: extent, maxExtent: extent), parentUsesSize: true);
    }

    final double paintedChildSize = calculatePaintOffset(constraints, from: 0.0, to: extent);
    assert(paintedChildSize.isFinite);
    assert(paintedChildSize >= 0.0);
    geometry = SliverGeometry(
      scrollExtent: extent,
      paintExtent: paintedChildSize,
      maxPaintExtent: paintedChildSize,
      hasVisualOverflow: extent > constraints.remainingPaintExtent || constraints.scrollOffset > 0.0,
    );
    if (child != null)
      setChildParentData(child, constraints, geometry);
  }
}

class SliverOverscrollFill extends SingleChildRenderObjectWidget {

  Widget child;
  FloatingHeaderSnapConfiguration snapConfig;

  SliverOverscrollFill({Key key, this.child, this.snapConfig}) : super(key: key, child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSliverOverscrollFill();
  }
}

class _RenderSliverOverscrollFill extends RenderSliverSingleBoxAdapter {

  @override
  void performLayout() {
    final double extent = math.max(0.0, constraints.remainingPaintExtent - math.min(constraints.overlap, 0.0));
    if (child != null)
      child.layout(constraints.asBoxConstraints(minExtent: extent, maxExtent: extent), parentUsesSize: true);
    final double paintedChildSize = calculatePaintOffset(constraints, from: 0.0, to: extent);
    assert(paintedChildSize.isFinite);
    assert(paintedChildSize >= 0.0);
    geometry = SliverGeometry(
      scrollExtent: 0.0,
      paintExtent: extent,
      maxPaintExtent: paintedChildSize,
      layoutExtent: 0.0,
      paintOrigin: -1.0,
      hasVisualOverflow: extent > constraints.remainingPaintExtent || constraints.scrollOffset > 0.0,
    );
    if (child != null)
      setChildParentData(child, constraints, geometry);
  }
}

class SliverFlexibleBox extends SingleChildRenderObjectWidget {

  Widget child;
  FloatingHeaderSnapConfiguration snapConfig;

  GlobalKey scrollerContainerKey;

  SliverFlexibleBox({Key key, this.child, this.snapConfig, this.scrollerContainerKey}) : super(key: key, child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSliverFlexibleBox(widget: this);
  }
}

class _RenderSliverFlexibleBox extends RenderSliverSingleBoxAdapter {

  SliverFlexibleBox widget;

  _RenderSliverFlexibleBox({this.widget});

  @override
  void performLayout() {

    final RenderBox renderBox = widget.scrollerContainerKey.currentContext.findRenderObject();

    double extent = constraints.remainingPaintExtent * 0.65;
    extent = math.min(constraints.remainingPaintExtent, math.max(extent, constraints.viewportMainAxisExtent - renderBox.getMaxIntrinsicHeight(constraints.crossAxisExtent)));

    if (child != null) {
      child.layout(constraints.asBoxConstraints(minExtent: extent, maxExtent: extent), parentUsesSize: true);
    }
    geometry = SliverGeometry(
      scrollExtent: extent,
      paintExtent: extent,
      maxPaintExtent: extent,
      layoutExtent: math.max(0.0, extent - constraints.scrollOffset),
      hasVisualOverflow: false,
    );
    if(child != null) {
      setChildParentData(child, constraints, geometry);
    }
  }


}