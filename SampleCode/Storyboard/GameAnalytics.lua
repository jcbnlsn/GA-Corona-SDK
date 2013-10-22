----------------------------------------------------------------------------------
-- Game Analytics for Corona SDK - Version 2.0

-- This code for the Game Analytics SDK is open source - feel free to create 
-- your own fork or rewrite it for your own needs.
--
-- For documentation see: http://support.gameanalytics.com/forums
-- Sign up and get your keys here: http://www.gameanalytics.com
--
-- Written by Jacob Nielsen for Game Analytics in 2013
----------------------------------------------------------------------------------

local GameAnalytics, sdk_version = {}, 2.0

-----------------------------------------------
-- Default values for properties
-----------------------------------------------
--Settings
GameAnalytics.isDebug                   = true
GameAnalytics.runInSimulator            = true
GameAnalytics.submitWhileRoaming        = false
GameAnalytics.archiveEvents             = true
GameAnalytics.archiveEventsLimit        = 512 	-- kilobytes 
GameAnalytics.waitForCustomUserID       = false
GameAnalytics.newSessionOnResume        = false
GameAnalytics.batchRequests             = false
GameAnalytics.batchRequestsInterval     = 30	-- seconds (minimum 1 second)

-- Quality

GameAnalytics.submitSystemInfo          = false
GameAnalytics.submitUnhandledErrors     = false
GameAnalytics.submitStackTraces         = false
GameAnalytics.submitMemoryWarnings      = false -- iOS only!
GameAnalytics.maxErrorCount             = 20    -- errors per session

-- Design
GameAnalytics.useStoryboard             = false
GameAnalytics.submitStoryboardEvents    = false

GameAnalytics.submitAverageFps          = false
GameAnalytics.submitAverageFpsInterval  = 30    -- seconds (minimum 5)

GameAnalytics.submitCriticalFps         = false
GameAnalytics.submitCriticalFpsInterval = 5     -- seconds (minimum 5)
GameAnalytics.criticalFpsRange          = 15    -- frames  (minimum 10)

GameAnalytics.criticalFpsBelow          = display.fps/2

-----------------------------------------------

local json, crypto, lfs = require "json", require "crypto", require "lfs"
local rand = math.random

local apiUrl = "http://api.gameanalytics.com"
local apiVersion = 1

local gameKey, secretKey, userId, build, sessionId, endpointUrl

local customUserID, userData
local newEvent, submitEvents

local categories = { design=true, quality=true, user=true, business=true }

local isSimulator = "simulator" == system.getInfo("environment")
local platformName = system.getInfo("platformName")

local initialized, disabled, isRoaming, hasConnection = false, false, false, true

local gameAnalyticsData, dataDirectory
local storedEventsCount, maxStoredEventsCount, errorCount = 0, 200, 0
local archiveEventsLimitReached, eventsArchived = false, false

local minBatchRequestsInterval, minAverageFpsInterval, minCriticalFpsInterval, minCriticalFpsRange = 1, 5, 5, 10

local stb, storyboard
local prt = function () end

---------------------------------------- 
-- Debug print
----------------------------------------
local msg, l, dl = {},"",""

