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
}
