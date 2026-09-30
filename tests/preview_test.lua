-- Standalone: luajit mods/pokebag_plus/tests/preview_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
if not _G.love then _G.love = require("tests.love_stub") end

local T = require("tests.modkit")
local P = dofile("mods/pokebag_plus/Preview.lua")

-- Geometry.  The panel is a tab off the bag window: its box runs into the
-- window's left border (tile column 4, src/ui/ListMenu.lua ITEM_BOX.tx), so
-- the window paints over the box's right edge and only three interior tiles
-- are left, which is exactly one 24px Gen 3 icon.
local ITEM_BOX_TX = 4
T.eq(P.BOX[1], 0, "the box starts at the screen edge")
T.eq(P.BOX[3], ITEM_BOX_TX + 1, "and runs one tile into the window's left border")
T.eq((P.BOX[3] - 2) * 8, P.SIZE, "leaving an interior exactly one icon wide")
T.eq((P.BOX[4] - 2) * 8, P.SIZE, "and one icon tall")
T.eq(P.ICON_X, 8, "the icon sits inside the left border")
T.eq(P.ICON_Y, (P.BOX[2] + 1) * 8, "and inside the top border")

-- Id table: every mapped id is a real Gen 3 icon slot.
for gen1, gen3 in pairs(P.ICON) do
  T.check(gen3 >= 1 and gen3 <= 375, gen1 .. " maps inside the icon table")
end
T.eq(P.ICON.POKE_BALL, 4, "POKE BALL")
T.eq(P.ICON.POTION, 13, "POTION")
T.eq(P.ICON.RARE_CANDY, 68, "RARE CANDY")
T.eq(P.ICON.GUARD_SPEC, 73, "the X items start after the unused slot at 72")
T.eq(P.ICON.POKE_DOLL, 80, "and POKE DOLL follows them")
T.eq(P.ICON.MOON_STONE, 94, "stones start at MOON STONE")
T.eq(P.ICON.LEAF_STONE, 98, "and end at LEAF STONE")
T.eq(P.ICON.BICYCLE, 360, "the FRLG key items sit after the shared list")

-- Machines: HMs by number, TMs by the move's type.
local function machine(kind, number, move)
  return { id = kind .. number, machine = { kind = kind, number = number, move = move } }
end
local moves = { CUT = { type = "NORMAL" }, FLY = { type = "FLYING" },
                TOXIC = { type = "POISON" }, HYPER_BEAM = { type = "NORMAL" },
                FIRE_BLAST = { type = "FIRE" }, MYSTERY = { type = "???" } }
T.eq(P.iconId(machine("HM", 1, "CUT"), moves), 339, "HM01 is the first HM disc")
T.eq(P.iconId(machine("HM", 5, "FLASH"), moves), 343, "HM05 is the fifth")
T.eq(P.iconId(machine("TM", 6, "TOXIC"), moves), P.TYPE_DISC.poison, "a poison TM gets the poison disc")
T.eq(P.iconId(machine("TM", 38, "FIRE_BLAST"), moves), P.TYPE_DISC.fire, "a fire TM gets the fire disc")
T.eq(P.iconId(machine("TM", 99, "MYSTERY"), moves), P.TYPE_DISC.normal, "an unknown type falls back to the plain disc")
T.eq(P.iconId(machine("TM", 99, "NOPE"), moves), P.TYPE_DISC.normal, "as does a move with no data")
for type, id in pairs(P.TYPE_DISC) do
  T.check(id >= 289 and id <= 338, type .. " disc is one of the 50 TM icons")
end

-- Anything the table does not know shows Gen 3's own unknown-item icon.
T.eq(P.iconId({ id = "BOULDERBADGE" }, moves), P.UNKNOWN, "an unmapped item shows the unknown icon")
T.eq(P.UNKNOWN, 0, "which is slot 0")
T.eq(P.iconId(nil, moves), nil, "no item, no icon")

