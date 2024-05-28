local Controller = {
  _VERSION     = 'GameSpeed v1.0.0',
  _DESCRIPTION = 'Game speed control for Solar2D',
  _URL         = 'https://github.com/depilz/Solar2DGameSpeed',
  _LICENSE     = [[
    MIT LICENSE

    Copyright (c) 2024 Studycat Limited

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]]
}


--[[ 
    ⚠️ DISCLAIMER:
    It is possible to experience some bugs or glitches when changing the game speed. So be careful 
    when using this feature.
    
    🎮 CONTROLS:
    space bar - Press the space bar to toggle auto speed up
    ← Hold the left arrow key to slow down the game
    → Hold the right arrow key to speed up the game
    ↑ Press the up arrow key to make it faster
    ↓ Press the down arrow key to make it slower
]]--


local timeScale = 1

local systemGetTimer = system.getTimer
local timerStart = systemGetTimer()
local physics = require("physics")

-- local osDate = os.date
-- local timeStart = os.time()

-- local startTimer = systemGetTimer()
local prevTimer = systemGetTimer()
local scaledTimer = systemGetTimer()

local autoSpeeding = false

local clockStart = os.clock()


local function getTimer(timer)
    timer = timer or systemGetTimer()
    return scaledTimer + (timer - prevTimer) * timeScale
end


function system.getTimer()
    return getTimer()
end

-- Messing with the date can cause bugs across sessions on features that rely on this value.
-- function os.date(format, date)
--     date = date or (timeStart + (scaledTimer - startTimer))

--     return osDate(format, date)
-- end

function os.clock(...)
    return getTimer() + clockStart - timerStart
end

-- local audioGetDuration = audio.getDuration

-- function audio.getDuration(...)
--     return (audioGetDuration(...) or 0) / timeScale
-- end


local frameCounter = 0
Runtime:addEventListener("enterFrame", function(e)
    local originalTime = e.time
    local originalPrevTime = prevTimer
    scaledTimer = getTimer(e.time)
    prevTimer = originalTime
    e.time = scaledTimer
    
    -- return if this is not an actual enterFrame event
    if e.fake then return end
        
    do
        -- what this block does is to trigger multiple enterFrames per frame so
        -- those animation that rely on the enterFrame instead of being time based 
        -- will also be affected by the timeScale

        if timeScale > 1 then
            frameCounter = frameCounter + (timeScale - 1)
        else
            frameCounter = 0
        end

        local extraFrames = math.floor(frameCounter)
        if extraFrames > 1 then
            frameCounter = frameCounter - extraFrames
        end
        for i = 1, extraFrames do
            local time = originalPrevTime + (originalTime - originalPrevTime) * (i / (extraFrames + 1))
            Runtime:dispatchEvent{name = "enterFrame", time = time, fake = true}
            -- Runtime:dispatchEvent{name = "lateUpdate", time = getTimer(e.time), fake = true} -- Not so necessary
        end
    end

    prevTimer = originalTime
    scaledTimer = e.time
end)

Runtime:addEventListener("lateUpdate", function(e)
    e.time = getTimer(e.time)
end)

-- Reload global libraries that depend on the timer
_G.timer = require("gameSpeed.timer")
_G.transition = require("gameSpeed.transition")


-- CONTROLLER ----------------------------------------------------------------------------------------------------------

local speedUpMultiplier = 1
local slowDownMultiplier = 1

local speedingUp = false
local slowingDown = false

local function updateGameSpeed()
    if speedingUp then 
        timeScale = 1 + (2 * speedUpMultiplier)
    elseif slowingDown then
        timeScale = 1 / (1 + slowDownMultiplier)
    else
        timeScale = 1
    end
    physics.setTimeScale( timeScale )
end

function Controller:toggleAutoSpeedUp()
    autoSpeeding = not autoSpeeding
    if autoSpeeding then
        speedingUp = true
    else
        speedingUp = false
    end

    updateGameSpeed()
end

function Controller:speedUp()
    if autoSpeeding then return end
    speedingUp = true
    updateGameSpeed()
end

function Controller:slowDown()
    if autoSpeeding then return end
    slowingDown = true
    updateGameSpeed()
end

function Controller:faster()
    speedUpMultiplier = speedUpMultiplier * 1.3
    slowDownMultiplier = slowDownMultiplier / 1.5
    updateGameSpeed()
end

function Controller:slower()
    speedUpMultiplier = speedUpMultiplier / 1.3
    slowDownMultiplier = slowDownMultiplier * 1.5
    updateGameSpeed()
end

function Controller:reset()
    if autoSpeeding then return end
    speedingUp = false
    slowingDown = false
    timeScale = 1
end


return Controller