local function initDebugPrint ()

	for i=1, 60 do l=l.."-" dl=dl.."=" end

	msg["initialized"] = function ()
		if customUserID then prt("") prt(dl) prt("Game Analytics initialized with custom user id.") prt(l)
		else prt(dl) prt("Game Analytics initialized.") prt(l) end
		if GameAnalytics.customUserID then prt("Custom user ID: "..tostring(GameAnalytics.customUserID)) 
		else prt("User ID:       "..tostring(userId)) end 
		prt("Session ID:    "..tostring(sessionId)) prt(dl) 
	end

	msg["wait"] = function () prt(l) prt("GameAnalytics initialization called. Game Analytics will") prt("initialize automatically when custom user id is set!") prt(l) end
	msg["connection"] = function () prt(l) prt("Device has connection:    "..tostring (hasConnection).."\n") prt ("Device is roaming:        "..tostring(isRoaming)) prt(l) end
	msg["save"] = function ( message ) prt(dl) prt("Saving stored events. File id: "..message..".txt") prt(dl) end
	msg["disabled"] = function () prt(l) prt("GameAnalytics is disabled in the Corona simulator.") prt(l) end
	msg["advertisingTrackingDisabled"] = function () prt(dl) prt("Advertising tracking is disabled on this device.") prt("No data will be sent to Game Analytics.") prt(dl) end
	msg["roamingWarning"] = function () prt(l) prt ( "Warning! It is not possible to detect if this device is roaming." ) prt(l) end
	msg["submittingArchivedEvents"]	= function ( message ) prt(l) prt ( "Submitting "..message[1].." archived event batch(es) from "..message[2].." session(s)") prt(l) end
	msg["submittingEventBatch"]	= function ( message ) prt(l) prt ( "Submitting "..message.." batched requests.") prt(l) end
	msg["storyboardWarning"] = function () prt(l) prt ( "Warning! You should also enable useStoryboard") prt ("if you wan't to enable submitStoryboardEvents.") prt(l) end
	msg["maxErrorCount"] = function () if errorCount-1==GameAnalytics.maxErrorCount then prt(l) prt("ErrorCount="..(errorCount-1)..": Maximum error count reached.") 
	prt ("No more errors will be submitted in this session!") prt(l) end end
	msg["newSession"] = function () prt(l) prt ( "New session id generated for resume: "..sessionId) prt(l) end

	msg["event"] = function ( message )
		
		local c, m = message[1], message[2]
		local e = "'"..c.."': "
		if #m>1 then e=e.."{ " end
		for i=1, #m do
			e=e.."{ "
			for k, v in pairs ( m[i]) do
				e=e..k.."=".."'"..v.."'"..", "
			end
			e=e:sub(0, e:len()-2)   
			e=e.." }, "
		end
		e=e:sub(0, e:len()-2)  
		if #m>1 then e=e.." } " end
		return e
	end

	prt = function ( message, id )
		if GameAnalytics.isDebug then 
			if not id then print ( "GA: "..message )
			else 
				return msg[id](message) 
			end
		end
	end
end

----------------------------------------
-- Network reachability
----------------------------------------
local function networkReachabilityListener ( event )
	hasConnection = event.isReachable
	if event.isReachable then
		isRoaming = event.isReachable == event.isReachableViaCellular
	end
	if initialized then prt ( nil, "connection" ) end
end

if network.canDetectNetworkStatusChanges then
	network.setStatusListener( "www.gameanalytics.com", networkReachabilityListener )
else
    local socket = require("socket")
    local ping = socket.tcp()
    ping:settimeout(1000)
    local connection = ping:connect("www.gameanalytics.com", 80)
    if connection == nil then hasConnection = false end
    ping:close()
    prt ( nil, "roamingWarning" )
    prt ( nil, "connection" )
end

----------------------------------------
-- Submit system info
----------------------------------------
local function submitSystemInfo ()

	local systemProperties = { 
		"model", "enviroment", "platformName", "appVersionString", "architectureInfo", "platformVersion",
		"targetAppStore", "build", "appVersionString", "androidAppVersionCode"
	}
	
	local systemInfo, index = {}, 1

	for i=1, #systemProperties do
		local message = system.getInfo(systemProperties[i])
		if message and message~="" then
			local systemProperty = {}
			systemProperty["event_id"] = "GA:SystemInfo:"..systemProperties[i]
			systemProperty["message"]  = system.getInfo(systemProperties[i])
			systemInfo[index] = systemProperty
			index=index+1
		end
	end	

	newEvent ( "systemInfo", unpack (systemInfo) )
end

----------------------------------------
-- Submit user event
----------------------------------------
local function submitUserEvent ( initial )

	local userEvent = userData or 
	{
		platform=platformName,
		os_minor=system.getInfo("platformVersion"),
		device=system.getInfo("model")..", "..system.getInfo("architectureInfo"),
		sdk_version="GA Corona SDK v."..sdk_version,
		build=build,
	}
	
	if platformName == "iPhone OS" then userEvent["ios_id"]=system.getInfo( "iosAdvertisingIdentifier" )
	elseif platformName == "Android" then userEvent["android_id"]=system.getInfo("deviceID") end

	userData = userEvent

	if initial then
		if not isSimulator then newEvent ( "user", userEvent ) end
	else
		newEvent ( "user", userEvent )
	end
