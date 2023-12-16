local modules = OhHaiMaulgar.modules
if modules.BossGui then return end

local M = {}

local api = modules.api
local colorize_player = modules.colorize_player
local BossType = modules.BossType
local RoleType = modules.RoleType
local create_marking_macro = modules.create_marking_macro
--local create_unmarking_macro = modules.create_unmarking_macro
local get_raid_mark_number_by_type = modules.get_raid_mark_number_by_type
local ValidationType = modules.ValidationType
local ErrorType = modules.ErrorType
local WarningType = modules.WarningType
local red = modules.colors.red
local white = modules.colors.white
local hl = modules.colors.hl
local green = modules.colors.green

local WIDTH = 750
local HEIGHT = 340
local PADDING = 75
local ASSIGN = "Assign"
local CANCEL = "Cancel"
local EDIT = "Edit"
local LOCK = "Lock"

local FIRST_ROW_PADDING = -18
local ROW_PADDING = -8

local layout = {
  [ BossType.Kiggler ] = {
    RoleType.Tank,
    RoleType.Tank,
    RoleType.Healer
  },
  [ BossType.Blindeye ] = {
    RoleType.Tank,
    RoleType.Healer,
    RoleType.MD
  },
  [ BossType.Maulgar ] = {
    RoleType.Tank,
    RoleType.Healer,
    RoleType.Healer,
    RoleType.MD
  },
  [ BossType.Olm ] = {
    RoleType.Tank,
    --RoleType.Tank,
    RoleType.Healer,
    RoleType.MD
  },
  [ BossType.Krosh ] = {
    RoleType.Tank,
    RoleType.Healer,
    RoleType.MD
  }
}

local function find_role_index( boss_type, role_type, index )
  local result = 0

  for i, role in ipairs( layout[ boss_type ] ) do
    if role == role_type then result = result + 1 end
    if i == index then return result end
  end

  return result
end

