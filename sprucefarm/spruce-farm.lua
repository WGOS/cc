local params = {
    xOffset = 0,
    yOffset = 0,
    zOffset = 0,
    rotOffset = 0,

    saplingItemName = "minecraft:spruce_sapling",
    logBlockName = "minecraft:spruce_log",
    fuelChestSide = "down",
    saplingChestSide = "right",
    logChestSide = "left",
    trashSide = "back",
    minFuel = 300,
    debug = true,
    treeCheckPause = 30,
    saplingEnsureInterval = 3,
    treeChecks = 0,

    state = 0,
    chopStep = 1
}

local restoreState = false
local doAdditionalChopCycle = false
local snapFile = "./spruce-farm.snapshot"

-- I hate this
local str2bool = {
    ["true"] = true,
    ["false"] = false
}

local function saveParamSnapshot()
    local snap = fs.open(snapFile, "w")
    snap.write(textutils.serialize(params))
    snap.close()
end

local function setTreeChecks(value)
    params.treeChecks = value;
    saveParamSnapshot()
end

local function setState(value)
    params.state = value
    saveParamSnapshot()
end

local function setChopStep(value)
    params.chopStep = value
    saveParamSnapshot()
end

local function updatePos()
    saveParamSnapshot()

    if not debug then
        return
    end

    print(string.format("x: %d, y: %d, z: %d, rot: %d", params.xOffset, params.yOffset, params.zOffset, params.rotOffset))
end

local function rotToSide(rot)
    if rot == 0 then
        return "front"
    end

    if rot == 1 then
        return "right"
    end

    if rot == 2 then
        return "back"
    end

    if rot == 3 then
        return "left"
    end
end

local function sideToRot(side)
    if side == "front" then
        return 0
    end

    if side == "right" then
        return 1
    end

    if side == "back" then
        return 2
    end

    if side == "left" then
        return 3
    end

    return -1;
end

local function turnRight()
    if not turtle.turnRight() then
        return false;
    end

    params.rotOffset = (params.rotOffset + 1) % 4

    updatePos()

    return true;
end

local function turnLeft()
    if not turtle.turnLeft() then
        return false
    end

    params.rotOffset = params.rotOffset - 1

    if params.rotOffset < 0 then
        params.rotOffset = 3
    end

    updatePos()

    return true
end

local function rotate(rot)
    if rot < 0 or rot > 3 then
        return
    end

    if rot % 4 == params.rotOffset then
        return
    end

    while rot ~= params.rotOffset do
        turnRight()
    end
end

local function rotateToSide(side)
    local rot = sideToRot(side)

    rotate(rot)
end

local function goForward(dig)
    if turtle.detect() and dig then
        turtle.dig()
    end

    if not turtle.forward() then
        return false
    end

    if params.rotOffset % 2 == 0 then
        params.xOffset = params.xOffset - (params.rotOffset - 1)
    else
        params.zOffset = params.zOffset - (params.rotOffset - 2)
    end

    updatePos()

    return true
end

local function goBack()
    if not turtle.back() then
        return false
    end

    if params.rotOffset % 2 == 0 then
        params.xOffset = params.xOffset + (params.rotOffset - 1)
    else
        params.zOffset = params.zOffset + (params.rotOffset - 2)
    end

    updatePos()

    return true
end

local function goUp(dig)
    if turtle.detectUp() and dig then
        turtle.digUp()
    end

    if not turtle.up() then
        return false
    end

    params.yOffset = params.yOffset + 1

    updatePos()

    return true
end

local function goDown(dig)
    if turtle.detectDown() and dig then
        turtle.digDown()
    end

    if not turtle.down() then
        return false
    end

    params.yOffset = params.yOffset - 1

    updatePos()

    return true
end

local function selectFirstEmptySlot()
    local slot = 1;

    while turtle.getItemDetail(slot) do
        slot = math.max(1, (slot + 1) % 17);
        sleep(0.05)
    end

    turtle.select(slot)
    return slot