-- Availability: the panel exists only when the player has imported FireRed.
local reads, images = {}, 0
local function fixture(have)
  reads, images = {}, 0
  return P.new({
    read = function(path)
      reads[#reads + 1] = path
      return have[path] and string.rep("\1", 24 * 24 * 4) or nil
    end,
    image = function(bytes)
      images = images + 1
      return { bytes = bytes }
    end,
  })
end

local none = fixture({})
T.eq(none:available(), false, "no cache, no panel")
T.eq(none:available(), false, "and the answer is remembered")
T.eq(#reads, #P.ROOTS + 1, "so the disk is asked once per source, and never again")
T.eq(none:image(4), nil, "nothing is loaded without a cache")
T.eq(images, 0, "no image is built")

local have = fixture({ [P.path(4)] = true, [P.path(13)] = true })
T.eq(have:available(), true, "with the cache present the panel is on")
T.eq(P.path(4), "firered/data/generated/gba/items/bag/icons/4.rgba",
  "icons are read from the FireRed cache, not the active game's")
local a = have:image(13)
T.check(a ~= nil, "a present icon loads")
T.eq(have:image(13), a, "and is built once")
T.eq(images, 1, "one image")
T.eq(have:image(14), nil, "an absent icon is nil")
have:image(14)
local misses = 0
for _, r in ipairs(reads) do if r == P.path(14) then misses = misses + 1 end end
T.eq(misses, 1, "and the miss is remembered too")

-- LeafGreen has the same icons (byte for byte: all 376 compared) under its own
-- cache folder, so a player who imported only that gets the panel too.
T.eq(P.path(4, "leafgreen"), "leafgreen/data/generated/gba/items/bag/icons/4.rgba",
  "LeafGreen's icons live under its own prefix")
local lg = fixture({ [P.path(4, "leafgreen")] = true, [P.path(13, "leafgreen")] = true })
T.eq(lg:available(), true, "a LeafGreen-only import turns the panel on")
T.check(lg:image(13) ~= nil, "and its icons load from the leafgreen tree")
local lgOnly = {}
for _, r in ipairs(reads) do lgOnly[#lgOnly + 1] = r end
T.eq(lgOnly[#lgOnly], P.path(13, "leafgreen"), "the icon is read from the tree that answered the probe")

local both = fixture({ [P.path(4)] = true, [P.path(4, "leafgreen")] = true,
                       [P.path(13)] = true, [P.path(13, "leafgreen")] = true })
T.eq(both:available(), true, "with both imported the panel is on")
both:image(13)
T.eq(reads[#reads], P.path(13), "and FireRed's tree wins")

-- Emerald keeps its icons as ONE strip, 24 wide and 24 * count tall, in
-- emerald/.../rse/bag/icons.rgba.  Icon n is the n-th 24x24 slice.
local SLICE = 24 * 24 * 4
local function strip(count)
  local parts = {}
  for i = 0, count - 1 do parts[#parts + 1] = string.rep(string.char(i % 256), SLICE) end
  return table.concat(parts)
end
local function emerald(count)
  reads, images = {}, 0
  local bytes = strip(count or 377)
  local got = {}
  local pv = P.new({
    read = function(path)
      reads[#reads + 1] = path
      return path == P.STRIP and bytes or nil
    end,
    image = function(b) got[#got + 1] = b return { bytes = b } end,
  })
  return pv, got
end

local em, got = emerald()
T.eq(P.STRIP, "emerald/data/generated/gba/rse/bag/icons.rgba", "Emerald's strip lives in its own rse tree")
T.eq(em:available(), true, "an Emerald-only import turns the panel on")
em:image(13)
T.eq(#got[1], SLICE, "an icon is one 24x24 slice of the strip")
T.eq(got[1]:byte(1), 13, "and it is slice 13, not slice 0")
T.eq(got[1]:byte(SLICE), 13, "through to its last byte")
em:image(100); em:image(100)
T.eq(#got, 2, "each icon is built once")
local strips = 0
for _, r in ipairs(reads) do if r == P.STRIP then strips = strips + 1 end end
T.eq(strips, 1, "and the strip itself is read once")

-- Emerald's table carries FireRed's key items in the same slots (checked
-- against a real Emerald import), so the same ids are read, 349 and up included.
em:image(349); em:image(360)
T.eq(got[#got - 1]:byte(1), 349 % 256, "a FRLG key item is read from its own slot in Emerald's strip")
T.eq(got[#got]:byte(1), 360 % 256, "and so is the bicycle")
T.eq(P.ICON.OAKS_PARCEL, 349, "OAKS PARCEL")
T.eq(P.ICON.TOWN_MAP, 361, "TOWN MAP")

local tiny = P.new({
  read = function(path) return path == P.STRIP and string.rep("", SLICE) or nil end,
  image = function() error("must not be called") end,
})
T.eq(tiny:available(), false, "a strip too short to hold the probe icon is not an import")

-- FireRed wins over Emerald when both exist.
local mixed = P.new({
  read = function(path)
    if path == P.path(4) then return string.rep("", SLICE) end
    if path == P.STRIP then return strip(377) end
  end,
  image = function(b) return { bytes = b } end,
})
T.eq(mixed:available(), true, "with both the panel is on")
T.eq(mixed.root, "firered", "and FireRed's tree is the one used")

-- A truncated file is not an icon.
local short = P.new({
  read = function() return "\1\2\3" end,
  image = function() error("must not be called") end,
})
T.eq(short:image(4), nil, "a short file is rejected before it reaches the image builder")

T.finish("preview")
