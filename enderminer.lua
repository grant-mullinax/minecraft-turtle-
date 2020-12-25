local facingDirs = {{x=0, z=1}, {x=-1, z=0}, {x=0, z=-1},  {x=1, z=0}}
local facingIdx = 0
pos = {x=0, y=0, z=0}

local directions = { forward=0 }

local getFacing = function()
    return facingDirs[facingIdx + 1]
end

getFuelLevel = function()
    return (turtle.getItemCount(1)-1) * 80 + turtle.getFuelLevel()
end

needFuel = function() return getFuelLevel() <= (math.abs(pos.x) + math.abs(pos.y) + math.abs(pos.z) + 40) or turtle.getFuelLevel() <= 0 end

--[[
    ########
    movement
    ########
]]

forward = function()
    while needFuel() do
        if turtle.getItemCount(1) >= 1 then
            turtle.select(1)
            turtle.refuel(1)
        else
            print("i need fuel! ", getFuelLevel())
            os.sleep(5)
        end
    end
    
    local b, reason = turtle.forward()
    if not b then
        print("failed,", reason)
        return false
    end

    local facing = getFacing()
    pos.x = pos.x + facing.x
    pos.z = pos.z + facing.z

    print("coords", pos.x, pos.y, pos.z)
    print("fuel", getFuelLevel())

    return true
end

up = function()
    if not turtle.up() then
        return false
    end
    pos.y = pos.y + 1

    return true
end

down = function()
    if not turtle.down() then
        return false
    end
    pos.y = pos.y - 1

    return true
end

turnLeft = function()
    facingIdx = (facingIdx - 1) % 4
    turtle.turnLeft()
end

turnRight = function()
    facingIdx = (facingIdx + 1) % 4
    turtle.turnRight()
end

local findDirIdx = function(idx)
    if facingIdx == idx then
        return
    end

    -- created from truth table
    if facingIdx-1 == idx or (facingIdx == 0 and idx == 3) then
        while facingIdx ~= idx do
            turnLeft()
        end
    else 
        while facingIdx ~= idx do
            turnRight()
        end
    end
end

shouldDeposit = function()
    local total = 0
    for i = 1, 16 do
        if turtle.getItemCount(i) == 0 then
            total = total + 1
        end
    end
    return total <= 1
end

depositInventoryForward = function()
    for i = 3, 16 do
        turtle.select(i)
        if turtle.drop() == false then
            return false
        end
    end
    return true
end

goHomeAndDeposit = function()
    goToRelativeCoords(0, 0, 0)
    findDirIdx(2) -- turn backward
    depositInventoryForward()
end

enderDeposit = function()
    print("dropping")
    turtle.dig()
    turtle.select(2)
    turtle.place()
    depositInventoryForward()
    turtle.select(2)
    turtle.dig()
    turtle.select(1)
end

dropCobble = function()
    for i = 3, 16 do
        local detail = turtle.getItemDetail(i)
        if detail ~= nil and detail.Name == "minecraft:cobblestone" then
            turtle.select(i)
            turtle.dropUp()
        end
    end
end

--[[
    #########
    dig types
    #########
]]

manageInventorySpace = function()
    if shouldDeposit() then
        goHomeAndDeposit()
    end

    return true
end

fullDig = function()

    turtle.dig()
    turtle.digUp()
    turtle.digDown()

    return true
end

quarry = function()
    return manageInventorySpace() and fullDig()
end

goToRelativeCoords = function(x, y, z, preFunc)

    local desiredXDir = pos.x > x and 1 or 3
    local desiredZDir = pos.z > z and 2 or 0

    -- could minimize turning by looping actions until failure
    while pos.x ~= x or pos.y ~= y or pos.z ~= z do
        -- do it after to not dig towards the wrong location
        if preFunc ~= nil then
            preFunc()
        end

        if (pos.x ~= x) then
            repeat
                findDirIdx(desiredXDir)
            until pos.x == x or forward() == false
        end

        if (pos.z ~= z) then
            repeat
                findDirIdx(desiredZDir)
            until pos.z == z or forward() == false
        end

        while pos.y < y and up() do end

        while pos.y > y and down() do end
    end
end

digRectangle = function(x1, y1, z1, x2, y2, z2)
    goToRelativeCoords(x1, y1, z1, quarry)

    for gy = 0, math.floor(math.abs(y2-y1)/3) do
        for gx = 0, x2-x1 do
            for pz = 0, z2-z1 do
                local gz = pz

                if gx % 2 == 1 then
                    gz = z2-z1 - pz
                end
                goToRelativeCoords(x1+gx, gy * -3, z1+gz, quarry)
            end
        end
    end
end

buildFunction = function(w, h, f)
    for x = 0, w do
        for py = 0, h do
            local y = py
            if x % 2 == 1 then
                y = h - py
            end

            print(math.floor(f(x, y)))
            goToRelativeCoords(x, math.floor(f(x, y)), y)
            for i = 1, 16 do
                turtle.select(i)
                if turtle.placeUp() then
                    break
                end
            end
        end
    end
end

findDirIdx(0)


local i = 0
local size = 8 - 1
while true do
    digRectangle(0,0,i, size, -63, i+size)
    i = i + size
end

--[[while true do
    local func = loadstring(io.read())
    setfenv(func, getfenv())
    turtle.refuel(1)
    func()
    goHomeAndDeposit()
end]]