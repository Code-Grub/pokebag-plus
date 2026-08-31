-- The pocket header: a name between two arrows.
--
-- The arrows are hand drawn rather than font glyphs.  The charmap has a
-- filled right arrow at $ED but no left companion, and Bill's PC+ hit the
-- same wall on its box pager, where the font has a down marker and no up
-- one.  It drew both halves by hand on the reasoning that two shapes from
-- the same hand read cleaner than one glyph beside one hand drawn cousin.
-- Its pair is 5 wide by 3 tall; this is the same triangle turned a quarter
-- turn, 3 wide by 5 tall.
--
-- Font is passed in rather than required so this file keeps no engine
-- dependency and tests with dofile alone.

local Header = {}

Header.LEFT_X  = 8    -- left arrow, 3 wide
Header.RIGHT_X = 92   -- right arrow, 3 wide; clears the longest name
Header.MID_X   = 52   -- names centre here
Header.TEXT_Y  = 4    -- matches ListMenu's own title row
Header.ARROW_Y = 6    -- 5 tall, so it straddles the text row

-- Every element sits at a fixed x.  Anchoring the right arrow to the end of
-- the name instead would swing it 32px between TM/HM and KEY ITEMS, which
-- reads as the interface twitching rather than as a page turning.
function Header.nameX(width)
  return math.floor(Header.MID_X - width / 2)
end

function Header.leftArrow(x, y)
  love.graphics.rectangle("fill", x + 2, y,     1, 5)
  love.graphics.rectangle("fill", x + 1, y + 1, 1, 3)
  love.graphics.rectangle("fill", x,     y + 2, 1, 1)
end

function Header.rightArrow(x, y)
  love.graphics.rectangle("fill", x,     y,     1, 5)
  love.graphics.rectangle("fill", x + 1, y + 1, 1, 3)
  love.graphics.rectangle("fill", x + 2, y + 2, 1, 1)
end

-- ListMenu:draw sets the colour back to white as its last statement, so the
-- caller wrapping it has to set black again or everything here renders
-- invisible against the white fill.
function Header.draw(Font, label)
  love.graphics.setColor(0, 0, 0, 1)
  Header.leftArrow(Header.LEFT_X, Header.ARROW_Y)
  Header.rightArrow(Header.RIGHT_X, Header.ARROW_Y)
  Font.draw(label, Header.nameX(Font.width(label)), Header.TEXT_Y)
  love.graphics.setColor(1, 1, 1, 1)
end

return Header
