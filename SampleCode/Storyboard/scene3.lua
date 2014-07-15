local storyboard = require( "storyboard" )
local scene = storyboard.newScene()

-- local forward references should go here --
local background, tf2

---------------------------------------------------------------------------
-- GA: When you want to submit custom events from a storyboard scene or any
-- other lua module it is necessary to require the GameAnalytics SDK.
---------------------------------------------------------------------------
local GA = require ("GameAnalytics")

---------------------------------------------------------------------------------
-- BEGINNING OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------

-- Called when the scene's view does not exist:
function scene:createScene( event )
    local group = self.view

    background = display.newRect ( group, display.screenOriginX, display.screenOriginY, display.contentWidth-(2*display.screenOriginX), display.contentWidth-(2*display.screenOriginY) )
	background:setFillColor (45/255,53/255,70/255)
    background.anchorX, background.anchorY = 0,0

	local tf1 = display.newText("Storyboard: scene 3", 0, 0, native.systemFont, 20)
    tf1.x, tf1.y = display.contentWidth/2, (display.contentHeight/2)-12
    tf1:setFillColor ( 220/255 )
    group:insert(tf1)

    tf2 = display.newText("(tap to change scene)", 0, 0, native.systemFont, 15)
    tf2.x, tf2.y = display.contentWidth/2, (display.contentHeight/2)+10
    tf2:setFillColor ( 220/255 )
    group:insert(tf2)
end


-- Called BEFORE scene has moved onscreen:
function scene:willEnterScene( event )
    local group = self.view
    tf2.text = "(tap to submit custom event)"
    tf2:setFillColor ( 220 )
end


-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
    local group = self.view

    local function changeSceneHandler ( event )
     	if "ended" == event.phase then
        	background:removeEventListener ( "touch", changeSceneHandler )
            storyboard.gotoScene( "scene1", { effect = "slideRight", time = 800 } )
    	end
    end

    local customEventHandler
    -- custom event
    customEventHandler = function( event )
    	if "ended" == event.phase then

            ---------------------------------------------------------------------------
            -- GA: Below we are submitting a custom event. 
            -- As you will notice (when looking at the printed event in the terminal) the 
            -- storyboard scene name is assigned automatically to the area parameter by     
            -- the Game Analytics SDK. If you want to overrule this assignment then just 
            -- fill in your own value for the area parameter in your custom event.
            ---------------------------------------------------------------------------
    		GA.newEvent ( "design", { event_id="some_custom_event"} )

    		-- Change touch to change scene handler 
            background:removeEventListener ( "touch", customEventHandler )
        	timer.performWithDelay( 500, function ()
        	   background:addEventListener( "touch", changeSceneHandler )
    	       tf2.text = "(tap to change scene)"
        	end )
        end
    end
	background:addEventListener ( "touch", customEventHandler )
end

---------------------------------------------------------------------------------
-- END OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------

-- "createScene" event is dispatched if scene's view does not exist
scene:addEventListener( "createScene", scene )

-- "willEnterScene" event is dispatched before scene transition begins
scene:addEventListener( "willEnterScene", scene )

-- "enterScene" event is dispatched whenever scene transition has finished
scene:addEventListener( "enterScene", scene )

---------------------------------------------------------------------------------

return scene