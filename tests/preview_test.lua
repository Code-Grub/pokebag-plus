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
T.eq(#reads, 1, "so the disk is asked once")
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

-- A truncated file is not an icon.
local short = P.new({
  read = function() return "\1\2\3" end,
  image = function() error("must not be called") end,
})
T.eq(short:image(4), nil, "a short file is rejected before it reaches the image builder")

T.finish("preview")
