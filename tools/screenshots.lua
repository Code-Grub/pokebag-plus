-- README screenshot driver for PokeBag+.
--
-- Run from the engine checkout with the mod installed in mods/ (the
-- tools/screenshots.ps1 wrapper sets all of this up):
--
--   POKEPORT_DRIVER=<abs path to this file> SHOT_DIR=<out dir> \
--   POKEPORT_IDENTITY=pokebag-plus-shots POKEPORT_TOUCH=0 love .
--
-- The test suites cover behaviour, not pixels, so this is the only way the
-- header actually gets looked at: capture the draw calls for each of the
-- four pockets and render them. Deterministic by construction: the
-- teleport skips the intro, the bag is seeded with one known item per
-- pocket, the screen is opened straight through the registry, and Right
-- is tapped between captures rather than relying on default cursor state.
return function(game)
  local U = dofile("tests/drivers/util.lua")
  local Screens = require("src.ui.Screens")
  local DIR = os.getenv("SHOT_DIR") or "shots"

  -- A quiet, proven map spot; BagMenu is opaque, so the map itself never
  -- shows. What matters is the seeded inventory below it.
  U.teleport(game, "SS_ANNE_1F", 31, 9, "up")

  -- One item per pocket, in acquisition order, so the shots prove the
  -- classifier as well as the header: POTION -> ITEMS, POKE_BALL -> BALLS,
  -- BICYCLE -> KEY ITEMS, HM_CUT -> TM/HM.
  local save = game.save
  local order = { "POTION", "POKE_BALL", "BICYCLE", "HM_CUT" }
  save.bagOrder = {}
  save.inventory = {}
  for _, id in ipairs(order) do
    save.bagOrder[#save.bagOrder + 1] = id
    save.inventory[id] = 1
  end
  save.money = save.money or 0

  -- straight through the registry: BagMenu resolves to the mod's screen,
  -- which always opens on whichever pocket PocketBag.lastPocket names --
  -- module state, defaulting to ITEMS (1) on a fresh process.
  Screens.push(game, "BagMenu")
  U.wait(5)

  local names = { "items", "balls", "key", "tmhm" }
  for i, name in ipairs(names) do
    U.wait(2)
    U.shot(game, DIR .. "/screen_" .. name .. ".png")
    if i < #names then
      U.tap(game, "right")
      U.wait(2)
    end
  end

  U.log("screenshots written to ", DIR)
end
