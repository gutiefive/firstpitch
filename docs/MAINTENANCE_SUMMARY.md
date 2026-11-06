# Ordered maintenance summary

Branch `maintenance/save-safety-career-v4` contains eight ordered commits, one per requested task, based on `5fdbacf`. First-person work is a subsequent feature on `feature/first-person`, which includes those maintenance commits.

Every stage launches every top-level test script with fresh isolated XDG roots. Counts below are suites, not assertions. The same sixteen graphical capture scripts cannot complete headlessly and remain baseline failures/unverified; six also report pre-existing headless UI assertions. No assertions were weakened to hide these failures. Details and the names are in `VERIFICATION.md`.

| Task / commit | Changes and primary files | Before → after | Focused checks / judgment |
| --- | --- | --- | --- |
| 1 · `ef81cd0` | Empty `docs/.gdignore`; remove 126 `docs/**/*.import`; verification notes | 42/58 → 42/58 | No runtime/test `res://docs` dependencies; GitHub images remain intact. |
| 2 · `fc7a95a` | `save_recovery.gd`, `career_profile.gd`, `field_save.gd`, `crew_autosave.gd`, `shift_director.gd`; recovery/corruption tests | 42/58 → 43/59 | 17 recovery checks. Main → tmp → bak full validation, redundant flushed backup, visible notices, all-corrupt refusal and autosave quarantine. Windows behavior is not directly tested. |
| 3 · `b070815` | Name-only changes across 20 production scripts, including geometry/tools/UI/game placards | 43/59 → 43/59 | Engine debug diagnostics clear for shadowing/built-in/unused variable/parameter categories. Existing integer-division notices remain. |
| 4 · `5c7b7f9` | All 117 `.gd` files in `scripts/`, `tests/`, `tools/` | 43/59 → 43/59 | Formatting only; tabs, readable dictionaries, byte-identical wrapped string contents; gdformat 4.5.0 safety checks enabled. |
| 5 · `3cdb3c9` | `crew_job.gd`, `hud_text.gd`, `game.gd`, inspection/tutorial/session/progress callers and HUD reference fixtures | 43/59 → 44/60 | 99 checks: 48 exact keyboard/pad mode/prompt pairs captured before extraction; cached bindings and unchanged indices 0–4. |
| 6 · `8563cc1` | `field_save.gd`, `save_recovery.gd`, `crew_autosave.gd`, `profile_autosave.gd`, performance test/raw samples | 44/60 → 45/61 | 8 checks; measured 218.122 → 14.638 ms. Trust live capture and checksum-identical prior bytes only on write; strict manual/load/recovery checks retained. Synchronous writes avoid thread/quit races. |
| 7 · `b857e2b` | `career_state.gd`, career/club/ownership/schedule/recap/history callers, frozen `legacy_*` rules, migration fixtures/tests, balance audit/docs | 45/61 → 46/62 | 76 checks, exact v1–v3 migration, one legacy replay, frozen v4 economics, once-only resume. Career size ceiling is 16 MiB to preserve all 2,000 attempts; a valid old career expands to 4,493,248 payload bytes. |
| 8 · `b72bd01` | `playtest_log.gd`, `shift_director.gd`, logging test, README/verification | 46/62 → 47/63 | 10 checks. Opt-in `-- --playtest-log`, no networking/UI expansion. Unknown earlier goal times stay blank; payout reflects settlement at finish. |

No maintenance task changes gameplay balance. Career v4 cannot be read by older builds; original legacy bytes and rolling recovery copies are retained. Manual field/autosave formats remain v3, including old fixture migration. Actual Windows replacement/interruption, power-loss durability, antivirus/file locking, Forward+ GPUs, physical controllers and human full-season pacing remain unverified. Existing teardown warnings and graphical-headless failures are disclosed rather than counted as passes.
