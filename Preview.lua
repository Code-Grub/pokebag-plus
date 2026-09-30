-- The item preview: the highlighted item's Gen 3 icon in a small window that
-- reads as a tab off the left of the bag window.
--
-- The icons are FireRed's own, baked into the player's cache when they import
-- that ROM ("Bag & Items Graphics").  Nothing is bundled: a player who has
-- not imported FireRed gets no panel at all, and the bag looks as it always
-- did.  They are read from the firered/ tree by explicit path, because the
-- engine's usual accessor reads the ACTIVE game's cache and a Gen 1 session's
-- is Red's.
--
-- Files and the image builder are passed in so this has no engine dependency
-- and tests with dofile alone.

local Preview = {}

-- The box, in tiles: x 0..40, y 24..64.  Its right border is tile column 4,
-- which is the bag window's own left border (ITEM_BOX.tx = 4 in
-- src/ui/ListMenu.lua).  Drawn before the window, the window paints over that
-- edge and the two read as one shape.  That leaves tiles 1..3 of interior, 24
-- pixels, exactly one icon; the icon is full colour, so the caller marks its
-- rectangle with PaletteFX.markTrueColor or the palette pass flattens it to
-- four shades.
Preview.BOX = { 0, 3, 5, 5 }
Preview.SIZE = 24
Preview.ICON_X = 8
Preview.ICON_Y = (Preview.BOX[2] + 1) * 8

-- Gen 3's icon for "no such item" (a question mark), shown for anything
-- below that has no counterpart: badges, floors, the Pokedex.
Preview.UNKNOWN = 0

-- Gen 1 item id -> FireRed icon slot.  Checked icon by icon against the
-- extracted set, not from memory: the X items start at 73 because slot 72 is
-- empty, and the evolution stones run Moon 94 through Leaf 98.
Preview.ICON = {
  MASTER_BALL = 1, ULTRA_BALL = 2, GREAT_BALL = 3, POKE_BALL = 4, SAFARI_BALL = 5,
  POTION = 13, ANTIDOTE = 14, BURN_HEAL = 15, ICE_HEAL = 16, AWAKENING = 17,
  PARLYZ_HEAL = 18, FULL_RESTORE = 19, MAX_POTION = 20, HYPER_POTION = 21,
  SUPER_POTION = 22, FULL_HEAL = 23, REVIVE = 24, MAX_REVIVE = 25,
  FRESH_WATER = 26, SODA_POP = 27, LEMONADE = 28,
  ETHER = 34, MAX_ETHER = 35, ELIXER = 36, MAX_ELIXER = 37,
  HP_UP = 63, PROTEIN = 64, IRON = 65, CARBOS = 66, CALCIUM = 67,
  RARE_CANDY = 68, PP_UP = 69, ITEM_32 = 69,   -- the extractor names PP UP both ways
  GUARD_SPEC = 73, DIRE_HIT = 74, X_ATTACK = 75, X_DEFEND = 76, X_SPEED = 77,
  X_ACCURACY = 78, X_SPECIAL = 79, POKE_DOLL = 80,
  SUPER_REPEL = 83, MAX_REPEL = 84, ESCAPE_ROPE = 85, REPEL = 86,
  MOON_STONE = 94, FIRE_STONE = 95, THUNDER_STONE = 96, WATER_STONE = 97,
  LEAF_STONE = 98,
  NUGGET = 110, EXP_ALL = 182,
  COIN_CASE = 260, ITEMFINDER = 261, OLD_ROD = 262, GOOD_ROD = 263,
  SUPER_ROD = 264, S_S_TICKET = 265,
  OAKS_PARCEL = 349, POKE_FLUTE = 350, SECRET_KEY = 351, BIKE_VOUCHER = 352,
  GOLD_TEETH = 353, OLD_AMBER = 354, CARD_KEY = 355, LIFT_KEY = 356,
  HELIX_FOSSIL = 357, DOME_FOSSIL = 358, SILPH_SCOPE = 359, BICYCLE = 360,
  TOWN_MAP = 361,
}

-- Gen 3 has fifty TM discs (289..338) and eight HM discs (339..346), each
-- coloured by its move's type.  Gen 1's fifty TMs are different moves, so a
-- TM takes the disc of a Gen 3 TM of the same type rather than its own
-- number.  Gen 1 has no bug TM, and Gen 3 none for bug either: plain disc.
Preview.TYPE_DISC = {
  normal = 289 + 26, fighting = 289, flying = 289 + 39, poison = 289 + 5,
  ground = 289 + 25, rock = 289 + 36, ghost = 289 + 29, fire = 289 + 37,
  water = 289 + 17, grass = 289 + 21, electric = 289 + 23, psychic = 289 + 28,
  ice = 289 + 12, dragon = 289 + 1,
}
local HM_FIRST = 339

-- The icon slot for an item definition, or nil for no item.
function Preview.iconId(def, moves)
  if not def then return nil end
  local m = def.machine
  if m then
    if m.kind == "HM" then return HM_FIRST + m.number - 1 end
    local move = moves and moves[m.move]
    local type = move and move.type and tostring(move.type):lower()
    return Preview.TYPE_DISC[type] or Preview.TYPE_DISC.normal
  end
  return Preview.ICON[def.id] or Preview.UNKNOWN
end

function Preview.path(id)
  return ("firered/data/generated/gba/items/bag/icons/%d.rgba"):format(id)
end

-- env.read(path) -> bytes or nil;  env.image(bytes) -> an image or nil.
function Preview.new(env)
  return setmetatable({ env = env, cache = {} }, { __index = Preview })
end

-- Has the player imported FireRed?  Asked once per bag: a probe of one icon
-- that every import has (the Poke Ball), and the answer is kept.
function Preview:available()
  if self.ready == nil then
    self.ready = self.env.read(Preview.path(4)) ~= nil
  end
  return self.ready
end

-- The built image for an icon slot, or nil.  A miss is remembered as well as
-- a hit, so a missing icon costs one disk read, not one per frame.
function Preview:image(id)
  if not self:available() then return nil end
  local got = self.cache[id]
  if got ~= nil then return got or nil end
  local bytes = self.env.read(Preview.path(id))
  local img = nil
  -- RGBA, 24x24; anything shorter is not an icon
  if bytes and #bytes >= Preview.SIZE * Preview.SIZE * 4 then
    img = self.env.image(bytes)
  end
  self.cache[id] = img or false
  return img
end

return Preview
