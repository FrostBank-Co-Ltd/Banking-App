import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'tokens.dart';

/// Layer recipe for the liquid glass chrome that floats over app content.
///
/// Apple documents Liquid Glass for Apple platforms only. There is no official
/// cross platform implementation, so this is an approximation. It is assembled
/// from five layers, always painted in the same order:
///
///   1. refraction  one blurred, saturated, and unevenly scaled copy of the
///                  backdrop. The scale is what bends the content behind the
///                  pane, and it is the layer that separates glass from a
///                  blurred rectangle
///   2. scrim       a thin dark wash that stops bright content behind the pane
///                  from blowing out the glyphs
///   3. lift        a brighter wash that keeps the pane visible over dark content
///   4. specular    a graded rim, two concentrated highlights, and a diagonal
///                  sheen. This is where the sense of a lit, solid edge comes
///                  from, and it carries more of the effect than the blur does
///   5. shadow      outer separation, tinted toward the brand navy
///
/// Refraction is a single pass covering the whole pane, never a stack of inset
/// bands. Bands need hard clips between them, and any hard clip inside the pane
/// reads as a second solid shape sitting inside the glass.
///
/// Scrim and lift are two passes rather than one tint on purpose. A single
/// translucent fill can either lift the pane above a dark backdrop or hold it
/// under a bright one, never both, and app chrome has to sit over both.
///
/// The two brightnesses invert the material rather than sharing it: dark mode is
/// dark glass carrying white glyphs, light mode is pale frosted glass carrying
/// ink glyphs. That is what keeps the pane readable while staying see through,
/// and it is how the system chrome behaves.
@immutable
class Glass {
  const Glass({
    required this.blur,
    required this.saturation,
    required this.lensX,
    required this.lensY,
    required this.scrim,
    required this.lift,
    required this.bloom,
    required this.rimTop,
    required this.rimBottom,
    required this.rimDim,
    required this.sheen,
    required this.shadow,
    required this.shadowBlur,
    required this.shadowOffset,
    required this.fallback,
    required this.onGlass,
    required this.onGlassMuted,
    required this.glyphShadow,
    required this.indicator,
    required this.indicatorRim,
    required this.indicatorGlow,
  });

  /// Blur sigma for the refraction pass, on both axes.
  ///
  /// Deliberately low. A heavy blur erases the very displacement that makes the
  /// pane read as glass, and leaves a grey slab.
  final double blur;

  /// Saturation multiplier applied after the blur, so colour behind the pane
  /// still reads as colour rather than grey.
  final double saturation;

  /// Horizontal scale the backdrop is sampled at. Below one compresses the
  /// surroundings into the pane, which is the direction a real glass edge bends
  /// light. Displacement grows with distance from the centre, so the effect
  /// ramps from nothing in the middle to its strongest at the rim on its own.
  final double lensX;

  /// Vertical scale. Set well below [lensX], because these panes are far wider
  /// than they are tall and a uniform scale would bend the long edges barely at
  /// all while badly distorting the end caps.
  final double lensY;

  /// Dark wash, top to bottom.
  final List<Color> scrim;

  /// Bright wash, top to bottom.
  final List<Color> lift;

  /// Lens light in the upper left corner.
  final Color bloom;

  /// Rim along the top edge, the primary highlight.
  final Color rimTop;

  /// Rim along the bottom edge, the bounce highlight.
  final Color rimBottom;

  /// Rim along the sides, where light only grazes.
  final Color rimDim;

  /// Diagonal reflection sweeping the upper half of the pane.
  final Color sheen;

  final Color shadow;
  final double shadowBlur;
  final Offset shadowOffset;

  /// Opaque fill used when the platform asks for reduced transparency.
  final Color fallback;

  /// Content colour for the selected item.
  final Color onGlass;

  /// Content colour for every other item.
  final Color onGlassMuted;

  /// Halo behind glyphs. A transparent pane cannot guarantee contrast on its
  /// own, so every glyph carries its own separation: a dark halo under white
  /// glyphs, a light one under ink glyphs.
  final Color glyphShadow;

  /// Fill of the selection capsule, top to bottom.
  ///
  /// Near neutral rather than a saturated accent. The selected destination is a
  /// brighter piece of glass sitting on the pane, not a painted button, and the
  /// brand colour arrives as light through [indicatorGlow] instead of as fill.
  final List<Color> indicator;

  final Color indicatorRim;

