import 'package:strategy_forge/strategy_forge.dart';

/// Sample layouts belong to the app and are passed into the generic editor.
class DemoLayouts {
  DemoLayouts._();

  static List<StrategyLayout> sample() => [
        _image('full', 'Full Rink', 'full_rink.png', 1240 / 620),
        _image('half', 'Half Rink', 'half_rink.png', 626 / 620),
        _image('quarter', 'Quarter Rink', 'quarter_rink.png', 626 / 310),
        _image('third', 'Third Rink', 'third_rink.png', 620 / 450),
        _image('sixth', 'Sixth Rink', 'sixth_rink.png', 451 / 310),
        _image('neutral', 'Neutral Zone', 'neutral_zone.jpg', 619 / 386),
        _image('studio', 'Studio Rink', 'studio_rink.png', 824 / 620),
        _image('crease', 'Goalie Crease', 'goalie_crease.png', 845 / 365),
      ];

  static StrategyLayout _image(
    String id,
    String label,
    String filename,
    double aspectRatio,
  ) =>
      StrategyLayout.asset(
        id: id,
        label: label,
        assetPath: 'assets/rinks/$filename',
        aspectRatio: aspectRatio,
      );
}
