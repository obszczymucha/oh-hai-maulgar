local M = {}

OhHaiMaulgar.debug = false
OhHaiMaulgar.mock_data = false
local mocked_player_list = nil

local modules = OhHaiMaulgar.modules
local api = modules.api
local pretty_print = modules.pretty_print
local filter = modules.filter
local red = modules.colors.red
local contains = modules.contains
local BossType = modules.BossType
local RoleType = modules.RoleType
local announce_rw = modules.announce_rw
local announce = modules.announce
local mark_map = modules.mark_map
local chat_marker = modules.get_raid_mark_chat_marker_by_type
local chat_icon = modules.get_frame_icon_by_type
local ok = modules.Validation.ok
local warning = modules.Validation.warning
local warning_entry = modules.Validation.warning_entry
local error = modules.Validation.error
local ErrorType = modules.ErrorType
local WarningType = modules.WarningType
local get_default_raid_mark = modules.get_default_raid_mark
local find_raid_leader = modules.find_raid_leader
local can_use_raid_warning = modules.can_use_raid_warning

local function mock_player_list()
  local result = {
    [ "Ohhaimark" ] = { class = "Warrior", alive = true, ghost = false, offline = false, unit = "raid1" },
    [ "Obszczymucha" ] = { class = "Druid", alive = true, ghost = false, offline = false, unit = "raid2" },
    [ "Leszarom" ] = { class = "Shaman", alive = true, ghost = false, offline = false, unit = "raid3" },
    [ "Sylveon" ] = { class = "Priest", alive = true, ghost = false, offline = false, unit = "raid4" },
    [ "Prestr" ] = { class = "Priest", alive = true, ghost = false, offline = false, unit = "raid5" },
    [ "Freira" ] = { class = "Priest", alive = true, ghost = false, offline = false, unit = "raid6" },
    [ "Gigamag" ] = { class = "Mage", alive = true, ghost = false, offline = false, unit = "raid7" },
    [ "Snappy" ] = { class = "Shaman", alive = true, ghost = false, offline = false, unit = "raid8" },
    [ "Punishher" ] = { class = "Warlock", alive = true, ghost = false, offline = false, unit = "raid9" },
    [ "Ehwapi" ] = { class = "Druid", alive = true, ghost = false, offline = false, unit = "raid10" },
    [ "Iriasus" ] = { class = "Mage", alive = true, ghost = false, offline = false, unit = "raid11" },
    [ "Hituhard" ] = { class = "Shaman", alive = true, ghost = false, offline = false, unit = "raid12" },
    [ "Meserschmitt" ] = { class = "Hunter", alive = true, ghost = false, offline = false, unit = "raid13" },
    [ "Elzabour" ] = { class = "Hunter", alive = true, ghost = false, offline = false, unit = "raid14" },
    [ "Peter" ] = { class = "Druid", alive = true, ghost = false, offline = false, unit = "raid15" },
    [ "Baltrig" ] = { class = "Shaman", alive = true, ghost = false, offline = false, unit = "raid16" },
    [ "Nardiyo" ] = { class = "Paladin", alive = true, ghost = false, offline = false, unit = "raid17" },
    [ "Justacow" ] = { class = "Druid", alive = true, ghost = false, offline = false, unit = "raid18" },
    [ "Chigg" ] = { class = "Hunter", alive = true, ghost = false, offline = false, unit = "raid19" },
    [ "Odb" ] = { class = "Warlock", alive = true, ghost = false, offline = false, unit = "raid20" },
    [ "Coccolinko" ] = { class = "Shaman", alive = true, ghost = false, offline = false, unit = "raid21" },
    [ "Galanyr" ] = { class = "Rogue", alive = true, ghost = false, offline = false, unit = "raid22" },
    [ "Hadezh" ] = { class = "Warlock", alive = true, ghost = false, offline = false, unit = "raid23" },
    [ "Renaissancee" ] = { class = "Warlock", alive = true, ghost = false, offline = false, unit = "raid24" },
  }

  local my_name = api.UnitName( "player" )

  if not result[ my_name ] then
    result[ my_name ] = { class = api.UnitClass( "player" ), alive = true, ghost = false, offline = false, unit = "raid25" }
  end

  MAGS = result
  return result
end

local function get_players()
  local players = M.group_roster.get_players()
  local result = {}

  for name, details in pairs( players ) do
    table.insert( result, {
      name = name,
      class = details.class,
      in_group = true,
      alive = details.alive
    } )
  end

  return result
