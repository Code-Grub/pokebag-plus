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
-- The engine's own bag window, from src/ui/ListMenu.lua's drawItemBox.  These
-- are the numbers the header has to agree with; if the engine moves its box,
-- these assertions are what notices.
local ITEM_BOX = { tx = 4, ty = 2, tw = 16, th = 11 }
local ITEM_CURSOR_X = 40

local bx, by, bw, bh = H.BOX[1], H.BOX[2], H.BOX[3], H.BOX[4]
T.eq(by, 0, "the header sits at the top of the screen")
T.eq(bx, ITEM_BOX.tx, "its left border shares the item box's column")
T.eq(bw, ITEM_BOX.tw, "and it is exactly as wide as the item box")

-- Its bottom border row IS the item box's top border row: one shared divider
-- rather than two edges a tile apart.  The strip above the item box is only
-- two tiles and a bordered box needs three, so this is what makes it fit.
T.eq(by + bh, ITEM_BOX.ty + 1,
  "the header's bottom border falls on the item box's top border row")

-- Interior is one tile in from each border.
local IN_L, IN_R = (bx + 1) * 8, (bx + bw - 1) * 8
T.eq(IN_L, 40, "interior starts at 40")
T.eq(IN_R, 152, "interior ends at 152")
T.eq(H.MID_X, (IN_L + IN_R) / 2, "names centre on the interior's midpoint")

-- Names centre; the arrows do not move.
T.eq(H.LEFT_X, IN_L, "the left arrow sits at the interior's left edge")
T.eq(H.LEFT_X, ITEM_CURSOR_X,
  "which is also the list's cursor column, so the arrow sits over the cursor")
T.eq(H.RIGHT_X + 3, IN_R, "the right arrow's right edge is the interior's")

-- Every name must clear both arrows, whatever its width.
for name, width in pairs(W) do
  T.check(H.nameX(width) >= H.LEFT_X + 3, name .. " clears the left arrow")
  T.check(H.nameX(width) + width <= H.RIGHT_X, name .. " clears the right arrow")
end
T.eq(H.nameX(W["KEY ITEMS"]), 60, "the longest name centres at 60")
T.eq(H.nameX(W.ITEMS), 76, "a short name centres on the same midpoint")

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
