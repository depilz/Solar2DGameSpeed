-- SETUP ---------------------------------------------------------------------------------------------------------------

display.setDefault("background", 1)

------------------------------------------------------------------------------------------------------------------------
-- RUN GAME --
------------------------------------------------------------------------------------------------------------------------

_G.GameSpeed = require("gameSpeed.GameSpeed")
require("gameSpeed.Keyboard")

local timeStart = system.getTimer()
local duration = 2000
local from = display.contentCenterX - 70
local to = display.contentCenterX + 100
local y = display.contentCenterY - 100
local padding = 70

local function newLabel(label, y)
    local text = display.newText(label, display.contentCenterX - 210, y, native.systemFont, 20)
    text.anchorX = 0
    text:setFillColor(0)
end


-- test 1 --------------------------------------------------------------------------------------------------------------
-- update a circle on a per frame basis

newLabel("Frame based:", y)

local circle = display.newCircle(from, y, 20)
circle:setFillColor(0)

local step = (to - from) / duration * (1000 / 60)
local dir = 1
local function onEnterFrame(event)
    circle.x = circle.x + step * dir
    if dir == 1 and circle.x > to then
        circle.x = to
        dir = -1
    elseif dir == -1 and circle.x < from then
        circle.x = from
        dir = 1
    end
end
Runtime:addEventListener("enterFrame", onEnterFrame)

y = y + padding


-- test 2 --------------------------------------------------------------------------------------------------------------
-- test enterFrame based on time

newLabel("Time based:", y)
local circle2 = display.newCircle(from, y, 20)
circle2:setFillColor(0, 0, 1)

local function onEnterFrame(event)
    local time = (event.time - timeStart) % (duration*2)
    time = time > 2000 and 4000 - time or time
    circle2.x = easing.linear(time, 2000, from, to - from)
end
Runtime:addEventListener("enterFrame", onEnterFrame)

y = y + padding

-- test 3 --------------------------------------------------------------------------------------------------------------
-- test transition

newLabel("transition.to:", y)

local circle3 = display.newCircle(from, y, 20)
circle3:setFillColor(0, 1, 0)
transition.loop(circle3, {
    time       = duration * 2,
    x          = display.contentCenterX + 100,
    iterations = 0,
    transition = easing.linear,
})

y = y + padding


-- test 4 --------------------------------------------------------------------------------------------------------------
-- test performWithDelay

newLabel("performWithDelay:", y)

local circle4 = display.newCircle(to, y, 20)
circle4:setFillColor(math.random(), math.random(), math.random())

timer.performWithDelay(duration, function()
    circle4:setFillColor(math.random(), math.random(), math.random())
end, 0)
