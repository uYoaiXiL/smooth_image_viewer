# smooth_image_viewer

A lightweight Flutter image viewer with paging, zoom, gesture dismissal, Hero
return transitions, and optional thumbnail-first rendering.

## Features

- Single-image and multi-image viewing from `ImageProvider`s.
- Page swiping, double-tap zoom, and pinch zoom.
- Pull down to dismiss with scale and background fade.
- Optional Hero return animation for the current image.
- Double-tap zoom between 1x and 2x, centered on the tap position.
- Circle, uniform rounded-corner, and per-corner Hero shapes.
- Optional low-resolution `previewProviders` for a fast first frame.
- No networking, caching, state-management, or UI dependencies.

## Usage

```dart
ImageViewerHero(
  tag: 'avatar-1',
  shape: const ImageViewerShape.circle(),
  child: Image(image: avatarProvider, fit: BoxFit.cover),
)
```

For independent corner radii, use `ImageViewerShape.roundedCorners(...)`.

```dart
ImageViewerRoute.open(
  context,
  images: <ImageProvider<Object>>[avatarProvider],
  initialIndex: 0,
  heroTags: const <Object?>['avatar-1'],
  previewProviders: <ImageProvider<Object>?>[avatarThumbnailProvider],
);
```

The package accepts `ImageProvider`s so applications can choose their own
network and disk-cache implementation.

## Example

Run the interactive gallery from the package root:

```bash
cd example
flutter run
```
