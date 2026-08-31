-- Splits the bag into four pockets by claiming the BagMenu screen id
-- (src/ui/BagMenu.lua).  Every bag entry point resolves here instead of to
-- the builtin: the START menu (src/ui/StartMenu.lua) and the battle bag
-- (src/battle/BattleState.lua) both go through src/ui/Screens.lua.
--
-- A mod cannot require its own files, so the siblings load through
-- mod:read + load, the same way example_jukebox loads its song.

return function(mod)
  local function sibling(name)
    local source = mod:read(name)
    if not source then
      mod.log:error("%s missing from %s -- reinstall the mod", name, mod.path)
      return nil
    end
    local chunk, compileErr = load(source, "@" .. mod.path .. "/" .. name)
    if not chunk then
      mod.log:error("%s did not compile: %s", name, tostring(compileErr))
      return nil
    end
    local ok, result = pcall(chunk)
    if not ok then
      mod.log:error("%s failed to load: %s", name, tostring(result))
      return nil
    end
    return result
  end

  local Pockets = sibling("Pockets.lua")
  local Header = sibling("Header.lua")
  local PocketBag = sibling("PocketBag.lua")
  if not (Pockets and Header and PocketBag) then return end

  local optionRows = sibling("options.lua")
  if optionRows then
    mod.options:define(optionRows)

    -- Bag.capacity re-reads data.constants.bagSize on every call
    -- (src/inventory/Bag.lua:16), so writing it is enough: no reload, and
    -- the change is visible to the next Bag.add.
    --
    -- Written straight to Data rather than through
    -- mod.content.constants:patch, because this has to run again from the
    -- options_changed handler, long after the registries were merged.  One
    -- path that works at both moments beats a load-time path plus a
    -- different runtime one.
    local Data = require("src.core.Data")
    local function applyCapacity()
      local value = mod.options:get("capacity") or 20
      if Data.constants then Data.constants.bagSize = value end
    end
    applyCapacity()
    mod.events:on("mod.options_changed", function(payload)
      if payload and payload.key == "capacity" then applyCapacity() end
    end)
  end

  local BagMenu = require("src.ui.BagMenu")
  local ItemEffects = require("src.inventory.ItemEffects")
  local Font = require("src.render.Font")
  local Sound = require("src.core.Sound")

  mod.content.screens:register("BagMenu", {
    new = function(game, opts)
      -- The builtin builds the whole list, wired to every item flow the
      -- engine has: the bicycle, fishing, the Poke Flute, the Escape Rope,
      -- TM teaching, the Rare Candy level-up chain, ball throws, USE/TOSS
      -- and QuantityBox.  We decorate rather than reimplement, so those all
      -- keep working and future fixes to them land here for free.
      local list = BagMenu.new(game, opts)

      local bag = PocketBag.new(list, {
        save = game.save,
        items = game.data.items,
        Pockets = Pockets,
        isBall = ItemEffects.isBall,
      })

      -- Left and Right are free: ListMenu ignores them unless pageJump is
      -- set (src/ui/ListMenu.lua:158,161) and BagMenu never sets it.
      local baseUpdate = list.update
      function list:update(dt)
        bag:sync()
        local input = self.game.input
        if input:wasPressed("left") then bag:page(-1) return end
        if input:wasPressed("right") then bag:page(1) return end
        baseUpdate(self, dt)
      end

      -- ListMenu:draw ends by setting the colour back to white, so the
      -- header has to set black again or it renders invisible.
      local baseDraw = list.draw
      function list:draw()
        baseDraw(self)
        Header.draw(Font, bag:label())
      end

      -- SELECT: the builtin's swap writes save.bagOrder with LIST indices,
      -- which a filtered pocket breaks.  Replace it outright.
      list.onSelectKey = function(item, l)
        if not item then return end
        if not l.swapIndex then
          l.swapIndex = l.index
          return
        end
        bag:swap(l.swapIndex, l.index)
        l.swapIndex = nil
        Sound.play(game.data, "Swap")
      end

      -- A also completes a pending swap in the builtin, with the same bad
      -- arithmetic.  Intercept that branch; delegate everything else.
      local baseChoose = list.onChoose
      list.onChoose = function(item, l)
        if list.swapIndex then
          bag:swap(list.swapIndex, list.index)
          list.swapIndex = nil
          Sound.play(game.data, "Swap")
          return
        end
        return baseChoose(item, l)
      end

      return list
    end,
  })
end