end

----------------------------------------
-- Load/save data
----------------------------------------
local function saveData ( data, path )
	local fh = io.open( path, "w+" )
	local content = json.encode( data )
	fh:write( content )
	io.close( fh )
end

 local function loadData ( path )
	local fh = io.open( path, "r" )
	local data
	if fh then
		local content = fh:read( "*a" )
		if content then data = json.decode( content ) 
		io.close( fh )
		else return end
	else data = {} end
	return data
end

----------------------------------------
-- User UID workaround for iOS below 6.0
----------------------------------------
local function createUserID ()

	local data = loadData( system.pathForFile( "GameAnalyticsID.txt", system.DocumentsDirectory ) ) 
	if not data.userID then 
        local time = os.time ()
        local name, deviceInfo = system.getInfo ("name" ), system.getInfo ( "architectureInfo" )
        local chars = {"0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"}
        local randomHexTable = {} math.randomseed( time )
        for i=1,16 do randomHexTable[i]=chars[rand(1,16)] end
        local randomHex = table.concat ( randomHexTable )
        local id = time..name..deviceInfo..randomHex
        id = id:gsub("%s+", "")
        data.userID = crypto.digest( crypto.md5, id )
        saveData ( data, system.pathForFile( "GameAnalyticsID.txt", system.DocumentsDirectory ) )
	end
	return data.userID
end

----------------------------------------
-- User id
----------------------------------------
local function getUserID ()
	if platformName == "iPhone OS" then
		local userID = system.getInfo ( "iosAdvertisingIdentifier" )
		return userID or createUserID()
	else
		return system.getInfo ( "deviceID" )
	end
end

----------------------------------------
-- Session id
----------------------------------------
local function createSessionID ( init )
	local time = os.time ()
	local sid = crypto.digest( crypto.md5, userId..time )
	if not init then prt(nil, "newSession") end
	return sid
end

----------------------------------------
-- Archive Events
----------------------------------------
local function archiveEvents ()
	if gameAnalyticsData then
		local fileName = os.time()
		local path = system.pathForFile( "/GameAnalyticsData/"..fileName..".txt", system.CachesDirectory )
		saveData ( gameAnalyticsData, path )
		gameAnalyticsData = nil
		eventsArchived = true
		prt ( fileName, "save" )
	
		if not archiveEventsLimitReached then
			if (lfs.attributes ( dataDirectory ).size) > GameAnalytics.archiveEventsLimit*1000 then
				archiveEventsLimitReached = true
			end
		end
	end
end

local function storeEvent ( reason, category, events )
	if GameAnalytics.archiveEvents then
		if archiveEventsLimitReached then
			prt ( "Event: size limit for archived events reached (event data will be lost)" )
		else
			if not gameAnalyticsData then gameAnalyticsData = { session_id=sessionId, user_id=userId, build=build, categories={} } end
			if not gameAnalyticsData.categories[category] then gameAnalyticsData.categories[category] = {} end
			
			for i=1,#events do 
				local event = events[i]
				local index = #gameAnalyticsData.categories[category]+1 
				gameAnalyticsData.categories[category][index] = event
			end
			prt ( "Storing event > category: "..category.." (reason: "..reason..")" )
			storedEventsCount = storedEventsCount + 1
			if storedEventsCount >= maxStoredEventsCount then 
				archiveEvents ()
				storedEventsCount = 0
			end
		end
	else
		prt ( "Can't submit event ("..reason.."). Archiving disabled (event data will be lost)" )
	end
end

