local modules = OhHaiMaulgar.modules
if modules.Db then return end

local M = {}
local api = modules.api
local BossType = modules.BossType
local RaidMarkType = modules.RaidMarkType
local raid_mark = modules.raid_mark

local DEFAULT_RAID_MARKS = {
  raid_mark( BossType.Kiggler, RaidMarkType.Star ),
  raid_mark( BossType.Blindeye, RaidMarkType.Skull ),
  raid_mark( BossType.Maulgar, RaidMarkType.Circle ),
  raid_mark( BossType.Olm, RaidMarkType.Cross ),
  raid_mark( BossType.Krosh, RaidMarkType.Square )
}

function M.new()
  local key = api.UnitName( "player" ) .. " - " .. api.GetRealmName()

  local function init()
    if not OhHaiMaulgarDb then
      OhHaiMaulgarDb = {}
      OhHaiMaulgarDb.char = {}
    end

    if not OhHaiMaulgarDb.char[ key ] then OhHaiMaulgarDb.char[ key ] = {} end
    if not OhHaiMaulgarDb.char[ key ].settings then OhHaiMaulgarDb.char[ key ].settings = {} end

    if not OhHaiMaulgarDb.char[ key ].boss_assignments then OhHaiMaulgarDb.char[ key ].boss_assignments = {} end
    if not OhHaiMaulgarDb.char[ key ].raid_marks then OhHaiMaulgarDb.char[ key ].raid_marks = DEFAULT_RAID_MARKS end
  end

  local function persist_boss_assignment( boss_type, role_type, index, player )
    OhHaiMaulgarDb.char[ key ].boss_assignments[ boss_type ] = OhHaiMaulgarDb.char[ key ].boss_assignments[ boss_type ] or {}
    OhHaiMaulgarDb.char[ key ].boss_assignments[ boss_type ][ role_type ] = OhHaiMaulgarDb.char[ key ].boss_assignments[ boss_type ][ role_type ] or {}
    OhHaiMaulgarDb.char[ key ].boss_assignments[ boss_type ][ role_type ][ index ] = player and
        { name = player.name, class = player.class, alive = player.alive, in_group = true } or nil
  end

  local function set_position( anchor, other_anchor, x, y )
    OhHaiMaulgarDb.char[ key ].settings.position = { anchor = anchor, other_anchor = other_anchor, x = x, y = y }
  end

  local function get_position()
    return OhHaiMaulgarDb.char[ key ].settings.position
  end

  local function get_boss_assignments()
    return OhHaiMaulgarDb.char[ key ].boss_assignments
  end

  local function get_boss_assignment( group_type, position )
    local assignments = get_boss_assignments()
    local group = assignments[ group_type ] or {}
    return group[ position ]
  end

  local function boss_assign( boss_type, role_type, index, player )
    persist_boss_assignment( boss_type, role_type, index, player )
  end

  local function boss_unassign( boss_type, role_type, index )
    persist_boss_assignment( boss_type, role_type, index )
  end

  local function persist_boss_assignments( boss_assignments )
    OhHaiMaulgarDb.char[ key ].boss_assignments = boss_assignments
  end

  local function get_raid_marks()
    return OhHaiMaulgarDb.char[ key ].raid_marks
  end

  local function persist_raid_marks( raid_marks )
    OhHaiMaulgarDb.char[ key ].raid_marks = raid_marks or DEFAULT_RAID_MARKS
  end

  local function get_locked()
    return OhHaiMaulgarDb.char[ key ].locked
  end

  local function set_locked( locked )
    OhHaiMaulgarDb.char[ key ].locked = locked
  end

  init()

  return {
    get_boss_assignments = get_boss_assignments,
    get_boss_assignment = get_boss_assignment,
    set_position = set_position,
    get_position = get_position,
    boss_assign = boss_assign,
    boss_unassign = boss_unassign,
    persist_boss_assignments = persist_boss_assignments,
    get_raid_marks = get_raid_marks,
    persist_raid_marks = persist_raid_marks,
    get_locked = get_locked,
    set_locked = set_locked
  }
end

modules.Db = M
return M
