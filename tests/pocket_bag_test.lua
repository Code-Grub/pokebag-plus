-- Standalone: luajit mods/pokebag_plus/tests/pocket_bag_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
if not _G.love then _G.love = require("tests.love_stub") end

local T = require("tests.modkit")
local Pockets = dofile("mods/pokebag_plus/Pockets.lua")
local PocketBag = dofile("mods/pokebag_plus/PocketBag.lua")

local BALLS = { POKE_BALL = true, GREAT_BALL = true, ULTRA_BALL = true }
local ITEMS = {
  POTION     = { id = "POTION" },
  ANTIDOTE   = { id = "ANTIDOTE" },
  POKE_BALL  = { id = "POKE_BALL" },
  GREAT_BALL = { id = "GREAT_BALL" },
  ULTRA_BALL = { id = "ULTRA_BALL" },
  BICYCLE    = { id = "BICYCLE", keyItem = true },
}

-- PocketBag.lastPocket is module state that outlives an instance, so every
-- fixture resets it.  Pass true to inherit it instead, which is how the
-- reopen test gets a second bag that remembers the first one's pocket.
local function fixture(keepPocket)
  if not keepPocket then PocketBag.lastPocket = 1 end
  local save = {
    bagOrder = { "POTION", "POKE_BALL", "ANTIDOTE", "GREAT_BALL",
                 "ULTRA_BALL", "BICYCLE" },
    inventory = { POTION = 5, POKE_BALL = 8, ANTIDOTE = 1, GREAT_BALL = 3,
                  ULTRA_BALL = 1, BICYCLE = 1 },
  }
  local list = { items = {}, index = 1, scroll = 0, title = "" }
  local bag = PocketBag.new(list, {
    save = save, items = ITEMS, Pockets = Pockets,
    isBall = function(id) return BALLS[id] or false end,
  })
  return bag, list, save
end

