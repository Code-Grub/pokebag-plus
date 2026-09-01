-- Pocket state over a ListMenu.  The list is duck-typed (items, index,
-- scroll, title), so this tests against a plain table with no engine.
--
-- Nothing here writes the save.  Pocket and cursor state live on the
-- instance and die with it, which is what keeps the mod's "never writes
-- your save" property.

local PocketBag = {}
PocketBag.__index = PocketBag

-- Which pocket the next bag opens on.  Module state, so it survives the
-- screen being closed and rebuilt -- opening the bag constructs a fresh
-- PocketBag every time, in battle and in the field alike.  It is NOT save
-- state: it resets at boot, and nothing here ever writes the save.
PocketBag.lastPocket = 1

function PocketBag.new(list, env)
  local self = setmetatable({}, PocketBag)
  self.list = list
  self.env = env
  self.pocket = PocketBag.lastPocket
  self.cursors = {}      -- pocket key -> { index, scroll }
  self.filtered = nil
  self.globalOf = {}
  self:refresh()
  return self
end

function PocketBag:key()
  return self.env.Pockets.ORDER[self.pocket]
end

function PocketBag:label()
  return self.env.Pockets.LABEL[self:key()]
end

-- Rebuild list.items for the current pocket, and remember where each row
-- sits in the global save.bagOrder so a swap can be remapped.
function PocketBag:refresh()
  local save = self.env.save
  local part = self.env.Pockets.partition(save.bagOrder, self.env.items, self.env)
  local rows, globals = {}, {}
  for i, entry in ipairs(part[self:key()]) do
    local def = self.env.items and self.env.items[entry.id]
    rows[i] = {
      value = entry.id,
      label = def and def.name or entry.id,
      right = "x" .. tostring(save.inventory[entry.id]),
    }
    globals[i] = entry.global
  end
  self.filtered = rows
  self.globalOf = globals
  self.orderLen = #save.bagOrder
  self.list.items = rows
  self.list.title = self:label()
  if self.list.index > #rows then
    self.list.index = math.max(1, #rows)
  end
  return rows
end

-- BagMenu reassigns list.items after a toss or a swap, which would drop the
-- filter.  Every one of those assigns a NEW table, so identity catches them
-- all in O(1).
--
-- Identity alone is not enough.  The `consumed` branch of
-- src/ui/BagMenu.lua edits the SAME table in place: it rewrites `right`
-- when a stack shrinks, and table.removes the row when the last one goes.
-- A removal also drops the id from save.bagOrder, so every later entry
-- shifts and globalOf goes stale while the table's identity never changes.
-- A swap then remaps through stale indices and reorders items the player
-- never touched -- use the last Potion, reorder two things, and two Poke
-- Balls move instead.
--
-- Comparing the row count against globalOf catches exactly that, still in
-- O(1): refresh() always leaves the two the same length, so any difference
-- means the list moved underneath us.  A `right` rewrite changes neither,
-- and correctly does not refresh.
--
-- The row-count check is a proxy, not an invariant: an item removed from a
-- DIFFERENT pocket shifts save.bagOrder without changing the current
-- pocket's row count, leaving globalOf stale while the count guard stays
-- silent.  Unreachable today (nothing removes from an inactive pocket
-- behind the player's back), but orderLen -- the length of save.bagOrder as
-- of the last refresh -- catches it too, so the guard holds even if that
-- changes.
function PocketBag:sync()
  if self.list.items ~= self.filtered
      or #self.list.items ~= #self.globalOf
      or #self.env.save.bagOrder ~= self.orderLen then
    self:refresh()
  end
end

function PocketBag:page(delta)
  local order = self.env.Pockets.ORDER
  -- remember where this pocket's cursor was
  self.cursors[self:key()] = { index = self.list.index, scroll = self.list.scroll }
  self:clearSwap()
  self.pocket = ((self.pocket - 1 + delta) % #order) + 1
  PocketBag.lastPocket = self.pocket
  self:refresh()
  local remembered = self.cursors[self:key()]
  local n = #self.list.items
  self.list.index = math.max(1, math.min(remembered and remembered.index or 1, math.max(1, n)))
  self.list.scroll = remembered and remembered.scroll or 0
  if self.list.scroll >= n then self.list.scroll = 0 end
end

-- Exchange two rows of the CURRENT pocket in the global save.bagOrder.
--
-- BagMenu does this with list indices (src/ui/BagMenu.lua:436 and :446),
-- which is correct only while list index equals bagOrder index.  Under a
-- filter it is not: the second entry of BALLS is not the second entry of
-- bagOrder.  globalOf is the translation, built by refresh().
--
-- BagMenu.new calls buildItems, which calls Bag.order (src/ui/BagMenu.lua)
-- and that normalizes save.bagOrder -- creating it for old saves, pruning
-- stale and duplicate ids -- before PocketBag ever reads it raw.  The mod
-- depends on that construction order rather than normalizing it itself.
function PocketBag:swap(localA, localB)
  local ga, gb = self.globalOf[localA], self.globalOf[localB]
  if not (ga and gb) then return false end
  local order = self.env.save.bagOrder
  if ga < 1 or ga > #order or gb < 1 or gb > #order then return false end
  order[ga], order[gb] = order[gb], order[ga]
  self:refresh()
  return true
end

-- A pending swap holds indices into the pocket that was on screen when it
-- started.  Carrying it across a page would apply them to a different
-- pocket's rows, so paging drops it.
function PocketBag:clearSwap()
  self.list.swapIndex = nil
end

return PocketBag