  /// Glow the selection capsule casts onto the pane beneath it.
  final Color indicatorGlow;

  /// Pale frosted glass carrying ink glyphs.
  static const Glass light = Glass(
    blur: 11,
    saturation: 1.5,
    lensX: 0.9,
    lensY: 0.6,
    // Barely there, just enough to keep a white backdrop from flattening the rim.
    scrim: [Color(0x0F0B0D2B), Color(0x1A0B0D2B)],
    // 0.46 and 0.38. Milky, but a paler pane cannot hold ink glyphs when dark
    // content scrolls under it.
    lift: [Color(0x75FFFFFF), Color(0x61FFFFFF)],
    bloom: Color(0x59FFFFFF),
    rimTop: Color(0xFFFFFFFF),
    rimBottom: Color(0xA6FFFFFF),
    rimDim: Color(0x2E0B0D2B),
    sheen: Color(0x73FFFFFF),
    shadow: Color(0x3D0B0D2B),
    shadowBlur: 28,
    shadowOffset: Offset(0, 10),
    fallback: Color(0xFFF4F7FF),
    onGlass: Palette.textPrimary,
    onGlassMuted: Color(0xB80F1123),
    glyphShadow: Color(0x73FFFFFF),
    // White 0.62 and 0.42. Brighter than the pane, so ink glyphs gain contrast.
    indicator: [Color(0x9EFFFFFF), Color(0x6BFFFFFF)],
    indicatorRim: Color(0x380B0D2B),
    indicatorGlow: Color(0x596A5CFF),
  );

  /// Dark glass carrying white glyphs.
  static const Glass dark = Glass(
    blur: 12,
    saturation: 1.7,
    lensX: 0.9,
    lensY: 0.6,
    // 0.22 and 0.30.
    scrim: [Color(0x38000000), Color(0x4D000000)],
    // 0.13 and 0.05. Low enough to read the backdrop straight through the pane.
    lift: [Color(0x21FFFFFF), Color(0x0DFFFFFF)],
    bloom: Color(0x3DFFFFFF),
    rimTop: Color(0xDBFFFFFF),
    rimBottom: Color(0x6BFFFFFF),
    rimDim: Color(0x1FFFFFFF),
    sheen: Color(0x2EFFFFFF),
    shadow: Color(0x99040616),
    shadowBlur: 34,
    shadowOffset: Offset(0, 14),
    fallback: Palette.darkSurfaceRaised,
    onGlass: Color(0xFFFFFFFF),
    onGlassMuted: Color(0xD1FFFFFF),
    glyphShadow: Color(0x8C04060B),
    // Periwinkle at 0.34 and 0.14: a cool white, not a purple fill.
    indicator: [Color(0x57B0CBFF), Color(0x24B0CBFF)],
    indicatorRim: Color(0x9EFFFFFF),
    indicatorGlow: Color(0x7A6A5CFF),
  );

  static Glass of(BuildContext context) =>
      AppTokens.of(context).isDark ? dark : light;

  /// True when the platform asks for less transparency. Flutter does not expose
  /// the iOS reduce transparency flag, so high contrast stands in for it, the
  /// same substitution the rest of the app makes.
  static bool isReduced(BuildContext context) =>
      MediaQuery.maybeOf(context)?.highContrast ?? false;

  /// Blur composed with the saturation lift.
  ///
  /// Cached, because a fresh [ui.ImageFilter] on every build forces the backdrop
  /// layer to rebuild.
  ui.ImageFilter get filter => _filters.putIfAbsent(this, _buildFilter);

  ui.ImageFilter _buildFilter() => ui.ImageFilter.compose(
    outer: ui.ColorFilter.matrix(_saturationMatrix(saturation)),
    inner: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
  );

  static final Map<Glass, ui.ImageFilter> _filters = {};

  /// Colour matrix that scales saturation around the Rec. 709 luminance axis, so
  /// the lift brightens colour without shifting perceived brightness.
  static List<double> _saturationMatrix(double s) {
    const lr = 0.2126;
    const lg = 0.7152;
    const lb = 0.0722;
    final d = 1 - s;
    return <double>[
      d * lr + s, d * lg, d * lb, 0, 0, //
      d * lr, d * lg + s, d * lb, 0, 0, //
      d * lr, d * lg, d * lb + s, 0, 0, //
      0, 0, 0, 1, 0, //
    ];
  }
}
