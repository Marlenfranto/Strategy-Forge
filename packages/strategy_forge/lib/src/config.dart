import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'tool_icons.dart';

/// The drawing behavior associated with a toolbar option.
enum StrategyToolKind {
  /// Selects and transforms existing elements.
  select,

  /// Draws a freeform solid path.
  freehand,

  /// Draws a freeform path with an arrow at its end.
  freehandArrow,

  /// Draws a dashed freeform path with an arrow at its end.
  freehandDashedArrow,

  /// Draws a freeform arrow followed by stop bars.
  freehandStopArrow,

  /// Draws the lateral movement notation.
  lateral,

  /// Draws lateral movement followed by stop bars.
  lateralStop,

  /// Draws repeated backwards movement marks.
  backwards,

  /// Draws a wave path.
  wave,

  /// Draws a straight solid line.
  line,

  /// Draws a straight line with an arrow at its end.
  arrow,

  /// Draws a straight arrow followed by stop bars.
  stopArrow,

  /// Draws a straight dashed line.
  dashedLine,

  /// Draws a straight dashed line with an arrow at its end.
  dashedArrow,

  /// Draws a dashed arrow followed by stop bars.
  dashedStopArrow,

  /// Draws a path with an arrow at both ends.
  doubleArrow,

  /// Draws a dashed path with an arrow at both ends.
  dashedDoubleArrow,

  /// Draws an outlined rectangle.
  rectangle,

  /// Draws a filled rectangle.
  filledRectangle,

  /// Draws an outlined ellipse.
  ellipse,

  /// Draws a filled ellipse.
  filledEllipse,

  /// Places a multiline text element.
  text,

  /// Places a marker element.
  marker,
}

/// A strategy background supplied by the host application.
class StrategyLayout {
  /// Creates a layout rendered by [builder].
  const StrategyLayout({
    required this.id,
    required this.label,
    required this.builder,
    this.aspectRatio = 2,
    this.thumbnailBuilder,
  }) : assert(aspectRatio > 0);

  /// Creates a layout from a Flutter image asset.
  StrategyLayout.asset({
    required this.id,
    required this.label,
    required String assetPath,
    String? package,
    this.aspectRatio = 2,
    BoxFit fit = BoxFit.fill,
  })  : assert(aspectRatio > 0),
        builder = ((context) => Image.asset(
              assetPath,
              package: package,
              fit: fit,
              width: double.infinity,
              height: double.infinity,
            )),
        thumbnailBuilder = ((context) =>
            Image.asset(assetPath, package: package, fit: BoxFit.contain));

  /// Creates a layout from encoded image [bytes].
  StrategyLayout.memory({
    required this.id,
    required this.label,
    required Uint8List bytes,
    this.aspectRatio = 2,
    BoxFit fit = BoxFit.fill,
  })  : assert(aspectRatio > 0),
        builder = ((context) => Image.memory(
              bytes,
              fit: fit,
              width: double.infinity,
              height: double.infinity,
            )),
        thumbnailBuilder =
            ((context) => Image.memory(bytes, fit: BoxFit.contain));

  /// The stable identifier serialized in strategy documents.
  final String id;

  /// The label shown by the built-in layout control.
  final String label;

  /// The widget builder used for the full layout.
  final WidgetBuilder builder;

  /// The layout width divided by its height.
  final double aspectRatio;

  /// The optional compact preview shown by the layout menu.
  final WidgetBuilder? thumbnailBuilder;
}

/// Default toolbar icons supplied by the package for custom tools.
class StrategyToolIcons {
  StrategyToolIcons._();

  /// Returns the package fallback icon for [kind].
  static IconData forKind(StrategyToolKind kind) => switch (kind) {
        StrategyToolKind.select => Icons.ads_click_outlined,
        StrategyToolKind.freehand => MyFlutterApp.arrow_freehand,
        StrategyToolKind.freehandArrow => MyFlutterApp.arrow1,
        StrategyToolKind.freehandDashedArrow => MyFlutterApp.dash_lines,
        StrategyToolKind.freehandStopArrow => MyFlutterApp.arrow2,
        StrategyToolKind.lateral => MyFlutterApp.arrow13,
        StrategyToolKind.lateralStop => MyFlutterApp.njsj__1_,
        StrategyToolKind.backwards => CustomIcon.backwards,
        StrategyToolKind.wave => Icons.waves,
        StrategyToolKind.line => MyFlutterApp.straight_lines,
        StrategyToolKind.arrow => Icons.arrow_forward,
        StrategyToolKind.stopArrow => MyFlutterApp.arrow_stright_stop,
        StrategyToolKind.dashedLine => MyFlutterApp.dash_line,
        StrategyToolKind.dashedArrow => MyFlutterApp.arrow11,
        StrategyToolKind.dashedStopArrow => MyFlutterApp.arroew,
        StrategyToolKind.doubleArrow => CustomIcon.twowayarrow,
        StrategyToolKind.dashedDoubleArrow => CustomIcon.twowaydasharrow,
        StrategyToolKind.rectangle => Icons.crop_square,
        StrategyToolKind.filledRectangle => Icons.rectangle,
        StrategyToolKind.ellipse => Icons.circle_outlined,
        StrategyToolKind.filledEllipse => Icons.circle,
        StrategyToolKind.text => Icons.text_fields,
        StrategyToolKind.marker => Icons.place_outlined,
      };
}

