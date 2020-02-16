dofile("data/trading/trading_post_ui.lua")

function spawn_trading_post( x, y )
    GamePrint("spawn_trading_post start");
    EntityLoad( "data/trading/entity_trading_post.xml", x, y )
    GamePrint("spawn_trading_post end");
end
