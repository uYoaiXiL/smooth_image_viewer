import 'package:flutter/material.dart';
import 'package:smooth_image_viewer/smooth_image_viewer.dart';

void main() => runApp(const ExampleApp());

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

  List<AssetImage> get _images => _paths
      .map((path) => AssetImage(path, package: 'smooth_image_viewer'))
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final images = _images;
    return Scaffold(
      appBar: AppBar(title: const Text('Smooth Image Viewer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('点击图片进入预览，支持双击缩放、双指缩放、左右切换和下滑关闭。'),
          const SizedBox(height: 16),
          _Section(
            title: '多图预览 + 缩略图首帧',
            child: _GalleryGrid(images: images),
          ),
          _Section(
            title: 'Hero 形状',
            child: Row(
              children: [
                Expanded(
                  child: _HeroSample(
                    label: '圆形',
                    tag: 'circle',
                    shape: const ImageViewerShape.circle(),
                    image: images[1],
                  ),
                ),
                Expanded(
                  child: _HeroSample(
                    label: '统一圆角',
                    tag: 'rounded',
                    shape: const ImageViewerShape.rounded(20),
                    image: images[2],
                  ),
                ),
                Expanded(
                  child: _HeroSample(
                    label: '四角圆角',
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
            title: '单图预览',
            child: _HeroSample(label: '无 Hero 单图', tag: null, image: images[0]),
          ),
        ],
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
  });

  final String label;
  final AssetImage image;
  final Object? tag;
  final ImageViewerShape shape;

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
  const _PreviewTile({required this.image, required this.onTap});

  final ImageProvider<Object> image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.8,
      child: Material(
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(12),
        child: Ink.image(
          image: image,
          fit: BoxFit.cover,
          child: InkWell(onTap: onTap),
        ),
      ),
    );
  }
}
