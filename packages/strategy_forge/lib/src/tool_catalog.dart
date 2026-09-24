import 'package:flutter/material.dart';

import 'config.dart';
import 'tool_assets.dart';

/// Generic editing tools and bundled marker artwork provided by the package.
///
/// An embedding app chooses individual tool IDs for each view. Catalog order is
/// stable so a host can filter [all] without rebuilding toolbar metadata.
class StrategyToolCatalog {
  StrategyToolCatalog._();

  static const pucksGroup = StrategyToolGroup(
    id: 'pucks',
    label: 'Pucks',
    icon: Icons.blur_circular_outlined,
  );
  static const equipmentGroup = StrategyToolGroup(
    id: 'equipment',
    label: 'Equipment',
    icon: Icons.construction_outlined,
  );
  static const netsGroup = StrategyToolGroup(
    id: 'nets',
    label: 'Nets',
    icon: Icons.grid_4x4_rounded,
  );
  static const playersGroup = StrategyToolGroup(
    id: 'players',
    label: 'Players',
    icon: Icons.groups_outlined,
  );
  static const positionsGroup = StrategyToolGroup(
    id: 'positions',
    label: 'Positions',
    icon: Icons.account_tree_outlined,
  );
  static const numbersGroup = StrategyToolGroup(
    id: 'numbers',
    label: 'Numbers',
    icon: Icons.pin_outlined,
  );
  static const teamsGroup = StrategyToolGroup(
    id: 'teams',
    label: 'Teams',
    icon: Icons.groups_2_outlined,
  );
  static const objectsGroup = StrategyToolGroup(
    id: 'objects',
    label: 'Objects',
    icon: Icons.sports_soccer_outlined,
  );
  static const targetsGroup = StrategyToolGroup(
    id: 'targets',
    label: 'Targets',
    icon: Icons.flag_outlined,
  );
  static const trainingGroup = StrategyToolGroup(
    id: 'training',
    label: 'Training',
    icon: Icons.fitness_center_outlined,
  );

  /// One selectable tool for every distinct canvas editing behavior.
  static const List<StrategyTool> core = [
    StrategyTool(id: 'select', label: 'Select', kind: StrategyToolKind.select),
    StrategyTool(
      id: 'freehand',
      label: 'Freehand',
      kind: StrategyToolKind.freehand,
    ),
    StrategyTool(
      id: 'freehand_arrow',
      label: 'Freehand Arrow',
      kind: StrategyToolKind.freehandArrow,
    ),
    StrategyTool(
      id: 'freehand_dashed_arrow',
      label: 'Freehand Dashed Arrow',
      kind: StrategyToolKind.freehandDashedArrow,
      iconSvgAssetPath: StrategyToolAssets.freehandDashedArrow,
      iconSvgAssetPackage: StrategyToolAssets.packageName,
    ),
    StrategyTool(
      id: 'freehand_stop_arrow',
      label: 'Freehand Stop',
      kind: StrategyToolKind.freehandStopArrow,
    ),
    StrategyTool(
      id: 'lateral',
      label: 'Lateral',
      kind: StrategyToolKind.lateral,
    ),
    StrategyTool(
      id: 'lateral_stop',
      label: 'Lateral Stop',
      kind: StrategyToolKind.lateralStop,
    ),
    StrategyTool(
      id: 'backwards',
      label: 'Backwards',
      kind: StrategyToolKind.backwards,
    ),
    StrategyTool(id: 'wave', label: 'Wave', kind: StrategyToolKind.wave),
    StrategyTool(id: 'line', label: 'Line', kind: StrategyToolKind.line),
    StrategyTool(id: 'arrow', label: 'Arrow', kind: StrategyToolKind.arrow),
    StrategyTool(
      id: 'stop_arrow',
      label: 'Stop Arrow',
      kind: StrategyToolKind.stopArrow,
    ),
    StrategyTool(
      id: 'dashed_line',
      label: 'Dashed Line',
      kind: StrategyToolKind.dashedLine,
    ),
    StrategyTool(
      id: 'dashed_arrow',
      label: 'Dashed Arrow',
      kind: StrategyToolKind.dashedArrow,
    ),
    StrategyTool(
      id: 'dashed_stop_arrow',
      label: 'Dashed Stop Arrow',
      kind: StrategyToolKind.dashedStopArrow,
    ),
    StrategyTool(
      id: 'double_arrow',
      label: 'Two-way Arrow',
      kind: StrategyToolKind.doubleArrow,
    ),
    StrategyTool(
      id: 'dashed_double_arrow',
      label: 'Dashed Two-way Arrow',
      kind: StrategyToolKind.dashedDoubleArrow,
    ),
    StrategyTool(
      id: 'rectangle',
      label: 'Rectangle',
      kind: StrategyToolKind.rectangle,
    ),
    StrategyTool(
      id: 'filled_rectangle',
      label: 'Filled Rectangle',
      kind: StrategyToolKind.filledRectangle,
    ),
    StrategyTool(
      id: 'ellipse',
      label: 'Ellipse',
      kind: StrategyToolKind.ellipse,
    ),
    StrategyTool(
      id: 'filled_ellipse',
      label: 'Filled Ellipse',
      kind: StrategyToolKind.filledEllipse,
    ),
    StrategyTool(id: 'text', label: 'Text', kind: StrategyToolKind.text),
    StrategyTool(id: 'marker', label: 'Marker', kind: StrategyToolKind.marker),
  ];