end

local function findItem(itemName, count)
    count = count or 1

    for i = 1, 16, 1 do
        local item = turtle.getItemDetail(i)

        if item and (item.name == itemName and item.count >= count) then
            return true, i
        end
    end

    return false, nil
end

local function waitUnload(side, count)
    count = count or 1

    if not turtle.getItemDetail() then
        return
    end

    local dropped = false

    while not dropped do
        if side == "up" then
            dropped = turtle.dropUp(count)
        elseif side == "down" then
            dropped = turtle.dropDown(count)
        else
            dropped = turtle.drop(count)
        end

        sleep(0.1)
    end
end

local function waitLoad(side, count)
    count = count or 1

    local loaded = false

    while not loaded do
        if side == "up" then
            loaded = turtle.suckUp(count)
        elseif side == "down" then
            loaded = turtle.suckDown(count)
        else
            loaded = turtle.suck(count)
        end

        sleep(0.1)
    end
end

local function emptyInvOfItem(itemName, sideName)
    rotateToSide(sideName)

    for i = 1, 16, 1 do
        turtle.select(i)
        local item = turtle.getItemDetail()

        if item and item.name == itemName then
            waitUnload(sideName, 64)
        end
    end
end

local function emptyInventory()
    print("Cleaning inventory")
    rotateToSide(params.trashSide)

    for i = 1, 16, 1 do
        turtle.select(i)
        local fuel = turtle.refuel(0)

        if not fuel then
            waitUnload(params.trashSide, 64)
        end
    end
end

local function unloadExcessFuel()
    print("Unloading excess fuel")
    rotateToSide(params.trashSide)

    for i = 1, 16, 1 do
        turtle.select(i)
        local fuel = turtle.refuel(0)

        if fuel and (turtle.getFuelLevel() >= turtle.getFuelLimit()) then
            waitUnload(params.fuelChestSide, 64)
        end
    end
end

local function invRefuel()
    print("Refueling from inventory")

    for i = 1, 16, 1 do
        if turtle.getFuelLevel() >= turtle.getFuelLimit() then
            return
        end

        turtle.select(i)
        turtle.refuel(64)
    end
end

local function refuel()
    if turtle.getFuelLevel() >= params.minFuel then
        return
    end

    print("Refueling...")
    rotateToSide(params.fuelChestSide)

    print("Selecting first empty slot...")
    selectFirstEmptySlot()

    while turtle.getFuelLevel() < params.minFuel do
        waitLoad(params.fuelChestSide, 1)
        turtle.refuel()
    end
end

local function correctChoppingRotation()
    local x = params.xOffset
    local z = params.zOffset

    -- should I calculate rotation mathematically?
    if x == 2 and z == 0 then
        rotate(0)
    elseif x == 3 and z == 0 then
        rotate(1)
    elseif x == 3 and z == 1 then
        rotate(2)
    elseif x == 2 and z == 1 then
        rotate(3)
    end
end

local function chopLayer()
    local detected = turtle.detectUp()
    correctChoppingRotation()

    -- we can use corrected rotation as start index
    for i = params.rotOffset + 1, 4, 1 do
        if turtle.detectUp() then
            detected = true
        end

        if turtle.detect() then
            turtle.dig()
        end

        goForward()
        turnRight()
    end

    if doAdditionalChopCycle then
        doAdditionalChopCycle = false
        detected = chopLayer()
    end

    return detected
end

local function nextLayer()
    if turtle.detectUp() then
        turtle.digUp()
    end

    goUp()
end

-- This function made with some assumptions
-- such like turtle will newer go zOffset < 0
local function travelToBase()
    rotate(3)

    for i = params.zOffset, 1, -1 do
        goForward(true)
    end

    rotate(2)

    for i = params.xOffset, 2, -1 do
        goForward(true)
    end

    for i =  params.yOffset, 1, -1 do
        goDown(true)
    end

    goForward()
    rotate(0)
    setState(0)