local function submitArchivedEvents ()
	timer.performWithDelay ( 500, function ()
		if hasConnection then
			if not GameAnalytics.submitWhileRoaming and isRoaming then 
			else
				local eventCount, sessionCount = 0, 0
				for file in lfs.dir( dataDirectory ) do
					local data = loadData ( system.pathForFile( "/GameAnalyticsData/"..file, system.CachesDirectory ) )
					if data then
						sessionCount = sessionCount+1
						for k,v in pairs( categories ) do
							if data[k] then
								for i=1,#data[k] do
									if not data[k][i].session_id then
										data[k][i].session_id=data.session_id
										data[k][i].user_id=data.user_id
										data[k][i].build=data.build
									end
								end
								eventCount = eventCount+1
								newEvent ( k, unpack (data[k]) )  
							end 
						end
						os.remove ( dataDirectory.."/"..file )
					end
				end

				if eventCount>0 then prt ( { eventCount, sessionCount }, "submittingArchivedEvents" ) end 
				eventsArchived = false
			end
		end
	end )
end

local function submitStoredEvents ()
	if hasConnection then
		if not GameAnalytics.submitWhileRoaming and isRoaming then 
		else
			if gameAnalyticsData then
				local eventCount = 0
				for k,v in pairs( gameAnalyticsData.categories ) do
					eventCount = eventCount+1
					submitEvents ( k, unpack (v) )  
				end
				gameAnalyticsData = nil
				if eventCount>0 then prt ( eventCount, "submittingEventBatch" ) end 
			end
			if eventsArchived then submitArchivedEvents () end
		end
	end
end

local function initBatchRequests ()
	if GameAnalytics.batchRequestsInterval < minBatchRequestsInterval then
		error ( "GA: Minimum value for batchRequestsInterval is "..minBatchRequestsInterval.." second!", 3 )
	else
		timer.performWithDelay( GameAnalytics.batchRequestsInterval*1000, submitStoredEvents, 0 )
	end
end

----------------------------------------
-- Setup archiving
----------------------------------------
 local function initArchiving ()
	if lfs.chdir( system.pathForFile( "", system.CachesDirectory ) ) then 
		if not ( lfs.attributes( (lfs.currentdir().."/GameAnalyticsData"):gsub("\\$",""),"mode") == "directory" ) then
			lfs.mkdir( "GameAnalyticsData" )
		end
		dataDirectory = lfs.currentdir().."/GameAnalyticsData"
	end
	submitArchivedEvents () 
end

