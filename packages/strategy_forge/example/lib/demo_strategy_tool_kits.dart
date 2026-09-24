/// Example host-side tool selections for common strategy-board sports.
///
/// The reusable package remains unaware of sport selection and layouts. A host
/// may pass one of these ID lists to DemoConfigurations.sample, replace it, or
/// define a narrower list for a specific strategy view.
class DemoStrategyToolKits {
  DemoStrategyToolKits._();

  static const common = [
    'freehand',
    'text',
    'rectangle',
    'ellipse',
    'freehand_arrow',
    'dashed_arrow',
    'freehand_dashed_arrow',
    'double_arrow',
    'team_home',
    'team_away',
    'team_neutral',
    'role_official',
    'role_substitute',
    'role_coach',
    'role_possession',
    'equipment_cone',
    'training_hurdle',
    'training_pole',
    'training_ladder',
    'training_mannequin',
    'training_zone',
  ];

  static const invasionRoundBall = [
    ...common,
    'wave',
    'arrow',
    'stop_arrow',
    'role_goalkeeper',
    'object_round_ball',
    'target_goal',
  ];
  static const gridiron = [
    ...common,
    'stop_arrow',
    'object_oval_ball',
    'target_flag',
    'target_goal',
  ];
  static const rugby = [
    ...common,
    'stop_arrow',
    'object_oval_ball',
    'target_goal',
    'target_flag',
  ];
  static const stickAndBall = [
    ...common,
    'wave',
    'arrow',
    'role_goalkeeper',
    'object_small_ball',
    'equipment_stick',
    'target_goal',
  ];
  static const stickAndPuck = [
    ...common,
    'wave',
    'arrow',
    'role_goalkeeper',
    'puck',
    'equipment_stick',
    'target_goal',
  ];
  static const netCourt = [
    ...common,
    'arrow',
    'stop_arrow',
    'object_round_ball',
    'target_net',
  ];
  static const racketCourt = [
    ...common,
    'arrow',
    'object_small_ball',
    'object_racket',
    'target_net',
    'target_bullseye',
  ];
  static const shuttleCourt = [...racketCourt, 'object_shuttlecock'];
  static const diamond = [
    ...common,
    'arrow',
    'object_small_ball',
    'object_bat',
    'target_base',
    'target_bullseye',
  ];
  static const cricket = [
    ...common,
    'arrow',
    'object_small_ball',
    'object_bat',
    'target_wicket',
    'target_bullseye',
  ];
  static const water = [...invasionRoundBall, 'target_bullseye'];
  static const disc = [...common, 'arrow', 'object_disc', 'target_flag'];
  static const curling = [
    ...common,
    'arrow',
    'wave',
    'object_curling_stone',
    'object_broom',
    'target_bullseye',
  ];
  static const territory = [...common, 'stop_arrow', 'object_round_ball'];

  /// Coverage audited from international coaching resources and current
  /// multi-sport strategy-board products. Variants share the same tool grammar.
  static const Map<String, List<String>> bySport = {
    'association_football': invasionRoundBall,
    'futsal': invasionRoundBall,
    'beach_soccer': invasionRoundBall,
    'small_sided_football': invasionRoundBall,
    'basketball': invasionRoundBall,
    'basketball_3x3': invasionRoundBall,
    'netball': invasionRoundBall,
    'korfball': invasionRoundBall,
    'team_handball': invasionRoundBall,
    'beach_handball': invasionRoundBall,
    'water_polo': water,
    'rugby_union': rugby,
    'rugby_league': rugby,
    'rugby_sevens': rugby,
    'touch_rugby': rugby,
    'american_football': gridiron,
    'flag_football': gridiron,
    'canadian_football': gridiron,
    'australian_rules_football': rugby,
    'gaelic_football': rugby,
    'hurling': stickAndBall,
    'camogie': stickAndBall,
    'shinty': stickAndBall,
    'field_hockey': stickAndBall,
    'indoor_hockey': stickAndBall,
    'ice_hockey': stickAndPuck,
    'roller_hockey': stickAndPuck,
    'rink_hockey': stickAndBall,
    'floorball': stickAndBall,
    'bandy': stickAndBall,
    'field_lacrosse': stickAndBall,
    'box_lacrosse': stickAndBall,
    'lacrosse_sixes': stickAndBall,
    'volleyball': netCourt,
    'beach_volleyball': netCourt,
    'sitting_volleyball': netCourt,
    'fistball': netCourt,
    'sepak_takraw': netCourt,
    'tennis': racketCourt,
    'tennis_doubles': racketCourt,
    'padel': racketCourt,
    'pickleball': racketCourt,
    'squash': racketCourt,
    'racquetball': racketCourt,
    'table_tennis': racketCourt,
    'beach_tennis': racketCourt,
    'badminton': shuttleCourt,
    'pelota_mano': racketCourt,
    'padbol': netCourt,
    'baseball': diamond,
    'softball': diamond,
    'cricket': cricket,
    'ultimate': disc,
    'curling': curling,
    'polo': rugby,
    'kabaddi': territory,
    'kho_kho': territory,
    'goalball': invasionRoundBall,
    'quadball': invasionRoundBall,
    'roller_derby': territory,
  };

  static List<String> toolIdsFor(String sportId) =>
      bySport[sportId] ??
      (throw ArgumentError.value(sportId, 'sportId', 'Unknown sport kit.'));
}
