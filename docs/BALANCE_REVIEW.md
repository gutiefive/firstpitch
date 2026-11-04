# Progression and starter-tool balance

This pass eases starter handling while preserving all historical prices, wage rules, gate economics and manager payouts.

| Equipment | Previous starter | Revised starter | Purchased target |
| --- | ---: | ---: | ---: |
| Mower deck | 1.8 m | 1.8 m | 3.0 m |
| Drag mat | 2.2 m | 2.4 m | 3.5 m |
| Water application rate | 0.55 | 0.65 | 1.0 |

The drag sweeps about 9% more width before upgrading. Water applies about 18% faster; the bought nozzle still cuts ideal soak time by 35% relative to the revised starter. The live gameplay test qualifies an actual dry patch in roughly a second with the starter and verifies more than 20% less time with the purchased nozzle. No score targets, tool reaches, moisture target or chalk assist rules were changed.

## Progression audit

Run `godot --headless --path . --script tools/audit_club_balance.gd` with isolated XDG roots. It writes no career files and uses valid frozen ShiftSession results, normal game-day rotation, actual wage/forecast formulas, fan prerequisites, rank locks and project dependencies. Each route buys at most one upgrade per date and saves toward its next priority. Dates finish at 1,000 seconds, capped just below a profile's limit, so doubleheader priorities are missed. This is a conservative timing assumption, not a routed human playthrough.

| Route | First nozzle | First seating | Snack shack | Covered stand | All six stadium projects |
| --- | ---: | ---: | ---: | ---: | ---: |
| Clean work, tools first | Date 1 | Date 4 | Date 5 | Date 8 | Date 13 |
| Clean work, seats first | Date 5 | Date 3 | Date 4 | Date 8 | Date 13 |
| Clean work, nozzle then seats | Date 1 | Date 3 | Date 4 | Date 8 | Date 13 |
| Rough finish, tools first | Date 1 | Date 4 | Date 5 | Date 8 | Date 13 |
| Rough finish, seats first | Date 5 | Date 3 | Date 4 | Date 8 | Date 13 |
| Rough finish, nozzle then seats | Date 1 | Date 3 | Date 5 | Date 8 | Date 13 |

Clean work uses neutral finish penalties (100 score). Rough work uses 0.75 dirt/chalk/water job quality, producing approximately 85–87.5 scores according to the requested jobs and missing manager quality targets. Rough routes retain less cash even where modeled purchase dates coincide. The rank calculation uses lifetime wages plus net club income, independently of spending.


Buying both early tool upgrades delays modeled first seating from date 3 to date 4. Buying only the nozzle can still leave enough for seats on date 3; rough work then delays the snack shack from date 4 to date 5. They do not prove human aiming, travel, fatigue or late-shift difficulty. Further player feedback should guide live-tool tuning; changing committed profile or project economics would require new rules/IDs to avoid repricing history.

## Season ownership goals

The sixth hosted date freezes the review and the next goal from that closing event's record/tool prefixes. Goals ask for 80 additional supporters plus the next unbuilt project, then missing tools, then four manager targets for fully equipped parks. The objective catalog/order is fixed for this rule version. The next finale evaluates the old goal against its own closing state, so buying after the deadline cannot turn a miss into a success. These are narrative milestones, with no additional currency reward.
