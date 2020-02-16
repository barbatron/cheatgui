
local entity_id = GetUpdatedEntityID()

function spawn_trading_post( x, y )
    GamePrint("spawn_trading_post start");
    EntityLoad( "data/trading/trading_post.xml", x, y )
    GamePrint("spawn_trading_post end");
end
