-- Read by the mod manager's auto-UI (through manifest.options_schema) and
-- by main.lua, so the launcher can show the row before the mod is loaded
-- and the mod can read the same defaults after it is.
--
-- 999 is effectively unlimited rather than literal.  Vanilla has 152 item
-- ids of which 8 are badges, so a bag tops out at 144 distinct items.  The
-- bigger number is still the right one to ship: a content mod that adds
-- items raises that ceiling, and 999 stays unbounded where 144 would
-- quietly start binding.
return {
  {
    key = "capacity",
    type = "choice",
    label = "BAG SLOTS",
    default = 20,
    choices = { { "20", 20 }, { "999", 999 } },
  },
  -- On shows "TM01 MEGA PUNCH", scrolling when the highlighted label is
  -- wider than the list's name column.  Off is vanilla: a machine shows as
  -- "TM01" and you learn the move from the booted-up text.
  {
    key = "tmhm_names",
    type = "choice",
    label = "TM/HM NAMES",
    default = "on",
    choices = { { "ON", "on" }, { "OFF", "off" } },
  },
  -- On shows the highlighted item's icon in a small window beside the list.
  -- The icons are FireRed's, read from the player's own import of that ROM;
  -- with no import there is nothing to show and no window is drawn, whatever
  -- this is set to.
  {
    key = "item_preview",
    type = "choice",
    label = "ITEM PREVIEW",
    default = "on",
    choices = { { "ON", "on" }, { "OFF", "off" } },
  },
  -- On sorts the TM/HM pocket into HMs then TMs, each by number, instead of
  -- acquisition order.  Off is vanilla order.  While on, SELECT does not pick
  -- anything up in that pocket, because the order is derived; every other
  -- pocket keeps it.
  {
    key = "tmhm_group",
    type = "choice",
    label = "GROUP TM/HM",
    default = "on",
    choices = { { "ON", "on" }, { "OFF", "off" } },
  },
}