end

local function startChopping()
    if params.state <= 1 then
        turtle.dig()
        setState(1)
    end

    if params.state <= 2 then
        goForward()
        setState(2)
    end

    while chopLayer() do
        nextLayer()
    end

    setState(3)
    travelToBase()
end

local function loadSaplings()
    print("Trying to load saplings")
    rotateToSide(params.saplingChestSide)
    waitLoad(params.saplingChestSide, 4)
end

local function checkSaplings(plant)
    print("Checking if saplings are ok")

    local inspectUp = false
    local saplingsOk = true
    local saplingsAvail, saplingsSlot = false, nil
    plant = plant or false

    if plant then
        saplingsAvail, saplingsSlot = findItem(params.saplingItemName, 4)
        
        if not saplingsAvail then
            loadSaplings()
            saplingsAvail, saplingsSlot = findItem(params.saplingItemName, 4)
        end

        turtle.select(saplingsSlot)
    end

    rotate(0)

    goForward(true)
    goUp(true)
    goForward(true)

    for i = 1, 4, 1 do
        local inspRes, block = turtle.inspectDown()
        
        if turtle.inspectUp() then
            -- If turtle detected something above e.g. trees
            -- then we should chop it and also set state to 2
            -- to start chopping immediately in case of restart
            inspectUp = true
            setState(2)
        end

        if inspRes and (block.name ~= params.saplingItemName) then
            turtle.digDown()
            saplingsOk = false

            if plant then
                turtle.placeDown()
            end
        elseif not inspRes then
            saplingsOk = false
            
            if plant then
                turtle.placeDown()
            end
        end

        goForward(true)
        turnRight()
    end

    if inspectUp then
        nextLayer()
        startChopping()
    else
        goBack()
        goDown()
        goBack()
    end

    

    return saplingsOk;
end

local function farmingLoop()
    refuel()
    goForward()

    local inspRes, block = turtle.inspect()

    if inspRes and block.name == params.logBlockName then
        setTreeChecks(0)
        startChopping()
        return
    else
        goBack()
    end

    if not inspRes then
        setTreeChecks(0)
        checkSaplings(true)
        sleep(params.treeCheckPause)
        farmingLoop()
        return
    end

    setTreeChecks(params.treeChecks + 1);

    if params.treeChecks >= params.saplingEnsureInterval then
        setTreeChecks(0)
        local saplingCheckRes = checkSaplings()

        if not saplingCheckRes then
            checkSaplings(true)
        end
    end

    sleep(params.treeCheckPause)

    farmingLoop()
end

local function mainLoop()
    rotate(0)
    setState(0)

    print("Dropping logs")
    emptyInvOfItem(params.logBlockName, params.logChestSide)

    print("Dropping saplings")
    emptyInvOfItem(params.saplingItemName, params.saplingChestSide)

    emptyInventory()
    invRefuel()
    unloadExcessFuel()
    refuel()

    rotate(0)

    farmingLoop()

    mainLoop()
end

local function restoreTurtleState()
    local snap = fs.open(snapFile, "r")
    local info = snap.readAll()

    params = textutils.unserialize(info)
    snap.close()

    if params.state == 0 then
        travelToBase()
    elseif params.state >= 1 and params.state <= 2 then
        startChopping()
    elseif params.state == 3 then
        travelToBase()
    end
end

local function modifyStartup()
    local localFile = shell.getRunningProgram()
    local startFile = fs.open("/startup", "w")

    startFile.write("shell.execute(\"" .. localFile .. "\", \"true\")")
    startFile.close()
end

local function start(resState)
    modifyStartup()

    restoreState = str2bool[string.lower(resState or "false")]
    doAdditionalChopCycle = restoreState

    if restoreState then
        restoreTurtleState()
    end

    mainLoop()
end

start(...)