function M.new( on_drag_stop,
                on_assign,
                on_unassign,
                hide_player_list_fn,
                get_assignments,
                get_raid_marks,
                announce_tank_and_heal_assignments,
                announce_misdirect_assignments,
                announce_melee_kill_order,
                announce_ranged_kill_order,
                validate_setup,
                is_locked,
                on_lock,
                on_edit )
  local m_frame = api.CreateFrame( "Frame", "OhHaiMaulgarBossFrame", api.UIParent )
  local bosses = {}
  m_frame:Hide()

  m_frame:SetWidth( WIDTH )
  m_frame:SetHeight( HEIGHT )
  m_frame:SetBackdrop( {
    bgFile = "Interface\\Tooltips\\UI-tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  } )
  m_frame:SetBackdropColor( 0, 0, 0, 0.8 )
  m_frame:SetMovable( true )
  m_frame:EnableMouse( true )
  m_frame:RegisterForDrag( "LeftButton" )

  m_frame:SetScript( "OnHide", function()
    hide_player_list_fn()
  end )

  m_frame:SetScript( "OnDragStart", m_frame.StartMoving )
  m_frame:SetScript( "OnDragStop", function( self, ... )
    self:StopMovingOrSizing( ... )
    local anchor, _, other_anchor, x, y = m_frame:GetPoint()
    on_drag_stop( anchor, other_anchor, x, y )
  end )

  local function dim( frame )
    frame:SetBackdropColor( 0.5, 0.5, 0.5, 0 )
  end

  --local function highlight( frame )
  --frame:SetBackdropColor( 1, 1, 1, 0.3 )
  --end

  --local function press( frame )
  --frame:SetBackdropColor( 1, 1, 1, 0.7 )
  --end

  local function create_image( boss_type, height, width )
    local frame = api.CreateFrame( "FRAME", nil, m_frame )
    frame:SetWidth( height or 64 )
    frame:SetHeight( width or 64 )
    frame:SetFrameLevel( m_frame:GetFrameLevel() + 1 )
    local texture = frame:CreateTexture( nil, "BACKGROUND" )
    texture:SetTexture( string.format( "Interface\\AddOns\\OhHaiMaulgar\\assets\\%s.blp", boss_type ) )
    texture:SetAllPoints( frame )

    local raid_mark_button = api.CreateFrame( "Button", nil, frame )
    raid_mark_button:SetWidth( 20 )
    raid_mark_button:SetHeight( 20 )
    raid_mark_button:SetPoint( "TOP", frame, "TOP", 0, 30 )
    raid_mark_button:SetBackdrop( { bgFile = "Interface\\Buttons\\WHITE8x8" } )
    raid_mark_button:SetNormalTexture( "" )

    --raid_mark_button:SetScript( "OnEnter", function( self ) highlight( self ) end )
    --raid_mark_button:SetScript( "OnLeave", function( self ) dim( self ) end )
    --raid_mark_button:SetScript( "OnMouseDown", function( self, button )
    --if button == "LeftButton" then press( self ) end
    --end )
    --raid_mark_button:SetScript( "OnMouseUp", function( self, button )
    --if button == "LeftButton" then
    --if modules.api.MouseIsOver( self ) then
    --highlight( self )
    --else
    --dim( self )
    --end
    --end
    --end )
    dim( raid_mark_button )

    local raid_mark = raid_mark_button:CreateTexture( nil, "ARTWORK" )
    raid_mark:SetAllPoints( raid_mark_button )

    bosses[ boss_type ] = {
      raid_mark = raid_mark,
      frame = frame,
      buttons = {},
      set_raid_mark = function( raid_mark_type )
        local number = get_raid_mark_number_by_type( raid_mark_type )
        raid_mark:SetTexture( "Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. number )
      end
    }
  end

  create_image( BossType.Maulgar, 85, 85 )
  create_image( BossType.Blindeye )
  create_image( BossType.Kiggler )
  create_image( BossType.Olm )
  create_image( BossType.Krosh )

  local function set_raid_marks()
    local marks = get_raid_marks()
    for _, raid_mark in ipairs( marks ) do
      bosses[ raid_mark.boss_type ].set_raid_mark( raid_mark.raid_mark_type )
    end
  end

  set_raid_marks()

  bosses[ BossType.Maulgar ].frame:SetPoint( "TOP", m_frame, "TOP", 0, -55 )
  bosses[ BossType.Blindeye ].frame:SetPoint( "RIGHT", bosses[ BossType.Maulgar ].frame, "LEFT", PADDING * -1, 5 )
  bosses[ BossType.Kiggler ].frame:SetPoint( "RIGHT", bosses[ BossType.Blindeye ].frame, "LEFT", PADDING * -1, 9 )
  bosses[ BossType.Olm ].frame:SetPoint( "LEFT", bosses[ BossType.Maulgar ].frame, "RIGHT", PADDING, 5 )
  bosses[ BossType.Krosh ].frame:SetPoint( "LEFT", bosses[ BossType.Olm ].frame, "RIGHT", PADDING, 9 )

  local mark_button = api.CreateFrame( "Button", nil, m_frame, "SecureActionButtonTemplate,UIPanelButtonTemplate" )
  mark_button:SetAttribute( "type", "macro" )
  local marking_macro = create_marking_macro( get_raid_marks() )
  mark_button:SetAttribute( "macrotext", marking_macro )
  mark_button:SetWidth( 80 )
  mark_button:SetHeight( 21 )
  mark_button:SetText( "Mark" )
  mark_button:SetPoint( "BOTTOMRIGHT", m_frame, "BOTTOMRIGHT", -20, 20 )

  --local unmark_button = api.CreateFrame( "Button", nil, m_frame, "SecureActionButtonTemplate,UIPanelButtonTemplate" )
  --unmark_button:SetAttribute( "type", "macro" )
  --unmark_button:SetAttribute( "macrotext", create_unmarking_macro() )
  --1nmark_button:SetWidth( 80 )
  --unmark_button:SetHeight( 21 )
  --unmark_button:SetText( "Unmark" )
  --unmark_button:SetPoint( "RIGHT", lock_button, "LEFT", -15, 0 )

  local assignments_button = api.CreateFrame( "Button", nil, m_frame, "UIPanelButtonTemplate" )
  assignments_button:SetWidth( 110 )
  assignments_button:SetHeight( 21 )
  assignments_button:SetPoint( "BOTTOMLEFT", m_frame, "BOTTOMLEFT", 20, 20 )
  assignments_button:SetText( "Tanks + heals" )
  assignments_button:SetScript( "OnClick", announce_tank_and_heal_assignments )

  local mds_button = api.CreateFrame( "Button", nil, m_frame, "UIPanelButtonTemplate" )
  mds_button:SetWidth( 50 )
  mds_button:SetHeight( 21 )
  mds_button:SetPoint( "LEFT", assignments_button, "RIGHT", 12, 0 )
  mds_button:SetText( "MDs" )
  mds_button:SetScript( "OnClick", announce_misdirect_assignments )

  local melee_kill_order_button = api.CreateFrame( "Button", nil, m_frame, "UIPanelButtonTemplate" )
  melee_kill_order_button:SetWidth( 125 )
  melee_kill_order_button:SetHeight( 21 )
  melee_kill_order_button:SetPoint( "LEFT", mds_button, "RIGHT", 12, 0 )
  melee_kill_order_button:SetText( "Melee kill order" )
  melee_kill_order_button:SetScript( "OnClick", announce_melee_kill_order )

  local ranged_kill_order_button = api.CreateFrame( "Button", nil, m_frame, "UIPanelButtonTemplate" )
  ranged_kill_order_button:SetWidth( 130 )
  ranged_kill_order_button:SetHeight( 21 )
  ranged_kill_order_button:SetPoint( "LEFT", melee_kill_order_button, "RIGHT", 12, 0 )
  ranged_kill_order_button:SetText( "Ranged kill order" )
  ranged_kill_order_button:SetScript( "OnClick", announce_ranged_kill_order )

  local lock_edit_button = api.CreateFrame( "Button", nil, m_frame, "UIPanelButtonTemplate" )
  lock_edit_button:SetWidth( 80 )
  lock_edit_button:SetHeight( 21 )
  lock_edit_button:SetPoint( "RIGHT", mark_button, "LEFT", -15, 0 )
  lock_edit_button:SetText( is_locked() and EDIT or LOCK )

  local info_message = m_frame:CreateFontString( nil, "ARTWORK", "GameFontNormal" )
  info_message:SetPoint( "BOTTOMLEFT", assignments_button, "TOPLEFT", 5, 13 )
  info_message:SetText( "" )
  info_message:SetJustifyH( "LEFT" )

  local function disable_all_buttons( boss_type, index )
    for boss, data in pairs( bosses ) do
      for _, frame in ipairs( data.buttons ) do
        if boss ~= boss_type or boss == boss_type and frame.button.index ~= index then
          frame.button:Disable()
        end
      end
    end

    lock_edit_button:Disable()
  end

  local function enable_all_buttons()
    for _, data in pairs( bosses ) do
      for _, frame in ipairs( data.buttons ) do
        frame.button:Enable()

        if frame.assigning then
          frame.reset()
        end
      end
    end

    lock_edit_button:Enable()
  end

  local function set_info_message( validation_result )
    if validation_result.validation_type == ValidationType.Ok then
      info_message:SetText( green( "Ready to pull!" ) )
      return
    end

    if validation_result.validation_type == ValidationType.Warning then
      local messages = {}

      for _, warning in ipairs( validation_result.entries ) do
        local message = warning.warning_type == WarningType.OneHealer and
            string.format( "has only one %s %s", hl( "healer" ), white( "assigned and he hits really hard!" ) )
            or warning.warning_type == WarningType.OneHunter and
            string.format( "is tanked by only one %s %s", hl( "hunter" ), white( "and you ideally want two." ) )
            or warning.warning_type == WarningType.UnassignedMisdirect and
            string.format( "%s still have unassigned %s.", #validation_result.entries > 1 and "You" or "you", hl( "misdirects" ) )
        local boss_name = modules.get_boss_name_by_type( warning.boss_type )
        table.insert( messages, string.format( "%s%s", boss_name and string.format( "%s ", hl( boss_name ) ) or "", white( message ) ) )
      end

      local message = string.format( "%s%s", green( "Ready to pull" ), white( string.format( ", however%s", #messages > 1 and ":\n" or ", " ) ) )

      for i = 1, #messages do
        if i > 1 then message = message .. "\n" end
        local next_message = messages[ i ]

        if #messages > 1 then
          message = message .. string.format( "%s. ", i )
        end

        message = message .. next_message
      end

      info_message:SetText( message )
      m_frame:SetHeight( HEIGHT + (#messages * 12) )
      return
    end

    local message = validation_result.error_type == ErrorType.NoTank and " needs a tank!"
        or validation_result.error_type == ErrorType.NoHealer and " needs a healer!"

    local boss_name = modules.get_boss_name_by_type( validation_result.boss_type )
    info_message:SetText( string.format( "%s %s", hl( boss_name ), red( message ) ) )
  end

  local function disable_buttons()
    assignments_button:Disable()
    mds_button:Disable()
    melee_kill_order_button:Disable()
    ranged_kill_order_button:Disable()
  end

  local function toggle_buttons( validation_result )
    if validation_result.validation_type ~= ValidationType.Error then
      assignments_button:Enable()

      if validation_result.misdirect_count > 0 then
        mds_button:Enable()
      else
        mds_button:Disable()
      end

      melee_kill_order_button:Enable()
      ranged_kill_order_button:Enable()
      return
    end

    disable_buttons()
  end

  local function create_buttons()
    local function create_button( boss_type, role_type, index )
      local button_width = 55
      local icon_size = 18
      local margin = 2

      local frame = api.CreateFrame( "Frame", nil, m_frame )
      frame:SetHeight( 21 )
      frame:SetFrameLevel( m_frame:GetFrameLevel() + 1 )

      local texture = frame:CreateTexture( nil, "BACKGROUND" )
      texture:SetTexture( string.format( "Interface\\AddOns\\OhHaiMaulgar\\assets\\%s.blp", role_type ) )
      texture:SetPoint( "LEFT", frame, "LEFT" )
      texture:SetWidth( icon_size )
      texture:SetHeight( icon_size )

      local player_name = frame:CreateFontString( nil, "ARTWORK", "GameFontNormal" )
      player_name:SetPoint( "LEFT", texture, "RIGHT", 3, 0 )
      player_name:SetText( "" )

      local button = api.CreateFrame( "Button", nil, frame, "UIPanelButtonTemplate" )
      button:SetWidth( button_width )
      button:SetHeight( 19 )
      button:SetText( ASSIGN )
      local font_string = button:GetFontString()
      local font, _, flags = font_string:GetFont()
      font_string:SetFont( font, 10, flags )
      button:SetPoint( "RIGHT", frame, "RIGHT", 0, 0 )

      frame.role_type = role_type
      frame.assigning = false

      local function reset()
        frame.assigning = false

        if not frame.assigned then
          frame.button:SetText( ASSIGN )
          button:SetPoint( "RIGHT", frame, "RIGHT", 0, 0 )
        end

        set_info_message( validate_setup() )
      end

      local function resize()
        local player_name_width = player_name:GetWidth()
        local button_visible = button:IsVisible()
        local spacer = player_name_width > 0 and button_visible and 4 or 0
        local width = button_visible and button:GetWidth() or 0
        frame:SetWidth( icon_size + margin + player_name_width + spacer + width )
      end

      resize()

      button:SetScript( "OnClick", function()
        if frame.assigned then
          frame.assigned = false
          player_name:SetText( "" )
          button:SetText( ASSIGN )
          button:SetWidth( button_width )
          button:SetPoint( "RIGHT", frame, "RIGHT", 0, 0 )
          resize()

          local role_index = find_role_index( boss_type, role_type, index )
          on_unassign( boss_type, role_type, role_index )
          return
        end

        if frame.assigning == true then
          frame.assigning = false
          button:SetText( ASSIGN )
          button:SetPoint( "RIGHT", frame, "RIGHT", 0, 0 )
          button:SetWidth( button_width )
          enable_all_buttons()
          hide_player_list_fn()
          return
        end

        frame.assigning = true
        button:SetText( CANCEL )
        disable_all_buttons( boss_type, index )

        local role_index = find_role_index( boss_type, role_type, index )

        if not on_assign( m_frame, boss_type, role_type, role_index ) then
          enable_all_buttons()
        end
      end )

      local function assign( player )
        frame.assigning = false

        if not player then
          button:SetText( ASSIGN )
          button:SetWidth( button_width )
          button:SetPoint( "RIGHT", frame, "RIGHT", 0, 0 )
          frame.assigned = false
          resize()
          return
        end

        button:SetText( "X" )
        button:SetWidth( 16 )
        button:SetPoint( "RIGHT", frame, "RIGHT", 0, -1 )
        player_name:SetText( colorize_player( player ) )
        frame.assigned = true
        resize()
      end

      button.index = index
      frame.reset = reset
      frame.resize = resize
      frame.assign = assign
      frame.button = button
      return frame
    end

    for boss_type, role_types in pairs( layout ) do
      local boss = bosses[ boss_type ]

      for _, role_type in ipairs( role_types ) do
        local index = #boss.buttons + 1
        local last_button = boss.buttons[ index ]
        local parent = last_button or boss.frame
        local padding_top = last_button and ROW_PADDING or FIRST_ROW_PADDING

        local button = create_button( boss_type, role_type, index )
        button:SetPoint( "TOP", parent, "BOTTOM", 0, padding_top )
        table.insert( boss.buttons, button )
      end
    end
  end

  create_buttons()

  local function toggle_misdirect_buttons( validation_result )
    for _, data in pairs( bosses ) do
      for _, frame in ipairs( data.buttons ) do
        if frame.role_type == RoleType.MD then
          if not frame.assigned and validation_result.available_misdirect_count == 0 then
            frame:Hide()
          else
            frame:Show()
          end
        end
      end
    end
  end

  local function lock_buttons()
    hide_player_list_fn()

    for _, data in pairs( bosses ) do
      local parent = data.frame
      local padding_top = FIRST_ROW_PADDING

      for _, frame in ipairs( data.buttons ) do
        if not frame.assigned then
          frame:Hide()
        else
          frame.button:Hide()
          frame:SetPoint( "TOP", parent, "BOTTOM", 0, padding_top )
          parent = frame
          padding_top = ROW_PADDING
        end

        frame.resize()
      end
    end

    lock_edit_button:SetText( EDIT )

    local validation_result = validate_setup()
    toggle_buttons( validation_result )
    set_info_message( validation_result )

    on_lock()
  end

  local function unlock_buttons()
    hide_player_list_fn()

    for _, data in pairs( bosses ) do
      local parent = data.frame
      local padding_top = FIRST_ROW_PADDING

      for _, frame in ipairs( data.buttons ) do
        frame:Show()
        frame:SetPoint( "TOP", parent, "BOTTOM", 0, padding_top )
        frame.button:Show()
        frame.resize()
        parent = frame
        padding_top = ROW_PADDING
      end
    end

    lock_edit_button:SetText( LOCK )
    local validation_result = validate_setup()
    disable_buttons()
    set_info_message( validation_result )
    toggle_misdirect_buttons( validation_result )

    on_edit()
  end

  local function toggle_lock()
    if not is_locked() then
      lock_buttons()
    else
      unlock_buttons()
    end
  end

  lock_edit_button:SetScript( "OnClick", function()
    toggle_lock()
  end )

  local close_button = api.CreateFrame( "Button", nil, m_frame, "UIPanelButtonTemplate" )
  close_button:SetWidth( 19 )
  close_button:SetHeight( 20 )
  close_button:SetPoint( "TOPRIGHT", m_frame, -11, -9 )
  close_button:SetText( "X" )
  close_button:SetScript( "OnClick", function() m_frame:Hide() end )

  local function update()
    local assignments = get_assignments()

    for boss_type, data in pairs( bosses ) do
      local boss_assignment = assignments[ boss_type ] or {}

      for _, frame in ipairs( data.buttons ) do
        local roles = boss_assignment[ frame.role_type ] or {}
        local role_index = find_role_index( boss_type, frame.role_type, frame.button.index )
        local player = roles[ role_index ]
        frame.assign( player )
      end
    end

    local validation_result = validate_setup()
    set_info_message( validation_result )
    enable_all_buttons()
    if is_locked() then lock_buttons() else unlock_buttons() end
    toggle_misdirect_buttons( validation_result )
  end

  local function show()
    m_frame:Show()
    update()
  end

  local function toggle()
    if m_frame:IsVisible() then
      m_frame:Hide()
    else
      show()
    end
  end

  local function set_position( position )
    if position then
      m_frame:SetPoint( position.anchor, api.UIParent, position.other_anchor, position.x, position.y )
    else
      m_frame:SetPoint( "CENTER" )
    end
  end

  return {
    show = show,
    toggle = toggle,
    set_position = set_position,
    update = update
  }
end

modules.BossGui = M
return M
