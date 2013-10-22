local storyboard = require( "storyboard" )
local scene = storyboard.newScene()

-- local forward references should go here --
local window

---------------------------------------------------------------------------------
-- BEGINNING OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------

-- Called when the scene's view does not exist:
function scene:createScene( event )
    local group = self.view

    window = display.newRoundedRect ( group, 0,0, display.contentWidth/1.5, display.contentHeight/1.5, 5 )
    window:setReferencePoint(display.CenterReferencePoint)
    window.strokeWidth = 1
    window:setStrokeColor( 0 )
    window.x, window.y = display.contentWidth/2, display.contentHeight/2

    local tf1 = display.newText("Storyboard: overlay", 0, 0, native.systemFont, 20)
    tf1:setReferencePoint(display.CenterReferencePoint)
    tf1.x, tf1.y = display.contentWidth/2, (display.contentHeight/2)-12
    tf1:setTextColor ( 20 )
    group:insert(tf1)

    tf2 = display.newText("(tap to close)", 0, 0, native.systemFont, 15)
    tf2:setReferencePoint(display.CenterReferencePoint)
    tf2.x, tf2.y = display.contentWidth/2, (display.contentHeight/2)+10
    tf2:setTextColor ( 20 )
    group:insert(tf2)
end

-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
    local group = self.view

    local function tapHandler ( event )
        if "ended" == event.phase then 
            window:removeEventListener ( "touch", tapHandler )
            storyboard.hideOverlay( true, "slideUp", 300 )
        end
    end
    window:addEventListener ( "touch", tapHandler )
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