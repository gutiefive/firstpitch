# Six-date progression audit

Run `godot --headless --path . --script tests/test_season_polish.gd` with isolated XDG data/config/cache roots. It writes `/tmp/firstpitch-season-polish.csv`. The committed CSV records the audited route.

This is a deterministic integration audit, not a human playthrough. Prep surfaces and service completions are explicit ideal-work fixtures. Actual walking, interaction guards and once-only settlement have separate gameplay tests. The audit checks the full sequence, season rollover/review, purchases, all event types, money reconciliation and exact career-v4 reload (the original recorded route was verified under v3).

The tools-first route buys the 200-credit nozzle after date one, the 450-credit snack shack after date three, and 600-credit bleachers after date four. No side contracts or injected money are used. It ends with 1,967 credits, 189 supporters and 240 seats. The 200-supporter grandstand threshold gives season two a remaining goal despite sufficient cash.

An initial expectation that this route could also buy concessions after date two failed: only 428 credits remained. The route now makes that tools-versus-amenities tradeoff explicit; prices and payouts were not changed to force a purchase. Skipping the opening nozzle would allow earlier amenities. Lower finish quality, missed manager requests or incomplete service will delay this ideal route.

Both hot and rain prep recur over six dates; all three visit event types appear when concessions are available. Full human route timing, event waiting time, job satisfaction and long-session crowd performance still need hands-on playtesting. The listed 15/20-minute prep values are configured deadlines, not measured completion times.
