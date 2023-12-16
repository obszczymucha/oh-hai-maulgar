local modules = OhHaiMaulgar.modules
if modules.EventHandler then return end

local M = {}

function M.handle_events( main )
  local m_first_enter_world

  --eventHandler( frame, event, ... )
  local function eventHandler( _, event )
    if event == "PLAYER_LOGIN" then
      main.on_player_login()
    elseif event == "PLAYER_ENTERING_WORLD" then
      if not m_first_enter_world then
        main.on_first_enter_world()
        m_first_enter_world = true
      end
    elseif event == "PARTY_MEMBERS_CHANGED" then
      main.update_player_status()
    end
  end

  local frame = modules.api.CreateFrame( "FRAME" )

  frame:RegisterEvent( "PLAYER_LOGIN" )
  frame:RegisterEvent( "PLAYER_ENTERING_WORLD" )
  frame:RegisterEvent( "PARTY_MEMBERS_CHANGED" )

  frame:SetScript( "OnEvent", eventHandler )
end

modules.EventHandler = M
return M
