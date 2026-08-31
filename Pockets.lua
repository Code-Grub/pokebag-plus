-- Which pocket an item belongs to.  Pure: no engine requires, so this tests
-- with dofile and no LOVE.  Ball detection is injected rather than required
-- because mods can register new balls through the `balls` registry, so the
-- engine's own predicate is the only correct answer.

local Pockets = {}

-- Cycling order.  Left and Right walk this list.
Pockets.ORDER = { "ITEMS", "BALLS", "KEY", "TMHM" }

Pockets.LABEL = {
  ITEMS = "ITEMS",
  BALLS = "BALLS",
  KEY   = "KEY ITEMS",
  TMHM  = "TM/HM",
}

-- Order matters.  HM records carry keyItem AND machine (an HM is a key item
-- in Gen 1: it cannot be tossed), so the machine test has to come first or
-- every HM lands in KEY ITEMS.
function Pockets.pocketOf(id, def, env)
  -- Machine first: HM records carry keyItem AND machine (an HM is a key
  -- item in Gen 1, it cannot be tossed), so testing keyItem first would put
  -- every HM in KEY ITEMS.
  if def and def.machine then return "TMHM" end
  -- Ball detection needs no def: it routes through the engine's own
  -- predicate, so a ball another mod registered resolves here too.
  if env and env.isBall and env.isBall(id) then return "BALLS" end
  if def and def.keyItem then return "KEY" end
  -- No def, or none of the flags: an item some other mod added.  It stays
  -- reachable in ITEMS rather than disappearing into a pocket that does not
  -- exist for it.
  return "ITEMS"
end

return Pockets
