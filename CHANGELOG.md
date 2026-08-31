# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.1.0] - 2026-08-31

### Added

- The bag as four pockets -- ITEMS, BALLS, KEY ITEMS, TM/HM -- claiming the
  BagMenu screen id, so the START menu bag and the battle bag both go
  through it.
- Left and Right page between pockets from anywhere in the list. The bag
  reopens on whichever pocket was open last.
- `BAG SLOTS` option, 20 by default (the vanilla limit) or 999.

### Changed

- SELECT still picks an item up and places it, the way vanilla's bag does,
  now confined to the pocket you are in.

### Known limitations

- Raising the slot limit above 20 makes `.sav` export lossy: the Game Boy
  bag format holds 20 entries, so converting a save keeps the first 20
  items in acquisition order and drops the rest. At the default setting
  this cannot happen.
- The 99 per-stack cap is the engine's and is unchanged. The option
  controls how many distinct items fit, not how many of each.
- 999 is effectively unlimited rather than literal: vanilla has 144
  non-badge items, so that is the real ceiling until a content mod adds
  more.
