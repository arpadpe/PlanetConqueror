--The following global values are set via the simulation core:
-- ------------------------------------
-- IMMUTABLES.
-- ------------------------------------
-- ID -- id of the agent.
-- STEP_RESOLUTION 	-- resolution of steps, in the simulation core.
-- EVENT_RESOLUTION	-- resolution of event distribution.
-- ENV_WIDTH -- Width of the environment in meters.
-- ENV_HEIGHT -- Height of the environment in meters.
-- ------------------------------------
-- VARIABLES.
-- ------------------------------------
-- PositionX	 	-- Agents position in the X plane.
-- PositionY	 	-- Agents position in the Y plane.
-- DestinationX 	-- Agents destination in the X plane. 
-- DestinationY 	-- Agents destination in the Y plane.
-- StepMultiple 	-- Amount of steps to skip.
-- Speed 			-- Movement speed of the agent in meters pr. second.
-- Moving 			-- Denotes wether this agent is moving (default = false).
-- GridMove 		-- Is collision detection active (default = false).
-- ------------------------------------

-- Import valid Rana lua libraries.
Stat = require "ranalib_statistic"
Move = require "ranalib_movement"
Collision = require "ranalib_collision"
Utility = require "ranalib_utility"
Agent = require "ranalib_agent"
Shared = require "ranalib_shared"
Event = require "ranalib_event"
Map = require "ranalib_map"

PlanetMovement = require "modules/planet_movement"
PlanetScanner = require "modules/planet_scanner"
Descriptions = require "modules/event_descriptions"

background_color = {0,0,0}

state_init = true
state_deposit = false
state_return_to_base = false
state_pick_up = false
state_forward_full = false
state_moving = false
state_accept_ores = false
state_done = false
state_wait_new_ores = true
state_forward_time_up = false

robotsTable = {}

-- Initialization of the agent.
function InitializeAgent()
	
	say("Transporter #: " .. ID .. " has been initialized")

    Agent.changeColor{b=255}

	PositionX = math.floor(PositionX)
	PositionY = math.floor(PositionY)

	GridMove = true

    OreCapacity = Shared.getNumber(3)               -- C
    OreDensity = Shared.getNumber(4)                -- D
    Energy = Shared.getNumber(5)                    -- E
    GridSize = Shared.getNumber(6)                  -- G
    CommunicationScope = Shared.getNumber(7)        -- I
    CoordinationMode = Shared.getNumber(8)          -- M
    NumberOfBases = Shared.getNumber(9)             -- N
    PerceptionScope = Shared.getNumber(10)          -- P
    MotionCost = Shared.getNumber(11)               -- Q
    MemorySize = Shared.getNumber(12)               -- S
    NumberOfCycles = Shared.getNumber(13)           -- T
    CarriageCapacity = Shared.getNumber(14)         -- W
    ExplorersNumber = Shared.getNumber(15)          -- X
    TransportersNumber = Shared.getNumber(16)       -- Y   

    CurrentEnergy = Energy
    MessageCost = 1
    PickupCost = 1
    OreCount = 0

    DestinationX = PositionX
    DestinationY = PositionY

    BasePosition = {x = PositionX, y = PositionY}

    Memory = {}     
end

val = true

function TakeStep()

    if val then
        Move.to{x=PositionX + 1, y=PositionY}
        val = false
    end

    if CurrentEnergy < 0 then
        die()
    end

    if state_init then
        -- wait for base

    elseif state_accept_ores then
        sendAcceptMessage()
        state_accept_ores = false
        determineNextAction()

    elseif state_moving and Memory[2] ~= nil then
        if not Moving then
            move()
        end
        if PositionX == Memory[2].x and PositionY == Memory[2].y then
            shiftMemory()
            state_moving = false
            Moving = false
        else
            --print("Not there yet")
        end

    elseif state_forward_full then
        forwardFullMessage()
        Memory[2] = Memory[1]
        state_moving = true
        state_forward_full = false
        state_forward_time_up = false
        state_deposit = false
        state_pick_up = false
        state_accept_ores = false
        state_done = false
        state_wait_new_ores = false
        state_return_to_base = true

    elseif state_forward_time_up then
        forwardTimeUpMessage()
        Memory[2] = Memory[1]
        state_moving = true
        state_forward_time_up = false
        state_deposit = true
        state_pick_up = false
        state_forward_full = false
        state_accept_ores = false
        state_done = false
        state_wait_new_ores = false
        state_return_to_base = true
    
    elseif state_deposit then
        depositOres()
        state_deposit = false
        if not state_return_to_base then
            state_moving = true
            determineNextAction()
        end
    
    elseif state_pick_up then
        pickUpOre()
        state_pick_up = false
        determineNextAction()

    elseif state_done then
        sendDoneMessage()
        state_done = false
        state_wait_new_ores = true

    elseif state_return_to_base then
        -- Do nothing

    elseif state_wait_new_ores then
        handleWaiting()

    end