end

local function get_boss_assignees( all_assignments, boss_type )
  local result = {}

  for boss, role_types in pairs( all_assignments ) do
    if boss == boss_type then
      for _, indexes in pairs( role_types ) do
        for _, player in pairs( indexes ) do
          table.insert( result, player.name )
        end
      end
    end
  end

  return result
end

local function get_role_assignees( all_assignments, role_type, boss_type )
  local result = {}

  for boss, role_types in pairs( all_assignments ) do
    for role, indexes in pairs( role_types ) do
      if role == role_type and (not boss_type or boss_type == boss) then
        for _, player in pairs( indexes ) do
          table.insert( result, player.name )
        end
      end
    end
  end

  return result
end

local function sort_by_class_in_order( t, order )
  table.sort( t,
    function( l, r )
      if l.class == r.class then
        return l.name < r.name
      else
        local left_ordering = order[ string.lower( l.class ) ] or -1
        local right_ordering = order[ string.lower( r.class ) ] or -1

        return left_ordering < right_ordering
      end
    end )
end

local function one_of_classes( ... )
  local classes = { ... }

  return function( player )
    return player.class and contains( classes, string.lower( player.class ) ) or false
  end
end

local function olm_tank_candidates()
  local order = { druid = 1, paladin = 2, warrior = 3, warlock = 4 }
  local assignments = M.db.get_boss_assignments()
  local all_candidates = filter( get_players(), one_of_classes( "warrior", "druid", "paladin", "warlock" ) ) or {}
  local current_group_assignments = get_boss_assignees( assignments, BossType.Olm )
  local not_assigned_in_the_group = filter( all_candidates, function( v ) return not contains( current_group_assignments, v.name ) end )
  local assigned_as_tank = get_role_assignees( assignments, RoleType.Tank )
  local not_assigned = filter( not_assigned_in_the_group, function( v ) return not contains( assigned_as_tank, v.name ) end )
  sort_by_class_in_order( not_assigned, order )
  return not_assigned
end

local function sort_by_name( t )
  table.sort( t, function( l, r ) return l.name < r.name end )
end

local function mage_candidates()
  local candidates = filter( get_players(), one_of_classes( "mage" ) ) or {}
  sort_by_name( candidates )
  return candidates
end

local function misdirect_candidates()
  local all_candidates = filter( get_players(), one_of_classes( "hunter" ) ) or {}
  local assignments = M.db.get_boss_assignments()
  local currently_assigned = get_role_assignees( assignments, RoleType.MD )
  local not_assigned = filter( all_candidates, function( v ) return not contains( currently_assigned, v.name ) end )
  local is_tanking = get_role_assignees( assignments, RoleType.Tank, BossType.Kiggler )
  local not_tanking = filter( not_assigned, function( v ) return not contains( is_tanking, v.name ) end )
  sort_by_name( not_tanking )
  return not_tanking
end

local function kiggler_tank_candidates()
  local order = { hunter = 1, druid = 2 }
  local assignments = M.db.get_boss_assignments()
  local all_candidates = filter( get_players(), one_of_classes( "hunter", "druid" ) ) or {}
  local currently_assigned = get_boss_assignees( assignments, BossType.Kiggler )
  local not_assigned = filter( all_candidates, function( v ) return not contains( currently_assigned, v.name ) end )
  local misdirecting = get_role_assignees( assignments, RoleType.MD )
  local not_misdirecting = filter( not_assigned, function( v ) return not contains( misdirecting, v.name ) end )
  sort_by_class_in_order( not_misdirecting, order )
  return not_misdirecting
end

local function healer_candidates( boss_type )
  local order = { priest = 1, druid = 2, paladin = 3, shaman = 4 }
  local all_candidates = filter( get_players(), one_of_classes( "priest", "druid", "paladin", "shaman" ) ) or {}
  local currently_assigned = get_boss_assignees( M.db.get_boss_assignments(), boss_type )
  local not_assigned = filter( all_candidates, function( v ) return not contains( currently_assigned, v.name ) end )
  sort_by_class_in_order( not_assigned, order )
  return not_assigned
end

