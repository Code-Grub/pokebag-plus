-- Standalone: luajit mods/pokebag_plus/tests/pokebag_plus_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
if not _G.love then _G.love = require("tests.love_stub") end

local T = require("tests.modkit")
local Data = require("tests.modkit.fixtures").fresh()

local run = T.sdk.loadMod("mods/pokebag_plus", { data = Data })
T.eq(#run.errors, 0, "loads clean (" .. tostring(run.errors[1]) .. ")")

local Screens = require("src.ui.Screens")
Screens.invalidate()

local pressed = nil
local game = {
  data = Data,
  save = {
    bagOrder = { "POTION", "POKE_BALL", "ANTIDOTE", "GREAT_BALL" },
    inventory = { POTION = 5, POKE_BALL = 8, ANTIDOTE = 1, GREAT_BALL = 3 },
    money = 3000,
    player = { name = "RED" },
  },
  stack = { push = function() end, pop = function() end, top = function() end },
  input = {
    wasPressed = function(_, k) return pressed == k end,
    isDown = function() return false end,
  },
}

local factory = Screens.get(game, "BagMenu")
T.check(factory and factory.new, "BagMenu resolves through the registry")
T.check(factory ~= require("src.ui.BagMenu"),
  "the mod screen wins over the builtin BagMenu")

local screen = factory.new(game, {})
T.eq(#screen.items, 2, "opens on ITEMS: POTION and ANTIDOTE")

-- Right pages to BALLS through the real update path
pressed = "right"
screen:update(0)
T.eq(#screen.items, 2, "BALLS holds both balls")
T.eq(screen.items[1].value, "POKE_BALL", "paged to BALLS")
T.eq(screen.title, "BALLS", "and the header followed")

-- Left pages back
pressed = "left"
screen:update(0)
T.eq(screen.title, "ITEMS", "Left pages back to ITEMS")

-- Up and Down still reach the builtin list behaviour
pressed = "down"
screen:update(0)
T.eq(screen.index, 2, "Down still moves the cursor")

pressed = nil

-- Later suites append above this line: the mod must still be loaded.
run.release()

T.finish("pokebag_plus")
