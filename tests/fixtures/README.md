# Pre-refactor field-save fixture

`cedar_grove_v1.dat.gz` is a gzip-compressed, checksummed v1 field slot generated
by the unmodified game at commit `4ff75db`, before introducing FieldLayout.
It contains only synthetic test work and an isolated test attempt, not player data.

The original layout signature is
`4b93508a852f996a404526525630f7fcb6b2271cd10d8adedd4c9f2364fd70b5`.
Original totals: grass 61,444; dirt/moisture 12,618; chalk 808; mound 18.
Recorded work: 284 cut cells, 84 prepared cells, 256 wet cells, 13 chalk sections,
one accepted mound impact, plus an off-guide chalk stroke. It is an active
training attempt with 123.4 seconds elapsed.

The immutable `resources/layouts/cedar_grove_v1_masks.res` stores validity arrays
captured from that same unmodified build, compressed as a native Godot Resource.
The migration uses those original arrays to reject work outside the v1 masks.
The resource test decompresses the original slot to an isolated `user://` path,
loads it through FieldSave, and checks preservation and v2 round-tripping.
Do not regenerate these fixtures from the refactored implementation.
