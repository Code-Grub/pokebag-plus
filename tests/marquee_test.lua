-- Standalone: luajit mods/pokebag_plus/tests/marquee_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
if not _G.love then _G.love = require("tests.love_stub") end

local T = require("tests.modkit")
local M = dofile("mods/pokebag_plus/Marquee.lua")

-- The name column runs from ITEM_NAME_X=48 to the item box's right border at
-- 152 (src/ui/ListMenu.lua), at the GB's flat 8px advance.
T.eq(M.COLS, (152 - 48) / 8, "the window is the engine's name column, 13 glyphs")

-- Anything that fits is left alone, at every moment.
T.eq(M.fit("TM06 TOXIC", M.COLS), "TM06 TOXIC", "a short label is untouched")
T.eq(M.window("TM06 TOXIC", M.COLS, 0), "TM06 TOXIC", "and never scrolls")
T.eq(M.window("TM06 TOXIC", M.COLS, 99), "TM06 TOXIC", "at any time")
T.eq(M.fit("TM13 ICE BEAM", M.COLS), "TM13 ICE BEAM", "exactly 13 glyphs fits")

-- Resting rows are cut to the window with the engine's trailing-dot mark.
T.eq(M.fit("TM01 MEGA PUNCH", M.COLS), "TM01 MEGA PU.", "a long label is cut and marked")
T.eq(#M.fit("TM03 SWORDS DANCE", M.COLS), M.COLS, "the cut label fills the window exactly")

-- The marquee rests on the front, walks one glyph per step, rests on the end,
-- then starts over.
local label = "TM03 SWORDS DANCE" -- 17 glyphs: 4 past the window
local P, S = M.PAUSE, M.STEP
T.eq(M.window(label, M.COLS, 0), "TM03 SWORDS D", "starts on the front of the label")
T.eq(M.window(label, M.COLS, P - 0.01), "TM03 SWORDS D", "rests for PAUSE first")
T.eq(M.window(label, M.COLS, P), "M03 SWORDS DA", "then moves one glyph")
T.eq(M.window(label, M.COLS, P + S), "03 SWORDS DAN", "and one more each STEP")
T.eq(M.window(label, M.COLS, P + 2 * S), "3 SWORDS DANC", "and another")
T.eq(M.window(label, M.COLS, P + 3 * S), " SWORDS DANCE", "reaching the last glyph")
T.eq(M.window(label, M.COLS, P + 3.5 * S), " SWORDS DANCE", "holds on the last glyph between steps")
-- The end rests for PAUSE, then the cycle restarts from the front.
local cycle = P + 3 * S + P
T.eq(M.window(label, M.COLS, cycle - 0.01), " SWORDS DANCE", "rests on the end for PAUSE")
T.eq(M.window(label, M.COLS, cycle), "TM03 SWORDS D", "then wraps to the front")
T.eq(M.window(label, M.COLS, cycle + P + S), "03 SWORDS DAN", "and runs again")

-- Whatever the time, the window is always exactly COLS glyphs of a long label.
for i = 0, 400 do
  T.eq(#M.window("TM36 SELFDESTRUCT", M.COLS, i * 0.05), M.COLS,
    "window stays 13 glyphs at t=" .. i * 0.05)
end

-- A multi-byte glyph counts once, not once per byte.
T.eq(M.fit("TM99 POK\xc3\xa9MON BEAM", M.COLS), "TM99 POK\xc3\xa9MON.", "cuts by glyph, not by byte")

T.finish("marquee")