local function tank_candidates( boss_type )
  local order = { warrior = 1, druid = 2, paladin = 3 }
  local assignments = M.db.get_boss_assignments()
  local all_candidates = filter( get_players(), one_of_classes( "warrior", "druid", "paladin" ) ) or {}
  local current_group_assignments = get_boss_assignees( assignments, boss_type )
  local not_assigned_in_the_group = filter( all_candidates, function( v ) return not contains( current_group_assignments, v.name ) end )
  local assigned_as_tank = get_role_assignees( assignments, RoleType.Tank )
  local not_assigned = filter( not_assigned_in_the_group, function( v ) return not contains( assigned_as_tank, v.name ) end )
  sort_by_class_in_order( not_assigned, order )
  return not_assigned
end

local function on_assign( frame, boss_type, role_type, index )
  local candidates =
      boss_type == BossType.Kiggler and role_type == RoleType.Tank and kiggler_tank_candidates()
      or boss_type == BossType.Krosh and role_type == RoleType.Tank and mage_candidates()
      or boss_type == BossType.Olm and role_type == RoleType.Tank and olm_tank_candidates()
      or role_type == RoleType.Tank and tank_candidates( boss_type )
      or role_type == RoleType.Healer and healer_candidates( boss_type )
      or role_type == RoleType.MD and misdirect_candidates()

  if not candidates then
    pretty_print( "ERROR: I fucked up lol :P", red )
    return false
  end

  if #candidates == 0 then
    pretty_print( "No assignment candidates found.", red )
    return false
  end

  M.player_list_gui.show( frame, candidates, function( player )
    M.db.boss_assign( boss_type, role_type, index, player )
    M.boss_gui.update()
  end )

  return true
end

local function on_unassign( boss_type, role_type, index )
  M.db.boss_unassign( boss_type, role_type, index )
  M.boss_gui.update()
end

function M.update_player_status()
  local players = M.group_roster.get_players()
  local boss_assignments = M.db.get_boss_assignments()

  for _, data in pairs( boss_assignments ) do
    for _, indexes in pairs( data ) do
      for _, player in pairs( indexes ) do
        local player_details = players[ player.name ]
        player.in_group = player_details and true or false

        if player_details then
          player.alive = player_details.alive
          player.offline = player_details.offline
        else
          player.alive = nil
          player.offline = nil
        end
      end
    end
  end

  M.db.persist_boss_assignments( boss_assignments )
  M.boss_gui.update()
end

local function count_misdirects( assignments )
  local result = 0

  for _, role_types in pairs( assignments ) do
    for role_type, players in pairs( role_types ) do
      if role_type == RoleType.MD and players[ 1 ] and players[ 1 ].in_group then result = result + 1 end
    end
  end

  return result
end

local function beg_for_assistant()
  local leader = find_raid_leader()

  if not leader then
    pretty_print( "Can't find the raid leader.", red )
    return
  end

  api.SendChatMessage( "Please give me an assistant.", "WHISPER", nil, leader )
end

local function marker( raid_mark_type )
  if api.IsInRaid() or api.IsInParty() then
    return chat_marker( raid_mark_type )
  else
    return chat_icon( raid_mark_type )
  end
end

local function announce_tank_and_heal_assignments()
  local assignments = M.db.get_boss_assignments()
  local tanks_healers = {}
  local misdirect_count = count_misdirects( assignments )

  if api.IsInRaid() and not can_use_raid_warning() then
    beg_for_assistant()
    return
  end

  local function create_announcement( boss_type )
    local roles = assignments[ boss_type ]
    local raid_mark = marker( get_default_raid_mark( boss_type ) )

    local tank1 = roles[ RoleType.Tank ] and roles[ RoleType.Tank ][ 1 ]
    local tank2 = roles[ RoleType.Tank ] and roles[ RoleType.Tank ][ 2 ]
    local tanks = tank1 and tank2 and string.format( "%s + %s", tank1.name, tank2.name ) or tank1 and tank1.name or tank2 and tank2.name
    local healer1 = roles[ RoleType.Healer ] and roles[ RoleType.Healer ][ 1 ]
    local healer2 = roles[ RoleType.Healer ] and roles[ RoleType.Healer ][ 2 ]
    local healers = healer1 and healer2 and string.format( "%s + %s", healer1.name, healer2.name ) or healer1 and healer1.name or healer2 and healer2.name
    table.insert( tanks_healers, string.format( "%s %s healed by %s.", raid_mark, tanks, healers ) )
  end

  create_announcement( BossType.Kiggler )
  create_announcement( BossType.Blindeye )
  create_announcement( BossType.Maulgar )
  create_announcement( BossType.Olm )
  create_announcement( BossType.Krosh )

  announce_rw( string.format( "Tank + healer assignments" ) )

  for _, message in ipairs( tanks_healers ) do
    announce( message )
  end

  if misdirect_count == 0 then
    announce( "There will be no misdirects." )
  end
