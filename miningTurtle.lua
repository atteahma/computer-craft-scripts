-- GLOBAL CONST
NORTH = 0
EAST = 1
SOUTH = 2
WEST = 3

FUEL_SLOT = 1
MIN_FUEL_ALLOWED = 5

FUEL_CHEST_DIR = SOUTH
ITEM_CHEST_DIR = EAST

FUEL_VALUES = {
    ['minecraft:coal']=80,
    ['minecraft:charcoal']=80
} -- only supports coal and charcoal currently

-- COORDINATE SPACE:
--    N
--  W   E
--    S
--   +y
-- +x  -x  (z is as expected)
--   -y
-- from perspective of turtle.
-- note: y >= 0 , x >= 0 , z <= 0
-- should ALWAYS hold


function turnLeft(dir)
    success = false

    if turtle.turnLeft() then
        dir = math.fmod(dir - 1,4)
        success = true
    end

    return dir,success
end

function turnRight(dir)
    success = false

    if turtle.turnRight() then
        dir = math.fmod(dir + 1,4)
        success = true
    end

    return dir,success
end

function turnToDir(dir,goalDir)
    turn = goalDir - dir

    if math.abs(turn) == 3 then
        turn = -1 * (turn / math.abs(turn))
    end

    if turn > 0 then
        turnFunc = turnRight
    elseif turn < 0 then
        turnFunc = turnLeft
    end

    i = 0
    while i < math.abs(turn) do

        dir,success = turnFunc(dir)
        if not success then
            return dir,false
        end

        i = i + 1
    end

    return dir,true
end

-- mines block in front (and optionally the block
-- above that block and below that block), AND
-- moves forward

-- blockBelow=True means:
--     mines current level AND level directly below
-- blockAbove=True means:
--     mines current level AND level directly above
function mineForward(x,y,dir,blockBelow,blockAbove)

    while turtle.detect() do -- while loop for gravity blocks
        if not turtle.dig() then
            return x,y,dir,false
        end
    end
    
    if not turtle.forward() then
        return x,y,dir,false
    end

    if dir == NORTH then
        y = y + 1
    elseif dir == SOUTH then
        y = y - 1
    elseif dir == WEST then
        x = x + 1
    elseif dir == EAST then
        x = x - 1
    end

    if blockBelow then
        while turtle.detectDown() do
            if not turtle.digDown() then
                return x,y,dir,false
            end
        end
    end

    if blockAbove then
        while turtle.detectUp() do
            if not turtle.digUp() then
                return x,y,dir,false
            end
        end
    end

    return x,y,dir,true
end

-- mines block above AND moves up
function mineUp(z)

    while turtle.detectUp() do -- while loop for gravity blocks
        if not turtle.digUp() then
            return z,false
        end
    end
    
    if not turtle.up() then
        return z,false
    end

    z = z + 1

    return z,true
end

-- mines block below AND moves down
function mineDown(z)

    while turtle.detectDown() do -- while loop for gravity blocks
        if not turtle.digDown() then
            return z,false
        end
    end
    
    if not turtle.down() then
        return z,false
    end

    z = z - 1

    return z,true
end

-- will work with any digging project, but works
-- without needing to break blocks when box dug out
-- (0,0) -> (0,Y) -> (1,Y) -> (1,0) -> ...
-- if z layers > 3, then 'odd' multiples of 3 of z
-- layer is done in reverse for optimal move count
function goToOrigin(x,y,z,dir)

    while z < 0 do
        z,success = mineUp(z)
        if not success then
            return x,y,z,dir,false
        end
    end

    dir,success = turnToDir(dir,EAST)
    if not success then
        return x,y,z,dir,false
    end
    
    while x > 0 do
        x,y,dir,success = mineForward(
            x,y,dir,
            false,
            false
        )
        if not success then
            return x,y,z,dir,false
        end
    end

    dir,success = turnToDir(dir,SOUTH)
    if not success then
        return x,y,z,dir,false
    end

    while y > 0 do
        x,y,dir,success = mineForward(
            x,y,dir,
            false,
            false
        )
        if not success then
            return x,y,z,dir,false
        end
    end

    dir,success = turnToDir(dir,NORTH)
    if not success then
        return x,y,z,dir,false
    end

    return x,y,z,dir,true
