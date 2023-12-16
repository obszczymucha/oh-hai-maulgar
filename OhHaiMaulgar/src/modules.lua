if OhHaiMaulgar and OhHaiMaulgar.modules then return end

---@diagnostic disable: undefined-global
local M = {}

M.api = {
  CreateFrame = CreateFrame,
  UIParent = UIParent,
  SendChatMessage = SendChatMessage,
  SlashCmdList = SlashCmdList,
  UnitName = UnitName,
  GetRealmName = GetRealmName,
  RAID_CLASS_COLORS = RAID_CLASS_COLORS,
  FONT_COLOR_CODE_CLOSE = FONT_COLOR_CODE_CLOSE,
  math = math,
  GetCursorPosition = GetCursorPosition,
  MouseIsOver = MouseIsOver,
  DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME,
  IsInRaid = function() return GetNumRaidMembers() > 0 end,
  IsInParty = function() return GetNumRaidMembers() == 0 and GetNumPartyMembers() > 0 end,
  GetRaidRosterInfo = GetRaidRosterInfo,
  UnitHealth = UnitHealth,
  UnitDebuff = UnitDebuff,
  SetRaidTarget = SetRaidTarget,
  GetRealZoneText = GetRealZoneText,
  InCombatLockdown = InCombatLockdown,
  time = time,
  UnitClass = UnitClass,
  CombatLogClearEntries = CombatLogClearEntries,
  GetMacroIndexByName = GetMacroIndexByName,
  CreateMacro = CreateMacro,
  EditMacro = EditMacro,
  GetAddOnMetadata = GetAddOnMetadata
}

M.api.RAID_CLASS_COLORS.HUNTER.colorStr = "ffabd473"
M.api.RAID_CLASS_COLORS.WARLOCK.colorStr = "ff8788ee"
M.api.RAID_CLASS_COLORS.PRIEST.colorStr = "ffffffff"
M.api.RAID_CLASS_COLORS.PALADIN.colorStr = "fff58cba"
M.api.RAID_CLASS_COLORS.MAGE.colorStr = "ff3fc7eb"
M.api.RAID_CLASS_COLORS.ROGUE.colorStr = "fffff569"
M.api.RAID_CLASS_COLORS.DRUID.colorStr = "ffff7d0a"
M.api.RAID_CLASS_COLORS.SHAMAN.colorStr = "ff0070de"
M.api.RAID_CLASS_COLORS.WARRIOR.colorStr = "ffc79c6e"

M.colors = {
  highlight = function( text )
    return string.format( "|cffff9f69%s|r", text )
  end,
  blue = function( text )
    return string.format( "|cff209ff9%s|r", text )
  end,
  white = function( text )
    return string.format( "|cffffffff%s|r", text )
  end,
  red = function( text )
    return string.format( "|cffff2f2f%s|r", text )
  end,
  orange = function( text )
    return string.format( "|cffff8f2f%s|r", text )
  end,
  grey = function( text )
    return string.format( "|cff9f9f9f%s|r", text )
  end,
  green = function( text )
    return string.format( "|cff2fff5f%s|r", text )
  end,
  not_in_group = function( text )
    return string.format( "|cff4f4f4f%s|r", text )
  end
}

M.colors.hl = M.colors.highlight

function M.map( t, f, extract_field )
  if type( f ) ~= "function" then return t end

  local result = {}

  for k, v in pairs( t ) do
    if type( v ) == "table" and extract_field then
      local mapped_result = f( v[ extract_field ] )
      local value = M.clone( v )
      value[ extract_field ] = mapped_result
      result[ k ] = value
    else
      result[ k ] = f( v )
    end
  end

  return result
end

function M.filter( t, f, extract_field )
  if not t then return nil end
  if type( f ) ~= "function" then return t end

  local result = {}

  for i = 1, #t do
    local v = t[ i ]
    local value = type( v ) == "table" and extract_field and v[ extract_field ] or v
    if f( value ) then table.insert( result, v ) end
  end

  return result
end

function M.announce( message )
  if M.api.IsInRaid() then
    M.api.SendChatMessage( message, "RAID" )
  elseif M.api.IsInParty() then
    M.api.SendChatMessage( message, "PARTY" )
  else
    M.pretty_print( message )
  end
end

