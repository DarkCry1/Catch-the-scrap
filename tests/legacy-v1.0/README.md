# Historical v1.0 tests

These tests describe the pre-Claude game: four platforms, selected chassis, 70 collection entries, old plaza dimensions and old box payouts. The user-supplied v1.4 place deliberately changes those contracts (six/eight platforms, 61 randomly rolled species, persistent Robotdex, rebirth). They are retained for historical reference and are not part of the current check command. Their failures against v1.4 are not treated as passing tests.

Current regression coverage is tests/progression-v14.spec.luau, tests/guardians.spec.luau, the compatible inventory/movement, upgrade and yard suites, and scripts/check-guardians.py for real server/builder/client boundaries. The older check-services.py/check-items.py/check-presentation.py helpers also target pre-v1.4 APIs and are not run by the current command.
