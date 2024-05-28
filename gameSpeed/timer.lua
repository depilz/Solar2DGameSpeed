-------------------------------------------------------------------------------
--
-- Corona Labs
--
-- timer.lua
--
-- Code is MIT licensed; see https://www.coronalabs.com/links/code/license
--
-------------------------------------------------------------------------------
local tInsert = table.insert
local tRemove = table.remove
local getTimer = system.getTimer

-- NOTE: timer is assigned to the global var "timer" on startup.
-- This file should follow standard Lua module conventions
local timer = {
	_runlist = {},
	_pausedTimers = {},
	allowIterationsWithinFrame = false,
}
local toInsert = {}

function timer.performWithDelay( delay, listener, varA, varB )
	-- varA and varB are optional "iterations" and "tag" parameters.
	local iterations = "number" == type(varA) and varA or nil
	local tag = "string" == type(varA) and varA or "string" == type(varB) and varB or ""

	local entry
	local t = type(listener)
	if "function" == t or ( "table" == t and "function" == type( listener.timer ) ) then
		-- faster to access a local timer var than a global one
		local timer = timer

		local fireTime = getTimer() + delay

		entry = { _listener = listener, _time = fireTime }

		if nil ~= iterations and type(iterations) == "number" then
			-- pre-subtract out one iteration, so for an initial value of...
			--   ...1, it's a no-op b/c we always fire at least once
			--   ...0, it become -1 which we will interpret as forever
			iterations = iterations - 1
			if iterations ~= 0 then
				entry._delay = delay
				entry._iterations = iterations
			end
		end

		entry._count = 1
		entry._tag = tag
		entry._inFrameIterations = timer.allowIterationsWithinFrame

		timer._insert( timer, entry, fireTime )

	end

	return entry
end

