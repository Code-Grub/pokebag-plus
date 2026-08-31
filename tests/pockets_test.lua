-- Standalone: luajit mods/pokebag_plus/tests/pockets_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
if not _G.love then _G.love = require("tests.love_stub") end

local T = require("tests.modkit")
local P = dofile("mods/pokebag_plus/Pockets.lua")

local BALLS = { POKE_BALL = true, GREAT_BALL = true, ULTRA_BALL = true,
                MASTER_BALL = true, SAFARI_BALL = true }
local env = { isBall = function(id) return BALLS[id] or false end }

T.eq(P.pocketOf("POTION", { id = "POTION" }, env), "ITEMS",
  "an ordinary item is an ITEM")
T.eq(P.pocketOf("POKE_BALL", { id = "POKE_BALL" }, env), "BALLS",
  "a ball is a BALL")
T.eq(P.pocketOf("BICYCLE", { id = "BICYCLE", keyItem = true }, env), "KEY",
  "a key item is a KEY item")
T.eq(P.pocketOf("TM_01", { id = "TM_01", machine = { kind = "TM" } }, env),
  "TMHM", "a TM is a machine")

-- The ordering trap: an HM carries BOTH machine and keyItem.  If the keyItem
-- test runs first the HMs land in KEY ITEMS, which is wrong and which no
-- other assertion here would catch.
T.eq(P.pocketOf("HM_01", { id = "HM_01", machine = { kind = "HM" },
                           keyItem = true }, env),
  "TMHM", "an HM is a machine, not a key item, despite carrying both flags")

-- An item another mod added, carrying none of the flags, must stay reachable
T.eq(P.pocketOf("MOD_WIDGET", { id = "MOD_WIDGET" }, env), "ITEMS",
  "an unknown mod item falls through to ITEMS")
T.eq(P.pocketOf("MOD_WIDGET", nil, env), "ITEMS",
  "a missing item def falls through to ITEMS rather than erroring")

T.eq(#P.ORDER, 4, "four pockets")
T.eq(P.LABEL.KEY, "KEY ITEMS", "KEY displays as two words")

-- partition keeps acquisition order inside each pocket, and records where
-- each entry sits in the global order so a swap can be remapped later
local items = {
  POTION     = { id = "POTION" },
  POKE_BALL  = { id = "POKE_BALL" },
  ANTIDOTE   = { id = "ANTIDOTE" },
  GREAT_BALL = { id = "GREAT_BALL" },
  BICYCLE    = { id = "BICYCLE", keyItem = true },
  HM_01      = { id = "HM_01", machine = { kind = "HM" }, keyItem = true },
}
local order = { "POTION", "POKE_BALL", "ANTIDOTE", "GREAT_BALL", "BICYCLE", "HM_01" }
local part = P.partition(order, items, env)

T.eq(#part.ITEMS, 2, "two ordinary items")
T.eq(part.ITEMS[1].id, "POTION", "POTION first, as acquired")
T.eq(part.ITEMS[2].id, "ANTIDOTE", "ANTIDOTE second, as acquired")
T.eq(part.ITEMS[1].global, 1, "POTION is global 1")
T.eq(part.ITEMS[2].global, 3, "ANTIDOTE is global 3, not local 2")

T.eq(#part.BALLS, 2, "two balls")
T.eq(part.BALLS[1].global, 2, "POKE BALL is global 2")
T.eq(part.BALLS[2].global, 4, "GREAT BALL is global 4")

T.eq(#part.KEY, 1, "one key item")
T.eq(#part.TMHM, 1, "the HM is a machine")

-- every pocket key exists even when empty, so callers never nil-index
local empty = P.partition({}, items, env)
for _, key in ipairs(P.ORDER) do
  T.eq(#empty[key], 0, key .. " is present and empty")
end

T.finish("pockets")