end

function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)


    if eventDescription == Descriptions.INIT then
        BaseID = sourceID
        state_init = false
        say("Transporter #: " .. ID .. " received init from " .. sourceID)
        print("base: " .. sourceX .. "  " .. sourceY)
        table.insert(Memory, {x=sourceX, y=sourceY})
        robotsTable = Shared.getTable(Descriptions.ROBOTS)
	elseif eventDescription == Descriptions.FULL and not (state_return_to_base or state_forward_full) then
        local baseFullId = eventTable[Descriptions.BASEID]
        if baseFullId == BaseID then
            state_forward_full = true
            state_moving = false
            state_deposit = false
            state_pick_up = false
            state_forward_time_up = false
            state_accept_ores = false
            state_done = false
            state_wait_new_ores = false
            state_return_to_base = true
            say("Transporter #: " .. ID .. " received base full for " .. baseFullId .. " forwarding and returning to base")
        end

        -- TODO: Add logic to handle coordination mode

    elseif eventDescription == Descriptions.TIMEUP and not (state_return_to_base or state_forward_time_up) then
        local baseTimeUpId = eventTable[Descriptions.BASEID]
        if baseTimeUpId == BaseID then
            state_forward_time_up = true
            state_moving = false
            state_deposit = false
            state_pick_up = false
            state_forward_full = false
            state_accept_ores = false
            state_done = false
            state_wait_new_ores = false
            state_return_to_base = true
            say("Transporter #: " .. ID .. " received base time up for " .. baseTimeUpId .. " forwarding and returning to base")
        end

        -- TODO: Add logic to handle coordination mode


    elseif eventDescription == Descriptions.OREPOS then
        say("Transporter #: " .. ID .. " received " .. #eventTable ..  " ore positions from " .. sourceID)
        local oreTable = eventTable

        local index = 1

        for i = 2, #Memory do
            if Memory[i] == nil then
                index = i - 1
                break
            end
        end

        local freeSpace = MemorySize - index

        print(freeSpace .. " " .. #Memory)

        if #oreTable <= freeSpace then

            for j = 1, #oreTable do
                Memory[index] = oreTable[j]
                index = index + 1
            end

            AcceptID = sourceID

            state_accept_ores = true
            print("to accept")
        end
	end
end

function determineNextAction()
    
    if Memory[2] ~= nil then

        if OreCount < CarriageCapacity then

            if (PlanetMovement.get_distance_to(Memory[2]) * MotionCost) + PickupCost + (PlanetMovement.get_distance_between(Memory[1], Memory[2]) * MotionCost) <= CurrentEnergy * 0.8 then
                say("Transporter #: " .. ID .. " current position " .. PositionX .. " " .. PositionY)
                say("Transporter #: " .. ID .. " is going to " .. Memory[2].x .. " " .. Memory[2].y)
                state_moving = true
                state_pick_up = true
                return

            else -- low on energy, return to base
                say("Transporter #: " .. ID .. " is low on energy ".. CurrentEnergy .. ", returning to base ")
                state_deposit = true
                state_moving = true
                return

            end

        else -- storage is full, deposit ores
            say("Transporter #: " .. ID .. " storage full, returning to base ")
            state_deposit = true
            state_moving = true
            return
        end

    elseif calculateEnergyToBase() >= CurrentEnergy * 0.7 then -- Running low on energy, return to base
        say("Transporter #: " .. ID .. " is low on energy ".. CurrentEnergy .. ", returning to base ")
        state_deposit = true
        state_moving = true
        Memory[2] = {x=PositionX, y=PositionY}
        return
    end

    if OreCount == CarriageCapacity then -- storage is full, deposit ores
        say("Transporter #: " .. ID .. " storage full, returning to base ")
        state_deposit = true
        state_moving = true
        return
    end

    say("Transporter #: " .. ID .. " done, waiting for new ore positions")
    if AcceptID ~= nil then
        state_done = true
    else
        state_wait_new_ores = true
    end

end

function handleWaiting()
    
    local ids = PlanetScanner.get_ids_in_range(CommunicationScope)

    for i=1, #ids do

        if robotsTable[BaseID].explorers[i] ~= nil then
            return
        end

        --[[
        for j=1, #robotsTable[BaseID].explorers do

            if ids[i] == robotsTable[BaseID].explorers[j] then
                return
            end

        end
        ]]
    end

    -- did not find explorers, move
    Memory[2] = PlanetMovement.get_random_pos(CommunicationScope)

    if (PlanetMovement.get_distance_to(Memory[2]) * MotionCost) + (PlanetMovement.get_distance_between(Memory[1], Memory[2]) * MotionCost) <= CurrentEnergy * 0.8 then
        say("Transporter #: " .. ID .. " current position " .. PositionX .. " " .. PositionY)
        say("Transporter #: " .. ID .. " is going to " .. Memory[2].x .. " " .. Memory[2].y)
        state_moving = true
        return

    else -- low on energy, return to base
        say("Transporter #: " .. ID .. " is low on energy ".. CurrentEnergy .. ", returning to base ")
        state_deposit = true
        state_moving = true
        return

    end

end

function sendAcceptMessage()
    sendMessage(AcceptID, Descriptions.ACCEPT)
end

function sendDoneMessage()
    sendMessage(AcceptID, Descriptions.DONE)
    AcceptID = nil
end

function forwardFullMessage()
    local ids = PlanetScanner.get_ids_in_range(CommunicationScope)
    for i=1, #ids do
        local targetID = ids[i]
        if targetID ~= ID then
            sendMessage(targetID, Descriptions.FULL, {baseID = BaseID})
        end
    end
end

function forwardTimeUpMessage()
    local ids = PlanetScanner.get_ids_in_range(CommunicationScope)
    for i=1, #ids do
        local targetID = ids[i]
        if targetID ~= ID then
            sendMessage(targetID, Descriptions.TIMEUP, {baseID = BaseID})
        end
    end
end

function sendMessage(targetID, eventDescription, eventTable)
    if calculateEnergyToBase() < CurrentEnergy * 0.9 then
        CurrentEnergy = CurrentEnergy - MessageCost
        say("Transporter #: " .. ID .. " sending message '" .. eventDescription .. "' to " .. targetID)
        Event.emit{speed=343, targetID=targetID, description=eventDescription, table=eventTable}
    end
end

function depositOres()
    say("Transporter #: " .. ID .. " depositing " .. OreCount .. " ores to: " .. BaseID .. " recharging")
    sendMessage(BaseID, Descriptions.ORE, {ore=OreCount})
    OreCount = 0
    CurrentEnergy = Energy
end

function pickUpOre()
    if Map.checkColor(PositionX, PositionY) ~= background_color then
        Map.modifyColor(PositionX, PositionY, background_color)
        OreCount = OreCount + 1
        CurrentEnergy = CurrentEnergy - PickupCost
        say("Transporter #: " .. ID .. " picked up ore, current ore count: " .. OreCount)
    end
end

function die()
    say("Transporter #: " .. ID .. " died.")
    GridMove = false
    Collision.reinitializeGrid()
    Agent.removeAgent(ID)
end

function shiftMemory()
    local j = 2
    for i=2, #Memory do
        j = i
        if Memory[i + 1] == nil then break end 
        Memory[i] = Memory[i+1]
    end
    Memory[j] = nil
end

function move()
    PositionX = math.floor(PositionX)
    PositionY = math.floor(PositionY)

    local currentPosition = {x=PositionX, y=PositionY}

    local bestDelta = PlanetMovement.get_delta_position(currentPosition, Memory[2])

    if PlanetMovement.advance_position(bestDelta.x, bestDelta.y) then
        CurrentEnergy = CurrentEnergy - MotionCost
    else
        local secondBestDelta = PlanetMovement.get_second_delta_position(currentPosition, Memory[2])
        if PlanetMovement.advance_position(secondBestDelta.x, secondBestDelta.y) then
            CurrentEnergy = CurrentEnergy - MotionCost
        end
    end
end

function calculateEnergyToBase()
    return PlanetMovement.get_distance_to(Memory[1]) * MotionCost
end