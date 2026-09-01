-- Standalone: luajit mods/pokebag_plus/tests/header_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
if not _G.love then _G.love = require("tests.love_stub") end

local T = require("tests.modkit")
local H = dofile("mods/pokebag_plus/Header.lua")

-- The four names at the GB's flat 8px advance
local W = { ITEMS = 40, BALLS = 40, ["KEY ITEMS"] = 72, ["TM/HM"] = 40 }

-- The header sits in the same columns the list below uses, so it lines up
-- with what it describes.  These are the engine's own numbers, from
-- src/ui/ListMenu.lua's draw: cursor at x=8, label at x=16, right-aligned
-- quantity ending at x=152, first row at y=24.
local CURSOR_X, LABEL_X, COUNT_RIGHT, FIRST_ROW_Y = 8, 16, 152, 24

T.eq(H.LEFT_X, CURSOR_X, "the left arrow sits in the list's cursor column")
T.eq(H.NAME_X, LABEL_X, "the pocket name sits in the list's label column")
T.eq(H.RIGHT_X + 3, COUNT_RIGHT,
  "the right arrow's right edge lands where the quantity column ends")

-- Nothing centres any more, so no name can collide with either arrow: the
-- only question is whether the longest one still clears the right arrow.
T.check(H.NAME_X + W["KEY ITEMS"] <= H.RIGHT_X,
  "KEY ITEMS, the longest name, clears the right arrow")
for name, width in pairs(W) do
  T.check(H.NAME_X + width <= H.RIGHT_X, name .. " clears the right arrow")
end

-- The box is three tiles tall at the very top, which is the space ListMenu's
-- own title already occupied.  If it grew, it would start covering row one.
local bx, by, bw, bh = H.BOX[1], H.BOX[2], H.BOX[3], H.BOX[4]
T.eq(bx, 0, "the box starts at the left edge")
T.eq(by, 0, "and at the top")
T.eq(bw, 20, "and spans the full 20 tiles")
T.eq((by + bh) * 8, FIRST_ROW_Y, "and ends exactly where the first row begins")

-- The interior row is one tile, and the text and arrows must both sit inside
-- it rather than on a border.
T.check(H.TEXT_Y >= (by + 1) * 8 and H.TEXT_Y < (by + bh - 1) * 8,
  "the name draws inside the box, not on a border")
T.check(H.ARROW_Y >= (by + 1) * 8 and H.ARROW_Y + 5 <= (by + bh - 1) * 8,
  "the whole 5px arrow fits inside the box's interior row")

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