  /// Unique marker entries from the original toolbar palettes.
  static final List<StrategyTool> svgTools = List.unmodifiable([
    _svg('puck', 'Puck', StrategyToolAssets.puck, pucksGroup, size: 26),
    _svg(
      'puck_group',
      'Group of pucks',
      StrategyToolAssets.pucks,
      pucksGroup,
      size: 38,
    ),
    _svg('equipment_cone', 'Cone', StrategyToolAssets.cone, equipmentGroup),
    _svg('equipment_tire', 'Tire', StrategyToolAssets.tire, equipmentGroup),
    _svg('equipment_stick', 'Stick', StrategyToolAssets.stick, equipmentGroup),
    _svg(
      'equipment_stickhandling',
      'Stickhandling',
      StrategyToolAssets.stickhandling,
      equipmentGroup,
    ),
    _svg(
      'equipment_triangle',
      'Triangle',
      StrategyToolAssets.triangle,
      equipmentGroup,
    ),
    _svg(
      'equipment_border_vertical',
      'Border vertical',
      StrategyToolAssets.borderVertical,
      equipmentGroup,
    ),
    _svg(
      'equipment_border_horizontal',
      'Border horizontal',
      StrategyToolAssets.borderHorizontal,
      equipmentGroup,
    ),
    _svg('net_up', 'Net up', StrategyToolAssets.netUp, netsGroup, size: 52),
    _svg(
      'net_down',
      'Net down',
      StrategyToolAssets.netDown,
      netsGroup,
      size: 52,
    ),
    _svg(
      'net_right',
      'Net right',
      StrategyToolAssets.netRight,
      netsGroup,
      size: 52,
    ),
    _svg(
      'net_left',
      'Net left',
      StrategyToolAssets.netLeft,
      netsGroup,
      size: 52,
    ),
    _svg(
      'net_mini',
      'Mini net',
      StrategyToolAssets.miniNet,
      netsGroup,
      size: 52,
    ),
    ..._playerPalette('player', playersGroup),
    _svg(
      'position_center',
      'Center',
      StrategyToolAssets.center,
      positionsGroup,
    ),
    _svg(
      'position_left_wing',
      'Left wing',
      StrategyToolAssets.leftWing,
      positionsGroup,
    ),
    _svg(
      'position_right_wing',
      'Right wing',
      StrategyToolAssets.rightWing,
      positionsGroup,
    ),
    _svg(
      'position_left_defense',
      'Left defense',
      StrategyToolAssets.leftDefense,
      positionsGroup,
    ),
    _svg(
      'position_right_defense',
      'Right defense',
      StrategyToolAssets.rightDefense,
      positionsGroup,
    ),
    for (var index = 0; index < _numbers.length; index++)
      _svg(
        'number_${index + 1}',
        '${index + 1}',
        _numbers[index],
        numbersGroup,
        size: 28,
      ),
  ]);

