/// Gesture-first image preview routes for Flutter.
///
/// The package accepts [ImageProvider]s so callers can keep ownership of
/// networking, caching, and image loading.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Defines the shape used by an [ImageViewerHero] source widget.
sealed class ImageViewerShape {
  const ImageViewerShape();

  /// Uses the image's natural rectangular bounds.
  const factory ImageViewerShape.rectangle() = ImageViewerRectangle;

  /// Clips the source image to a circle.
  const factory ImageViewerShape.circle() = ImageViewerCircle;

  /// Clips all corners to [radius].
  const factory ImageViewerShape.rounded(double radius) = ImageViewerRounded;

  /// Clips each corner using its corresponding radius in [borderRadius].
  const factory ImageViewerShape.roundedCorners(BorderRadius borderRadius) =
      ImageViewerRoundedCorners;
}

/// Rectangular Hero source shape.
final class ImageViewerRectangle extends ImageViewerShape {
  const ImageViewerRectangle();
}

/// Circular Hero source shape.
final class ImageViewerCircle extends ImageViewerShape {
  const ImageViewerCircle();
}

/// Hero source shape with one radius applied to every corner.
final class ImageViewerRounded extends ImageViewerShape {
  const ImageViewerRounded(this.radius);

  /// The radius applied to all four corners.
  final double radius;
}

/// Hero source shape with independently configurable corner radii.
final class ImageViewerRoundedCorners extends ImageViewerShape {
  const ImageViewerRoundedCorners(this.borderRadius);

  /// The corner radii used to clip the source image.
  final BorderRadius borderRadius;
}

/// Wraps a thumbnail or avatar as the Hero source for a preview route.
///
/// Use the same [tag] in [ImageViewerRoute.open] to keep the return animation
/// connected to the source image.
class ImageViewerHero extends StatelessWidget {
  /// Creates a Hero source with an optional shape clip.
  const ImageViewerHero({
    super.key,
    required this.tag,
    required this.child,
    this.shape = const ImageViewerShape.rectangle(),
  });

  /// The Hero identifier shared with the corresponding preview image.
  final Object tag;

  /// The image widget shown at the source location.
  final Widget child;

  /// The clip shape used during the Hero return transition.
  final ImageViewerShape shape;

  @override
  Widget build(BuildContext context) {
    final content = switch (shape) {
      ImageViewerCircle() => ClipOval(child: child),
      ImageViewerRounded(:final radius) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
      ImageViewerRoundedCorners(:final borderRadius) => ClipRRect(
        borderRadius: borderRadius,
        child: child,
      ),
      ImageViewerRectangle() => child,
    };
    return Hero(
      tag: tag,
      placeholderBuilder: (_, _, child) => child,
      child: content,
    );
  }
}

class ImageViewerRoute {
  const ImageViewerRoute._();

  /// Opens an image preview route.
  ///
  /// [images] supplies the full-resolution images. [initialIndex] is clamped
  /// to the available range. Optional [heroTags] and [previewProviders] use
  /// the same indexes as [images]; missing entries simply disable that feature
  /// for the corresponding page.
  ///
  /// The returned Future completes when the preview route is dismissed. An
  /// empty [images] list is ignored.
  static Future<void> open(
    BuildContext context, {
    required List<ImageProvider<Object>> images,
    required int initialIndex,
    List<Object?>? heroTags,
    List<ImageProvider<Object>?>? previewProviders,
    Color backgroundColor = Colors.black,
    bool showCloseButton = true,
    bool showPageIndicator = true,
  }) {
    if (images.isEmpty) return Future<void>.value();
    final index = initialIndex.clamp(0, images.length - 1);
    return Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        pageBuilder: (_, _, _) => _ViewerPage(
          images: List.unmodifiable(images),
          initialIndex: index,
          heroTags: heroTags,
          previewProviders: previewProviders,
          backgroundColor: backgroundColor,
          showCloseButton: showCloseButton,
          showPageIndicator: showPageIndicator,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 180),
        reverseTransitionDuration: const Duration(milliseconds: 240),
      ),
    );
  }
}

class _ViewerPage extends StatefulWidget {
  const _ViewerPage({
    required this.images,
    required this.initialIndex,
    required this.heroTags,
    required this.previewProviders,
    required this.backgroundColor,
    required this.showCloseButton,
    required this.showPageIndicator,
  });
  final List<ImageProvider<Object>> images;
  final int initialIndex;
  final List<Object?>? heroTags;
  final List<ImageProvider<Object>?>? previewProviders;
  final Color backgroundColor;
  final bool showCloseButton;
  final bool showPageIndicator;