end

-- gX,gY,gZ,gDir is goalX,goalY,goalZ,goalDir
function goToPosFromOrigin(x,y,z,dir,gX,gY,gZ,gDir)

    dir,success = turnToDir(dir,NORTH)
    if not success then
        return x,y,z,dir,false
    end
    
    while y < gY do
        x,y,dir,success = mineForward(
            x,y,dir,
            false,
            false
        )
        if not success then
            return x,y,z,dir,false
        end
    end

    dir,success = turnToDir(dir,WEST)
    if not success then
        return x,y,z,dir,false
    end

    while x < gX do
        x,y,dir,success = mineForward(
            x,y,dir,
            false,
            false
        )
        if not success then
            return x,y,z,dir,false
        end
    end

    while z > gZ do
        z,success = mineDown(z)
        if not success then
            return x,y,z,dir,false
        end
    end

    dir,success = turnToDir(dir,gDir)
    if not success then
        return x,y,z,dir,false
    end

    return x,y,z,dir,true
end

function needsRefuel()
    currFuel = turtle.getFuelLevel()

    return currFuel < MIN_FUEL_ALLOWED
end

function doRefuel()
    currFuel = turtle.getFuelLevel()
    maxFuel = turtle.getFuelLimit()
    maxRefuel = maxFuel - currFuel

    turtle.select(FUEL_SLOT)
    fuelData = turtle.getItemDetail()
    if fuelData == nil then
        -- slot is empty,
        -- should never happen
        return 0,false
    end

    fuelName = fuelData.name
    fuelCount = fuelData.count - 1 -- always leave one item in
    fuelValuePerItem = FUEL_VALUES[fuelName]
    if fuelValuePerItem == nil then
        -- fuel type not recognized
        return 0,false
    end

    numItemsToRefuel = math.floor(
        math.min(maxRefuel / fuelValuePerItem,fuelCount)
    )
    if numItemsToRefuel > 0 then
        if not turtle.refuel(numItemsToRefuel) then
            -- in theory the previous checks should
            -- negate any change of this case
            return 0,false
        end
    end

    return numItemsToRefuel,true
end

function needsFuelItems(x,y,z)

    turtle.select(FUEL_SLOT)
    fuelData = turtle.getItemDetail()

    if fuelData == nil then
        -- fuel slot is empty,
        -- should never happen
        moveDistFromInv = 0

    else
        fuelName = fuelData.name
        fuelCount = fuelData.count - 1 -- always leave one item in
        fuelValuePerItem = FUEL_VALUES[fuelData.name]
        if fuelValuePerItem == nil then
            -- fuel type not recognized
            moveDistFromInv = 0
        else
            moveDistFromInv = fuelValuePerItem * fuelCount
        end
    end

    currFuel = turtle.getFuelLevel()
    range = currFuel + moveDistFromInv
    distToOrigin = x + y + z
    buffer = MIN_FUEL_ALLOWED + 3 -- safety buffer

    if distToOrigin > (range + buffer) then
        return false
    end

    return true
end

-- dumpItems=True means:
--     will drop off items at the same time,
--     regardless of current inventory capacity
function doRefuelFromChest(x,y,z,dir,dumpItems)
    prevX = x
    prevY = y
    prevZ = z
    prevDir = dir

    x,y,z,dir,success = goToOrigin(x,y,z,dir)
    if not success then
        return x,y,z,dir,false
    end

    dir,success = turnToDir(dir,FUEL_CHEST_DIR)
    if not success then
        return x,y,z,dir,false
    end

    numFuelItemsConsumed = 1
    while numFuelItemsConsumed > 0 do
        -- max out on fuel items from chest
        turtle.select(FUEL_SLOT)
        numFuelItemsToGet = turtle.getItemSpace()

        gotItems = turtle.suck(numFuelItemsToGet)

        if gotItems then
            -- max out internal fuel
            numFuelItemsConsumed,success = doRefuel()
            if not success then
                return x,y,z,dir,false
            end
        else
            -- no more items in fuel chest,
            -- just continue with what you have
            -- not great, improve later
            numFuelItemsConsumed = 0
        end
    end
    
    if dumpItems then
        x,y,z,dir,success = dumpItemsInChest(
            x,y,z,dir,
            False
        )
        if not success then
            return x,y,z,dir,false
        end
    end
    
    x,y,z,dir,success = goToPosFromOrigin(
            x,    y,    z,    dir,
        prevX,prevY,prevZ,prevDir
    )
    if not success then
        return x,y,z,dir,false
    end
    
    return x,y,z,dir,true
