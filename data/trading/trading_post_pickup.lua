function item_pickup( entity_item, entity_who_picked, item_name )
    GamePrint("trading_post_pickup start")
    local pos_x, pos_y = EntityGetTransform( entity_item )
    GamePrintImportant("Trading " .. tostring(pos_x) .. ", " .. tostring(pos_y)) 
    GamePrint("trading_post_pickup end")
end
