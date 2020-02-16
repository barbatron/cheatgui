

function item_pickup( entity_item, entity_who_picked, item_name )
  local pos_x, pos_y = EntityGetTransform( entity_item )
  
  -- open trading UI
  GamePrintImportant("Trading at " .. tostring(pos_x) .. ", " .. tostring(pos_y), "Trading post activated") 
  dofile("data/trading/trading_post_ui.lua")
  open_trading_ui()
  
  -- spawn a new one
  EntityKill( entity_item )
  EntityLoad( "data/trading/entity_trading_post.xml", pos_x, pos_y )
end
