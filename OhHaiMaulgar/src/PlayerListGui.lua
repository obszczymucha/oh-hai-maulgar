local modules = OhHaiMaulgar.modules
if modules.PlayerListGui then return end

local M = {}

local button_width = 85
local button_height = 16
local horizontal_padding = 3
local vertical_padding = 5
local rows = 25

local function highlight( frame )
  frame:SetBackdropColor( frame.color.r, frame.color.g, frame.color.b, 0.3 )
end

local function dim( frame )
  frame:SetBackdropColor( 0.5, 0.5, 0.5, 0.1 )
end

local function press( frame )
  frame:SetBackdropColor( frame.color.r, frame.color.g, frame.color.b, 0.7 )
end

local function create_main_frame()
  local frame = modules.api.CreateFrame( "Frame", "OhHaiMaulgarPlayerListFrame" )
  frame:Hide()
  frame:SetBackdrop( {
    bgFile = "Interface\\Tooltips\\UI-tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  } )
  frame:SetBackdropColor( 0, 0, 0, 1 )
  frame:SetFrameStrata( "DIALOG" )
  frame:SetWidth( 100 )
  frame:SetHeight( 100 )
  frame:SetPoint( "CENTER", modules.api.UIParent, "Center" )
  frame:EnableMouse( true )

  return frame
end

local function create_button( parent, index )
  local frame = modules.api.CreateFrame( "Button", nil, parent )
  local width = 5 + horizontal_padding + modules.api.math.floor( (index - 1) / rows ) * (button_width + horizontal_padding)
  local height = -5 - vertical_padding - ((index - 1) % rows) * (button_height + vertical_padding)
  frame:SetWidth( button_width )
  frame:SetHeight( button_height )
  frame:SetPoint( "TOPLEFT", parent, "TOPLEFT", width, height )
  frame:SetBackdrop( { bgFile = "Interface\\Buttons\\WHITE8x8" } )
  frame:SetNormalTexture( "" )
  frame.parent = parent

  local text = frame:CreateFontString( nil, "OVERLAY", "GameFontNormalSmall" )
  text:SetPoint( "CENTER", frame, "CENTER" )
  text:SetText( "" )
  frame.text = text

  frame:SetScript( "OnEnter", function( self ) highlight( self ) end )
  frame:SetScript( "OnLeave", function( self ) dim( self ) end )
  frame:SetScript( "OnMouseDown", function( self, button )
    if button == "LeftButton" then press( self ) end
  end )
  frame:SetScript( "OnMouseUp", function( self, button )
    if button == "LeftButton" then
      if modules.api.MouseIsOver( self ) then
        highlight( self )
      else
        dim( self )
      end
    end
  end )

  return frame
end

function M.new()
  local m_frame = create_main_frame()
  local m_buttons = {}

  local function create_candidate_frames( candidates, on_assign )
    local total = #candidates

    local columns = modules.api.math.ceil( total / rows )
    local total_rows = total < rows and total or rows

    m_frame:SetWidth( (button_width + horizontal_padding) * columns + horizontal_padding + 11 )
    m_frame:SetHeight( (button_height + vertical_padding) * total_rows + vertical_padding + 11 )

    local function loop( i )
      if i > total then
        if m_buttons[ i ] then m_buttons[ i ]:Hide() end
        return
      end

      local candidate = candidates[ i ]

      if not m_buttons[ i ] then
        m_buttons[ i ] = create_button( m_frame, i )
      end

      local button = m_buttons[ i ]
      button.text:SetText( candidate.name )
      local color = modules.api.RAID_CLASS_COLORS[ candidate.class:upper() ]
      button.color = color
      button.player = candidate

      if color then
        button.text:SetTextColor( color.r, color.g, color.b )
        dim( button )
      else
        button.text:SetTextColor( 1, 1, 1 )
      end

      button:SetScript( "OnClick", function( self )
        on_assign( self.player )
        m_frame:Hide()
      end )

      button:Show()
    end

    for i = 1, 40 do
      loop( i )
    end
  end

  local function anchor( frame )
    m_frame:SetPoint( "TOPLEFT", frame, "TOPRIGHT", 0, 0 )
  end

  local function show( frame_to_anchor, player_list, on_assign )
    if m_frame then
      anchor( frame_to_anchor )
      create_candidate_frames( player_list, on_assign )
      m_frame:Show()
    end
  end

  local function hide()
    if m_frame then m_frame:Hide() end
  end

  return {
    show = show,
    hide = hide
  }
end

modules.PlayerListGui = M
return M
