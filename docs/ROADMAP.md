# Roadmap

- **M1 — Stadium and character: implemented prototype.** Procedural recognizable park, consistent meter scale, colliders, daylight, player locomotion and camera. First visual pass complete: covered stands, field-facing dugouts connected to a backstop and foul-side perimeter, detailed workshop, community signs, infield lawn, textured dirt, and surrounding trees. Properly shaped home plate, sized batter/coaching boxes and on-deck circles now complete the static field references. Next polish: authored assets and a final Windows lighting pass.
- **M2 — Drivable mower: implemented prototype.** Enter/exit, protected dismounts, arcade driving, reverse, braking, animated wheels and steering. First visual pass adds treaded wheels, fenders, grille, and a visible seated groundskeeper. A positional engine loop now responds to driving speed. Next polish: handling and audio balance on Windows.
- **M3 — Grass mowing: implemented prototype.** Spatial cut mask, swept deck, direction shading, persistent session tracks and accurate unique-cell progress. First visual pass adds mask-aware instanced grass tufts. Next polish: GPU performance validation and mowing polish.
- **M4 — Core field tools: implemented prototypes.** Tool-bay swapping between mower deck and tow-behind drag, lift/lower controls, visible rough-to-smooth dirt, unique-cell preparation score, protected grass/bases/mound/plate areas, and independent HUD objectives. A separate pushable chalk marker adds a paint gate, persistent real-position strokes, dashed foul-line guides, left/right unique-section coverage, and independent task selection. A hose station adds on-foot spray aiming, timed moisture accumulation, dark wet dirt, protected areas, reach/obstruction checks, and a fourth independent task. A fifth task uses a hand tamper to repair six worn mound patches through eighteen timed impacts, with a walkable mound slope and persistent patch state. Advanced clay handling, deformable terrain, and physically articulated tools remain future refinements.
- **M5 — Shifts, objectives, scoring: initial prototype implemented.** Free practice, fresh training and seeded game-day starts, 15-minute training and 30-minute full-park profiles, paused planning board, live five-job checklist, proportional repair coverage with finish-quality scoring, and frozen completion/timeout/early-end results. Manual single-slot persistence now restores all task visuals, active clocks, and frozen results, with parked equipment on load. Game wear, puddles, wet-drag ruts, stripe bonuses and quality tips are implemented. Next: human timing balance and expanded result history.
- **M6 — Career progression: first playable slice implemented.** Paid partial/completed shifts, lifetime-earnings crew ranks, personal bests, recent results, a persistent wallet and four permanent upgrades (wider mower deck, high-flow hose nozzle, wider drag mat and chalk guide wheel). Saved attempts cannot pay twice. Four focused repeatable contracts now provide mowing, mound-repair and rank-unlocked infield work and Crew Lead doubleheader turnaround, with distinct deadlines and pay. The Owls club story now connects priority prep, hosted home dates, supporters, gate income, stadium projects and tool purchases. Next: human economy/story pacing, richer characters/match presentation and additional park projects.

- **Sound feedback: initial pass implemented.** Original synthesized engine, tool, footstep, impact and result effects, quiet wind/bird ambience, separate audio buses, and persisted master/effects/ambience/mute preferences. Next: natural recordings, occlusion, material-specific footsteps, and desktop listening tests.

- **Architecture — Shared FieldLayout: Part 1 implemented.** Cedar Grove dimensions, derived 90 ft bases, canonical drawn edges, mask bounds, surface heights and equipment locations live in one exported resource assigned before system construction. A narrow v1-to-v2 field migration preserves prior work across corrected boundary cells. Part 2 now adds seeded wear, repair baselines, quality and v3 saves with neutral v1/v2 migration. Part 3 now adds a seven-step first-run guide, separate autosave/paused resume and controller bindings, device-aware prompts and menu focus. Physical pad and Windows validation remain outstanding.

- **Onboarding and continuity — Part 3 implemented.** Seven real-action guide steps with checkpoints/skip/replay, InputMap-generated Controls and persisted pad sensitivity. Separate atomic autosave on start/finish/board/quit and dirty 60-second intervals, paused recovery choice, corrupt-file quarantine and once-only resumed payouts. Synthetic pad events cover movement, look, tools and menus; next: real hardware, Windows and human usability tests.

- **Field inspection: implemented.** Toggle a temporary view for unfinished grass/dirt, exact missing chalk sections, wet-drag ruts, puddles and unfinished mound patches. Keyboard/pad job cycling follows paid goals; tool selection still selects its job. Exact water-credit flags drive highlighting. View-only state clears on start/load/reset and never changes score or saves. Next: human readability/accessibility testing and hardware performance.

