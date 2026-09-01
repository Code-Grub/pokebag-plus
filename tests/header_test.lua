-- Standalone: luajit mods/pokebag_plus/tests/header_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
if not _G.love then _G.love = require("tests.love_stub") end

local T = require("tests.modkit")
local H = dofile("mods/pokebag_plus/Header.lua")

-- The four names at the GB's flat 8px advance
local W = { ITEMS = 40, BALLS = 40, ["KEY ITEMS"] = 72, ["TM/HM"] = 40 }

-- Names centre on a fixed midpoint, so only the name moves as pockets cycle
T.eq(H.nameX(W["KEY ITEMS"]), 16, "the longest name starts at 16")
T.eq(H.nameX(W.ITEMS), 32, "a short name centres on the same midpoint")
T.eq(H.nameX(W.ITEMS) + W.ITEMS, 72, "and ends short of the right arrow")

-- The longest name must not collide with the fixed right arrow
T.check(H.nameX(W["KEY ITEMS"]) + W["KEY ITEMS"] <= H.RIGHT_X,
  "KEY ITEMS clears the right arrow")
-- ...and the shortest must not collide with the fixed left arrow
T.check(H.nameX(W.ITEMS) >= H.LEFT_X + 3,
  "a short name clears the left arrow")

-- Arrow geometry: 3 wide, 5 tall, whole pixels, apex on the outer edge.
-- Capture the rectangles rather than trusting the eye.
local rects = {}
local realRect = love.graphics.rectangle
love.graphics.rectangle = function(mode, x, y, w, h)
  rects[#rects + 1] = { mode = mode, x = x, y = y, w = w, h = h }
end

H.leftArrow(8, 6)
T.eq(#rects, 3, "the left arrow is three columns")
for _, r in ipairs(rects) do
  T.eq(r.mode, "fill", "filled, not outlined")
  T.eq(r.x, math.floor(r.x), "on a whole pixel in x")
  T.eq(r.y, math.floor(r.y), "on a whole pixel in y")
  T.eq(r.w, 1, "every column is exactly one pixel wide")
end
T.eq(rects[1].h, 5, "the trailing column is the full 5 tall")
T.eq(rects[3].h, 1, "the apex is a single pixel")
T.eq(rects[3].x, 8, "and it sits at the leading edge")
T.eq(rects[2].x, 9, "the middle column sits between the other two")
T.eq(rects[2].h, 3, "the middle column steps down to 3 tall")

rects = {}
H.rightArrow(92, 6)
T.eq(#rects, 3, "the right arrow is three columns")
for _, r in ipairs(rects) do
  T.eq(r.w, 1, "every column is exactly one pixel wide")
end
T.eq(rects[1].x, 92, "its full-height column is at the leading edge")
T.eq(rects[1].h, 5, "5 tall")
T.eq(rects[3].h, 1, "tapering to a single pixel")
T.eq(rects[3].x, 94, "at the outer edge, mirroring the left arrow")
T.eq(rects[2].x, 93, "the middle column sits between the other two")
T.eq(rects[2].h, 3, "the middle column steps down to 3 tall")

love.graphics.rectangle = realRect

T.finish("header")
