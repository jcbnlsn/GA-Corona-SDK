local composer = require( "composer" )
local scene = composer.newScene()

-- -----------------------------------------------------------------------------------------------------------------
-- All code outside of the listener functions will only be executed ONCE unless "composer.removeScene()" is called.
-- -----------------------------------------------------------------------------------------------------------------

-- local forward references should go here
local background, tf2

---------------------------------------------------------------------------
-- GA: When you want to submit custom events from a composer scene or any
-- other lua module it is necessary to require the GameAnalytics SDK.
---------------------------------------------------------------------------
local GA = require ("GameAnalytics")

-- -------------------------------------------------------------------------------

-- "scene:create()"
function scene:create( event )

    local sceneGroup = self.view

    -- Initialize the scene here.
    -- Example: add display objects to "sceneGroup", add touch listeners, etc.
     background = display.newRect ( sceneGroup, display.screenOriginX, display.screenOriginY, display.contentWidth-(2*display.screenOriginX), display.contentWidth-(2*display.screenOriginY) )
	   background:setFillColor (226/255,88/255,0)
    background.anchorX, background.anchorY = 0,0

	local tf1 = display.newText("Composer: scene 2", 0, 0, native.systemFont, 20)
    tf1.x, tf1.y = display.contentWidth/2, (display.contentHeight/2)-12
  	tf1:setFillColor ( 20/255 )
    sceneGroup:insert(tf1)

   	tf2 = display.newText("(tap to change scene)", 0, 0, native.systemFont, 15)
    tf2.x, tf2.y = display.contentWidth/2, (display.contentHeight/2)+10
  	tf2:setFillColor ( 20/255 )
   	sceneGroup:insert(tf2)
end


-- "scene:show()"
function scene:show( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Called when the scene is still off screen (but is about to come on screen).
        tf2.text = "(tap to submit custom event)"

    elseif ( phase == "did" ) then
        -- Called when the scene is now on screen.
        -- Insert code here to make the scene come alive.
        -- Example: start timers, begin animation, play audio, etc.
        local function changeSceneHandler ( event )
     		if "ended" == event.phase then
       		 	background:removeEventListener ( "touch", changeSceneHandler )
        	    composer.gotoScene( "scene1", { effect = "slideRight", time = 800 } )
    		end
   		end

	    -- custom event
	    local function customEventHandler ( event )

	    	if "ended" == event.phase then

	            ---------------------------------------------------------------------------
	            -- GA: Below we are submitting a custom event. 
	            -- As you will notice (when looking at the printed event in the terminal) the 
	            -- composer scene name is assigned automatically to the area parameter by     
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
end

-- -------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )

-- -------------------------------------------------------------------------------

return scene