/// Display metadata used to group related tools in the built-in toolbar.
class StrategyToolGroup {
  /// Creates toolbar group metadata.
  const StrategyToolGroup({
    required this.id,
    required this.label,
    required this.icon,
  });

  /// The stable identifier used to combine tools into this group.
  final String id;

  /// The label shown by the built-in toolbar.
  final String label;

  /// The icon shown when none of the group's tools is active.
  final IconData icon;
}

/// A selectable editing action. The package supplies a default toolbar icon.
/// [iconBuilder] can replace that icon with any host-provided widget.
class StrategyTool {
  /// Creates a configurable editor tool.
  const StrategyTool({
    required this.id,
    required this.label,
    required this.kind,
    this.icon,
    this.iconBuilder,
    this.markerBuilder,
    this.markerSize = 32,
    this.group,
    this.svgAssetPath,
    this.svgAssetPackage,
    this.primarySvgColor,
    this.iconSvgAssetPath,
    this.iconSvgAssetPackage,
  }) : assert(markerSize > 0);

  /// The stable identifier serialized for marker elements.
  final String id;

  /// The label shown by the built-in toolbar.
  final String label;

  /// The editing behavior activated by this tool.
  final StrategyToolKind kind;

  /// The optional icon used before applying fallback behavior.
  final IconData? icon;

  /// The optional builder that replaces the toolbar icon.
  final WidgetBuilder? iconBuilder;

  /// The optional builder that renders custom marker artwork.
  final WidgetBuilder? markerBuilder;

  /// The unscaled marker width and height in logical pixels.
  final double markerSize;

  /// The optional toolbar group for this tool.
  final StrategyToolGroup? group;

  /// Optional SVG used as both the toolbar icon and marker artwork.
  final String? svgAssetPath;
  final String? svgAssetPackage;

  /// The SVG color replaced by a user's selected marker color. Other SVG
  /// colors remain unchanged. When omitted, selected colors tint the complete
  /// SVG for compatibility with custom tools that predate this option.
  final Color? primarySvgColor;

  /// Optional SVG used only for the toolbar icon.
  final String? iconSvgAssetPath;
  final String? iconSvgAssetPackage;

  Widget buildIcon(BuildContext context) {
    if (iconBuilder != null) {
      return SizedBox(
        width: 18,
        height: 18,
        child: IconTheme.merge(
          data: const IconThemeData(size: 18),
          child: iconBuilder!(context),
        ),
      );
    }
    if (icon != null) return Icon(icon, size: 18);
    if (iconSvgAssetPath != null) {
      final iconColor = IconTheme.of(context).color;
      return SizedBox.square(
        dimension: 18,
        child: SvgPicture.asset(
          iconSvgAssetPath!,
          package: iconSvgAssetPackage,
          fit: BoxFit.contain,
          colorFilter: iconColor == null
              ? null
              : ColorFilter.mode(iconColor, BlendMode.srcIn),
        ),
      );
    }
    if (svgAssetPath != null) {
      return SizedBox.square(
        dimension: 18,
        child: SvgPicture.asset(
          svgAssetPath!,
          package: svgAssetPackage,
          fit: BoxFit.contain,
        ),
      );
    }
    return Icon(StrategyToolIcons.forKind(kind), size: 18);
  }

  /// Renders a marker on the canvas. Hosts may supply custom marker artwork.
  Widget buildMarker(BuildContext context) =>
      buildMarkerWithColor(context, color: null);