end

function invFull()
    spaceForItems = {}
    for slot = 1,16 do
        if slot ~= FUEL_SLOT then

            turtle.select(FUEL_SLOT)
            itemData = turtle.getItemDetail()

            if itemData == nil then
                -- there exists an empty slot
                return false

            else
                itemName = itemData.name
                itemCount = itemData.count
                itemSpace = turtle.getItemSpace()

                if spaceForItems[itemName] == nil then
                    -- item not yet seen in inventory
                    spaceForItems[itemName] = 0
                end

                spaceForItems[itemName] = spaceForItems[itemName] + itemSpace
            end
        end        
    end

    for itemName,itemSpace in pairs(spaceForItems) do
        if itemSpace == 0 then
            return true
        end
    end

    return false
end

-- getFuel=True means:
--     will get fuel from chest at the same time,
--     regardless of current fuel item number
function dumpItemsInChest(x,y,z,dir,getFuel)
    prevX = x
    prevY = y
    prevZ = z
    prevDir = dir

    x,y,z,dir,success = goToOrigin(x,y,z,dir)
    if not success then
        return x,y,z,dir,false
    end

    dir,success = turnToDir(dir,ITEM_CHEST_DIR)
    if not success then
        return x,y,z,dir,false
    end

    -- DUMP ITEMS
    for slot = 1,16 do
        if slot ~= FUEL_SLOT then
            turtle.select(slot)
            if turtle.getItemCount() > 0 then
                if not turtle.drop() then
                    return x,y,z,dir,false
                end
            end
        end
    end

    if getFuel then
        x,y,z,dir,success = doRefuelFromChest(
            x,y,z,dir,
            False
        )
        if not success then
            return x,y,z,dir,false
        end
    end

    x,y,z,dir,success = goToPosFromOrigin(
            x,    y,    z,    dir,
        prevX,prevY,prevZ,prevDir
    )
    if not success then
        return x,y,z,dir,false
    end
    
    return x,y,z,dir,true
end

function doSelfCare(x,y,z,dir)
    if needsRefuel() then
        print('[RUN] refueling...')
        
        numFuelItemsConsumed,success = doRefuel()
        if not success then
            print('[ERR] failed to refuel.')
            return x,y,z,dir,false
        end

        print('[RUN] refueled using ' .. numFuelItemsConsumed .. 'fuel items.')
    end

    if needsFuelItems(x,y,z) then
        print('[RUN] refueling from origin...')
        
        x,y,z,dir,success = doRefuelFromChest(
            x,y,z,dir,
            True
        )
        if not success then
            print('[ERR] failed to refuel from origin.')
            return x,y,z,dir,false
        end

        print('[RUN] refueled from origin and returned to previous location.')        
    end
    
    if invFull() then
        print('[RUN] inventory full, dumping items at origin...')
        
        x,y,z,dir,success = dumpItemsInChest(
            x,y,z,dir,
            True
        )
        if not success then
            print('[ERR] failed to dump items at origin.')
            return x,y,z,dir,false
        end

        print('[RUN] dumped items at origin and returned to original location.') 
    end

    return x,y,z,dir,true
end

