# Changelog

Written in the style described in [docs/changelog-style.md](docs/changelog-style.md):
what changed for the player, with the reasoning left in the commit history.

## [0.2.0] - 2026-09-30

### Added

- A `TM/HM NAMES` option, off by default. On, the TM/HM pocket shows the move
  beside each machine, as `TM01 MEGA PUNCH`. Long names are cut to fit, and
  the highlighted row scrolls to show the rest.

## [0.1.0] - 2026-08-31

### Added

- The bag as four pockets -- ITEMS, BALLS, KEY ITEMS, TM/HM. Both the START
  menu bag and the battle bag go through it.
- Left and Right page between pockets from anywhere in the list, and the bag
  reopens on whichever pocket you had open last.
- A `BAG SLOTS` option: 20 by default, the vanilla limit, or 999.

### Changed

- SELECT still picks an item up and places it the way vanilla's bag does, now
  confined to the pocket you are in.

### Known limitations

- Raising the slot limit above 20 makes `.sav` export lossy. The Game Boy bag
  format holds 20 entries, so a converted save keeps the first 20 items in
  acquisition order and drops the rest. At the default setting this cannot
  happen.
- The option controls how many distinct items fit, not how many of each. The 99
  per-stack cap is the engine's and is unchanged.
- 999 is effectively unlimited rather than literal: vanilla has 144 non-badge
  items, so that is the real ceiling until a content mod adds more.
