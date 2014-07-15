local composer = require( "composer" )
local scene = composer.newScene()

-- -----------------------------------------------------------------------------------------------------------------
-- All code outside of the listener functions will only be executed ONCE unless "composer.removeScene()" is called.
-- -----------------------------------------------------------------------------------------------------------------

-- local forward references should go here
local background

-- -------------------------------------------------------------------------------

-- "scene:create()"
function scene:create( event )

    local sceneGroup = self.view

    -- Initialize the scene here.
    -- Example: add display objects to "sceneGroup", add touch listeners, etc.

    background = display.newRect ( sceneGroup, display.screenOriginX, display.screenOriginY, display.contentWidth-(2*display.screenOriginX), display.contentWidth-(2*display.screenOriginY) )
    background:setFillColor (36/255,36/255,36/255)
    background.anchorX, background.anchorY = 0,0

    local tf1 = display.newText("Composer: scene 1", 0, 0, native.systemFont, 20)
    tf1.x, tf1.y = display.contentWidth/2, (display.contentHeight/2)-12
    tf1:setFillColor ( 220/255 )
    sceneGroup:insert(tf1)

    local tf2 = display.newText("(tap to change scene)", 0, 0, native.systemFont, 15)
    tf2.x, tf2.y = display.contentWidth/2, (display.contentHeight/2)+10
    tf2:setFillColor ( 220/255 )
    sceneGroup:insert(tf2)
end

-- "scene:show()"
function scene:show( event )

    local sceneGroup = self.view
    local phase = event.phase

     if ( phase == "did" ) then    
        local function touchHandler ( event )
            if "ended" == event.phase then
                background:removeEventListener ( "touch", touchHandler )
                composer.gotoScene( "scene2", { effect = "slideLeft", time = 800 } )
            end
        end
        background:addEventListener ( "touch", touchHandler )
    end
end

-- -------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )

-- -------------------------------------------------------------------------------

return scene