function M.announce_rw( message )
  if M.api.IsInRaid() then
    M.api.SendChatMessage( message, "RAID_WARNING" )
  elseif M.api.IsInParty() then
    M.api.SendChatMessage( message, "PARTY" )
  else
    M.pretty_print( message )
  end
end

function M.pretty_print( message, color_fn, module_name )
  if not message then return end

  local c = color_fn and type( color_fn ) == "function" and color_fn or color_fn and type( color_fn ) == "string" and M.colors[ color_fn ] or M.colors.blue
  local module_str = module_name and string.format( "%s%s%s", c( "[ " ), M.colors.white( module_name ), c( " ]" ) ) or ""
  M.api.DEFAULT_CHAT_FRAME:AddMessage( string.format( "%s%s: %s", c( "OhHaiMaulgar" ), module_str, message ) )
end

function M.print_debug( message )
  if OhHaiMaulgar.debug then
    M.pretty_print( message, M.colors.grey )
  end
end

function M.class_color( class )
  return function( name )
    local color = M.api.RAID_CLASS_COLORS[ class:upper() ].colorStr
    return "|c" .. color .. name .. M.api.FONT_COLOR_CODE_CLOSE
  end
end

function M.colorize_player( player )
  local color = (not player or not player.in_group) and M.colors.not_in_group or not player.alive and M.colors.red or M.class_color( player.class )
  return color( player.name )
end

function M.colorize_player_by_class( name, class )
  return M.class_color( class )( name )
end

local RoleType = {
  Tank = "Tank",
  Healer = "Healer",
  MD = "MD"
}

M.RoleType = RoleType

local BossType = {
  Kiggler = "Kiggler",
  Blindeye = "Blindeye",
  Maulgar = "Maulgar",
  Olm = "Olm",
  Krosh = "Krosh"
}

M.BossType = BossType

local RaidMarkType = {
  Skull = "Skull",
  Cross = "Cross",
  Star = "Star",
  Moon = "Moon",
  Square = "Square",
  Circle = "Circle",
  Diamond = "Diamond",
  Triangle = "Triangle",
  None = "None"
}

M.RaidMarkType = RaidMarkType

function M.get_raid_mark_number_by_type( raid_mark_type )
  if raid_mark_type == RaidMarkType.Star then
    return 1
  elseif raid_mark_type == RaidMarkType.Circle then
    return 2
  elseif raid_mark_type == RaidMarkType.Diamond then
    return 3
  elseif raid_mark_type == RaidMarkType.Triangle then
    return 4
  elseif raid_mark_type == RaidMarkType.Moon then
    return 5
  elseif raid_mark_type == RaidMarkType.Square then
    return 6
  elseif raid_mark_type == RaidMarkType.Cross then
    return 7
  elseif raid_mark_type == RaidMarkType.Skull then
    return 8
  elseif raid_mark_type == RaidMarkType.None then
    return 0
  end
end

function M.get_raid_mark_chat_marker_by_type( raid_mark_type )
  return string.format( "{%s}", string.lower( raid_mark_type ) )
end

function M.get_frame_icon_by_type( raid_mark_type )
  local number = M.get_raid_mark_number_by_type( raid_mark_type )
  return string.format( "\124TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%s:0\124t", number )
end

function M.get_boss_name_by_type( boss_type )
  if boss_type == BossType.Kiggler then
    return "Kiggler the Crazed"
  elseif boss_type == BossType.Blindeye then
    return "Blindeye the Seer"
  elseif boss_type == BossType.Maulgar then
    return "High King Maulgar"
  elseif boss_type == BossType.Olm then
    return "Olm the Summoner"
  elseif boss_type == BossType.Krosh then
    return "Krosh Firehand"
  end
end

function M.get_default_raid_mark( boss_type )
  if boss_type == BossType.Kiggler then
    return RaidMarkType.Star
  elseif boss_type == BossType.Blindeye then
    return RaidMarkType.Skull
  elseif boss_type == BossType.Maulgar then
    return RaidMarkType.Circle
  elseif boss_type == BossType.Olm then
    return RaidMarkType.Cross
  elseif boss_type == BossType.Krosh then
    return RaidMarkType.Square
  end
end

function M.contains( t, value )
  for _, v in pairs( t ) do
    if v == value then return true end
  end

  return false
end

local get_macro_index = M.api.GetMacroIndexByName

function M.create_macro( name, body, global, icon_index )
  local index = get_macro_index( name )
  if index ~= 0 then return end

  M.api.CreateMacro( name, not icon_index and 1 or icon_index, body or "", nil, not global and true or false )
