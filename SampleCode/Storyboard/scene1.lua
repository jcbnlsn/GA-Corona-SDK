local storyboard = require( "storyboard" )
local scene = storyboard.newScene()

-- local forward references should go here --
local background

---------------------------------------------------------------------------------
-- BEGINNING OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------

-- Called when the scene's view does not exist:
function scene:createScene( event )
    local group = self.view

    background = display.newRect ( group, display.screenOriginX, display.screenOriginY, display.contentWidth-(2*display.screenOriginX), display.contentWidth-(2*display.screenOriginY) )
	background:setFillColor (36,36,36)

    local tf1 = display.newText("Storyboard: scene 1", 0, 0, native.systemFont, 20)
    tf1:setReferencePoint(display.CenterReferencePoint)
	tf1.x, tf1.y = display.contentWidth/2, (display.contentHeight/2)-12
  	tf1:setTextColor ( 220 )
    group:insert(tf1)

    local tf2 = display.newText("(tap to change scene)", 0, 0, native.systemFont, 15)
    tf2:setReferencePoint(display.CenterReferencePoint)
	tf2.x, tf2.y = display.contentWidth/2, (display.contentHeight/2)+10
  	tf2:setTextColor ( 220 )
    group:insert(tf2)
end


-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
    local group = self.view

	local function touchHandler ( event )
		if "ended" == event.phase then
			background:removeEventListener ( "touch", touchHandler )
			storyboard.gotoScene( "scene2", { effect = "slideLeft", time = 800 } )
		end
	end
	background:addEventListener ( "touch", touchHandler )
end

---------------------------------------------------------------------------------
-- END OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------

-- "createScene" event is dispatched if scene's view does not exist
scene:addEventListener( "createScene", scene )

-- "enterScene" event is dispatched whenever scene transition has finished
scene:addEventListener( "enterScene", scene )

---------------------------------------------------------------------------------

return scene