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

-- Initialization of the agent.
function InitializeAgent()
	
	say("Transporter #: " .. ID .. " has been initialized")

    Agent.changeColor{b=255}

	PositionX = math.floor(PositionX)
	PositionY = math.floor(PositionY)

	GridMove = true

	Energy = 150                -- E
    CurrentEnergy = Energy
    CommunicationScope = 20     -- I
    MotionCost = 5              -- Q
    MessageCost = 1
    PickupCost = 0
    MemorySize = 15             -- S
    MaxCycles = 100000          -- T
    CarriageCapacity = 25       -- W
    OreCount = 0

    DestinationX = PositionX
    DestinationY = PositionY

    Memory = {}     
end

function TakeStep()

    if CurrentEnergy < 0 then
        die()
    end

    if state_init then
        -- wait for base
    elseif not Moving then
        
        if state_moving then
        
            move()
            if PositionX == Memory[2].x and PositionY == Memory[2].y then
                shiftMemory()
                state_moving = false
            end
        
        elseif state_deposit then
            depositOres()
            state_deposit = false
            state_moving = true
            state_pick_up = true
        
        elseif state_pick_up then
            pickUpOre()
            state_pick_up = false
            determineNextAction()

        elseif state_forward_full then
            forwardMessage()
            Memory[2] = Memory[1]
            state_moving = true
            state_forward_full = false
            state_return_to_base = true

        elseif state_accept_ores then
            sendAcceptMessage()
            state_accept_ores = false
            determineNextAction()

        elseif state_return_to_base then
            -- Do nothing
        end
    end
end

function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)

    if eventDescription == Descriptions.INIT then
        BaseID = sourceID
        state_init = false
        say("Transporter #: " .. ID .. " received init from " .. sourceID)
        table.insert(Memory, {x=sourceX, y=sourceY}) 
	elseif eventDescription == Descriptions.FULL and not (state_return_to_base or state_forward_full) then
        local baseFullId = eventTable[Descriptions.BASEID]
        if baseFullId == BaseID then
            state_forward_full = true
            say("Transporter #: " .. ID .. " received base full for " .. baseFullId .. " forwarding and returning to base")
        end

        -- TODO: Add logic to handle coordination mode

    elseif eventDescription == Descriptions.OREPOS then
        say("Transporter #: " .. ID .. " received ore positions from " .. sourceID)
        local oreTable = eventTable
        AcceptID = sourceID

        state_accept_ores = true
	end
end

function determineNextAction()
    
    if Memory[2] ~= nil then

        if OreCount < CarriageCapacity then

            if PlanetMovement.get_distance_to(Memory[2]) * MotionCost + PickupCost + PlanetMovement.get_distance_between(Memory[1], Memory[2]) * MotionCost <= CurrentEnergy * 0.8 then

                state_moving = true
                state_pick_up = true
                return

            else -- low on energy, return to base
                state_deposit = true
                state_moving = true
                return

            end

        else -- storage is full, deposit ores
            state_deposit = true
            state_moving = true
            return
        end

    elseif calculateEnergyToBase() >= CurrentEnergy * 0.7 then -- Running low on energy, return to base
        state_deposit = true
        state_moving = true
        Memory[2] = {x=PositionX, y=PositionY}
        return
    end

end

function sendAcceptMessage()
    sendMessage(AcceptID, Descriptions.ACCEPT)
end

function forwardMessage()
    local ids = PlanetScanner.get_ids_in_range(CommunicationScope)
    for i=1, #ids do
        local targetID = ids[i]
        if targetID ~= ID then
            sendMessage(targetID, Descriptions.FULL, {baseID = BaseID})
        end
    end
end

function sendMessage(targetID, eventDescription, eventTable)
    if calculateEnergyToBase() < CurrentEnergy * 0.9 then
        CurrentEnergy = CurrentEnergy - MessageCost
        say("Transporter #: " .. ID .. " sending message '" .. eventDescription .. "' to " .. targetID)
        Event.emit{targetID=targetID, description=eventDescription, table=eventTable}
    end
end

function depositOres()
    say("Transporter #: " .. ID .. " depositing " .. OreCount .. " ores to: " .. BaseID)
    sendMessage(BaseID, Descriptions.ORE, {ore=OreCount})
    OreCount = 0
    CurrentEnergy = Energy
end

function pickUpOre()
    Map.modifyColor(PositionX, PositionY, background_color)
    OreCount = OreCount + 1
    CurrentEnergy = CurrentEnergy - PickupCost
    say("Transporter #: " .. ID .. " picked up ore, current ore count: " .. OreCount)
end

function die()
    say("Transporter #: " .. ID .. " died.")
    GridMove = false
    Collision.reinitializeGrid()
    Agent.removeAgent(ID)
end

function shiftMemory()
    local j = 2
    for i=2,#Memory-1 do
        if Memory[i + 1] == nil then break end 
        Memory[i] = Memory[i+1]
        j = i
    end
    Memory[j] = nil
end

function move()
    local delta_x = PlanetMovement.get_delta_x(PositionX, Memory[2].x)
    local delta_y = PlanetMovement.get_delta_y(PositionY, Memory[2].y)

    if PlanetMovement.advance_position(delta_x, delta_y) then
        CurrentEnergy = CurrentEnergy - MotionCost
    end
end

function calculateEnergyToBase()
    return PlanetMovement.get_distance_to(Memory[1]) * MotionCost
end