  /// Generic markers that let host apps compose tool sets for many sports
  /// without placing sport selection or layouts inside the package.
  static final List<StrategyTool> universalMarkerTools = List.unmodifiable([
    _marker(
      'team_home',
      'Home player',
      StrategyToolAssets.playerHome,
      teamsGroup,
    ),
    _marker(
      'team_away',
      'Away player',
      StrategyToolAssets.playerAway,
      teamsGroup,
    ),
    _marker(
      'team_neutral',
      'Neutral player',
      StrategyToolAssets.playerNeutral,
      teamsGroup,
    ),
    _marker(
      'role_goalkeeper',
      'Goalkeeper',
      StrategyToolAssets.goalkeeper,
      teamsGroup,
    ),
    _marker(
      'role_official',
      'Official',
      StrategyToolAssets.official,
      teamsGroup,
    ),
    _marker(
      'role_substitute',
      'Substitute',
      StrategyToolAssets.substitute,
      teamsGroup,
    ),
    _marker('role_coach', 'Coach', StrategyToolAssets.coachBoard, teamsGroup),
    _marker(
      'role_possession',
      'Possession',
      StrategyToolAssets.possession,
      teamsGroup,
    ),
    _marker(
      'object_round_ball',
      'Round ball',
      StrategyToolAssets.roundBall,
      objectsGroup,
      size: 26,
    ),
    _marker(
      'object_oval_ball',
      'Oval ball',
      StrategyToolAssets.ovalBall,
      objectsGroup,
      size: 30,
    ),
    _marker(
      'object_small_ball',
      'Small ball',
      StrategyToolAssets.smallBall,
      objectsGroup,
      size: 22,
    ),
    _marker(
      'object_disc',
      'Flying disc',
      StrategyToolAssets.disc,
      objectsGroup,
      size: 30,
    ),
    _marker(
      'object_shuttlecock',
      'Shuttlecock',
      StrategyToolAssets.shuttlecock,
      objectsGroup,
      size: 30,
    ),
    _marker(
      'object_curling_stone',
      'Curling stone',
      StrategyToolAssets.curlingStone,
      objectsGroup,
      size: 34,
    ),
    _marker('object_bat', 'Bat', StrategyToolAssets.bat, objectsGroup),
    _marker('object_racket', 'Racket', StrategyToolAssets.racket, objectsGroup),
    _marker(
      'object_broom',
      'Broom / brush',
      StrategyToolAssets.broom,
      objectsGroup,
    ),
    _marker(
      'target_goal',
      'Goal',
      StrategyToolAssets.goal,
      targetsGroup,
      size: 52,
    ),
    _marker(
      'target_hoop',
      'Hoop',
      StrategyToolAssets.hoop,
      targetsGroup,
      size: 46,
    ),
    _marker(
      'target_net',
      'Net',
      StrategyToolAssets.net,
      targetsGroup,
      size: 52,
    ),
    _marker(
      'target_wicket',
      'Wicket',
      StrategyToolAssets.wicket,
      targetsGroup,
      size: 42,
    ),
    _marker(
      'target_base',
      'Base',
      StrategyToolAssets.base,
      targetsGroup,
      size: 32,
    ),
    _marker(
      'target_bullseye',
      'Target',
      StrategyToolAssets.target,
      targetsGroup,
      size: 40,
    ),
    _marker(
      'target_flag',
      'Flag',
      StrategyToolAssets.flag,
      targetsGroup,
      size: 38,
    ),
    _marker(
      'training_hurdle',
      'Hurdle',
      StrategyToolAssets.hurdle,
      trainingGroup,
    ),
    _marker('training_pole', 'Pole', StrategyToolAssets.pole, trainingGroup),
    _marker(
      'training_ladder',
      'Ladder',
      StrategyToolAssets.ladder,
      trainingGroup,
    ),
    _marker(
      'training_mannequin',
      'Mannequin',
      StrategyToolAssets.mannequin,
      trainingGroup,
    ),
    _marker(
      'training_zone',
      'Zone',
      StrategyToolAssets.zone,
      trainingGroup,
      size: 52,
    ),
  ]);

