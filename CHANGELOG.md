## 0.6.0 - 2026-10-09

* Added `overlayBuilder` for custom captions and controls that follow the current
  image index and fade during dismissal. Overlay controls handle their own
  gestures while unoccupied areas allow image gestures through.
* Added opt-in `preloadAdjacentImages` to preload the immediate next and previous
  images sequentially through Flutter's shared cache, skipping obsolete queued
  neighbors after paging.
* Improved accessibility with a localized close tooltip, initial keyboard focus,
  visible focus feedback, and `pageIndicatorSemanticLabelBuilder` for custom
  page announcements. The header now accommodates large text and RTL layouts.
* Prevented horizontal and ambiguous diagonal drags from turning into accidental
  dismissal, and stabilized paging and dismissal when additional fingers join.
* Guarded against repeated dismissal, stopped zoom animations while closing,
  and added regression coverage for rapid paging and interrupted gestures.
* Updated the example with English copy, preloading, and a dedicated three-image
  overlay demonstration with matching Hero transitions.
* Reorganized the README with Features, Platform Support, concise usage examples,
  and a configuration reference.

## 0.5.1 - 2026-10-09

* Fixed mouse-drag paging on Web and desktop while preserving image panning
  when zoomed and pull-down dismissal.
* Fit previews within both viewport dimensions to display the entire image on
  wide screens and adapt to window resizing, with matching Hero image bounds.
* Added macOS and Windows example projects and constrained the gallery width
  for desktop layouts.
* Added regression coverage for mouse gestures, viewport resizing, and the
  example preview flow.

## 0.5.0
* fix live link

## 0.4.0 - 2026-09-22

* Improved default rectangular Hero return transitions when the source child
  provides its own clipping or rounded layout.
* Added configurable enter and exit Hero animations with fast, normal, and slow
  transition presets.
* Added the `onPageChanged` callback for multi-image viewers.
* Added a responsive desktop Web preview frame and GitHub Pages deployment.
* Expanded the README with installation, API, Hero shape, and live preview
  documentation.

## 0.3.0

* Improved Hero rendering with a thumbnail-first static layer and deferred
  full-resolution interaction layer.
* Stabilized Hero return transitions for rectangular, circular, and rounded
  source widgets.
* Added optional enter and exit Hero animation flags.
* Added fast, normal, and slow transition speed presets.
* Added the `onPageChanged` callback for horizontal paging.
* Expanded the example with transition speed demos and a responsive desktop
  web phone frame.
* Added GitHub Pages deployment for the web example.

## 0.1.0

* Added single-image and multi-image preview routes.
* Added horizontal paging, pinch zoom, smooth double-tap zoom, and panning.
* Added pull-down dismissal with distance and velocity thresholds.
* Added optional Hero return transitions for the current image.
* Added circle, uniform rounded, and per-corner Hero shapes.
* Added optional preview providers for thumbnail-first rendering.

## 0.0.1

* Initial package scaffold.