  /// Renders a marker with an optional selected color. A null color preserves
  /// the tool's original artwork.
  Widget buildMarkerWithColor(BuildContext context, {required Color? color}) {
    if (kind != StrategyToolKind.marker) {
      throw StateError('Only marker tools can render markers.');
    }
    if (markerBuilder != null) {
      final marker = markerBuilder!(context);
      return color == null
          ? marker
          : ColorFiltered(
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              child: marker,
            );
    }
    if (svgAssetPath != null) {
      final sourceColor = primarySvgColor;
      return SvgPicture.asset(
        svgAssetPath!,
        package: svgAssetPackage,
        fit: BoxFit.contain,
        colorMapper: color == null || sourceColor == null
            ? null
            : _PrimarySvgColorMapper(sourceColor, color),
        colorFilter: color != null && sourceColor == null
            ? ColorFilter.mode(color, BlendMode.srcIn)
            : null,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? const Color(0xff164c85),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(Icons.place, color: Colors.white, size: 18),
      ),
    );
  }

  /// Returns a copy that uses [builder] as its toolbar icon.
  StrategyTool withIconBuilder(WidgetBuilder builder) => StrategyTool(
        id: id,
        label: label,
        kind: kind,
        icon: icon,
        iconBuilder: builder,
        markerBuilder: markerBuilder,
        markerSize: markerSize,
        group: group,
        svgAssetPath: svgAssetPath,
        svgAssetPackage: svgAssetPackage,
        primarySvgColor: primarySvgColor,
        iconSvgAssetPath: iconSvgAssetPath,
        iconSvgAssetPackage: iconSvgAssetPackage,
      );
}

@immutable
class _PrimarySvgColorMapper extends ColorMapper {
  const _PrimarySvgColorMapper(this.source, this.replacement);

  final Color source;
  final Color replacement;

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) =>
      color.toARGB32() == source.toARGB32() ? replacement : color;

  @override
  bool operator ==(Object other) =>
      other is _PrimarySvgColorMapper &&
      other.source == source &&
      other.replacement == replacement;

  @override
  int get hashCode => Object.hash(source, replacement);
}

/// Configuration can be created at runtime and changed by swapping controllers.
class StrategyEditorConfig {
  /// Creates and validates the configuration for one editor view.
  StrategyEditorConfig({
    required this.id,
    required this.name,
    required List<StrategyLayout> layouts,
    required List<StrategyTool> tools,
    List<StrategyTool>? markerRenderers,
    List<Color> colors = const [
      Colors.black,
      Colors.red,
      Colors.orange,
      Colors.green,
      Colors.blue,
      Colors.white,
    ],
    List<double> strokeWidths = const [2, 4, 6, 8],
  })  : layouts = List.unmodifiable(layouts),
        tools = List.unmodifiable(tools),
        markerRenderers = List.unmodifiable(
          markerRenderers ??
              tools.where((tool) => tool.kind == StrategyToolKind.marker),
        ),
        colors = List.unmodifiable(colors),
        strokeWidths = List.unmodifiable(strokeWidths) {
    if (layouts.isEmpty ||
        tools.isEmpty ||
        colors.isEmpty ||
        strokeWidths.isEmpty) {
      throw ArgumentError(
        'Layouts, tools, colors, and stroke widths cannot be empty.',
      );
    }
    if (this.markerRenderers.any(
          (tool) => tool.kind != StrategyToolKind.marker,
        )) {
      throw ArgumentError('Marker renderers must be marker tools.');
    }
    if (layouts.map((item) => item.id).toSet().length != layouts.length ||
        tools.map((item) => item.id).toSet().length != tools.length) {
      throw ArgumentError('Layout and tool IDs must be unique.');
    }
    if (strokeWidths.any((width) => width <= 0)) {
      throw ArgumentError('Stroke widths must be positive.');
    }
  }

  /// The stable configuration identifier serialized in every document.
  final String id;

  /// The host-facing name of this editor configuration.
  final String name;

  /// The host-defined layouts available to the editor.
  final List<StrategyLayout> layouts;

  /// The tools exposed by the built-in toolbar.
  final List<StrategyTool> tools;

  /// Marker renderers available to existing document elements, even when the
  /// corresponding placement tool is hidden from the toolbar.
  final List<StrategyTool> markerRenderers;

  /// The selectable drawing and text colors.
  final List<Color> colors;

  /// The selectable positive stroke widths.
  final List<double> strokeWidths;

  /// Returns the configured layout with [id].
  StrategyLayout layout(String id) =>
      layouts.firstWhere((layout) => layout.id == id);

  /// Returns the enabled tool with [id].
  StrategyTool tool(String id) => tools.firstWhere((tool) => tool.id == id);
}
