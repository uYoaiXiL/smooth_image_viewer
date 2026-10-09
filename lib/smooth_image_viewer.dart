/// Gesture-first image preview routes for Flutter.
///
/// The package accepts [ImageProvider]s so callers can keep ownership of
/// networking, caching, and image loading.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Preset durations for opening and closing the viewer.
enum ImageViewerTransitionSpeed { fast, normal, slow }

extension on ImageViewerTransitionSpeed {
  Duration get enterDuration => switch (this) {
    ImageViewerTransitionSpeed.fast => const Duration(milliseconds: 150),
    ImageViewerTransitionSpeed.normal => const Duration(milliseconds: 200),
    ImageViewerTransitionSpeed.slow => const Duration(milliseconds: 280),
  };

  Duration get exitDuration => switch (this) {
    ImageViewerTransitionSpeed.fast => const Duration(milliseconds: 180),
    ImageViewerTransitionSpeed.normal => const Duration(milliseconds: 240),
    ImageViewerTransitionSpeed.slow => const Duration(milliseconds: 320),
  };
}

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
      createRectTween: (begin, end) => RectTween(begin: begin, end: end),
      flightShuttleBuilder: _heroFlight,
      // Keep the source image visible while the return shuttle settles.
      // Without this, Flutter hides the source for a frame and the slot
      // flashes before the shuttle reaches it.
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
  /// [overlayBuilder] builds custom content with the current zero-based image
  /// index and a context inside the preview route. It fills the viewport above
  /// the images and below the built-in close button and page indicator. Use
  /// [Align] or [Stack] to position content and [SafeArea] as needed. Set
  /// [showCloseButton] or [showPageIndicator] to false to replace those controls.
  ///
  /// The overlay stays in place and fades during pull-down dismissal. Its
  /// hit-tested content receives its own gestures; leave unused areas without
  /// opaque hit targets so image gestures can pass through. The builder may
  /// run more than once per page and should not perform side effects.
  ///
  /// [preloadAdjacentImages] optionally warms the previous and next image in
  /// Flutter's shared image cache after the route or paging settles. Requests
  /// run one at a time and obsolete queued neighbors are skipped. Providers
  /// already loading cannot be cancelled. Cache eviction and byte limits remain
  /// controlled by Flutter; use resized providers for very large images.
  ///
  /// [pageIndicatorSemanticLabelBuilder] customizes the screen-reader label
  /// using a zero-based index and the total image count. It defaults to
  /// "Image 1 of 3". The close button's semantic label uses [MaterialLocalizations].
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
    bool enableEnterHero = true,
    bool enableExitHero = true,
    ImageViewerTransitionSpeed transitionSpeed =
        ImageViewerTransitionSpeed.normal,
    ValueChanged<int>? onPageChanged,
    IndexedWidgetBuilder? overlayBuilder,
    bool preloadAdjacentImages = false,
    String Function(int index, int total)? pageIndicatorSemanticLabelBuilder,
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
          enableEnterHero: enableEnterHero,
          enableExitHero: enableExitHero,
          onPageChanged: onPageChanged,
          overlayBuilder: overlayBuilder,
          preloadAdjacentImages: preloadAdjacentImages,
          pageIndicatorSemanticLabelBuilder: pageIndicatorSemanticLabelBuilder,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: transitionSpeed.enterDuration,
        reverseTransitionDuration: transitionSpeed.exitDuration,
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
    required this.enableEnterHero,
    required this.enableExitHero,
    required this.onPageChanged,
    required this.overlayBuilder,
    required this.preloadAdjacentImages,
    required this.pageIndicatorSemanticLabelBuilder,
  });
  final List<ImageProvider<Object>> images;
  final int initialIndex;
  final List<Object?>? heroTags;
  final List<ImageProvider<Object>?>? previewProviders;
  final Color backgroundColor;
  final bool showCloseButton;
  final bool showPageIndicator;
  final bool enableEnterHero;
  final bool enableExitHero;
  final ValueChanged<int>? onPageChanged;
  final IndexedWidgetBuilder? overlayBuilder;
  final bool preloadAdjacentImages;
  final String Function(int index, int total)?
  pageIndicatorSemanticLabelBuilder;

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
  final Set<int> _pointers = {};
  bool _multiTouch = false;
  bool _closing = false;
  bool _dragging = false;
  bool _cancelled = false;
  bool _heroEnabled = false;
  bool _settled = false;
  bool _popping = false;
  final Set<int> _zoomedPages = <int>{};
  Animation<Offset>? _resetAnimation;
  Animation<double>? _routeAnimation;
  VelocityTracker? _velocity;
  final Set<ImageProvider<Object>> _preloadAttempted = {};
  bool _preloadScheduled = false;
  bool _preloadRunning = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _heroEnabled = widget.enableEnterHero;
    _pages = PageController(initialPage: _index);
    _reset = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..addListener(_tickReset);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleAdjacentPreload();
    final animation = ModalRoute.of(context)?.animation;
    if (identical(animation, _routeAnimation)) return;
    _routeAnimation?.removeStatusListener(_routeStatus);
    _routeAnimation = animation;
    animation?.addStatusListener(_routeStatus);
    final route = ModalRoute.of(context);
    if (animation?.status == AnimationStatus.completed &&
        !(route?.offstage ?? false)) {
      _heroEnabled = widget.enableExitHero;
      _settled = true;
    } else {
      _heroEnabled = animation?.status == AnimationStatus.reverse
          ? widget.enableExitHero
          : widget.enableEnterHero;
      _settled =
          animation?.status == AnimationStatus.reverse &&
          !widget.enableExitHero;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !identical(_routeAnimation, animation)) return;
        if (animation?.status == AnimationStatus.completed &&
            !(ModalRoute.of(context)?.offstage ?? false)) {
          setState(() {
            _heroEnabled = widget.enableExitHero;
            _settled = true;
          });
        }
      });
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
        child: Stack(
          children: [
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: _pointerDown,
                onPointerMove: _pointerMove,
                onPointerUp: _pointerUp,
                onPointerCancel: _pointerCancel,
                child: Transform.translate(
                  offset: _offset,
                  child: Transform.scale(
                    scale: (1 - progress).clamp(0.8, 1.0).toDouble(),
                    child: NotificationListener<ScrollEndNotification>(
                      onNotification: (notification) {
                        if (notification.depth == 0) _scheduleAdjacentPreload();
                        return false;
                      },
                      child: PageView.builder(
                        controller: _pages,
                        physics: _canPage
                            ? const PageScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                        itemCount: widget.images.length,
                        onPageChanged: (value) {
                          if (_isZoomed && value != _index) {
                            _pages.jumpToPage(_index);
                            return;
                          }
                          setState(() => _index = value);
                          widget.onPageChanged?.call(value);
                        },
                        itemBuilder: (_, index) => _ViewerImage(
                          key: ValueKey<Object?>(
                            Object.hash(widget.images[index], index),
                          ),
                          image: widget.images[index],
                          pageController: _pages,
                          preview: _preview(index),
                          heroTag: _heroTag(index),
                          heroEnabled: _heroEnabled && index == _index,
                          settled: _settled,
                          interactionEnabled: !_closing,
                          canPage: () => _canPage,
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
              ),
            ),
            if (widget.overlayBuilder != null)
              Positioned.fill(
                child: Opacity(
                  opacity: opacity,
                  child: Builder(
                    builder: (context) =>
                        widget.overlayBuilder!(context, _index),
                  ),
                ),
              ),
            if (widget.showCloseButton ||
                (widget.showPageIndicator && widget.images.length > 1))
              PositionedDirectional(
                top: 0,
                start: 0,
                end: 0,
                child: Opacity(
                  opacity: opacity,
                  child: SafeArea(
                    minimum: const EdgeInsets.only(top: 16),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.showCloseButton)
                            IconButton(
                              autofocus: true,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              style: const ButtonStyle(
                                backgroundColor: WidgetStatePropertyAll(
                                  Colors.transparent,
                                ),
                                overlayColor: WidgetStatePropertyAll(
                                  Colors.transparent,
                                ),
                                splashFactory: NoSplash.splashFactory,
                              ),
                              onPressed: _closing ? null : _dismiss,
                              icon: Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                semanticLabel: MaterialLocalizations.of(
                                  context,
                                ).closeButtonTooltip,
                              ),
                            ),
                          if (widget.showPageIndicator &&
                              widget.images.length > 1)
                            Expanded(
                              child: Align(
                                alignment: AlignmentDirectional.topEnd,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Semantics(
                                    liveRegion: true,
                                    excludeSemantics: true,
                                    label:
                                        widget.pageIndicatorSemanticLabelBuilder
                                            ?.call(
                                              _index,
                                              widget.images.length,
                                            ) ??
                                        'Image ${_index + 1} of ${widget.images.length}',
                                    child: Text(
                                      '${_index + 1} / ${widget.images.length}',
                                      textAlign: TextAlign.end,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
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

  bool get _canInteract =>
      mounted &&
      !_closing &&
      _routeAnimation?.status == AnimationStatus.completed &&
      (ModalRoute.of(context)?.isCurrent ?? false);

  bool get _canPage => _canInteract && !_isZoomed && !_dragging && !_multiTouch;

  void _dismiss({bool fromDrag = false}) {
    if (!_canInteract) return;
    setState(() {
      _closing = true;
      _popping = fromDrag;
    });
    Navigator.of(context).pop();
  }

  void _scheduleAdjacentPreload() {
    if (!widget.preloadAdjacentImages || _preloadScheduled) return;
    _preloadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadScheduled = false;
      if (mounted) _preloadNeighbors();
    });
  }

  bool get _canPreload =>
      mounted &&
      !_popping &&
      _routeAnimation?.status == AnimationStatus.completed &&
      (ModalRoute.of(context)?.isCurrent ?? false) &&
      _pages.hasClients &&
      !_pages.position.isScrollingNotifier.value;

  Future<void> _preloadNeighbors() async {
    if (_preloadRunning || !_canPreload) return;
    _preloadRunning = true;
    try {
      while (_canPreload) {
        // Recompute after each request instead of accumulating a queue when
        // the user pages quickly. Prefer the next image, then the previous one.
        final neighbors = <ImageProvider<Object>>{
          if (_index + 1 < widget.images.length) widget.images[_index + 1],
          if (_index > 0) widget.images[_index - 1],
        };
        _preloadAttempted.retainAll(neighbors);
        final pending = neighbors.difference(_preloadAttempted);
        if (pending.isEmpty) break;
        final image = pending.first;
        _preloadAttempted.add(image);
        if (!mounted) break;
        await precacheImage(image, context, onError: (error, stackTrace) {});
        // precacheImage releases its listener at the end of the frame. Wait
        // for that release before starting another speculative request.
        await WidgetsBinding.instance.endOfFrame;
      }
    } finally {
      _preloadRunning = false;
    }
  }

  void _pointerDown(PointerDownEvent event) {
    if (!_canInteract || !_pointers.add(event.pointer)) return;
    if (_pointers.length != 1) {
      setState(() {
        _multiTouch = true;
        _cancelled = true;
        _dragging = false;
      });
      // Cancel an in-progress page drag/fling before a pinch takes over.
      if (_pages.hasClients &&
          (_pages.position.isScrollingNotifier.value ||
              (_pages.page! - _index).abs() > 0.001)) {
        _pages.jumpToPage(_index);
      }
      _animateBack();
      return;
    }
    if (_reset.isAnimating) {
      _reset.stop();
      setState(() => _offset = Offset.zero);
    }
    _pointer = event.pointer;
    _start = event.position;
    // A zoomed pan or an interrupted page fling cannot become dismissal later
    // in the same pointer sequence, even if the image returns to scale 1.
    _cancelled = _isZoomed || _pages.position.isScrollingNotifier.value;
    _velocity = VelocityTracker.withKind(event.kind)
      ..addPosition(event.timeStamp, event.position);
  }

  void _pointerMove(PointerMoveEvent event) {
    if (event.pointer == _pointer) {
      _velocity?.addPosition(event.timeStamp, event.position);
    }
    if (!_canInteract || event.pointer != _pointer || _cancelled || _isZoomed) {
      return;
    }
    final start = _start;
    if (start == null) return;
    final delta = event.position - start;
    if (!_dragging) {
      if (delta.distance < kTouchSlop) return;
      // Commit once: ambiguous diagonals and horizontal/upward gestures are
      // never reconsidered as dismissal after the finger changes direction.
      if (delta.dy <= 0 || delta.dy <= delta.dx.abs() * 1.5) {
        _cancelled = true;
        return;
      }
      _dragging = true;
    }
    setState(() => _offset = Offset(0, delta.dy.clamp(0.0, double.infinity)));
  }

  void _pointerUp(PointerUpEvent event) {
    if (!mounted) return;
    if (!_pointers.remove(event.pointer)) return;
    if (_pointers.isEmpty && _multiTouch) {
      setState(() => _multiTouch = false);
    }
    if (event.pointer != _pointer) return;
    _velocity?.addPosition(event.timeStamp, event.position);
    final downwardVelocity = _velocity?.getVelocity().pixelsPerSecond.dy ?? 0.0;
    final shouldPop =
        _canInteract &&
        !_isZoomed &&
        !_cancelled &&
        _dragging &&
        (_offset.dy > MediaQuery.sizeOf(context).height / 6 ||
            (_offset.dy > 32 && downwardVelocity > 900));
    _pointer = null;
    _start = null;
    _velocity = null;
    setState(() => _dragging = false);
    _cancelled = _pointers.isNotEmpty;
    if (shouldPop) {
      _dismiss(fromDrag: true);
    } else if (!_closing) {
      _animateBack();
    }
  }

  void _pointerCancel(PointerCancelEvent event) {
    if (!mounted) return;
    if (!_pointers.remove(event.pointer)) return;
    if (_pointers.isEmpty && _multiTouch) {
      setState(() => _multiTouch = false);
    }
    if (event.pointer != _pointer) return;
    _pointer = null;
    _start = null;
    _velocity = null;
    setState(() => _dragging = false);
    _cancelled = _pointers.isNotEmpty;
    if (!_closing) _animateBack();
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
    if (!mounted) return;
    if (status == AnimationStatus.completed &&
        !(ModalRoute.of(context)?.offstage ?? false)) {
      setState(() {
        _heroEnabled = widget.enableExitHero;
        _settled = true;
      });
      _scheduleAdjacentPreload();
    } else if (status == AnimationStatus.forward) {
      setState(() {
        _heroEnabled = widget.enableEnterHero;
        _settled = false;
      });
    } else if (status == AnimationStatus.reverse) {
      _reset.stop();
      setState(() {
        _closing = true;
        _cancelled = true;
        _dragging = false;
        _heroEnabled = widget.enableExitHero;
        _settled = !widget.enableExitHero;
      });
    } else if (status == AnimationStatus.dismissed) {
      setState(() => _settled = false);
    }
  }
}

class _ViewerImage extends StatefulWidget {
  const _ViewerImage({
    super.key,
    required this.image,
    required this.pageController,
    required this.preview,
    required this.heroTag,
    required this.heroEnabled,
    required this.settled,
    required this.interactionEnabled,
    required this.canPage,
    required this.onZoomChanged,
  });
  final ImageProvider<Object> image;
  final PageController pageController;
  final ImageProvider<Object>? preview;
  final Object? heroTag;
  final bool heroEnabled;
  final bool settled;
  final bool interactionEnabled;
  final bool Function() canPage;
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
  Drag? _mousePageDrag;

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
    _mousePageDrag?.cancel();
    _zoomAnimation.dispose();
    _transform.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ViewerImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.interactionEnabled) {
      _zoomAnimation.stop();
      _mousePageDrag?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final staticImage = Image(
          key: ValueKey<Object>(widget.preview ?? widget.image),
          image: widget.preview ?? widget.image,
          width: constraints.maxWidth,
          fit: BoxFit.fitWidth,
          alignment: Alignment.center,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 42,
            ),
          ),
        );
        // Fit both axes while keeping the Hero bounds on the visible image.
        // A width-fitted image alone crops tall images in a wide viewport.
        final fittedStaticImage = FittedBox(
          fit: BoxFit.contain,
          child: staticImage,
        );
        final hero = widget.heroTag == null
            ? fittedStaticImage
            : HeroMode(
                enabled: widget.heroEnabled,
                child: Hero(
                  tag: widget.heroTag!,
                  createRectTween: (begin, end) =>
                      RectTween(begin: begin, end: end),
                  flightShuttleBuilder: _heroFlight,
                  child: RepaintBoundary(child: fittedStaticImage),
                ),
              );
        final full = Image(
          key: ValueKey<Object>(widget.image),
          image: widget.image,
          width: constraints.maxWidth,
          fit: BoxFit.fitWidth,
          alignment: Alignment.center,
          gaplessPlayback: true,
          // Keep the loading preview in the same transform as the full image.
          // A stationary fallback underneath would show through when panning.
          frameBuilder: (_, child, frame, sync) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 120),
            child: frame != null || sync ? child : staticImage,
          ),
          errorBuilder: (_, _, _) => const SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 42,
            ),
          ),
        );
        final interactive = GestureDetector(
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
            // Handle mouse paging inside InteractiveViewer so its scale
            // recognizer cannot win the same drag first. Forward to the page
            // position to retain its snapping, velocity, and edge physics.
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              supportedDevices: const {PointerDeviceKind.mouse},
              onHorizontalDragStart: _zoomed ? null : _startMousePaging,
              onHorizontalDragUpdate: _zoomed
                  ? null
                  : (details) => _mousePageDrag?.update(details),
              onHorizontalDragEnd: _zoomed
                  ? null
                  : (details) => _mousePageDrag?.end(details),
              onHorizontalDragCancel: _zoomed
                  ? null
                  : () => _mousePageDrag?.cancel(),
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: Center(
                  child: FittedBox(fit: BoxFit.contain, child: full),
                ),
              ),
            ),
          ),
        );
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              // Preserve Hero registration and geometry for the return flight,
              // but do not paint a second image underneath the interactive one.
              child: Opacity(
                opacity: widget.settled ? 0 : 1,
                child: Center(child: hero),
              ),
            ),
            if (widget.settled)
              IgnorePointer(
                ignoring: !widget.interactionEnabled,
                child: interactive,
              ),
          ],
        );
      },
    );
  }

  Offset _doubleTapPosition = Offset.zero;

  void _startMousePaging(DragStartDetails details) {
    if (!widget.canPage()) return;
    _mousePageDrag?.cancel();
    _mousePageDrag = widget.pageController.position.drag(
      details,
      () => _mousePageDrag = null,
    );
  }

  void _handleDoubleTap() {
    if (!widget.interactionEnabled ||
        !widget.pageController.hasClients ||
        widget.pageController.position.isScrollingNotifier.value) {
      return;
    }
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
    if (!widget.interactionEnabled) return;
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
  if (direction != HeroFlightDirection.pop) {
    return from;
  }
  if (target is! ClipOval && target is! ClipRRect) return target;
  final targetImage = target is ClipOval
      ? target.child
      : (target as ClipRRect).child;
  return AnimatedBuilder(
    animation: animation,
    child: targetImage,
    builder: (_, child) => LayoutBuilder(
      builder: (_, constraints) {
        final progress = 1 - animation.value;
        final radius = target is ClipOval
            ? BorderRadius.circular(constraints.biggest.shortestSide / 2)
            : (target as ClipRRect).borderRadius;
        final borderRadius = target is ClipOval
            ? BorderRadius.circular(
                constraints.biggest.shortestSide / 2 * progress,
              )
            : BorderRadiusGeometry.lerp(BorderRadius.zero, radius, progress)!;
        return ClipRRect(borderRadius: borderRadius, child: child);
      },
    ),
  );
}
