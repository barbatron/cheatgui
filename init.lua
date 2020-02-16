dofile_once("data/hax/utils.lua")

function OnWorldPostUpdate() 
  if _cheat_gui_main then _cheat_gui_main() end
end

function OnPlayerSpawned( player_entity )
  print("OnPlayerSpawned require check:")
  if not require then
    print("NO require.")
  else
    print("YES require.")
  end
  dofile("data/hax/cheatgui.lua")
  dofile("data/trading/trading_post.lua")

  local px, py = get_player_pos()  
  spawn_trading_post(px, py)  
end