end

local function announce_misdirect_assignments()
  local assignments = M.db.get_boss_assignments()
  local mds = {}

  if api.IsInRaid() and not can_use_raid_warning() then
    beg_for_assistant()
    return
  end

  local function create_announcement( boss_type )
    local roles = assignments[ boss_type ]
    local raid_mark = marker( get_default_raid_mark( boss_type ) )

    local tank1 = roles[ RoleType.Tank ] and roles[ RoleType.Tank ][ 1 ]
    local tank2 = roles[ RoleType.Tank ] and roles[ RoleType.Tank ][ 2 ]
    local md = roles[ RoleType.MD ] and roles[ RoleType.MD ][ 1 ]

    if md and md.in_group then
      table.insert( mds, string.format( "%s MD %s to %s.", md.name, raid_mark, tank1 and tank1.name or tank2 and tank2.name ) )
    end
  end

  create_announcement( BossType.Kiggler )
  create_announcement( BossType.Blindeye )
  create_announcement( BossType.Maulgar )
  create_announcement( BossType.Olm )
  create_announcement( BossType.Krosh )

  if #mds > 0 then
    announce_rw( string.format( "Misdirection assignment%s", #mds > 1 and "s" or "" ) )

    for _, message in ipairs( mds ) do
      announce( message )
    end

    return
  end
end

local function announce_melee_kill_order()
  local marks = mark_map( M.db.get_raid_marks() )

  local blindeye = marker( marks[ BossType.Blindeye ] )
  local olm = marker( marks[ BossType.Olm ] )
  local kiggler = marker( marks[ BossType.Kiggler ] )
  local maulgar = marker( marks[ BossType.Maulgar ] )

  if api.IsInRaid() and not can_use_raid_warning() then
    beg_for_assistant()
    return
  end

  announce_rw( "Melee kill order" )
  announce( string.format( "%s -> %s -> %s -> %s (includes hunter pets)", blindeye, olm, kiggler, maulgar ) )
end

local function validate_setup()
  local assignments = M.db.get_boss_assignments()
  local errors = {}
  local warnings = {}
  local misdirect_count = count_misdirects( assignments )
  local available_misdirects = misdirect_candidates()
  local available_misdirect_count = #available_misdirects

  local function validate_double_tank( boss_type )
    local tanks = assignments[ boss_type ] and assignments[ boss_type ][ RoleType.Tank ]

    if not tanks or ((not tanks[ 1 ] or tanks[ 1 ] and not tanks[ 1 ].in_group) and (not tanks[ 2 ] or tanks[ 2 ] and not tanks[ 2 ].in_group)) then
      table.insert( errors, error( boss_type, ErrorType.NoTank, available_misdirect_count ) )
    end
  end

  local function validate( boss_type, role_type )
    local roles = assignments[ boss_type ] and assignments[ boss_type ][ role_type ]

    if not roles or (not roles[ 1 ]) or (roles[ 1 ] and not roles[ 1 ].in_group) then
      table.insert( errors, error( boss_type, role_type == RoleType.Tank and ErrorType.NoTank or ErrorType.NoHealer, available_misdirect_count ) )
    end
  end

  local function validate_either( boss_type, role_type )
    local roles = assignments[ boss_type ] and assignments[ boss_type ][ role_type ]

    if not roles or (not roles[ 1 ] and not roles[ 2 ]) or (roles[ 1 ] and not roles[ 1 ].in_group and roles[ 2 ] and not roles[ 2 ].in_group) then
      table.insert( errors, error( boss_type, role_type == RoleType.Tank and ErrorType.NoTank or ErrorType.NoHealer, available_misdirect_count ) )
    end
  end

  local function validate_double_healer()
    local boss_type = BossType.Maulgar
    local tanks = assignments[ boss_type ] and assignments[ boss_type ][ RoleType.Healer ]

    if not tanks or (not tanks[ 1 ]) or (not tanks[ 2 ]) or (tanks[ 1 ] and not tanks[ 1 ].in_group) or (tanks[ 2 ] and not tanks[ 2 ].in_group) then
      table.insert( warnings, warning_entry( boss_type, WarningType.OneHealer ) )
    end
  end

  local function validate_hunter_tanks()
    local boss_type = BossType.Kiggler
    local tanks = assignments[ boss_type ] and assignments[ boss_type ][ RoleType.Tank ]
    if not tanks then return end

    if tanks[ 1 ] and tanks[ 1 ].in_group and tanks[ 1 ].class == "Hunter" and (not tanks[ 2 ] or tanks[ 2 ] and not tanks[ 2 ].in_group)
        or tanks[ 2 ] and tanks[ 2 ].in_group and tanks[ 2 ].class == "Hunter" and (not tanks[ 1 ] or tanks[ 1 ] and not tanks[ 1 ].in_group) then
      table.insert( warnings, warning_entry( BossType.Kiggler, WarningType.OneHunter ) )
    end
  end

  local function validate_unassigned_misdirects()
    if #available_misdirects > 0 and misdirect_count < 4 then
      table.insert( warnings, warning_entry( nil, WarningType.UnassignedMisdirect ) )
    end
  end


  validate_double_tank( BossType.Kiggler )
  validate( BossType.Blindeye, RoleType.Tank )
  validate( BossType.Maulgar, RoleType.Tank )
  validate_double_tank( BossType.Olm )
  validate( BossType.Krosh, RoleType.Tank )
  validate( BossType.Kiggler, RoleType.Healer )
  validate( BossType.Blindeye, RoleType.Healer )
  validate_either( BossType.Maulgar, RoleType.Healer )
  validate( BossType.Olm, RoleType.Healer )
  validate( BossType.Krosh, RoleType.Healer )
  validate_double_healer()
  validate_hunter_tanks()

  validate_unassigned_misdirects()

  if #errors > 0 then return errors[ 1 ] end
  if #warnings > 0 then return warning( warnings, misdirect_count, available_misdirect_count ) end

  return ok( misdirect_count, available_misdirect_count )
end

local function announce_ranged_kill_order()
  if api.IsInRaid() and not can_use_raid_warning() then
    beg_for_assistant()
    return
  end

  local marks = mark_map( M.db.get_raid_marks() )
  local blindeye = marker( marks[ BossType.Blindeye ] )
  local olm = marker( marks[ BossType.Olm ] )
  local krosh = marker( marks[ BossType.Krosh ] )
  local kiggler = marker( marks[ BossType.Kiggler ] )
  local maulgar = marker( marks[ BossType.Maulgar ] )

  announce_rw( "Ranged kill order" )
  announce( string.format( "%s -> %s -> %s -> %s -> %s (no hunter pets)", blindeye, olm, krosh, kiggler, maulgar ) )
end

local function is_locked()
  return M.db.get_locked() or false
end

local function on_lock()
  M.db.set_locked( true )
end

local function on_edit()
  M.db.set_locked( false )
end

local function create_components()
  if OhHaiMaulgar.mock_data == true then
    mocked_player_list = mock_player_list()
  end

  M.ace_timer = LibStub( "AceTimer-3.0" )
  M.db = modules.Db.new()
  M.player_list_gui = modules.PlayerListGui.new()
  M.group_roster = modules.GroupRoster.new( M.db, mocked_player_list )
  M.boss_gui = modules.BossGui.new(
    M.db.set_position,
    on_assign,
    on_unassign,
    M.player_list_gui.hide,
    M.db.get_boss_assignments,
    M.db.get_raid_marks,
    announce_tank_and_heal_assignments,
    announce_misdirect_assignments,
    announce_melee_kill_order,
    announce_ranged_kill_order,
    validate_setup,
    is_locked,
    on_lock,
    on_edit
  )
  M.boss_gui.set_position( M.db.get_position() )
end

local function parse_command()
  M.boss_gui.set_position( M.db.get_position() )
  M.boss_gui.toggle()
end

function M.on_player_login()
  create_components()
  M.update_player_status()
end

function M.on_first_enter_world()
  local version = modules.get_addon_version()

  local hl = modules.colors.hl
  pretty_print( string.format( "Loaded (%s). Type %s to show.", hl( string.format( "v%s", version.str or "Unknown version" ) ), hl( "/hkm" ) ) )
end

modules.EventHandler.handle_events( M )

SLASH_HKM1 = "/hkm"
api.SlashCmdList[ "HKM" ] = parse_command
