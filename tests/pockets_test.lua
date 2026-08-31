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

T.finish("pockets")
