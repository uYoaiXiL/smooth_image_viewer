# smooth_image_viewer

[![pub.dev](https://img.shields.io/pub/v/smooth_image_viewer.svg)](https://pub.dev/packages/smooth_image_viewer)
[![Live Demo](https://img.shields.io/badge/demo-live-4c8bf5)](https://uyoaixil.github.io/smooth_image_viewer/)

A lightweight Flutter image viewer with smooth Hero transitions, natural gestures,
and customizable overlays. Bring your own `ImageProvider`; the package handles
presentation and interaction.

[Try the live Web demo](https://uyoaixil.github.io/smooth_image_viewer/)

## Features

- **Image gestures** — swipe between images, pinch or double-tap to zoom, pan
  when zoomed, and pull down to dismiss with background fade.
- **Hero transitions** — optional enter and exit animations, four source shapes,
  and fast, normal, or slow transition presets.
- **Thumbnail-first previews** — show a thumbnail during the opening transition
  before displaying the full-resolution image.
- **Adaptive display** — fit the entire image within the viewport, respond to
  window resizing, and support mouse dragging for paging and panning.
- **Custom overlays** — add captions or controls with `overlayBuilder`, using
  the current image index and your own button callbacks.
- **Optional preloading** — warm the immediate next and previous images with
  sequential requests through Flutter's shared image cache.
- **Accessibility** — localized close tooltips, keyboard focus, customizable
  page announcements, large text, and right-to-left header layouts.
- **No third-party runtime dependencies** — works with asset, network, memory,
  and custom image providers supported by your target platform.

## Platform Support

| Android | iOS | Web | macOS | Windows | Linux |
| :---: | :---: | :---: | :---: | :---: | :---: |
| ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

Image loading depends on the provider and platform. For example, network images
on Web must satisfy the image host's CORS policy.

## Installation

```yaml
dependencies:
  smooth_image_viewer: ^0.6.0
```

```dart
import 'package:smooth_image_viewer/smooth_image_viewer.dart';
```

Requires Dart `^3.11.3` and Flutter `>=3.35.0`; use a Flutter SDK that bundles
the required Dart version.

## Usage

The following snippets belong inside a widget's `build` method or its callbacks.
Replace the asset paths with assets declared by your app, or supply another
`ImageProvider`, such as `NetworkImage`.

### Open a single image with Hero

Wrap the thumbnail with `ImageViewerHero` and use the same tag in the preview:

```dart
const image = AssetImage('assets/1.webp');

return ImageViewerHero(
  tag: 'photo-1',
  shape: const ImageViewerShape.rounded(12),
  child: GestureDetector(
    onTap: () => ImageViewerRoute.open(
      context,
      images: [image],
      initialIndex: 0,
      heroTags: ['photo-1'],
    ),
    child: Image(image: image, width: 120, height: 150, fit: BoxFit.cover),
  ),
);
```

Hero tags must be unique within the source route. For a plain preview, call
`ImageViewerRoute.open` without the Hero wrapper or `heroTags`.

### Multiple images, preloading, and callbacks

```dart
final images = <ImageProvider<Object>>[
  const AssetImage('assets/1.webp'),
  const AssetImage('assets/2.webp'),
  const AssetImage('assets/3.webp'),
];

ImageViewerRoute.open(
  context,
  images: images,
  initialIndex: 1, // Start with the second image.
  preloadAdjacentImages: true,
  transitionSpeed: ImageViewerTransitionSpeed.fast,
  onPageChanged: (index) => debugPrint('Current image: $index'),
);
```

Indexes are zero-based. For a Hero gallery, provide matching `heroTags` for the
source thumbnails. To use smaller thumbnails during the opening transition,
pass them in `previewProviders` at the same indexes as `images`.

Preloading is off by default. When enabled, it considers only the immediate
neighbors after paging settles, with one speculative request at a time. Rapid
paging skips obsolete queued neighbors; closing stops new requests. In-flight
provider loads cannot be cancelled. This limits request scope, not total memory:
Flutter still manages its shared cache. Use resized providers for very large
images when appropriate.

### Add a custom overlay

The builder receives the current image index and a context inside the preview
route. This example uses the `images` list above:

```dart
ImageViewerRoute.open(
  context,
  images: images,
  initialIndex: 0,
  overlayBuilder: (previewContext, index) => Align(
    alignment: Alignment.bottomCenter,
    child: SafeArea(
      minimum: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Photo ${index + 1} of ${images.length}',
            style: const TextStyle(color: Colors.white),
          ),
          TextButton(
            onPressed: () => Navigator.of(previewContext).pop(),
            child: const Text('Close preview'),
          ),
        ],
      ),
    ),
  ),
);
```

Overlays sit above the image and below the built-in controls, stay in place,
and fade during pull-down dismissal. Hide the default controls with
`showCloseButton: false` or `showPageIndicator: false` if you replace them.

Keep unused overlay areas free of opaque hit targets so image gestures can pass
through. Wrap purely decorative content in `IgnorePointer` when needed. Builders
should have no side effects; button actions belong to your app.

## Configuration

| Option | Default | Purpose |
| --- | --- | --- |
| `heroTags` | None | Connect each image to its source Hero |
| `previewProviders` | None | Show thumbnails during the opening transition |
| `enableEnterHero` / `enableExitHero` | `true` | Enable either Hero direction independently |
| `transitionSpeed` | `normal` | Choose `fast`, `normal`, or `slow` |
| `preloadAdjacentImages` | `false` | Preload the immediate neighboring images |
| `showCloseButton` / `showPageIndicator` | `true` | Toggle built-in controls; single images omit the count |
| `backgroundColor` | `Colors.black` | Set the preview background |
| `onPageChanged` | None | Receive the current zero-based index |
| `overlayBuilder` | None | Build custom preview content |
| `pageIndicatorSemanticLabelBuilder` | English image count | Customize the page indicator's screen-reader description |

`ImageViewerHero.shape` supports `ImageViewerShape.rectangle()` (default),
`.circle()`, `.rounded(12)`, and `.roundedCorners(BorderRadius.only(...))`.
Use the shape matching your thumbnail; the example app demonstrates all four.

## Interaction and Accessibility

Pull-down dismissal requires a clearly downward initial movement. Horizontal or
ambiguous diagonal gestures cannot turn into dismissal midway through a drag.
Additional fingers cancel pending dismissal and unfinished paging. Lift all
fingers before starting a new pull-down gesture; double-tap zoom is accepted
once paging settles.

The close button uses `MaterialLocalizations`, receives initial keyboard focus,
and has a visible focus highlight. Tab and Shift+Tab move between focusable
controls; Enter or Space activates buttons. The header respects text scaling
and layout direction.

The page count announces changes with a live semantic description. To localize
it, pass a builder to `ImageViewerRoute.open`:

```dart
pageIndicatorSemanticLabelBuilder: (index, total) =>
    'Image ${index + 1} of $total',
```

Custom overlays provide their own semantics, focus behavior, and text layout.

## Example App

The [example gallery](example/lib/main.dart) demonstrates multi-image previews
with preloading, Hero shapes, custom overlays, transition speeds, and single images.

```bash
cd example
flutter pub get
flutter run -d chrome
```

Use `flutter devices` to find another target. Native desktop builds require the
matching host platform: macOS for macOS, Windows for Windows.

## License

[MIT](LICENSE)
