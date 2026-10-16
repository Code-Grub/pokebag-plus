-- Item icons, read straight out of a ROM the player supplied.
--
-- The manifest declares FireRed and LeafGreen as optional_imports, so the
-- launcher validates the dump, keeps a private copy for this mod, and hands
-- bytes back through mod.imports:read.  Nothing is bundled and nothing is
-- taken from the engine's own cache: a player who supplies neither ROM gets
-- no preview panel, and the bag looks as it always did.
--
-- Gen 3 keeps one pointer pair per item (graphics, palette) in a table;
-- both are LZ77-compressed.  An icon is 3x3 tiles of 4 bits per pixel, drawn
-- in a 16 colour palette whose colour 0 is transparent.  The layout follows
-- pret's item_icon_table, the same table the engine's importer reads.
--
-- read(id, offset, length) -> bytes or nil is passed in, so this tests with
-- dofile alone.  The decoders are exposed for the same reason.

local RomIcons = {}

RomIcons.SIZE = 24                         -- an icon is 24x24
RomIcons.COUNT = 376                       -- slots 0..375
local TILES = 9                            -- 3x3
local TILE_BYTES = 32                      -- 8x8 at 4 bits per pixel

-- Where sItemIconTable sits in each revision, keyed by the dump's MD5 because
-- the address differs between revisions of one game.  1.1 and LeafGreen were
-- found by locating the 376 pointer pairs in a real dump and matching every
-- icon against the engine's own extraction.  1.0 is the engine's own address
-- for that revision (its 1.1 table is 0x70 bytes later, which is how 1.1 was
-- derived).  LeafGreen 1.0 is the engine's LeafGreen profile for the same
-- symbol, which lands exactly 0x70 before the 1.1 table I checked.  A dump not
-- listed here simply gets no panel.
RomIcons.ROMS = {
  { id = "firered",   md5 = "e26ee0d44e809351c8ce2d73c7400cdd", table = 0x3D4294 },   -- FireRed 1.0 (U)
  { id = "firered",   md5 = "51901a6e40661b3914aa333c802e24e8", table = 0x3D4304 },   -- FireRed 1.1 (U)
  { id = "leafgreen", md5 = "612ca9473451fa42b51d1711031ed5f6", table = 0x3D40D0 },   -- LeafGreen 1.0 (U)
  { id = "leafgreen", md5 = "9d33a02159e018d09073e700e1fd10fd", table = 0x3D4140 },   -- LeafGreen 1.1 (U)
}

-- GBA LZ77 (BIOS type 0x10).  `data` is a string and `pos` the 1-based index
-- of the 0x10 header byte.  Returns the decompressed string, or nil when the
-- header is not LZ77 or the stream runs out.
function RomIcons.lz77(data, pos)
  pos = pos or 1
  if data:byte(pos) ~= 0x10 then return nil end
  local b1, b2, b3 = data:byte(pos + 1, pos + 3)
  if not b3 then return nil end
  local size = b1 + b2 * 256 + b3 * 65536
  local out, n = {}, 0
  local i = pos + 4
  while n < size do
    local flags = data:byte(i)
    if not flags then return nil end
    i = i + 1
    for bit = 7, 0, -1 do
      if n >= size then break end
      if flags >= 2 ^ bit then
        flags = flags - 2 ^ bit
        -- a back-reference: 4 bit length (+3), 12 bit distance (+1)
        local hi, lo = data:byte(i, i + 1)
        if not lo then return nil end
        i = i + 2
        local len = math.floor(hi / 16) + 3
        local dist = (hi % 16) * 256 + lo + 1
        if dist > n then return nil end
        for _ = 1, len do
          if n >= size then break end
          out[n + 1] = out[n + 1 - dist]
          n = n + 1
        end
      else
        local byte = data:byte(i)
        if not byte then return nil end
        i = i + 1
        n = n + 1
        out[n] = byte
      end
    end
  end
  for k = 1, n do out[k] = string.char(out[k]) end
  return table.concat(out)
end

