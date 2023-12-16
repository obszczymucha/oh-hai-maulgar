local modules = OhHaiMaulgar.modules
if modules.GroupRoster then return end

local M = {}
local api = modules.api

function M.new( db, mocked_player_list )
  local function get_players()
    if mocked_player_list then
      return mocked_player_list
    end

    local result = {}

    if not api.IsInRaid() then
      local function get_details( unit )
        local is_ghost = api.UnitDebuff( unit, 1 ) == "Ghost"
        local name = api.UnitName( unit )

        if not name then return end

        result[ name ] = {
          class = api.UnitClass( unit ),
          alive = api.UnitHealth( unit ) > 0 and not is_ghost,
          ghost = is_ghost,
          offline = false,
          unit = unit
        }
      end

      get_details( "player" )

      for i = 1, 4 do
        get_details( "party" .. i )
      end

      return result
    end

    for i = 1, 40 do
      local name, _, _, _, class, _, offline = api.GetRaidRosterInfo( i )

      if name then
        local unit = "raid" .. i
        local is_ghost = api.UnitDebuff( unit, 1 ) == "Ghost"

        result[ name ] = {
          class = class,
          alive = api.UnitHealth( unit ) > 0 and not is_ghost,
          ghost = is_ghost,
          offline = offline == "Offline" or false,
          unit = unit
        }
      end
    end

    return result
  end

  local function get_player_status( player_name )
    local players = get_players()
    return players[ player_name ]
  end

  return {
    get_players = get_players,
    get_player_status = get_player_status
  }
end

modules.GroupRoster = M
return M
