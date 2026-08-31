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
  self.list.items = rows
  self.list.title = self:label()
  if self.list.index > #rows then
    self.list.index = math.max(1, #rows)
  end
  return rows
end

-- BagMenu reassigns list.items after a toss or a swap, which would drop the
-- filter.  Every one of those assigns a NEW table, so identity catches them
-- all in O(1).  In-place edits (the `consumed` branch updating `right` or
-- removing a row) do not trip this, and do not need to: they act on our
-- table, holding our entries, which is already correct under a filter.
function PocketBag:sync()
  if self.list.items ~= self.filtered then
    self:refresh()
  end
end

function PocketBag:page(delta)
  local order = self.env.Pockets.ORDER
  -- remember where this pocket's cursor was
  self.cursors[self:key()] = { index = self.list.index, scroll = self.list.scroll }
  self.pocket = ((self.pocket - 1 + delta) % #order) + 1
  PocketBag.lastPocket = self.pocket
  self:refresh()
  local remembered = self.cursors[self:key()]
  local n = #self.list.items
  self.list.index = math.max(1, math.min(remembered and remembered.index or 1, math.max(1, n)))
  self.list.scroll = remembered and remembered.scroll or 0
  if self.list.scroll >= n then self.list.scroll = 0 end
end

return PocketBag