-- 15 bit BGR to 8 bit RGB, rounded the way the engine's importer rounds.
local function rgb(c)
  c = c % 32768
  return math.floor((c % 32) * 255 / 31 + 0.5),
    math.floor(math.floor(c / 32) % 32 * 255 / 31 + 0.5),
    math.floor(math.floor(c / 1024) % 32 * 255 / 31 + 0.5)
end

-- 3x3 tiles of 4bpp pixels plus a 16 entry palette -> 24x24 RGBA bytes.
-- Colour 0 is transparent.  Short input is padded with colour 0 rather than
-- refused: a corrupt icon should look empty, not stop the bag.
function RomIcons.decode(tiles, palette)
  local W = RomIcons.SIZE
  local colour = {}
  for c = 1, 15 do
    local lo, hi = palette:byte(c * 2 + 1, c * 2 + 2)
    local r, g, b = rgb((lo or 0) + (hi or 0) * 256)
    colour[c] = string.char(r, g, b, 255)
  end
  local clear = string.char(0, 0, 0, 0)
  local px = {}
  for tile = 0, TILES - 1 do
    local tx, ty = tile % 3, math.floor(tile / 3)
    for row = 0, 7 do
      for bx = 0, 3 do
        local byte = tiles:byte(tile * TILE_BYTES + row * 4 + bx + 1) or 0
        local left, right = byte % 16, math.floor(byte / 16)
        local at = (ty * 8 + row) * W + tx * 8 + bx * 2 + 1
        px[at] = colour[left] or clear
        px[at + 1] = colour[right] or clear
      end
    end
  end
  return table.concat(px)
end

local function pointer(bytes, at)
  local a, b, c, d = bytes:byte(at, at + 3)
  if not d or d ~= 0x08 then return nil end        -- ROM space only
  return a + b * 256 + c * 65536
end

-- read(id, offset, length) -> bytes or nil;  md5Of(id) -> the supplied file's
-- lowercase MD5, or nil/false when none was supplied.
function RomIcons.new(read, md5Of)
  return setmetatable({ read = read, md5Of = md5Of, cache = {} },
    { __index = RomIcons })
end

-- One slot of the pointer table -> the two ROM offsets, or nil.
function RomIcons:entry(rom, id)
  local bytes = self.read(rom.id, rom.table + id * 8, 8)
  if not bytes or #bytes < 8 then return nil end
  local gfx, pal = pointer(bytes, 1), pointer(bytes, 5)
  if not (gfx and pal) then return nil end
  return gfx, pal
end

-- Both streams are compressed and their length is not recorded, so a window
-- is read and the decoder takes what it needs.  300 bytes holds a 288 byte
-- icon even if it does not compress; the palette is 32.
local WINDOW = 512

function RomIcons:bake(rom, id)
  local gfxAt, palAt = self:entry(rom, id)
  if not gfxAt then return nil end
  local gfxBytes = self.read(rom.id, gfxAt, WINDOW)
  local palBytes = self.read(rom.id, palAt, WINDOW)
  if not (gfxBytes and palBytes) then return nil end
  local tiles = RomIcons.lz77(gfxBytes)
  local palette = RomIcons.lz77(palBytes)
  if not (tiles and palette) then return nil end
  return RomIcons.decode(tiles, palette)
end

-- Has the player supplied a ROM this can read?  Asked once per bag: the first
-- listed ROM whose supplied file has that MD5 and whose Poke Ball slot (4)
-- decodes wins, and the answer is kept.  The probe is a second line of
-- defence: it catches an address that is wrong for a dump the MD5 matched.
function RomIcons:available()
  if self.ready == nil then
    self.ready = false
    for _, rom in ipairs(RomIcons.ROMS) do
      if self.md5Of(rom.id) == rom.md5 and self:bake(rom, 4) then
        self.ready, self.rom = true, rom
        break
      end
    end
  end
  return self.ready
end

-- 24x24 RGBA bytes for an icon slot, or nil.  A miss is remembered as well
-- as a hit, so a bad slot costs three reads, not three per frame.
function RomIcons:icon(id)
  if not self:available() then return nil end
  local got = self.cache[id]
  if got ~= nil then return got or nil end
  local bytes = id >= 0 and id < RomIcons.COUNT and self:bake(self.rom, id) or nil
  self.cache[id] = bytes or false
  return bytes
end

return RomIcons