- **Equipment progression: expanded.** Field Hand unlocks a 400-credit 3.5 m drag mat and 350-credit chalk guide wheel. Visible gear changes affect actual work: wider preparation and limited heading assistance near foul guides. Rank checks are enforced in both purchase and ledger validation; old profiles retain their prior payouts. Next: human price/assistance balance and more equipment variety.

- **Minor-league club story: first playable loop implemented.** Accept the Cedar Grove Owls groundskeeper job, use weaker unowned starter tools, complete home-game priority prep and explicitly host the date. Five manager-led chapters connect supporters, capacity-limited crowds, net ticket/food income and reinvestment. Bleachers, a snack shack and covered stands grow the park from 120 to 480 seats. Shared budget and once-only settlements persist in a replayable career-v2 event ledger; old careers retain exact payouts and equipment. Home games currently use summaries, with volunteer routine field completion and static batched supporters. Next: human progression balance, richer story events and game-day presentation.

- Home-season loop: six named fixtures, rotating optional score/time targets, durable season review and rollover with club investments retained. Baseball outcomes and target cash bonuses remain outside this feature.

- Stadium amenities: second grill concession, electronic scoreboard and later video board, with physical additions, purchase prerequisites and stacked ticket/food/fan benefits.

- Watering usability fix: visible free-aim spray, obstacle-clipped stream, live tutorial moisture/blocker feedback, and explicit chalk-cart-to-hose handoff.

- Four-pass visual revision complete: character/equipment silhouettes, restrained material palette, lighting/atmosphere and architectural detail. See `ART_REVIEW.md` for before/after views and remaining hardware verification.

- Close-up visual refinement: curved seating and stand rails, detailed concession displays, varied crowd batches, articulated walking legs and equipment finishing details.

- Park surroundings pass: ticket-plaza entrance, concourse paving and furnishings, native-style planting and a distant rolling landscape; reviewed from pedestrian and player cameras.

- Field surface art pass: rounded mound shoulder, irregular repair overlays, shorter bent turf tufts, smooth visual cut boundaries and distance-faded chalk guides.

- Game-day loop expansion: rotating hot/rain/doubleheader prep profiles, once-only manager cash priorities and consolidated postgame recaps with next-investment progress. Existing home-game payouts remain unchanged.

- Progression/payoff pass: eased starter hose/drag, reproducible purchase-route balance audit, skippable opening-gates presentation, crowd/concession audio and six-date ownership reviews with frozen next-season goals.

- Modern UI pass: persistent destination rail; shared navy/mint theme and original icons; Matchday/Stadium/Results/Season Clubhouse sections; card-based equipment and contracts; clearer live HUD; native mouse/controller navigation and responsive 1024/1280/1600-width checks.

- Living matchday first slice: moving representative supporters, public concourse and concession routes, animated staff, upgrade identity signs and warm counter lights, 47-second skippable arrivals/game/story sequence, nine-inning staged baseball action, live upgraded scoreboards, and progress-sensitive Mara/Eli/Leni story lines.

- Matchday viewing UI: pause/play, double speed, chapter skipping, clear chapter/time badge, safe explicit Results action, guarded latest-matchday replay, matching final score in Results, and a speaker-filtered Town tab.

- Playable live matchday: on-foot visits share time with broadcast; representative fans reserve seats, visit concessions, react and depart; optional held spill cleanup, breadcrumb-followed regular escort and carried concession delivery; service HUD and safe visit teardown.

- Fan-experience loop: scored satisfaction reviews, once-only modest credit/supporter rewards in career v3, immutable visit facility snapshots, rotating litter/rush/directions events, queue relief, articulated supporter knees/reactions, PA captions/chimes, and evening-fixture skies/floodlights with safe restoration.

- Job feel and club identity: visible sweeping and dedicated crate-carry poses, Owls and opponent uniforms, crowd clothing variations and recurring-character milestone lines. A reproducible six-date integration audit records legal purchases, event coverage and reconciled budgets; human timing and balance remain unverified. See `audits/SIX_DATE_POLISH.md` and `VERIFICATION.md` for results and the unresolved renderer shutdown texture leaks.

- Foul-line expansion layout: retain the starter home-plate sections; add bleachers on both lines, then extend covered wings toward the outfield. First-/third-base concessions share transformed locations with fan routes, staff, service jobs, audio and presentation cameras. Public promenades preserve workshop access; live field exclusion follows the sidelines. Existing career purchases and finances remain compatible.
