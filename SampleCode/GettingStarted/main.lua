
---------------------------------------------------------------------------------
-- Game Analytics for Corona SDK: Getting started example 
---------------------------------------------------------------------------------

---------------------------------------------
-- Require GA SDK
---------------------------------------------
local GA = require ( "GameAnalytics" )

---------------------------------------------
-- Set some GA properties. 
---------------------------------------------
-- This example enables submission of system info and 
-- average fps with an interval of 10 seconds. 

GA.isDebug                  = true
GA.runInSimulator           = true
GA.submitSystemInfo         = true
GA.submitAverageFps         = true
GA.submitAverageFpsInterval = 10

-- Initialize GA
GA.init ({
	game_key   = 'paste_your_game_key_here',
	secret_key = 'paste_your_secret_key_here',
	build_name = '1.0',
})

---------------------------------------------
-- Submit some custom events 
---------------------------------------------

-- Custom business event example
GA.newEvent ( "business", { event_id = "iap:purchase" , currency = "USD", amount = 0.99 } )  

-- Custom quality event example with multiple events in one request.
local  memUsage =  tostring (collectgarbage( "count" ) )
local  textureMemUsage = tostring (system.getInfo( "textureMemoryUsed" ))

GA.newEvent ( "quality", 
	{ event_id = "performance:MemoryUsed", message = memUsage }, 
	{ event_id = "performance:TextureMemoryUsed", message = textureMemUsage }
)

-- Custom user events
GA.newEvent ( "user", { gender = "F", birth_year = "1990", friend_count = 3 } )
GA.newEvent ( "user", { install_site="Facebook", install_launch="adgroup" })

-- Design example: submit x, y positions when touching the screen
local function touchHandler ( event )
	if "ended" == event.phase then
		GA.newEvent ( "design", { event_id = "touch_test", area = "some_area", x = event.x, y=event.y } )
	end
end
Runtime:addEventListener ( "touch", touchHandler )