----------------------------------------
-- Unhandled errors and memory warnings
----------------------------------------
local function unhandledErrorListener ( event )
	errorCount = errorCount+1
	if errorCount <= GameAnalytics.maxErrorCount then
		local e = {}
		if GameAnalytics.submitUnhandledErrors then e[#e+1]={ event_id = "GA:UnhandledError:ErrorMessage", message=event.errorMessage } end
		if GameAnalytics.submitStackTraces then e[#e+1]={ event_id = "GA:UnhandledError:StackTrace", message=event.stackTrace } end
		newEvent ( "unhandledError", e[1], e[2] )
	else prt( nil, "maxErrorCount" ) end
end

local function memoryWarningListener ( event ) 
	errorCount = errorCount+1
	if errorCount <= GameAnalytics.maxErrorCount then
		newEvent ( "memoryWarning", { event_id = "GA:MemoryWarning", message=event.name } )
	else prt( nil, "maxErrorCount" ) end
end

local function initSubmitUnhandledErrors ()
	if not isSimulator then
		Runtime:addEventListener( "unhandledError", unhandledErrorListener ) 
	end
end

local function initSubmitMemoryWarnings ()
	if platformName == "iPhone OS" then 
		Runtime:addEventListener( "memoryWarning", memoryWarningListener )
	end
end

----------------------------------------
-- Average / critical fps
----------------------------------------
local averageFps, criticalFpsRange = display.fps, GameAnalytics.criticalFpsRange
local criticalFpsSubmitEnabled = false

local r, st = math.round, system.getTimer
local dm, uc, tt, int, pt = 0, 0, 0, 0, 0

local function enableCriticalFps () criticalFpsSubmitEnabled = true end

local function submitCriticalFps ( fps )
	criticalFpsSubmitEnabled = false
	errorCount = errorCount+1
	if errorCount <= GameAnalytics.maxErrorCount then
		newEvent ( "criticalFps", { event_id="GA:CriticalFps", value=fps })
		timer.performWithDelay( GameAnalytics.submitCriticalFpsInterval*1000, enableCriticalFps )
	else prt (nil, "maxErrorCount") end
end

local function deltaTime()
	if int==0 then
	    local ct = st()
	    local dt = ct - pt 
	    pt, uc, tt = ct, uc+criticalFpsRange, tt+dt

	    if criticalFpsSubmitEnabled then
		    local td = tt/uc
		    if dm<td then
		    	local fps = r(1000/(td))
		    	submitCriticalFps ( fps )
		    end
		end
	end
	int=int+1
	if int==criticalFpsRange then int=0 end   
end

local function submitAverageFps ()
	local td = tt/uc
	local fps = r(1000/(td))
	newEvent ( "averageFps", { event_id="GA:AverageFps", value=fps })
	uc,tt = 0,0
end

local function initSubmitFps ()
	if GameAnalytics.submitAverageFpsInterval < minAverageFpsInterval then
		error ( "GA: Minimum value for submitAverageFpsInterval is "..minAverageFpsInterval.." seconds!", 3 )
	elseif GameAnalytics.submitCriticalFpsInterval < minCriticalFpsInterval then
		error ( "GA: Minimum value for submitCriticalFpsInterval is "..minCriticalFpsInterval.." seconds!", 3 )
	elseif GameAnalytics.criticalFpsRange < minCriticalFpsRange then
		error ( "GA: Minimum value for criticalFpsRange is "..minCriticalFpsRange.." seconds!", 3 )
	else
		dm = 1000/GameAnalytics.criticalFpsBelow
		Runtime:addEventListener("enterFrame", deltaTime)
		if GameAnalytics.submitCriticalFps then criticalFpsSubmitEnabled = true end
		if GameAnalytics.submitAverageFps then
			timer.performWithDelay( GameAnalytics.submitAverageFpsInterval*1000, submitAverageFps, 0 )
		end
	end
end

 
----------------------------------------
-- System event
----------------------------------------
local function onSystemEvents ( event )

	if event.type == "applicationExit" then
		if GameAnalytics.archiveEvents then archiveEvents () end

	elseif event.type == "applicationSuspend" then
		if stb then
			if stb.enterSceneTime then stb.applicationSuspendedSceneTime = os.time()-stb.enterSceneTime end
			if stb.enterOverlayTime then stb.applicationSuspendedOverlayTime = os.time()-stb.enterOverlayTime end
		end
		if GameAnalytics.newSessionOnResume and GameAnalytics.archiveEvents then archiveEvents () end

	elseif event.type == "applicationResume" then
		if stb then
			if stb.applicationSuspendedSceneTime and stb.enterSceneTime then stb.enterSceneTime = os.time()-stb.applicationSuspendedSceneTime end
			if stb.applicationSuspendedOverlayTime and stb.enterOverlayTime then stb.enterOverlayTime = os.time()-stb.applicationSuspendedOverlayTime end
			stb.applicationSuspendedOverlayTime, stb.applicationSuspendedOverlayTime = nil, nil
		end
		
		if GameAnalytics.archiveEvents then initArchiving() end
		if GameAnalytics.newSessionOnResume then 
			sessionId = createSessionID() 
			errorCount = 0
			enableCriticalFps ()
		end
	end
end

----------------------------------------
-- Storyboard events
----------------------------------------
local addStoryboardEventListeners, storyboardEventHandler
local eventListeners = { "enterScene", "didExitScene", "overlayBegan", "overlayEnded" }

storyboardEventHandler = function ( e )

	local storyboardEvent 

	if e.name == "enterScene" then
		
		local previousSceneName = storyboard.getPrevious()
		stb.currentSceneName = storyboard.getCurrentSceneName()
		stb.enterSceneTime = os.time()

		storyboardEvent = { event_id="GA:Storyboard:EnterScene", area=stb.currentSceneName }

	elseif e.name == "didExitScene" then

		for i=1,#eventListeners do stb.currentScene:removeEventListener( eventListeners[i], storyboardEventHandler ) end
		
		local timeSpentOnScene = os.time() - stb.enterSceneTime
		local nextSceneName = storyboard.getCurrentSceneName()

		storyboardEvent = { event_id = "GA:Storyboard:ExitScene", area=stb.currentSceneName, value=timeSpentOnScene }

		stb.currentSceneName = nextSceneName
		stb.currentScene = storyboard.getScene( nextSceneName )
		addStoryboardEventListeners ( stb.currentScene ) 
	
	elseif e.name == "overlayBegan" then

		stb.enterOverlayTime = os.time()
		storyboardEvent = { event_id="GA:Storyboard:OverlayBegan", area=stb.currentSceneName..":"..e.sceneName }
	
	elseif e.name == "overlayEnded" then

		local timeSpentOnOverlay = os.time() - stb.enterOverlayTime
		storyboardEvent = { event_id="GA:Storyboard:OverlayEnded", area=stb.currentSceneName..":"..e.sceneName, value=timeSpentOnOverlay }
	end

	if GameAnalytics.submitStoryboardEvents and storyboardEvent then newEvent ( "storyboard", storyboardEvent ) end
end

addStoryboardEventListeners = function ()
	for i=1,#eventListeners do 
		stb.currentScene:addEventListener( eventListeners[i], storyboardEventHandler ) 
	end
end

local function initStoryboardListener ()
	storyboard, stb = require "storyboard", {}
	local sceneName = storyboard.getCurrentSceneName()
	if sceneName then
		timer.performWithDelay( 20, function ()
			stb.currentScene = storyboard.getScene( sceneName )
			addStoryboardEventListeners ()
		end )
	else
		error ( "GA: You MUST require storyboard and call storyboard.gotoScene BEFORE initializing Game Analytics in your main file.", 3 )
	end
end

----------------------------------------
-- Submit events
----------------------------------------
local alias = { systemInfo="quality", storyboard="design", unhandledError="quality", memoryWarning="quality", averageFps="design", criticalFps="design" }

submitEvents = function ( category, ... )

	local params, headers, message = {}, {}, {...}

	local eventType 
	if alias[category] then 
		eventType = category
		category = alias[category] 
	else 
		eventType = "custom"
	end

	local dbgMsg = prt ( { category, message }, "event" )
			
	for k,v in pairs( message ) do
	
		if type(v) ~= "table" then error("GA: Attempt to submit non-table event!", 4) end  

		if not v["session_id"] then
			v["build"]		= build
			v["session_id"]	= sessionId
			v["user_id"] 	= userId
		else
			eventType = "archived"
		break end
	end

	local json_message = json.encode ( message )
	params.body = json_message

	local signature = json_message..secretKey
	headers['Authorization'] = crypto.digest( crypto.md5, signature )
	headers['Content-Type'] = "application/json"
	params.headers = headers
	
	local post_url = endpointUrl..category
	
	local function networkListener( event ) 
		if ( event.isError ) then
			storeEvent ( "unknown error, status="..tostring(event.status), category, message )
		else
			if GameAnalytics.isDebug then
				dbgMsg = "Submitting "..eventType.." event(s): "..dbgMsg.." - Server response: "..event.response
				prt(dbgMsg)
			end
		end
	end

	network.request( post_url, "POST", networkListener, params)
end

----------------------------------------
-- Private: New event
----------------------------------------
newEvent = function ( category, ... )
	if not disabled then

		local message, area = {...}
		
		if stb and stb.currentSceneName then 
			local area = stb.currentSceneName
			if category~="user" then
				for k,v in pairs( message ) do
					v["area"] = v["area"] or area
				end
			end
		end
		
		if GameAnalytics.batchRequests then
			storeEvent (  "batch requests", category, message )
				
		elseif hasConnection then
			if not GameAnalytics.submitWhileRoaming and isRoaming then
				storeEvent (  "roaming", category, message )
			else
				submitEvents ( category, ... )
			end
		else
			storeEvent ( "no connection", category, message )
		end
	end
end

----------------------------------------
-- Public: Initialize
----------------------------------------
function GameAnalytics.init ( params )

	if GameAnalytics.isDebug then initDebugPrint () end
	
	if isSimulator and not GameAnalytics.runInSimulator then
		prt ( nil, "disabled" )
		disabled = true
	elseif platformName=="iPhone OS" and system.getInfo("iosAdvertisingTrackingEnabled")==false then
		prt ( nil, "advertisingTrackingDisabled" )
		disabled = true
	else
		if initialized then
			error ( "GA: You already initialized Game Analytics.", 2 )
		else
			initialized = true
			if params then gameKey, secretKey, build = params["game_key"], params["secret_key"], params["build_name"] end
			
			if not gameKey 	then error ( "GA: You have to supply a game_key when initializing!", 2 ) end
			if not secretKey 	then error ( "GA: You have to supply a secret_key when initializing!", 2 ) end
			if not build 		then error ( "GA: You have to supply a build_name when initializing!", 2 ) end

			if GameAnalytics.waitForCustomUserID and customUserID == nil then
				prt ( nil, "wait" )
			else
				userId= customUserID or getUserID()
				sessionId = createSessionID( true )

				endpointUrl = apiUrl.."/"..apiVersion.."/"..gameKey.."/"

				if GameAnalytics.archiveEvents then initArchiving() end
				if GameAnalytics.batchRequests then initBatchRequests () end
				if GameAnalytics.useStoryboard then initStoryboardListener() end
				if GameAnalytics.submitMemoryWarnings then initSubmitMemoryWarnings() end
				if GameAnalytics.submitUnhandledErrors or GameAnalytics.submitStackTraces then initSubmitUnhandledErrors() end
				if GameAnalytics.submitAverageFps or GameAnalytics.submitCriticalFps then initSubmitFps () end
				if GameAnalytics.submitSystemInfo then timer.performWithDelay ( 100, submitSystemInfo ) end
				submitUserEvent ( true )

				Runtime:addEventListener( "system", onSystemEvents )
				prt ( nil, "initialized" )

				if not GameAnalytics.useStoryboard and GameAnalytics.submitStoryboardEvents then
					prt ( nil, "storyboardWarning")
				end
			end
		end
	end
end

----------------------------------------
-- Public: New event
---------------------------------------- 
function GameAnalytics.newEvent ( category, ... )
	
	if not disabled then		
		if userId then
			if categories[category] then
				newEvent ( category,...)
			else
				error ( "GA: Category error! '"..category.."' is not a valid category.", 2 )
			end
		else
			if GameAnalytics.waitForCustomUserID and not customUserID then
				prt ( "Event discarded. Waiting for custom user id!" )
			else
				error ( "GA: You have to initialize Game Analytics before submitting events!", 2 )
			end
		end
	end
end

----------------------------------------
-- Public: Set custom user id
---------------------------------------- 
function GameAnalytics.setCustomUserID ( id ) 

	if not disabled then
		if initialized then
			if GameAnalytics.waitForCustomUserID then
				customUserID = id
				prt ( "Custom user id set. Initializing GameAnalytics now..." )
				initialized = false
				GameAnalytics.init ()
			else
				error ( "GA: Set waitForCustomUserID to true if you want to set a custom user id after initializing!", 2 )
			end
		else
			customUserID = id
		end
		GameAnalytics.setCustomUserID = function () prt ( "Warning! You already supplied a custom user id. Your request will be ignored.") end
	end
end

----------------------------------------
-- Public: Get user id
---------------------------------------- 
function GameAnalytics.getUserID ()

	if GameAnalytics.waitForCustomUserID and not customUserID then 
		error ( "GA: You can't retrieve the user id because Game Analytics is waiting for you to set a custom user id.", 2 ) 
	elseif not initialized and not customUserID then 
		error ( "GA: Warning! You have to initialize Game Analytics before you can call getUserID()", 2 )
	end
	return userId or customUserID
end

----------------------------------------
-- Public: Set acquisition properties
---------------------------------------- 
function GameAnalytics.setAcquisition ( id, value )

	if not disabled then
		if initialized then
			local properties = { "publisher", "site", "campaign", "adgroup", "ad", "keyword" }
			if not table.indexOf ( properties, id ) then
				error ( "GA: The acquisition id you are trying to set is not valid.", 2 )
			else
				userData["install_"..id] = value
				submitUserEvent ()
			end
		else
			error ( "GA: You have to initialize Game Analytics before you can set acquisition properties.", 2 )
		end
	end
end

return GameAnalytics
