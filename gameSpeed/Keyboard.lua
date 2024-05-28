local function onKeyPress(event)


    if event.phase == "up" then
        if event.keyName == "right" or event.keyName == "left" then
            GameSpeed:reset()
        end

    elseif event.phase == "down" then

        if event.keyName == "space" then
            GameSpeed:toggleAutoSpeedUp()

        elseif event.keyName == "right" then
            GameSpeed:speedUp()
            
        elseif event.keyName == "left" then
            GameSpeed:slowDown()

        elseif event.keyName == "up" then
            GameSpeed:faster()

        elseif event.keyName == "down" then
            GameSpeed:slower()

        end
    end
end

Runtime:addEventListener("key", onKeyPress)