  static final List<StrategyTool> universalTools = List.unmodifiable([
    ...universalMarkerTools,
  ]);

  /// Every package tool, including core actions and original SVG palettes.
  static final List<StrategyTool> all = List.unmodifiable([
    ...core,
    ...svgTools,
    ...universalTools,
  ]);

  static const _numbers = [
    StrategyToolAssets.number1,
    StrategyToolAssets.number2,
    StrategyToolAssets.number3,
    StrategyToolAssets.number4,
    StrategyToolAssets.number5,
    StrategyToolAssets.number6,
    StrategyToolAssets.number7,
    StrategyToolAssets.number8,
    StrategyToolAssets.number9,
  ];

  /// The editable color in each multicolor package SVG. Dark outlines, white
  /// lettering, highlights, and contrasting details keep their source colors.
  static const _primarySvgColors = <String, Color>{
    StrategyToolAssets.cone: Color(0xffff5e24),
    StrategyToolAssets.netUp: Color(0xffd00000),
    StrategyToolAssets.netDown: Color(0xffd00000),
    StrategyToolAssets.netRight: Color(0xffd00000),
    StrategyToolAssets.netLeft: Color(0xffd00000),
    StrategyToolAssets.miniNet: Color(0xffd00000),
    StrategyToolAssets.forward: Color(0xff247ba0),
    StrategyToolAssets.defense: Color(0xffd00000),
    StrategyToolAssets.playerHome: Color(0xff2774ae),
    StrategyToolAssets.playerAway: Color(0xffd94b4b),
    StrategyToolAssets.playerNeutral: Color(0xfff5b942),
    StrategyToolAssets.goalkeeper: Color(0xff57a773),
    StrategyToolAssets.official: Color(0xffffffff),
    StrategyToolAssets.substitute: Color(0xff2774ae),
    StrategyToolAssets.coachBoard: Color(0xff2774ae),
    StrategyToolAssets.possession: Color(0xff2774ae),
    StrategyToolAssets.roundBall: Color(0xffffffff),
    StrategyToolAssets.ovalBall: Color(0xffa85d32),
    StrategyToolAssets.smallBall: Color(0xfff5f5f0),
    StrategyToolAssets.disc: Color(0xff5fb3d9),
    StrategyToolAssets.shuttlecock: Color(0xffffffff),
    StrategyToolAssets.curlingStone: Color(0xffd94b4b),
    StrategyToolAssets.bat: Color(0xffd8a35d),
    StrategyToolAssets.racket: Color(0xffffffff),
    StrategyToolAssets.broom: Color(0xfff5b942),
    StrategyToolAssets.goal: Color(0xff17324d),
    StrategyToolAssets.hoop: Color(0xffd94b4b),
    StrategyToolAssets.net: Color(0xff2774ae),
    StrategyToolAssets.wicket: Color(0xff17324d),
    StrategyToolAssets.base: Color(0xffffffff),
    StrategyToolAssets.target: Color(0xffd94b4b),
    StrategyToolAssets.flag: Color(0xfff5b942),
    StrategyToolAssets.hurdle: Color(0xfff5b942),
    StrategyToolAssets.pole: Color(0xffd94b4b),
    StrategyToolAssets.ladder: Color(0xff17324d),
    StrategyToolAssets.mannequin: Color(0xfff5b942),
    StrategyToolAssets.zone: Color(0xff5fb3d9),
  };

