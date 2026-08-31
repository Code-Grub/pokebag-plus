-- Standalone: luajit mods/pokebag_plus/tests/pokebag_plus_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
if not _G.love then _G.love = require("tests.love_stub") end

local T = require("tests.modkit")
local Data = require("tests.modkit.fixtures").fresh()

local run = T.sdk.loadMod("mods/pokebag_plus", { data = Data })
T.eq(#run.errors, 0, "loads clean (" .. tostring(run.errors[1]) .. ")")

-- Later suites append above this line: the mod must still be loaded.
run.release()

T.finish("pokebag_plus")
