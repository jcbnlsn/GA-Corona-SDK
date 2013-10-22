local storyboard = require( "storyboard" )
local scene = storyboard.newScene()

-- local forward references should go here --
local background, tf2

---------------------------------------------------------------------------------
-- BEGINNING OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------

-- Called when the scene's view does not exist:
function scene:createScene( event )
    local group = self.view

    background = display.newRect ( group, display.screenOriginX, display.screenOriginY, display.contentWidth-(2*display.screenOriginX), display.contentWidth-(2*display.screenOriginY) )
	background:setFillColor (226,88,0)

	local tf1 = display.newText("Storyboard: scene 2", 0, 0, native.systemFont, 20)
    tf1:setReferencePoint(display.CenterReferencePoint)
	tf1.x, tf1.y = display.contentWidth/2, (display.contentHeight/2)-12
  	tf1:setTextColor ( 20 )
    group:insert(tf1)

   	tf2 = display.newText("(tap to change scene)", 0, 0, native.systemFont, 15)
    tf2:setReferencePoint(display.CenterReferencePoint)
	tf2.x, tf2.y = display.contentWidth/2, (display.contentHeight/2)+10
  	tf2:setTextColor ( 20 )
    group:insert(tf2)
end


-- Called BEFORE scene has moved onscreen:
function scene:willEnterScene( event )
    local group = self.view

    tf2.text = "(tap to show overlay)"
end


-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
    local group = self.view

        -- show overlay
	local function touchHandler ( event )
		if "ended" == event.phase then
			background:removeEventListener ( "touch", touchHandler )
	    	storyboard.showOverlay( "overlay", { effect = "slideDown", time = 300 } )
	    end
	end
	background:addEventListener ( "touch", touchHandler )
end

-- Called if/when overlay scene is hidden/removed via storyboard.hideOverlay()
function scene:overlayEnded( event )
        local group = self.view

        tf2.text = "(tap to change scene)"

	local function touchHandler ( event )
		if "ended" == event.phase then
			background:removeEventListener ( "touch", touchHandler )
			storyboard.gotoScene( "scene3", { effect = "slideLeft", time = 800 } )
		end
	end
	background:addEventListener ( "touch", touchHandler )
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

-- "overlayEnded" event is dispatched when an overlay scene is hidden/removed
scene:addEventListener( "overlayEnded", scene )

---------------------------------------------------------------------------------

return scene