  static List<StrategyTool> _playerPalette(
    String prefix,
    StrategyToolGroup group,
  ) =>
      [
        _svg('${prefix}_forward', 'Forward', StrategyToolAssets.forward, group),
        _svg('${prefix}_defense', 'Defense', StrategyToolAssets.defense, group),
        _svg('${prefix}_opponent', 'Opponent', StrategyToolAssets.opponent,
            group),
        _svg(
          '${prefix}_type_1',
          'Player type 1',
          StrategyToolAssets.playerType1,
          group,
        ),
        _svg(
          '${prefix}_type_2',
          'Player type 2',
          StrategyToolAssets.playerType2,
          group,
        ),
        _svg(
          '${prefix}_type_x',
          'Player type X',
          StrategyToolAssets.playerTypeX,
          group,
        ),
      ];

  static StrategyTool _svg(
    String id,
    String label,
    String asset,
    StrategyToolGroup group, {
    double size = 40,
  }) =>
      StrategyTool(
        id: id,
        label: label,
        kind: StrategyToolKind.marker,
        group: group,
        markerSize: size,
        svgAssetPath: asset,
        svgAssetPackage: StrategyToolAssets.packageName,
        primarySvgColor: _primarySvgColors[asset] ?? Colors.black,
      );

  static StrategyTool _marker(
    String id,
    String label,
    String asset,
    StrategyToolGroup group, {
    double size = 40,
  }) =>
      StrategyTool(
        id: id,
        label: label,
        kind: StrategyToolKind.marker,
        group: group,
        markerSize: size,
        svgAssetPath: asset,
        svgAssetPackage: StrategyToolAssets.packageName,
        primarySvgColor: _primarySvgColors[asset] ?? Colors.black,
      );

  /// Former duplicate IDs mapped to the single canonical tool that implements
  /// the same behavior or places the same artwork.
  static const Map<String, String> aliases = {
    'action_move': 'freehand_arrow',
    'action_pass': 'dashed_arrow',
    'action_dribble': 'wave',
    'action_shot': 'arrow',
    'action_screen': 'stop_arrow',
    'action_press': 'freehand_dashed_arrow',
    'action_rotate': 'double_arrow',
    'action_carry': 'freehand_arrow',
    'action_serve': 'arrow',
    'action_return': 'dashed_arrow',
    'action_kick': 'freehand_arrow',
    'action_sweep': 'wave',
    'forward_forward': 'player_forward',
    'forward_defense': 'player_defense',
    'forward_opponent': 'player_opponent',
    'forward_type_1': 'player_type_1',
    'forward_type_2': 'player_type_2',
    'forward_type_x': 'player_type_x',
    'defense_forward': 'player_forward',
    'defense_defense': 'player_defense',
    'defense_opponent': 'player_opponent',
    'defense_type_1': 'player_type_1',
    'defense_type_2': 'player_type_2',
    'defense_type_x': 'player_type_x',
    'object_puck': 'puck',
    'object_stick': 'equipment_stick',
    'training_cone': 'equipment_cone',
    'position_goalie': 'role_goalkeeper',
    'position_coach': 'role_coach',
  };

  static String canonicalIdFor(String id) => aliases[id] ?? id;

  static StrategyTool tool(StrategyToolKind kind) {
    return core.firstWhere((item) => item.kind == kind);
  }

  static StrategyTool toolById(String id) {
    final canonicalId = canonicalIdFor(id);
    return all.firstWhere((item) => item.id == canonicalId);
  }

  /// Selects the core tool for each requested editing behavior.
  static List<StrategyTool> select(Iterable<StrategyToolKind> kinds) {
    final selected = kinds.toSet();
    return [
      for (final tool in core)
        if (selected.contains(tool.kind)) tool,
    ];
  }

  /// Selects individual core or SVG tools by their stable catalog IDs.
  static List<StrategyTool> selectByIds(Iterable<String> ids) {
    final selected = ids.map(canonicalIdFor).toSet();
    final available = all.map((tool) => tool.id).toSet();
    final unknown = selected.difference(available);
    if (unknown.isNotEmpty) {
      throw ArgumentError.value(
        unknown.toList(growable: false),
        'ids',
        'Unknown strategy tool IDs.',
      );
    }
    return [
      for (final tool in all)
        if (selected.contains(tool.id)) tool,
    ];
  }
}
