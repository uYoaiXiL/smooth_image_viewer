import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smooth_image_viewer/smooth_image_viewer.dart';

void main() => runApp(const _ExampleFrame(child: ExampleApp()));

class _ExampleFrame extends StatelessWidget {
  const _ExampleFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;
    return ColoredBox(
      color: const Color(0xFFDEDEDB),
      child: LayoutBuilder(
        builder: (_, constraints) {
          if (constraints.maxWidth < 600) return child;
          final width = (constraints.maxWidth - 32).clamp(0.0, 430.0);
          final height = (constraints.maxHeight - 32).clamp(0.0, 932.0);
          return Center(
            child: Container(
              width: width,
              height: height,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(40),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 80,
                    offset: Offset(0, 30),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smooth Image Viewer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      home: const GalleryPage(),
    );
  }
}

class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  static const _paths = <String>[
    'assets/1.webp',
    'assets/2.webp',
    'assets/3.webp',
    'assets/4.webp',
    'assets/5.webp',
    'assets/6.webp',
  ];

  List<AssetImage> get _images =>
      _paths.map(AssetImage.new).toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final images = _images;
    return Scaffold(
      appBar: AppBar(title: const Text('Smooth Image Viewer')),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Tap an image to preview. Double-tap or pinch to zoom, swipe to switch images, and pull down to close.',
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'Gallery · Thumbnails & preloading',
                  child: _GalleryGrid(images: images),
                ),
                _Section(
                  title: 'Hero shapes',
                  child: Row(
                    children: [
                      Expanded(
                        child: _HeroSample(
                          label: 'Circle',
                          tag: 'circle',
                          shape: const ImageViewerShape.rounded(99),
                          image: images[1],
                        ),
                      ),
                      Expanded(
                        child: _HeroSample(
                          label: 'Rounded',
                          tag: 'rounded',
                          shape: const ImageViewerShape.rounded(20),
                          image: images[2],
                        ),
                      ),
                      Expanded(
                        child: _HeroSample(
                          label: 'Custom corners',
                          tag: 'corners',
                          shape: const ImageViewerShape.roundedCorners(
                            BorderRadius.only(
                              topLeft: Radius.circular(28),
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(24),
                              bottomLeft: Radius.circular(4),
                            ),
                          ),
                          image: images[3],
                        ),
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: 'Custom overlayBuilder',
                  child: _OverlaySample(
                    images: images.take(3).toList(growable: false),
                  ),
                ),
                _Section(
                  title: 'Transition speed',
                  child: Row(
                    children: [
                      Expanded(
                        child: _HeroSample(
                          label: 'Fast',
                          tag: 'speed-fast',
                          image: images[3],
                          transitionSpeed: ImageViewerTransitionSpeed.fast,
                          // shape: const ImageViewerShape.rounded(12),
                        ),
                      ),
                      Expanded(
                        child: _HeroSample(
                          label: 'Normal (default)',
                          tag: 'speed-normal',
                          image: images[4],
                          transitionSpeed: ImageViewerTransitionSpeed.normal,
                          // shape: const ImageViewerShape.rounded(12),
                        ),
                      ),
                      Expanded(
                        child: _HeroSample(
                          label: 'Slow',
                          tag: 'speed-slow',
                          image: images[5],
                          transitionSpeed: ImageViewerTransitionSpeed.slow,
                          // shape: const ImageViewerShape.rounded(12),
                        ),
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: 'Single image',
                  child: _HeroSample(
                    label: 'Without Hero',
                    tag: null,
                    image: images[0],
                    shape: const ImageViewerShape.rounded(12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _GalleryGrid extends StatelessWidget {
  const _GalleryGrid({required this.images});

  final List<AssetImage> images;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: images.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (_, index) => ImageViewerHero(
        tag: 'gallery-$index',
        shape: const ImageViewerShape.rounded(12),
        child: _PreviewTile(
          image: images[index],
          onTap: () => ImageViewerRoute.open(
            context,
            images: images,
            initialIndex: index,
            heroTags: List<Object?>.generate(
              images.length,
              (i) => 'gallery-$i',
            ),
            previewProviders: images,
            preloadAdjacentImages: true,
            pageIndicatorSemanticLabelBuilder: (index, total) =>
                'Image ${index + 1} of $total',
          ),
        ),
      ),
    );
  }
}

class _OverlaySample extends StatelessWidget {
  const _OverlaySample({required this.images});

  final List<AssetImage> images;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < images.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(
            child: ImageViewerHero(
              tag: 'overlay-$index',
              shape: const ImageViewerShape.rounded(12),
              child: _PreviewTile(
                key: ValueKey('overlay-preview-$index'),
                image: images[index],
                onTap: () => _open(context, index),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _open(BuildContext context, int initialIndex) {
    ImageViewerRoute.open(
      context,
      images: images,
      initialIndex: initialIndex,
      heroTags: List<Object?>.generate(
        images.length,
        (index) => 'overlay-$index',
      ),
      previewProviders: images,
      pageIndicatorSemanticLabelBuilder: (index, total) =>
          'Image ${index + 1} of $total',
      overlayBuilder: (previewContext, index) => Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Material(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Custom title · Image ${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Swipe to update the title. This caption and button are provided by the example app.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.of(previewContext).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Close preview'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSample extends StatelessWidget {
  const _HeroSample({
    required this.label,
    required this.image,
    required this.tag,
    this.shape = const ImageViewerShape.rectangle(),
    this.transitionSpeed = ImageViewerTransitionSpeed.normal,
  });

  final String label;
  final AssetImage image;
  final Object? tag;
  final ImageViewerShape shape;
  final ImageViewerTransitionSpeed transitionSpeed;

  @override
  Widget build(BuildContext context) {
    final child = _PreviewTile(
      image: image,
      onTap: () => ImageViewerRoute.open(
        context,
        images: <ImageProvider<Object>>[image],
        initialIndex: 0,
        heroTags: <Object?>[tag],
        previewProviders: <ImageProvider<Object>?>[image],
        transitionSpeed: transitionSpeed,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        children: [
          if (tag == null)
            child
          else
            ImageViewerHero(tag: tag!, shape: shape, child: child),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({super.key, required this.image, required this.onTap});

  final ImageProvider<Object> image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.8,
      child: Material(
        clipBehavior: Clip.antiAlias,
        // borderRadius: BorderRadius.circular(12),
        child: Ink.image(
          image: image,
          fit: BoxFit.cover,
          child: InkWell(onTap: onTap),
        ),
      ),
    );
  }
}
