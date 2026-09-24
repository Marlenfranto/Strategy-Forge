# Sports strategy-board tool audit

Research updated 24 September 2026.

## Scope and method

There is no authoritative worldwide registry of sports that use strategy
boards. This audit therefore combines:

1. sports explicitly supported by current multi-sport tactics-board products;
2. coaching and play-diagram evidence from governing bodies;
3. closely related official variants that use the same playing surface and
   notation grammar.

The resulting host-side coverage contains 60 sport IDs. Layouts remain owned by
the embedding app. The package supplies the reusable notation tools.

## Evidence

- [CourtDraw](https://courtdraw.app/) lists 38 strategy-board sports and
  variants, including association football, basketball, racket sports,
  hockey variants, rugby codes, Gaelic games, Australian rules, netball,
  korfball, floorball, fistball, beach variants, and water polo.
- [Coach Board](https://www.coachboard.app/) documents player and equipment
  placement across 16 sports.
- [Sport Strats](https://sportstrats.com/) adds baseball, cricket, and ultimate
  to its multi-sport tactics-board coverage.
- [TATIBO](https://tatibo.com/) independently documents tactics-board use
  across 15 field, court, rink, and pool sports.
- The [FIBA coaches manual](https://assets.fiba.basketball/image/upload/documents-corporate-wabc-coaching-manual-level-3-eng.pdf)
  uses numbered players, cuts, passes, screens, dribbles, and shots in court
  diagrams.
- The [FIVB coaches manual](https://www.fivb.com/wp-content/uploads/2024/03/FIVB_Coach_Manual_EN.pdf)
  diagrams rotations, serve reception, setter movement, attacks, and blocks.
- [USA Football playbooks](https://assets.usafootball.com/documents/fdpb/FDPB-OFFENSE-PLAYBOOK_final.pdf)
  use player roles, routes, handoffs, passes, fakes, and blocks.
- [FIFA technical analysis](https://inside.fifa.com/tournaments/mens/mensolympic/tokyo2020/news/analysing-the-olympics-attacking-success-stories)
  describes positional switches, passes, runs, and pressure lines.
- [World Rugby coaching](https://passport.world.rugby/media/uc4cr1ol/t1-rugby-pe-scheme-of-work-example-final.pdf)
  diagrams running lines, passes, support, defensive alignment, and scoring
  zones.
- [USA Lacrosse](https://www.usalacrosse.com/game/field-diagrams) publishes
  field diagrams, while its coaching material uses drill and game diagrams.
- [WFDF](https://wfdf.sport/2024/09/wfdf-partnering-with-flik-for-coach-training-resources/)
  identifies diagrams and strategy resources as part of official Ultimate
  coach training.
- [World Curling](https://worldcurling.org/wp-content/uploads/2020/11/Technical-Officials-Manual.pdf)
  documents stone position, delivery, curl, sweeping, and shot selection.
- The [American Baseball Coaches Association](https://www.abca.org/Videos/ABCA/Education/Charts-and-Documents/Baseball-Charts-Documents.aspx)
  publishes field diagrams, defensive positioning, base running, and spray
  charts.
- The [International Floorball Federation](https://www.floorball.org/materiaalit/teamtactics_www.pdf)
  publishes team-tactics material illustrated with boards, player markers,
  arrows, and circles.

## Shared tool grammar

| Tool family | Package tools | Strategy uses |
| --- | --- | --- |
| Team and roles | home, away, neutral, goalkeeper, official, substitute, coach, possession | formations, matchups, special roles, substitutions |
| Action paths | freehand arrow, dashed arrow, wave, arrow, stop arrow, freehand dashed arrow, two-way arrow | runs, routes, ball/object movement, blocks, transitions, restarts |
| Objects | round ball, oval ball, small ball, puck, disc, shuttlecock, curling stone, bat, racket, stick, broom | possession and equipment placement |
| Targets | goal, hoop, net, wicket, base, bullseye, flag | scoring targets, destinations, accuracy drills |
| Training | cone, hurdle, pole, ladder, mannequin, zone | practice setup, channels, constraints, coverage |
| Annotation | text, numbers, freehand, line styles, rectangles, ellipses | labels, sequence, zones, emphasis, measurements |

## Covered sports and recommended profiles

| Profile | Sports and variants | Additional essential tools |
| --- | --- | --- |
| Invasion, round ball | association football, futsal, beach and small-sided football, basketball and 3x3, netball, korfball, handball and beach handball, goalball, quadball | round ball, goal/hoop, goalkeeper, dribble, shot, screen, carry, kick |
| Gridiron | American, flag, and Canadian football | oval ball, route, pass, carry, kick, screen/block, flags |
| Rugby and large-field codes | rugby union, league, sevens and touch, Australian rules, Gaelic football, polo | oval ball, run, pass, carry, kick, support, posts/flags |
| Stick and ball | field and indoor hockey, rink hockey, floorball, bandy, hurling, camogie, shinty, field/box/sixes lacrosse | small ball, stick, goalkeeper, carry/dribble, pass, shot, goal |
| Stick and puck | ice and roller hockey | puck, stick, goalkeeper, skate, pass, carry, shot, net |
| Net court | volleyball, beach and sitting volleyball, fistball, sepak takraw, padbol | ball, net, serve, receive, rotation, attack, block |
| Racket court | tennis, doubles, padel, pickleball, squash, racquetball, table tennis, beach tennis, pelota mano | racket, small ball, net/target, serve, return, shot |
| Shuttle court | badminton | racket, shuttlecock, net, serve, return, shot |
| Diamond | baseball and softball | small ball, bat, bases, throws, running paths, defensive zones |
| Cricket | cricket | small ball, bat, wicket, running paths, fielding zones, shot/throw |
| Pool | water polo | round ball, goal, goalkeeper, pass, carry, shot, pressure |
| Flying disc | ultimate | disc, throw/pass, cuts, carries/pivots, end-zone flags |
| Target ice | curling | stones, broom, target, delivery, curl, sweep/brush |
| Territory/tag | kabaddi, kho kho, roller derby | team markers, chase/carry paths, pressure, blocks, zones |

## Implementation boundary

StrategyToolCatalog contains the complete tool vocabulary and default assets.
DemoStrategyToolKits maps each researched sport ID to a recommended subset.
The demo does not expose a sport selector: developers choose a kit in code and
pass their own layout to the plugin.

Each visible catalog entry has a distinct drawing behavior or marker image.
Earlier semantic action names and repeated marker IDs are compatibility aliases
that resolve to one canonical visible tool.
