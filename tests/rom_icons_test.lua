-- Standalone: luajit mods/pokebag_plus/tests/rom_icons_test.lua
--
-- With POKEBAG_ROM_FIRERED, POKEBAG_ROM_LEAFGREEN and POKEBAG_ICON_REF set
-- (REF is a directory of the engine's own icons/N.rgba) it also compares all
-- 376 icons against the engine's extraction, byte for byte.
package.path = "./?.lua;./?/init.lua;" .. package.path
if not _G.love then _G.love = require("tests.love_stub") end

local T = require("tests.modkit")
local R = dofile("mods/pokebag_plus/RomIcons.lua")

local function le24(n) return string.char(n % 256, math.floor(n / 256) % 256, math.floor(n / 65536)) end

-- A stream with no back-references: header, then a zero flag byte before every
-- eight literals.
local function literals(s)
  local out = { string.char(0x10), le24(#s) }
  for i = 1, #s, 8 do
    out[#out + 1] = "\0" .. s:sub(i, i + 7)
  end
  return table.concat(out)
end

-- LZ77 ------------------------------------------------------------------
T.eq(R.lz77(literals("HELLO WORLD")), "HELLO WORLD", "literal-only data comes back unchanged")
T.eq(R.lz77("junk" .. literals("ab"), 5), "ab", "the stream can start part way into a buffer")
T.eq(R.lz77("\0\1\0\0"), nil, "a stream without the 0x10 header is refused")
T.eq(R.lz77(literals("ABCDEFGH"):sub(1, 8)), nil, "and so is one that ends early")

-- "AB" then a copy: flag 0b00100000 -> literal, literal, reference.  The
-- reference is len = 0x2 + 3 = 5, distance = 0x001 + 1 = 2, so it repeats the
-- last two bytes: ABABABA.
local withCopy = string.char(0x10) .. le24(7) .. string.char(0x20) .. "AB" .. string.char(0x20, 0x01)
T.eq(R.lz77(withCopy), "ABABABA", "a back-reference copies earlier output, overlapping itself")
local tooFar = string.char(0x10) .. le24(4) .. string.char(0x80) .. string.char(0x00, 0x05)
T.eq(R.lz77(tooFar), nil, "a reference to before the start is refused")

-- Decode ----------------------------------------------------------------
-- Palette: colour 1 = pure red (31,0,0), colour 2 = pure blue (0,0,31).
local function palette()
  local p = {}
  for c = 0, 15 do p[#p + 1] = string.char(0, 0) end
  p[2] = string.char(31, 0)             -- 0x001F
  p[3] = string.char(0, 31 * 4)         -- 0x7C00
  return table.concat(p)
end
local tiles = {}
for t = 1, 9 do tiles[t] = string.rep("\0", 32) end
-- tile 0, row 0, first byte: left pixel colour 1, right pixel colour 2
tiles[1] = string.char(0x21) .. string.rep("\0", 31)
-- tile 4 (the centre one), last row, last byte: left pixel 2, right pixel 0
tiles[5] = string.rep("\0", 31) .. string.char(0x02)
local rgba = R.decode(table.concat(tiles), palette())
T.eq(#rgba, 24 * 24 * 4, "an icon is 24x24 RGBA")
local function pixel(x, y) return { rgba:byte((y * 24 + x) * 4 + 1, (y * 24 + x) * 4 + 4) } end
T.eq(table.concat(pixel(0, 0), ","), "255,0,0,255", "the low nibble is the left pixel, colour 1 is red")
T.eq(table.concat(pixel(1, 0), ","), "0,0,255,255", "the high nibble is the right pixel, colour 2 is blue")
T.eq(pixel(2, 0)[4], 0, "colour 0 is transparent")
T.eq(table.concat(pixel(14, 15), ","), "0,0,255,255", "tile 4 is the centre of the 3x3, last row is y 15")
T.eq(pixel(15, 15)[4], 0, "and its other nibble is clear")
T.eq(#R.decode("", palette()), 24 * 24 * 4, "missing tile data pads with transparency")
T.eq(R.decode("", palette()):byte(4), 0, "and is clear")

-- A ROM ------------------------------------------------------------------
-- 16 icon slots are enough: the table lives at TABLE, the compressed icon and
-- palette follow.  Slot n's first pixel is colour 1 or 2 by parity.
local TABLE, GFX, PAL = 0x100, 0x400, 0x500
local function le32(n) return string.char(n % 256, math.floor(n / 256) % 256, math.floor(n / 65536) % 256, math.floor(n / 16777216)) end
local function gfxFor(colour)
  local t = { string.char(colour) .. string.rep("\0", 31) }
  for i = 2, 9 do t[i] = string.rep("\0", 32) end
  return literals(table.concat(t))
end
local rom = {}
local function put(at, s)
  for i = 1, #s do rom[at + i] = s:sub(i, i) end
end
local function build(slots)
  rom = {}
  for id = 0, slots - 1 do
    put(TABLE + id * 8, le32(0x08000000 + GFX + id * 0x200) .. le32(0x08000000 + PAL))
    put(GFX + id * 0x200, gfxFor(id % 2 == 0 and 1 or 2))
  end
  put(PAL, literals(palette()))
  local parts = {}
  for i = 1, 0x2000 do parts[i] = rom[i] or "\0" end
  return table.concat(parts)
end

local image = build(16)
local imported = { firered = "aa", leafgreen = "bb" }
local reads = 0
local function reader(rom_id, off, len)
  reads = reads + 1
  if rom_id ~= "firered" then return nil end
  if off + len > #image then len = #image - off end
  if off < 0 or len <= 0 then return nil end
  return image:sub(off + 1, off + len)
end
local saved = R.ROMS
R.ROMS = {
  { id = "firered", md5 = "aa", table = TABLE },
  { id = "firered", md5 = "cc", table = TABLE + 0x10 },    -- another revision of the same game
  { id = "leafgreen", md5 = "bb", table = TABLE },
}

local pv = R.new(reader, function(id) return imported[id] end)
T.eq(pv:available(), true, "with a readable ROM the source is available")
T.eq(pv.rom.id, "firered", "and it is the one that answered")
local n = reads
T.eq(pv:available(), true, "asked again")
T.eq(reads, n, "the answer is remembered and costs no read")
local a = pv:icon(4)
T.eq(#a, 24 * 24 * 4, "an icon comes back as 24x24 RGBA")
T.eq(a:byte(1), 255, "slot 4 is the red one")
T.eq(pv:icon(5):byte(3), 255, "slot 5 is the blue one")
n = reads
pv:icon(4)
T.eq(reads, n, "an icon is decoded once")
T.eq(pv:icon(200), nil, "a slot past the end of the table is nil")
T.eq(pv:icon(-1), nil, "as is a negative one")
T.eq(pv:icon(R.COUNT), nil, "and the first slot past the real count")

-- No ROM supplied, no panel.
local none = R.new(reader, function() return nil end)
T.eq(none:available(), false, "with no ROM supplied there is no panel")
T.eq(none:icon(4), nil, "and no icon")

-- A ROM that is imported but is another revision: the table address points at
-- garbage, so the Poke Ball probe fails and the source stays off.
image = string.rep("\0", 0x2000)
local wrong = R.new(reader, function(id) return imported[id] end)
T.eq(wrong:available(), false, "a ROM whose table is not where we expect gets no panel")
image = build(16)

-- FireRed is tried first; LeafGreen answers when it is the only one.
local lgOnly = R.new(function(id, off, len)
  return reader("firered", off, len)
end, function(id) return id == "leafgreen" and "bb" or nil end)
T.eq(lgOnly:available(), true, "a LeafGreen-only import turns the panel on")
T.eq(lgOnly.rom.id, "leafgreen", "and is the one used")

-- The table is chosen by the dump's MD5: the same game at another revision has
-- its table elsewhere, and a file with an unlisted MD5 is not read at all.
R.ROMS[2].table = TABLE + 0x800                -- the "cc" revision: nothing there
local rev = R.new(reader, function() return "cc" end)
T.eq(rev:available(), false, "a listed revision whose table address holds nothing fails the probe")
local other = R.new(reader, function() return "dd" end)
T.eq(other:available(), false, "a dump whose MD5 is not listed is never read")
local n2 = reads
other:icon(4)
T.eq(reads, n2, "and costs no reads")

-- Move the table for the "cc" revision only: "aa" no longer finds one, "cc" does.
local keep = image
image = image:sub(1, TABLE) .. string.rep("\0", 16 * 8) .. image:sub(TABLE + 16 * 8 + 1)
image = image:sub(1, TABLE + 0x800) .. keep:sub(TABLE + 1, TABLE + 16 * 8) .. image:sub(TABLE + 0x800 + 16 * 8 + 1)
T.eq(R.new(reader, function() return "cc" end):available(), true, "the other revision reads its own table")
T.eq(R.new(reader, function() return "aa" end):available(), false, "and the first revision no longer finds one")
image = keep

R.ROMS = saved
local byMd5 = {}
for _, r in ipairs(saved) do byMd5[r.md5] = r end
T.eq(#saved, 4, "both revisions of FireRed and of LeafGreen: Emerald is not read, its table is elsewhere")
T.eq(byMd5["e26ee0d44e809351c8ce2d73c7400cdd"].table, 0x3D4294, "FireRed 1.0's table address")
T.eq(byMd5["51901a6e40661b3914aa333c802e24e8"].table, 0x3D4304, "FireRed 1.1's table address, 0x70 on")
T.eq(byMd5["9d33a02159e018d09073e700e1fd10fd"].table, 0x3D4140, "LeafGreen 1.1's table address")
T.eq(byMd5["612ca9473451fa42b51d1711031ed5f6"].table, 0x3D40D0, "LeafGreen 1.0's table address")
T.eq(byMd5["612ca9473451fa42b51d1711031ed5f6"].table + 0x70, byMd5["9d33a02159e018d09073e700e1fd10fd"].table,
  "and it sits 0x70 before 1.1's, the same revision shift FireRed has")
T.eq(byMd5["e26ee0d44e809351c8ce2d73c7400cdd"].table + 0x70, byMd5["51901a6e40661b3914aa333c802e24e8"].table,
  "FireRed 1.0 sits 0x70 before 1.1")
T.eq(saved[1].id, "firered", "FireRed is tried first")

-- Against the real thing, when the ROMs are to hand ------------------------
local ref = os.getenv("POKEBAG_ICON_REF")
if ref then
  for _, game in ipairs({
  { "firered", "POKEBAG_ROM_FIRERED", "51901a6e40661b3914aa333c802e24e8" },
  { "firered", "POKEBAG_ROM_FIRERED_10", "e26ee0d44e809351c8ce2d73c7400cdd" },
  { "leafgreen", "POKEBAG_ROM_LEAFGREEN", "9d33a02159e018d09073e700e1fd10fd" },
  { "leafgreen", "POKEBAG_ROM_LEAFGREEN_10", "612ca9473451fa42b51d1711031ed5f6" },
}) do
    local path = os.getenv(game[2])
    local f = path and io.open(path, "rb")
    if f then
      local function read(_, off, len)
        f:seek("set", off)
        return f:read(len)
      end
      local real = R.new(read, function(id) return id == game[1] and game[3] or nil end)
      T.eq(real:available(), true, game[1] .. ": the real ROM is recognised")
      local same, bad = 0, {}
      for id = 0, R.COUNT - 1 do
        local rf = io.open(ref .. "/" .. id .. ".rgba", "rb")
        local want = rf and rf:read("*a")
        if rf then rf:close() end
        local got = real:icon(id)
        if got and want and got == want then same = same + 1
        else bad[#bad + 1] = id end
      end
      T.eq(same, R.COUNT, game[1] .. ": all 376 icons match the engine's extraction"
        .. (#bad > 0 and (" (first mismatch: " .. bad[1] .. ")") or ""))
      f:close()
    end
  end
end

T.finish("rom_icons")
