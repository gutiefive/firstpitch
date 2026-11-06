# Career v4

The `FPCREW01` envelope still contains SHA-256 plus a resource-free Variant payload. Manual field and autosave formats remain v3. The career envelope ceiling is 16 MiB so the additional frozen state can preserve the full existing 2,000-attempt capacity.

V4 stores authoritative wallet/lifetime earnings, completed count, personal bests and owned upgrades. Its club snapshot stores supporters, capacity, games, income/spending, buildings, hosted receipts, service reports, pending prep and hosted facilities. Additional state records ordered hosted IDs, pending IDs, frozen manager-target outcomes, service inputs, actual paid tool/project costs, and compact season closing snapshots with their original objectives/tools. Attempts retain their original result and actual paid wage.

Claims, construction, hosting and service settlement update a copied state using current rules, append the appropriate historical entry, and publish it only after a checked redundant save succeeds. Failed writes leave memory and funds unchanged. Paid attempt IDs and hosted/serviced IDs enforce once-only settlement, including autosave resume. History, recap and season UI read frozen pay/receipts/targets; they do not recompute old economics.

Loading v4 checks structure, known identifiers, scalar ranges, duplicate IDs and structural consistency between state and logs. It does not rerun scoring, reward formulas, prices, supporter prerequisites or past service evaluation. SHA-256 detects corruption; it is not an anti-cheat signature.

Legacy v1–v3 load through frozen `LegacyCareerRules`, `LegacyShiftSession` and `LegacyParkSatisfaction`. `ClubProgress.legacy_replay()` validates the event stream once while collecting season milestones. Conversion reuses that validated context, writes v4, and preserves the original bytes as `<career basename>.v3.bak`. If that name already holds different data, a distinct timestamped legacy backup is used. A failed original-backup or migration write blocks changes and keeps the existing files. The rolling `.tmp`/`.bak` recovery path is shared with other saves; recovery candidates still require complete validation.

The frozen legacy classes deliberately duplicate the pre-v4 formulas and catalogs. Change current rules for new work; keep legacy rules unchanged so old files remain importable without repricing. Version changes should migrate missing state explicitly rather than deriving money from historical events.

`tools/audit_club_balance.gd` now exercises the actual v4 transaction methods with a validation-preserving, in-memory commit adapter. It writes no careers. `tests/test_career_v4.gd` compares immutable pre-v4 fixtures against their exact converted state and exercises rule-independent reload/commit, structural rejection and duplicate/resumed payments.

Real Windows interrupted replacement and physical power-loss behavior remain unverified. Flushed redundant copies protect against the documented destination-delete gap; they do not establish hardware-level durability guarantees.
