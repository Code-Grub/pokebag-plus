<div align="center">

<img src="images/logo.png" alt="PokeBag+" width="640"/>

**A bag overhaul for the [Pokémon Gen 1 Recompilation Project](https://github.com/bryanthaboi/pokemon-gen1-recomp-project).**

Four Gen 2 pockets paged with Left and Right · acquisition order kept · the SELECT swap still works

<p align="center">
  <a href="https://github.com/Code-Grub/pokebag-plus/releases/latest"><img src="https://img.shields.io/github/v/release/Code-Grub/pokebag-plus?style=flat&label=release&color=306230" alt="Latest release"/></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/Code-Grub/pokebag-plus?style=flat&color=306230" alt="MIT license"/></a>
  <img src="https://img.shields.io/badge/lua-L%C3%96VE-306230?style=flat" alt="Written in Lua for LOVE"/>
</p>

</div>

---

PokeBag+ splits the bag into four pockets -- ITEMS, BALLS, KEY ITEMS and
TM/HM -- paged with Left and Right, in the style the Game Boy would have
shipped. It keeps the vanilla 20 slot limit, keeps acquisition order in three
of the four pockets, and keeps SELECT working, now confined to the pocket you
are in. The TM/HM pocket is grouped and shows move names by default; both can
be turned off.

<p align="center">
  <img src="images/screen_items.png" width="480" alt="The ITEMS pocket: the pocket name centred between two paging arrows, in a window sharing its borders with the item list below"/><br/>
  <sub>The header shares its left and right borders with the bag window, and its bottom border is that window's top edge. The window on the left is the item preview.</sub>
</p>

<p align="center">
  <img src="images/screen_tmhm.png" width="480" alt="The TM/HM pocket: HMs first, then TMs, with the highlighted name scrolling and a disc icon in the preview window"/><br/>
  <sub>HMs first, then TMs by number. The highlighted name scrolls when it is wider than the list</sub>
</p>

<p align="center">
  <img src="images/screen_key.png" width="480" alt="The KEY ITEMS pocket, the longest of the four names, still clear of both arrows"/><br/>
  <sub>KEY ITEMS, the longest of the four names, still clear of both arrows</sub>
</p>

The arrows are drawn by hand rather than taken from the font. The charmap
has a filled right arrow and no left one, and a glyph beside a hand-drawn
cousin reads as mismatched, so both sides are drawn the same way.

## Try it

    cmd /c mklink /J game\mods\pokebag_plus <path to this repo>
    cd game && luajit mods/pokebag_plus/tests/pokebag_plus_test.lua
    cd game && python tools/modkit.py validate mods/pokebag_plus --base imported

## What changes

- The bag is four pockets instead of one flat list. Left and Right page
  between them from anywhere in the list, and the bag reopens on whichever
  pocket you used last.
- SELECT still picks an item up and places it, the way vanilla's bag does.
  It now works inside the pocket you are in.
- Acquisition order is untouched in ITEMS, BALLS and KEY ITEMS. The TM/HM
  pocket is grouped by default (see `GROUP TM/HM`).
- The battle bag is the same four pockets, so there is one thing to learn
  rather than two.

## What does not change

The save. Pockets are a view over the item list the game already keeps, so
this mod adds no save field and changes no format. Uninstalling it leaves
the flat vanilla bag exactly as it was.

## Options

`BAG SLOTS`, in the mod manager, is 20 by default -- the vanilla limit.
Setting it to 999 lifts the cap on how many distinct items the bag holds.
See Limits below before raising it: past 20 it makes `.sav` export lossy.

`TM/HM NAMES` is on by default: the TM/HM pocket shows `TM01 MEGA PUNCH`.
Names wider than the list are cut with a trailing dot, and the highlighted
row scrolls so you can read it in full. Off shows a machine as `TM01`, like
vanilla.

`ITEM PREVIEW` is on by default: the highlighted item's icon shows in a small
window attached to the left of the list. The icons are FireRed's, read from
your own import of that ROM, so **the window only appears once you have
imported FireRed**; nothing is bundled with the mod. Without that import, or
with the option off, the bag looks exactly as it did before. TMs show a disc
matching their move's type.

`GROUP TM/HM` is also on by default: the TM/HM pocket lists HMs first, then
TMs, each in number order, instead of the order you found them. Because that
order is sorted for you, SELECT does not pick an item up in that pocket while
it is on; the other pockets keep it. Off restores acquisition order and the
swap.

## Limits

- Raising the slot limit above 20 makes `.sav` export lossy. The Game Boy
  bag format holds 20 entries, so converting a save keeps the first 20 in
  acquisition order and drops the rest. At the default setting this cannot
  happen.
- The 99 per-stack cap is the engine's and is unchanged. The option controls
  how many distinct items fit, not how many of each.
- 999 is effectively unlimited rather than literal: vanilla has 144
  non-badge items, so that is the real ceiling until a content mod adds more.

## Licence

MIT.
