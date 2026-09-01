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

-- A bordered window across the top, the same primitive the engine frames its
-- money box and text boxes with, so the header reads as a window rather than
-- as text floating on the list's white fill.  Three tiles tall: two borders
-- and one interior row.  It occupies only the space ListMenu's own title
-- already used, so no list row is lost -- the first row still starts at y=24,
-- immediately under the bottom border.
--
-- Inset one tile from each screen edge, so the box's OUTER edges land on the
-- list's own extent rather than overhanging it: the left border fills the
-- cursor column (x=8), the right border the last quantity tile (ending at
-- x=152).  A full-width box is the engine's idiom for the bottom text box,
-- but here it stuck out 8px further left than anything else on screen.
Header.BOX = { 1, 0, 18, 3 }   -- tile coords for Font.drawBox: x 8..152

-- Interior runs x=16..144, so the name centres on 80.  The arrows are fixed
-- and the name moves: anchoring an arrow to the name's own width would swing
-- it 32px between TM/HM and KEY ITEMS, which reads as the interface twitching
-- rather than as a page turning.
Header.LEFT_X  = 16   -- left arrow at the interior's left edge
Header.RIGHT_X = 141  -- 3 wide, so its right edge is the interior's, 144
Header.MID_X   = 80   -- interior centre; names centre here
Header.TEXT_Y  = 8    -- the box's interior row
Header.ARROW_Y = 10   -- the 5px arrow centred in that 8px row

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
-- invisible against the white fill.  Font.drawBox fills its own interior
-- white and restores whatever colour it found, so black survives it.
function Header.draw(Font, label)
  love.graphics.setColor(0, 0, 0, 1)
  Font.drawBox(Header.BOX[1], Header.BOX[2], Header.BOX[3], Header.BOX[4])
  Header.leftArrow(Header.LEFT_X, Header.ARROW_Y)
  Header.rightArrow(Header.RIGHT_X, Header.ARROW_Y)
  Font.draw(label, Header.nameX(Font.width(label)), Header.TEXT_Y)
  love.graphics.setColor(1, 1, 1, 1)
end

return Header
