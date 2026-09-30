-- Fits a long TM/HM label into the bag's name column.
--
-- "TM01 MEGA PUNCH" is 15 glyphs and the column is 13: 32 of the 55 Gen 1
-- labels overflow, the widest by four.  Resting rows are cut to the column
-- the way the engine cuts its own long labels (src/ui/ListMenu.lua fitLabel:
-- drop the tail, end on "."), and the highlighted row scrolls so the whole
-- name can be read.  It moves a glyph at a time, the way the GB moves text,
-- rather than smoothly by the pixel.
--
-- Pure string and clock arithmetic with no engine dependency, so it tests
-- with dofile alone.

local Marquee = {}

-- The name column: ITEM_NAME_X = 48 to the item box's right border at 152,
-- at the charmap's flat 8px advance (src/ui/ListMenu.lua).
Marquee.COLS = (152 - 48) / 8

Marquee.PAUSE = 1.0   -- seconds resting on the front, and again on the end
Marquee.STEP  = 0.2   -- seconds per glyph while moving

-- Split into glyphs rather than bytes: the charmap has multi-byte entries
-- (the accented e, the male/female signs) that a byte slice would cut in half.
local function glyphs(text)
  local out = {}
  for g in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do out[#out + 1] = g end
  return out
end

-- A resting row.
function Marquee.fit(label, cols)
  local g = glyphs(label)
  if #g <= cols then return label end
  return table.concat(g, "", 1, cols - 1) .. "."
end

-- The highlighted row, `t` seconds after it was highlighted.
function Marquee.window(label, cols, t)
  local g = glyphs(label)
  local over = #g - cols
  if over <= 0 then return label end
  local pause, step = Marquee.PAUSE, Marquee.STEP
  -- The last step lands at pause + (over - 1) * step; resting a further
  -- `pause` there ends the cycle.
  local cycle = pause + (over - 1) * step + pause
  t = t % cycle
  local offset = 0
  if t >= pause then
    -- the epsilon keeps 0.6 / 0.2 from flooring to 2
    offset = math.min(over, math.floor((t - pause) / step + 1e-9) + 1)
  end
  return table.concat(g, "", offset + 1, offset + cols)
end

return Marquee