end

function M.edit_macro( name, body, global, icon )
  local index = get_macro_index( name )
  if index == 0 then return end

  M.api.EditMacro( index, nil, icon, body, true, not global and 1 or nil )
end

function M.raid_mark( boss_type, raid_mark_type )
  return {
    boss_type = boss_type,
    raid_mark_type = raid_mark_type
  }
end

local clear_target = "/cleartarget\n"

local function target( boss_type, mark_type )
  local boss_name = M.get_boss_name_by_type( boss_type )
  local mark_number = M.get_raid_mark_number_by_type( mark_type )
  return string.format( "/targetexact %s\n/script SetRaidTarget(\"target\", %s)\n", boss_name, mark_number )
end

function M.create_marking_macro( raid_marks )
  local result = clear_target

  for _, raid_mark in ipairs( raid_marks ) do
    result = result .. target( raid_mark.boss_type, raid_mark.raid_mark_type )
  end

  result = result .. clear_target

  return result
end

function M.create_unmarking_macro()
  local result = clear_target

  result = result .. target( BossType.Kiggler, RaidMarkType.None )
  result = result .. target( BossType.Blindeye, RaidMarkType.None )
  result = result .. target( BossType.Maulgar, RaidMarkType.None )
  result = result .. target( BossType.Olm, RaidMarkType.None )
  result = result .. target( BossType.Krosh, RaidMarkType.None )
  result = result .. clear_target

  return result
end

-- This shuffles in place, but returning anyways for ease of use.
function M.shuffle( t )
  local n = #t

  for i = 1, n do
    local j = M.api.math.random( i, n )
    t[ i ], t[ j ] = t[ j ], t[ i ]
  end

  return t
end

function M.mark_map( raid_marks )
  local result = {}

  for _, raid_mark in ipairs( raid_marks ) do
    result[ raid_mark.boss_type ] = raid_mark.raid_mark_type
  end

  return result
end

local ValidationType = {
  Ok = "Ok",
  Warning = "Warning",
  Error = "Error",
}

M.ValidationType = ValidationType

local WarningType = {
  OneHealer = "OneHealer",
  OneHunter = "OneHunter",
  UnassignedMisdirect = "UnassignedMisdirect"
}

M.WarningType = WarningType

local ErrorType = {
  NoTank = "NoTank",
  NoHealer = "NoHealer"
}

M.ErrorType = ErrorType

local Validation = {
  ok = function( misdirect_count, available_misdirect_count )
    return {
      validation_type = ValidationType.Ok,
      misdirect_count = misdirect_count,
      available_misdirect_count = available_misdirect_count
    }
  end,
  warning_entry = function( boss_type, warning_type )
    return {
      boss_type = boss_type,
      warning_type = warning_type
    }
  end,
  warning = function( entries, misdirect_count, available_misdirect_count )
    return {
      validation_type = ValidationType.Warning,
      entries = entries,
      misdirect_count = misdirect_count,
      available_misdirect_count = available_misdirect_count
    }
  end,
  error = function( boss_type, error_type, available_misdirect_count )
    return {
      validation_type = ValidationType.Error,
      boss_type = boss_type,
      error_type = error_type,
      available_misdirect_count = available_misdirect_count
    }
  end
}

M.Validation = Validation

function M.find_raid_leader()
  if not M.api.IsInRaid() then return end

  for i = 1, 40 do
    local name, status = M.api.GetRaidRosterInfo( i )
    if status == 2 then return name end
  end
end

function M.can_use_raid_warning()
  if not M.api.IsInRaid() then return false end
  local my_name = M.api.UnitName( "player" )

  for i = 1, 40 do
    local name, status = M.api.GetRaidRosterInfo( i )
    if name == my_name and status > 0 then return true end
  end

  return false
end

function M.get_addon_version()
  local version = M.api.GetAddOnMetadata( "OhHaiMaulgar", "Version" )
  local major, minor = string.match( version, "(%d+)%.(%d+)" )

  local result = {
    str = version,
    major = tonumber( major ),
    minor = tonumber( minor )
  }

  if not version or not result.major or not result.minor then
    error( "Invalid OhHaiMaulgar addon version!" )
    return {}
  end

  return result
end

OhHaiMaulgar = {}
OhHaiMaulgar.modules = M