-- returns (time left until fire), (number of iterations left)
function timer.cancel( whatToCancel )
	local t = type( whatToCancel )
	if "string" ~= t and "table" ~= t then
		error("timer.cancel(): invalid timerId or tag (table or string expected, got "..t..")", 2)
	end

	-- Since pausing timers removes them from runlist, it means that both runlist
	-- and pausedTimers must be checked when cancelling timers using a tag.
	local list = {}
	if "table" == t then
		list[1] = whatToCancel
	else
		local runlist = timer._runlist
		for i = 1, #runlist do
			list[#list+1] = runlist[i]
		end
		local pausedTimers = timer._pausedTimers
		for i = 1, #pausedTimers do
			list[#list+1] = pausedTimers[i]
		end
		for i = 1, #toInsert do
			list[#list+1] = toInsert[i]
		end
	end
	local isTag = ("string" == t)

	for i = #list, 1, -1 do
		local v = list[i]
		-- If a tag was specified, then cancel all timers that share the tag,
		-- otherwise cancel only the specific timer that was specified.
		if (isTag and whatToCancel == v._tag) or whatToCancel == v then
			-- flag for removal from runlist
			v._cancelled = true
			-- prevent from being resumed
			v._expired = true
			
			if not isTag then
				-- Information is only returned when a specific timer is cancelled.
				local fireTime = v._time
				local baseTime = v._pauseTime
				if ( not baseTime ) then
					baseTime = getTimer()
				end
		
				return ( fireTime - baseTime ), ( v._iterations or 0 ) + 1
			end
		end
	end
end

function timer.pause( whatToPause, _pauseAll )
	local t = type( whatToPause )
	if "string" ~= t and "table" ~= t then
		error("timer.pause(): invalid timerId or tag (table or string expected, got "..t..")", 2)
	end
	
	local isTag = ("string" == t)
	
	-- If user is pausing timers using a tag or pauseAll(), then there won't be warning texts and nothing is returned to user.
	if not _pauseAll and ( not isTag and whatToPause._expired ) then
		print( "WARNING: timer.pause( timerId ) cannot pause a timerId that is already expired." )
		return 0
	elseif not _pauseAll and ( not isTag and whatToPause._pauseTime ) then
		print( "WARNING: timer.pause( timerId ) ignored because timerId is already paused." )
		return 0
	else
		local list = {}
		local pausedTimers = timer._pausedTimers
		if "table" == t then
			list[1] = whatToPause
		else
			local runlist = timer._runlist
			for i = 1, #runlist do
				list[#list+1] = runlist[i]
			end
			for i = 1, #toInsert do
				list[#list+1] = toInsert[i][2]
			end
		end
		
		for i = #list, 1, -1 do
			local v = list[i]
			if (isTag and whatToPause == v._tag and not v._expired and not v._pauseTime) or whatToPause == v then
				pausedTimers[#pausedTimers+1] = v
				local pauseTime = getTimer()
				v._pauseTime = pauseTime
				timer._remove( v )
				if not isTag then
					return ( v._time - pauseTime )
				end
			end
		end
	end
end

function timer.resume( whatToResume, _resumeAll )
	local t, msg = type( whatToResume )
	if "string" ~= t and "table" ~= t then
		error("timer.resume(): invalid timerId or tag (table or string expected, got "..t..")", 2)
	end
	
	local isTag = ("string" == t)

	-- If user is resuming timers using a tag or resumeAll(), then there won't be warning texts and nothing is returned to user.
	if not _resumeAll and ( not isTag and whatToResume._expired ) then
		print( "WARNING: timer.resume( timerId ) cannot resume a timerId that is already expired." )
		return 0
	elseif not _resumeAll and ( not isTag and not whatToResume._pauseTime ) then
		print( "WARNING: timer.resume( timerId ) ignored because timerId was not paused." )
		return 0
	else
		local list = {}
		if "table" == t then
			list[1] = whatToResume
		else
			local pausedTimers = timer._pausedTimers
			for i = 1, #pausedTimers do
				list[i] = pausedTimers[i]
			end
		end
		
		for i = #list, 1, -1 do
			local v = list[i]
			
			if not v._expired and v._pauseTime and (isTag and whatToResume == v._tag or not isTag and whatToResume == v) then
				local timeLeft = v._time - v._pauseTime
				local fireTime = getTimer() + timeLeft
				v._time = fireTime
				v._pauseTime = nil
				tRemove( timer._pausedTimers, i )
				
				if ( v._removed ) then
					timer._insert( timer, v, fireTime )
				end
				if not isTag then
					return timeLeft
				end
			end
		end
	end
end

function timer.pauseAll()
	local runlist = timer._runlist
	for i = #runlist, 1, -1 do
		timer.pause( runlist[i], true )
	end
	for i = #toInsert, 1, -1 do
		timer.pause( toInsert[i][2], true )
	end
end

function timer.resumeAll()
	local pausedTimers = timer._pausedTimers
	for i = #pausedTimers, 1, -1 do
		timer.resume( pausedTimers[i], true )
	end
end

function timer.cancelAll()
	local runlist = timer._runlist
	for i = #runlist, 1, -1 do
		timer.cancel( runlist[i] )
	end
	local pausedTimers = timer._pausedTimers
	for i = #pausedTimers, 1, -1 do
		timer.cancel( pausedTimers[i] )
	end
	for i = #toInsert, 1, -1 do
		timer.cancel( toInsert[i][2] )
	end
end

function timer._updateNextTime()
	local runlist = timer._runlist

	if #runlist > 0 then
		if timer._nextTime == nil then
			Runtime:addEventListener( "enterFrame", timer )
		end
		timer._nextTime = runlist[#runlist]._time
	else
		timer._nextTime = nil
		Runtime:removeEventListener( "enterFrame", timer )
	end
end

function timer._insert( timer, entry, fireTime )
	local runlist = timer._runlist
	
	-- sort in decreasing fireTime
	local index = #runlist + 1
	for i,v in ipairs( runlist ) do
		if v._time < fireTime then
			index = i
			break
		end
	end
	tInsert( runlist, index, entry )
	entry._removed = nil

	--print( "inserting entry firing at: "..fireTime.." at index: "..index )

	-- last element is the always the next to fire
	-- cache its fire time
	timer._updateNextTime()
end

function timer._remove( entry )
	local runlist, inRunlist = timer._runlist, false
	
	for i,v in ipairs( runlist ) do
		if v == entry then
			inRunlist = true
			entry._removed = true
			tRemove( runlist, i )
			break
		end
	end
	if not inRunlist then
		for i,v in ipairs( toInsert ) do
			if v == entry then
				entry._removed = true
				tRemove( toInsert, i )
				break
			end
		end
	end

	timer._updateNextTime()

	return entry
end

function timer:enterFrame( event )
	-- faster to access a local timer var than a global one
	local timer = timer

	local runlist = timer._runlist
	-- Clean up the table on every frame
	for i = 1, #toInsert do
		toInsert[i] = nil
	end

	-- If the listener throws an error and the runlist was empty, then we may
	-- not have cleaned up properly. So check that we have a non-empty runlist.
	if #runlist > 0 then
		local currentTime = getTimer()
		local timerEvent = { name="timer", time=currentTime }

		--print( "T(cur,fire) = "..currentTime..","..timer._nextTime )
		-- fire all expired timers
		while currentTime >= timer._nextTime do
			local entry = runlist[#runlist]
			timer._remove(entry)

			-- we cannot modify the runlist array, so we use _cancelled and _pauseTime
			-- flags to ensure that listeners are not called.
			if not entry._expired and not entry._cancelled and not entry._pauseTime then
				local iterations = entry._iterations

				timerEvent.source = entry
				local count = entry._count
				if count then
					timerEvent.count = count
					entry._count = count + 1
				end

				local listener = entry._listener
				if type( listener ) == "function" then
					listener( timerEvent )
				else
					-- must be a table b/c we only add when type is table or function
					local method = listener.timer
					method( listener, timerEvent )
				end

				if iterations then
					
					if iterations == 0 then
						entry._iterations = nil
						entry._delay = nil

						-- We need to expire the entry here if we don't want the extra trigger [Alex]
						iterations = nil
						entry._expired = true
					else
						if iterations > 0 then
							entry._iterations = iterations - 1
						end

						local fireTime = entry._time + entry._delay
						entry._time = fireTime
						if entry._inFrameIterations then
							timer._insert( timer, entry, fireTime )
						else
							toInsert[#toInsert+1] = {timer, entry, fireTime}
						end
					end
				else
					-- mark timer entry so we know it's finished
					entry._expired = true
				end
			end

			if ( timer._nextTime == nil ) then
				break;
			end
		end
		for i,v in ipairs(toInsert) do
			timer._insert(unpack(v))
		end
	end
end

return timer