-- opens on ITEMS, showing only ITEMS
local bag, list = fixture()
T.eq(bag:key(), "ITEMS", "opens on the first pocket")
T.eq(#list.items, 2, "ITEMS holds POTION and ANTIDOTE")
T.eq(list.items[1].label, "POTION", "labelled by name")
T.eq(list.items[1].right, "x5", "with the count on the right")

-- Right pages to BALLS
bag:page(1)
T.eq(bag:key(), "BALLS", "Right pages forward")
T.eq(#list.items, 3, "three balls")
T.eq(list.items[1].value, "POKE_BALL", "the first ball")

-- paging wraps in both directions
bag:page(1); bag:page(1)
T.eq(bag:key(), "TMHM", "third page is TM/HM")
bag:page(1)
T.eq(bag:key(), "ITEMS", "and it wraps forward to the start")
bag:page(-1)
T.eq(bag:key(), "TMHM", "and backward off the start")

-- the cursor is remembered per pocket
bag, list = fixture()
list.index = 2                       -- sit on ANTIDOTE in ITEMS
bag:page(1)                          -- to BALLS
T.eq(list.index, 1, "a fresh pocket starts at the top")
list.index = 3                       -- sit on ULTRA BALL
bag:page(-1)                         -- back to ITEMS
T.eq(list.index, 2, "ITEMS remembers where the cursor was")
bag:page(1)                          -- to BALLS again
T.eq(list.index, 3, "and so does BALLS")

-- the title follows the pocket
T.eq(list.title, "BALLS", "the title is the pocket label")
bag:page(1)
T.eq(list.title, "KEY ITEMS", "including the two-word one")

-- The last pocket is remembered ACROSS instances, because every time the
-- player opens the bag a new screen and a new PocketBag are built.  This is
-- module state, not save state: it resets at boot and writes nothing.
bag, list = fixture()
bag:page(1)                                  -- to BALLS
T.eq(bag:key(), "BALLS", "paged to BALLS")
local reopened = fixture(true)               -- a fresh screen, as on reopen
T.eq(reopened:key(), "BALLS", "a reopened bag lands on the last pocket used")

-- the resync guard: BagMenu rebuilds list.items as a NEW table after a toss,
-- which would wipe the filter.  Identity is what catches it, in O(1).
bag, list = fixture()
T.eq(#list.items, 2, "ITEMS to start")
list.items = { { value = "POTION", label = "POTION", right = "x5" },
               { value = "POKE_BALL", label = "POKE BALL", right = "x8" },
               { value = "ANTIDOTE", label = "ANTIDOTE", right = "x1" } }
bag:sync()
T.eq(#list.items, 2, "sync re-applies the pocket filter after a rebuild")
T.eq(list.items, bag.filtered, "and the list is our table again")

-- an untouched list is left alone
local before = list.items
bag:sync()
T.eq(list.items, before, "sync is a no-op when nothing replaced the table")

-- THE test.  BagMenu swaps save.bagOrder positions using LIST indices, which
-- is only correct while the list is the whole bag.  In BALLS, local 1 and 3
-- are global 2 and 5, so a naive swap would move POTION and ANTIDOTE and
-- leave the balls where they were.
local save
bag, list, save = fixture()
bag:page(1)                                   -- BALLS
T.eq(list.items[1].value, "POKE_BALL", "local 1 is POKE BALL")
T.eq(list.items[3].value, "ULTRA_BALL", "local 3 is ULTRA BALL")
T.eq(bag.globalOf[1], 2, "which is global 2")
T.eq(bag.globalOf[3], 5, "and global 5")

bag:swap(1, 3)

T.eq(save.bagOrder[2], "ULTRA_BALL", "global 2 now holds ULTRA BALL")
T.eq(save.bagOrder[5], "POKE_BALL", "global 5 now holds POKE BALL")
-- the items that were never touched must not have moved
T.eq(save.bagOrder[1], "POTION", "POTION did not move")
T.eq(save.bagOrder[3], "ANTIDOTE", "ANTIDOTE did not move")
T.eq(save.bagOrder[4], "GREAT_BALL", "GREAT BALL did not move")
T.eq(save.bagOrder[6], "BICYCLE", "BICYCLE did not move")
-- and the visible pocket reflects it
T.eq(list.items[1].value, "ULTRA_BALL", "the pocket shows the swap")
T.eq(list.items[3].value, "POKE_BALL", "both ends of it")

-- a half-finished move must not survive a page: the indices it captured
-- belong to a pocket that is no longer on screen
bag, list = fixture()
list.swapIndex = 1
bag:page(1)
T.eq(list.swapIndex, nil, "paging clears a pending swap")

-- Using the LAST of a stack removes the row in place (the consumed branch of
-- src/ui/BagMenu.lua), so the table's identity never changes -- but the id
-- also leaves save.bagOrder, shifting every later entry and leaving globalOf
-- stale.  Swapping through stale indices reorders items the player never
-- touched: use the last Poke Ball, reorder two balls, and POTION moves.
bag, list, save = fixture()
bag:page(1)                                   -- BALLS
T.eq(#list.items, 3, "BALLS starts with three rows")
T.eq(bag.globalOf[1], 2, "POKE BALL is global 2")

-- reproduce the engine's consumed branch: last one used, so the id leaves the
-- inventory and the order, and the row goes from the SAME table
save.inventory.POKE_BALL = nil
for i, oid in ipairs(save.bagOrder) do
  if oid == "POKE_BALL" then table.remove(save.bagOrder, i) break end
end
for i, it in ipairs(list.items) do
  if it.value == "POKE_BALL" then table.remove(list.items, i) break end
end
T.eq(list.items, bag.filtered, "the table's identity did not change, so identity alone cannot notice")

bag:sync()
T.eq(#bag.globalOf, #list.items, "sync noticed the row count moved and rebuilt")
T.eq(bag.globalOf[1], 3, "GREAT BALL shifted down to global 3")

-- now the swap must move the two balls and nothing else
bag:swap(1, 2)
T.eq(save.bagOrder[1], "POTION", "POTION did not move")
T.eq(save.bagOrder[2], "ANTIDOTE", "ANTIDOTE did not move")
T.eq(save.bagOrder[3], "ULTRA_BALL", "the two balls exchanged")
T.eq(save.bagOrder[4], "GREAT_BALL", "both ends of the exchange")
T.eq(save.bagOrder[5], "BICYCLE", "BICYCLE did not move")

T.finish("pocket_bag")
