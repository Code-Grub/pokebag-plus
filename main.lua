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

  -- siblings and the screen claim arrive in later tasks
  local _ = sibling
end