  @override
  State<_ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<_ViewerPage>
    with SingleTickerProviderStateMixin {
  late final PageController _pages;
  late final AnimationController _reset;
  late int _index;
  Offset _offset = Offset.zero;
  Offset? _start;
  int? _pointer;
  int _pointers = 0;
  bool _dragging = false;
  bool _cancelled = false;
  bool _heroEnabled = false;
  bool _popping = false;
  final Set<int> _zoomedPages = <int>{};
  Animation<Offset>? _resetAnimation;
  Animation<double>? _routeAnimation;
  VelocityTracker? _velocity;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pages = PageController(initialPage: _index);
    _reset = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..addListener(_tickReset);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animation = ModalRoute.of(context)?.animation;
    if (identical(animation, _routeAnimation)) return;
    _routeAnimation?.removeStatusListener(_routeStatus);
    _routeAnimation = animation;
    if (animation?.status == AnimationStatus.completed) {
      _heroEnabled = true;
    } else {
      animation?.addStatusListener(_routeStatus);
    }
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_routeStatus);
    _reset
      ..removeListener(_tickReset)
      ..dispose();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final progress = height == 0
        ? 0.0
        : (_offset.dy.abs() / (height / 2)).clamp(0.0, 1.0).toDouble();
    final opacity = _popping ? 0.0 : 1 - progress;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ColoredBox(
        color: widget.backgroundColor.withValues(alpha: opacity),
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _pointerDown,
          onPointerMove: _pointerMove,
          onPointerUp: _pointerUp,
          onPointerCancel: _pointerCancel,
          child: Stack(
            children: [
              Positioned.fill(
                child: Transform.translate(
                  offset: _offset,
                  child: Transform.scale(
                    scale: (1 - progress).clamp(0.8, 1.0).toDouble(),
                    child: PageView.builder(
                      controller: _pages,
                      physics: _isZoomed
                          ? const NeverScrollableScrollPhysics()
                          : const PageScrollPhysics(),
                      itemCount: widget.images.length,
                      onPageChanged: (value) {
                        if (_isZoomed && value != _index) {
                          _pages.jumpToPage(_index);
                          return;
                        }
                        setState(() => _index = value);
                      },
                      itemBuilder: (_, index) => _ViewerImage(
                        image: widget.images[index],
                        preview: _preview(index),
                        heroTag: _heroTag(index),
                        heroEnabled: _heroEnabled && index == _index,
                        onZoomChanged: (zoomed) => setState(() {
                          if (zoomed) {
                            _zoomedPages.add(index);
                          } else {
                            _zoomedPages.remove(index);
                          }
                        }),
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.showCloseButton)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Opacity(
                    opacity: opacity,
                    child: SafeArea(
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              if (widget.showPageIndicator && widget.images.length > 1)
                Positioned(
                  top: 0,
                  right: 12,
                  child: Opacity(
                    opacity: opacity,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          '${_index + 1} / ${widget.images.length}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider<Object>? _preview(int index) {
    final list = widget.previewProviders;
    return list != null && index < list.length ? list[index] : null;
  }

  Object? _heroTag(int index) {
    final list = widget.heroTags;
    return list != null && index < list.length ? list[index] : null;
  }

  bool get _isZoomed => _zoomedPages.contains(_index);

  void _pointerDown(PointerDownEvent event) {
    _pointers++;
    if (_pointers != 1) {
      _cancelled = true;
      _animateBack();
      return;
    }
    if (_reset.isAnimating) _reset.stop();
    _pointer = event.pointer;
    _start = event.position;
    _cancelled = false;
    _velocity = VelocityTracker.withKind(event.kind)
      ..addPosition(event.timeStamp, event.position);
  }

  void _pointerMove(PointerMoveEvent event) {
    if (event.pointer == _pointer) {
      _velocity?.addPosition(event.timeStamp, event.position);
    }
    if (event.pointer != _pointer || _cancelled || _isZoomed) return;
    final start = _start;
    if (start == null) return;
    final delta = event.position - start;
    if (!_dragging) {
      if (delta.dy < 8 || delta.dy <= delta.dx.abs()) return;
      _dragging = true;
    }
    setState(() => _offset = Offset(0, delta.dy.clamp(0.0, double.infinity)));
  }

  void _pointerUp(PointerUpEvent event) {
    if (_pointers > 0) _pointers--;
    if (event.pointer != _pointer) return;
    _velocity?.addPosition(event.timeStamp, event.position);
    final downwardVelocity = _velocity?.getVelocity().pixelsPerSecond.dy ?? 0.0;
    final shouldPop =
        !_cancelled &&
        _dragging &&
        (_offset.dy > MediaQuery.sizeOf(context).height / 6 ||
            (_offset.dy > 32 && downwardVelocity > 900));
    _pointer = null;
    _start = null;
    _velocity = null;
    _dragging = false;
    _cancelled = false;
    if (shouldPop) {
      setState(() => _popping = true);
      Navigator.of(context).pop();
    } else {
      _animateBack();
    }
  }

  void _pointerCancel(PointerCancelEvent event) {
    if (_pointers > 0) _pointers--;
    if (event.pointer != _pointer) return;
    _pointer = null;
    _start = null;
    _velocity = null;
    _dragging = false;
    _animateBack();
  }

  void _animateBack() {
    if (_offset == Offset.zero) return;
    _resetAnimation = Tween<Offset>(
      begin: _offset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _reset, curve: Curves.easeOutCubic));
    _reset.forward(from: 0);
  }

  void _tickReset() {
    if (_resetAnimation != null && mounted) {
      setState(() => _offset = _resetAnimation!.value);
    }
  }

  void _routeStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      _routeAnimation?.removeStatusListener(_routeStatus);
      setState(() => _heroEnabled = true);
    }
  }
}

class _ViewerImage extends StatefulWidget {
  const _ViewerImage({
    required this.image,
    required this.preview,
    required this.heroTag,
    required this.heroEnabled,
    required this.onZoomChanged,
  });
  final ImageProvider<Object> image;
  final ImageProvider<Object>? preview;
  final Object? heroTag;
  final bool heroEnabled;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ViewerImage> createState() => _ViewerImageState();
}

class _ViewerImageState extends State<_ViewerImage>
    with SingleTickerProviderStateMixin {
  final _transform = TransformationController();
  late final AnimationController _zoomAnimation;
  Animation<Matrix4>? _zoomTransform;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _zoomAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(_tickZoom);
  }

  @override
  void dispose() {
    _zoomAnimation.dispose();
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final full = Image(
          image: widget.image,
          width: constraints.maxWidth,
          fit: BoxFit.fitWidth,
          gaplessPlayback: true,
          frameBuilder: (_, child, frame, sync) => AnimatedOpacity(
            opacity: frame != null || sync ? 1 : 0,
            duration: const Duration(milliseconds: 120),
            child: child,
          ),
        );
        final child = widget.preview == null
            ? full
            : Stack(
                alignment: Alignment.center,
                children: [
                  Image(
                    image: widget.preview!,
                    width: constraints.maxWidth,
                    fit: BoxFit.fitWidth,
                    gaplessPlayback: true,
                  ),
                  full,
                ],
              );
        final hero = widget.heroTag == null
            ? child
            : HeroMode(
                enabled: widget.heroEnabled,
                child: Hero(
                  tag: widget.heroTag!,
                  flightShuttleBuilder: _heroFlight,
                  child: child,
                ),
              );
        return GestureDetector(
          onDoubleTapDown: (details) =>
              _doubleTapPosition = details.localPosition,
          onDoubleTap: _handleDoubleTap,
          child: InteractiveViewer(
            transformationController: _transform,
            panEnabled: _zoomed,
            minScale: 1,
            maxScale: 10,
            onInteractionStart: (_) => _zoomAnimation.stop(),
            onInteractionUpdate: (_) => _syncZoomState(),
            onInteractionEnd: (_) => _syncZoomState(),
            child: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Center(child: hero),
            ),
          ),
        );
      },
    );
  }

  Offset _doubleTapPosition = Offset.zero;

  void _handleDoubleTap() {
    if (_zoomed) {
      _animateZoom(Matrix4.identity());
      return;
    }
    final target = Matrix4.identity()
      ..translateByDouble(_doubleTapPosition.dx, _doubleTapPosition.dy, 0, 1)
      ..scaleByDouble(2, 2, 1, 1)
      ..translateByDouble(-_doubleTapPosition.dx, -_doubleTapPosition.dy, 0, 1);
    _animateZoom(target);
  }

  void _animateZoom(Matrix4 target) {
    _zoomTransform = Matrix4Tween(begin: _transform.value.clone(), end: target)
        .animate(
          CurvedAnimation(parent: _zoomAnimation, curve: Curves.easeOutCubic),
        );
    _zoomAnimation.forward(from: 0);
  }

  void _tickZoom() {
    final animation = _zoomTransform;
    if (animation == null) return;
    _transform.value = animation.value;
    _syncZoomState();
  }

  void _syncZoomState() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed == _zoomed) return;
    setState(() => _zoomed = zoomed);
    widget.onZoomChanged(zoomed);
  }
}

Widget _heroFlight(
  BuildContext context,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final from = (fromHeroContext.widget as Hero).child;
  final target = (toHeroContext.widget as Hero).child;
  if (direction != HeroFlightDirection.pop ||
      (target is! ClipOval && target is! ClipRRect)) {
    return from;
  }
  return AnimatedBuilder(
    animation: animation,
    child: from,
    builder: (_, child) => LayoutBuilder(
      builder: (_, constraints) {
        final progress = 1 - animation.value;
        final radius = target is ClipOval
            ? BorderRadius.circular(constraints.biggest.shortestSide / 2)
            : (target as ClipRRect).borderRadius;
        return ClipRRect(
          borderRadius: BorderRadiusGeometry.lerp(
            BorderRadius.zero,
            radius,
            progress,
          )!,
          child: child,
        );
      },
    ),
  );
}
