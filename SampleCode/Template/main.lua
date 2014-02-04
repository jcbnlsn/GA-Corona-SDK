---------------------------------------------------------------------------------
-- Game Analytics for Corona SDK: Template
---------------------------------------------------------------------------------

local GA = require ( "GameAnalytics" )

---------------------------------------------------------------------------------
-- Game Analytics properties with default values.
---------------------------------------------------------------------------------
-- To get an overview all the properties you can set are listed below.
-- To simplify your code you can omit the ones you don't want to change from their default values.

--Settings
GA.isDebug                   = true
GA.runInSimulator            = true

GA.submitWhileRoaming        = false
GA.waitForCustomUserID       = false
GA.newSessionOnResume        = false

GA.archiveEvents             = true
GA.archiveEventsLimit        = 512      -- kilobytes 

GA.batchRequests             = false
GA.batchRequestsInterval     = 30       -- seconds (minimum 1 second)

-- Built in quality events
GA.submitSystemInfo          = false

-- Built in error events
GA.submitUnhandledErrors     = false
GA.submitMemoryWarnings      = false    -- iOS only!
GA.maxErrorCount             = 20       -- errors per session

-- Built in design events
GA.useStoryboard             = false
GA.submitStoryboardEvents    = false

GA.useComposer				= false
GA.submitComposerEvents		= false

GA.submitAverageFps          = false
GA.submitAverageFpsInterval  = 30       -- seconds (minimum 5)

GA.submitCriticalFps         = false
GA.submitCriticalFpsInterval = 5        -- seconds (minimum 5)
GA.criticalFpsRange          = 15       -- frames  (minimum 10)

GA.criticalFpsBelow          = display.fps/2 -- half the fps value you set in the config.lua file

---------------------------------------------------------------------------------
-- Initialize Game Analytics.
---------------------------------------------------------------------------------
GA.init ({
	game_key   = 'paste_your_game_key_here',
	secret_key = 'paste_your_secret_key_here',
	build_name = '1.0',
})

---------------------------------------------------------------------------------
-- Game Analytics setters/getters ( Only call these after initialization )
---------------------------------------------------------------------------------
--GA.setCustomUserID ( "custom_user_id" )  -- In case you want to use your own user id. For example if the app has it's own email sign-in.
                                           -- Remember to set GA.waitForCustomUserID to true if you want to use this!

--GA.getUserID ()                          -- returns the UID GA uses.