function main(xSize,ySize,zSize)
    -- initial state values
    run = true
    x = 0
    y = 0
    z = 0
    dir = NORTH
    
    -- fill internal inventory fuelItem slot and refuel to max fuel
    x,y,z,dir,success = doRefuelFromChest(x,y,z,dir)
    if not success then
        run = false
        print('[INIT] failed to fill internal inventory with fuel.')
        return
    end

    -- assumes max 1 fuel consumed between doSelfCare calls.
    -- in theory should be fine up to MIN_FUEL_ALLOWED + 2
    -- fuel between doSelfCare calls.
    
    -- BUILD/DIG LOGIC
    numZLayers = math.ceil(zSize / 3) -- includes final Z-Layer
    finalZLayerHeight = math.fmod(zSize,3)
    if finalZLayerHeight == 0 then
        finalZLayerHeight = 3
    end
    
    for zLayer_i = 1,numZLayers do
        print('[RUN] starting Z-Layer=' .. zLayer_i)

        -- determine differences between normal/reversed Z-Layer
        if math.fmod(zLayer_i,2) == 0 then
            -- normal Z-Layer
            startX = 1
            endX = xSize
            dirX = 1
            startY = 1
            endY = ySize
            dirY = 1
            startDir = NORTH
        else
            -- reversed Z-Layer
            startX = xSize
            endX = 1
            dirX = -1
            startY = ySize
            endY = 1
            dirY = -1
            startDir = SOUTH
        end

        if ZLayer_i == numZLayers then
            -- this is the final ZLayer, use correct height
            zLayerHeight = finalZLayerHeight
        else
            zLayerHeight = 3
        end
        
        -- configure height params
        if zLayerHeight == 1 then
            doMineBelow = false
            doMineAbove = false
        elseif zLayerHeight == 2 then
            doMineBelow = true
            doMineAbove = false
        elseif zLayerHeight == 3 then
            doMineBelow = true
            doMineAbove = true

            -- start in the middle Z coordinate
            z,success = mineDown(z)
            if not success then
                print('[ERR] failed to get to midde of Z-Layer')
                return
            end
        end
        

        dir,success = turnToDir(dir,startDir)
        if not success then
            print('[ERR] failed to do initial turn')
            return
        end
        
        for x_i = startX,endX,dirX do
            for y_i = startY,endY,dirY do
                -- go straight
                x,y,dir,success = mineForward(
                    x,y,dir,
                    doMineBelow,
                    doMineAbove
                )
                if not success then
                    print('[ERR] failed to mine forward')
                    return
                end

                -- do self care after every main move call in build script
                x,y,z,dir,success = doSelfCare(x,y,z,dir)
                if not success then
                    print('[ERR] failed to do self care.')
                    return
                end
            end

            -- round the corner
            if math.fmod(x_i,2) == 0 then
                cornerFunc = turnLeft
            else
                cornerFunc = turnRight
            end

            -- if we reached the end of this Z-Layer, don't corner
            if x_i ~= endX then
                dir,success = cornerFunc(dir)
                if not success then
                    print('[ERR] failed rounding the corner [A]')
                    return
                end

                x,y,dir,success = mineForward(
                    x,y,dir,
                    doMineBelow,
                    doMineAbove
                )
                if not success then
                    print('[ERR] failed rounding the corner [B]')
                    return
                end

                dir,success = cornerFunc(dir)
                if not success then
                    print('[ERR] failed rounding the corner [C]')
                    return
                end
            end
        end

        -- end of Z-Layer, move to next Z-layer's uppermost position
        z,success = mineDown(z)
        if not success then
            print('[ERR] failed to get to next Z-Layer')
            return
        end

        z,success = mineDown(z)
        if not success then
            print('[ERR] failed to get to next Z-Layer')
            return
        end
    end

    -- digging complete!
    x,y,z,dir,success = goToOrigin(x,y,z,dir)
    if not success then
        print('[ERR] failed to get back to origin after finishing.')
        return
    end

    x,y,z,dir,success = dumpItemsInChest(
        x,y,z,dir,
        false
    )
    if not success then
        print('[ERR] failed to dump items after finishing.')
        return
    end

    dir,success = turnToDir(dir,NORTH)
    if not success then
        print('[ERR] failed to turn after finishing.')
        return
    end

    print('[FIN] TASK FINISHED!')

    return
end

io.write('[INP] Number of blocks to go left: ')
xSize = io.read()
io.write('\n')

io.write('[INP] Number of blocks to go forward: ')
ySize = io.read()
io.write('\n')

io.write('[INP] Number of blocks to go down: ')
zSize = io.read()
io.write('\n')

main(xSize,ySize,zSize)
