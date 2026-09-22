# smooth_image_viewer

A lightweight Flutter image viewer focused on smooth Hero transitions, a
thumbnail-first first frame, and gesture-first interaction.

## Why this package

- **Two-way Hero transitions** — enable or disable Hero independently for
  opening and returning to the source image.
- **Thumbnail-first rendering** — keep a lightweight image in the Hero flight,
  then mount the full-resolution image and gesture layer after the route settles.
- **Natural image interaction** — horizontal paging, pinch zoom, double-tap
  zoom, panning, and pull-down-to-dismiss with scale and background fade.
- **Shape-aware return animation** — rectangle, circle, uniform rounded corners,
  and four independently rounded corners.
- **Preset motion speeds** — fast, normal, and slow timings without exposing
  raw duration values in the public API.
- **Small surface area** — accepts `ImageProvider`s and owns no networking,
  caching, state management, or platform-specific code.

## Install

```yaml
dependencies:
  smooth_image_viewer: ^0.1.0
```

## Quick start

Wrap the image shown in your list or profile page with `ImageViewerHero` and
reuse the same tag when opening the viewer:

```dart
ImageViewerHero(
  tag: 'photo-$id',
  shape: const ImageViewerShape.rounded(12),
  child: Image(
    image: thumbnailProvider,
    fit: BoxFit.cover,
  ),
)
```

```dart
ImageViewerRoute.open(
  context,
  images: <ImageProvider<Object>>[fullProvider],
  initialIndex: 0,
  heroTags: <Object?>['photo-$id'],
  previewProviders: <ImageProvider<Object>?>[thumbnailProvider],
);
```

For multiple images, pass matching lists to `images`, `heroTags`, and
`previewProviders`. Missing Hero tags or previews simply disable that feature
for the corresponding page.

## Motion and callbacks

Hero opening and returning are enabled by default. The transition speed is a
preset, with `normal` matching the default timing:

```dart
ImageViewerRoute.open(
  context,
  images: images,
  initialIndex: 1,
  enableEnterHero: true,
  enableExitHero: true,
  transitionSpeed: ImageViewerTransitionSpeed.normal,
  onPageChanged: (index) {
    debugPrint('Current image: $index'); // zero-based
  },
);
```

Use `ImageViewerTransitionSpeed.fast` or `.slow` for the other presets. Set
either Hero flag to `false` to use the regular route fade for that direction.

## Hero shapes

`ImageViewerHero` is rectangular by default. Declare the shape when the source
image is clipped, especially when the child already uses a rounded `Material`
or another clipping widget:

```dart
// Circle
shape: const ImageViewerShape.circle()

// Same radius on every corner
shape: const ImageViewerShape.rounded(16)

// Independent corner radii
shape: const ImageViewerShape.roundedCorners(
  BorderRadius.only(
    topLeft: Radius.circular(24),
    topRight: Radius.circular(8),
    bottomRight: Radius.circular(18),
    bottomLeft: Radius.circular(4),
  ),
)
```

## Thumbnail-first previews

`previewProviders` is optional. When supplied, the preview provider is shown
first and the full-resolution provider is mounted after the opening transition
settles. For the most stable Hero flight, use the same thumbnail provider (or
an equal `ImageProvider`) in the source `ImageViewerHero` and in
`previewProviders`.

Without a preview provider, the full-resolution image is used as the static
Hero layer.

## API overview

| API | Purpose |
| --- | --- |
| `ImageViewerHero` | Hero source widget with optional shape clipping |
| `ImageViewerRoute.open` | Opens a single-image or multi-image viewer |
| `ImageViewerShape` | Rectangle, circle, rounded, or per-corner shapes |
| `ImageViewerTransitionSpeed` | `fast`, `normal`, and `slow` presets |
| `onPageChanged` | Reports the zero-based page index after horizontal paging |

## Example

The package includes an interactive gallery covering multi-image previews,
thumbnail-first rendering, Hero shapes, and all three transition speed presets:

```bash
cd example
flutter run
```

## License

MIT
