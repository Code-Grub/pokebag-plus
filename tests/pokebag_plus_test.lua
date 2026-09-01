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

-- Fresh fixture per swap test: PocketBag.lastPocket is module state that
-- survives across screen constructions in this process, and each test below
-- needs to control which pocket it starts on rather than inherit whatever
-- pocket the assertions above left behind.
local function newGame()
  local keys = { pressed = nil }
  local g = {
    data = Data,
    save = {
      bagOrder = { "POTION", "POKE_BALL", "ANTIDOTE", "GREAT_BALL" },
      inventory = { POTION = 5, POKE_BALL = 8, ANTIDOTE = 1, GREAT_BALL = 3 },
      money = 3000,
      player = { name = "RED" },
    },
    stack = { push = function() end, pop = function() end, top = function() end },
    input = {
      wasPressed = function(_, k) return keys.pressed == k end,
      isDown = function() return false end,
    },
  }
  return g, keys
end

-- SELECT swap under a pocket filter: local index 1 in BALLS is global 2
-- (POKE_BALL), local index 2 is global 4 (GREAT_BALL). A raw list-index
-- swap (the builtin's arithmetic) would exchange save.bagOrder[1] and
-- save.bagOrder[2] instead -- wrong entries, and it would silently corrupt
-- POTION's slot. bag:swap remaps through globalOf, so only positions 2 and
-- 4 move; 1 and 3 must stay put.
local selectGame, selectKeys = newGame()
local selectScreen = Screens.get(selectGame, "BagMenu").new(selectGame, {})
-- Page to BALLS explicitly (ORDER has 4 entries, so this always terminates).
while selectScreen.title ~= "BALLS" do
  selectKeys.pressed = "right"
  selectScreen:update(0)
end
selectKeys.pressed = nil
T.eq(selectScreen.items[1].value, "POKE_BALL", "swap fixture: local row 1 is POKE_BALL")
T.eq(selectScreen.items[2].value, "GREAT_BALL", "swap fixture: local row 2 is GREAT_BALL")

selectScreen.index = 1
selectKeys.pressed = "select"
selectScreen:update(0)
T.eq(selectScreen.swapIndex, 1, "SELECT on row 1 starts the pickup")

selectScreen.index = 2
selectKeys.pressed = "select"
selectScreen:update(0)
T.eq(selectScreen.swapIndex, nil, "second SELECT completes the swap")
T.eq(selectGame.save.bagOrder[1], "POTION", "global 1 (POTION) unmoved")
T.eq(selectGame.save.bagOrder[2], "GREAT_BALL", "global 2 now GREAT_BALL")
T.eq(selectGame.save.bagOrder[3], "ANTIDOTE", "global 3 (ANTIDOTE) unmoved")
T.eq(selectGame.save.bagOrder[4], "POKE_BALL", "global 4 now POKE_BALL")
selectKeys.pressed = nil

-- Same pending swap, completed with A instead of a second SELECT: exercises
-- the wrapped onChoose branch (main.lua) rather than onSelectKey.
local chooseGame, chooseKeys = newGame()
local chooseScreen = Screens.get(chooseGame, "BagMenu").new(chooseGame, {})
while chooseScreen.title ~= "BALLS" do
  chooseKeys.pressed = "right"
  chooseScreen:update(0)
end
chooseKeys.pressed = nil

chooseScreen.index = 1
chooseKeys.pressed = "select"
chooseScreen:update(0)
T.eq(chooseScreen.swapIndex, 1, "onChoose fixture: SELECT starts the pickup")

chooseScreen.index = 2
chooseKeys.pressed = "a"
chooseScreen:update(0)
T.eq(chooseScreen.swapIndex, nil, "A completes the pending swap")
T.eq(chooseGame.save.bagOrder[1], "POTION", "onChoose: global 1 (POTION) unmoved")
T.eq(chooseGame.save.bagOrder[2], "GREAT_BALL", "onChoose: global 2 now GREAT_BALL")
T.eq(chooseGame.save.bagOrder[3], "ANTIDOTE", "onChoose: global 3 (ANTIDOTE) unmoved")
T.eq(chooseGame.save.bagOrder[4], "POKE_BALL", "onChoose: global 4 now POKE_BALL")
chooseKeys.pressed = nil

-- The header label must reach Font/Header only after passing through
-- Strings (src/core/Strings.lua), or a translation mod cannot localize the
-- pocket names.  Header.draw's own inputs are not reachable from here --
-- main.lua closes over Header as a local sibling loaded via mod:read, not a
-- require -- but Strings IS a normal require, and Lua caches requires by
-- module name, so the table below is the exact same object main.lua's own
-- require("src.core.Strings") returned.  Spying on Strings.get therefore
-- genuinely discriminates: if main.lua regressed to handing bag:label() to
-- Header.draw raw, Strings.get would never see the pocket label below.
do
  local Strings = require("src.core.Strings")
  local seen = {}
  local realGet = Strings.get
  Strings.get = function(source, ...)
    seen[#seen + 1] = source
    return realGet(source, ...)
  end
  local drawOk, drawErr = pcall(function() screen:draw() end)
  Strings.get = realGet
  T.check(drawOk, "draw() does not error (" .. tostring(drawErr) .. ")")

  local sawLabel = false
  for _, s in ipairs(seen) do
    if s == screen.title then sawLabel = true end
  end
  T.check(sawLabel, "the pocket label (" .. tostring(screen.title)
    .. ") passes through Strings before it reaches the header")

  -- And the catalog itself is a transparent pass-through here: nothing in
  -- this process has called Strings.load, so the four pocket names must
  -- round-trip unchanged, which is the "vanilla boot draws byte-identical
  -- text" contract Strings.lua documents for an empty catalog.
  local Pockets = dofile("mods/pokebag_plus/Pockets.lua")
  for _, key in ipairs(Pockets.ORDER) do
    local label = Pockets.LABEL[key]
    T.eq(Strings(label), label,
      "Strings round-trips " .. label .. " under the default catalog")
  end
end

local Bag = require("src.inventory.Bag")

-- default is vanilla
T.eq(Bag.capacity(Data), 20, "defaults to the vanilla 20 slots")

-- raising it takes effect with no reload, because Bag.capacity re-reads
-- data.constants.bagSize on every call
Data.constants.bagSize = 999
T.eq(Bag.capacity(Data), 999, "the option value takes effect live")

-- an over-full bag survives being lowered again: Bag.add refuses NEW slots
-- while over the limit, but nothing already held is lost
local over = { inventory = {}, bagOrder = {} }
for i = 1, 25 do
  local id = "FILLER_" .. i
  over.inventory[id] = 1
  over.bagOrder[#over.bagOrder + 1] = id
end
T.eq(Bag.slots(over), 25, "25 slots held at the 999 setting")
Data.constants.bagSize = 20
T.eq(Bag.slots(over), 25, "lowering the limit loses nothing already held")
T.eq(Bag.add(over, "ANOTHER", 1, Data), false,
  "but no new slot is accepted while over the limit")

Data.constants.bagSize = 20

-- The assertions above only pin Bag.lua's pre-existing live-re-read
-- contract: the fixture seeds bagSize to 20 and Bag.capacity re-reads it
-- regardless of who wrote it, so they pass even if main.lua's option
-- wiring did nothing at all. These pin main.lua's own handler: they drive
-- it through the real mod.options_changed event on the loaded mod's own
-- loader, the same bus ManagerState.setOption emits on in the real game.

-- Case 1: load-time apply and the schema default. Sentinel the constant
-- away from both choices, then emit with nothing stored in
-- loader.modOptions yet, so mod.options:get("capacity") must fall back to
-- the options.lua schema row's default of 20.
Data.constants.bagSize = 1
run.loader.events:emit("mod.options_changed",
  { mod = "pokebag_plus", key = "capacity", value = 20 })
T.eq(Data.constants.bagSize, 20,
  "the mod's handler ran and fell back to the schema default of 20")

-- Case 2: a stored value is honoured, not just the default.
run.loader.modOptions.pokebag_plus = { capacity = 999 }
run.loader.events:emit("mod.options_changed",
  { mod = "pokebag_plus", key = "capacity", value = 999 })
T.eq(Data.constants.bagSize, 999,
  "the mod's handler applied the stored capacity of 999")

-- Case 3: it tracks the option back down too, not just up.
run.loader.modOptions.pokebag_plus.capacity = 20
run.loader.events:emit("mod.options_changed",
  { mod = "pokebag_plus", key = "capacity", value = 20 })
T.eq(Data.constants.bagSize, 20,
  "the mod's handler followed the stored capacity back down to 20")

-- Case 4: the key guard actually guards. A handler that ignored
-- payload.key entirely would still pass cases 1-3.
Data.constants.bagSize = 1
run.loader.events:emit("mod.options_changed",
  { mod = "pokebag_plus", key = "something_else", value = 999 })
T.eq(Data.constants.bagSize, 1,
  "an options_changed event for a different key is ignored")

-- Reset so nothing downstream inherits a sentinel.
Data.constants.bagSize = 20

-- Later suites append above this line: the mod must still be loaded.
run.release()

T.finish("pokebag_plus")
