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

background_color = {0,0,0}

ORE = "ore"
FULL = "full"
INIT = "init"
BASEID = "baseID"

state_init = true
state_to_base = false
state_return_to_base = false
state_pick_up = false
state_forward_message = false

-- Initialization of the agent.
function InitializeAgent()
	
	say("Transporter #: " .. ID .. " has been initialized")

	PositionX = math.floor(PositionX)
	PositionY = math.floor(PositionY)

	GridMove = true

	Energy = 150                -- E
    CurrentEnergy = Energy
    CommunicationScope = 20     -- I
    MotionCost = 5              -- Q
    MessageCost = 1
    MemorySize = 15             -- S
    MaxCycles = 100000          -- T
    CarriageCapacity = 25       -- W
    OreCount = 0

    DestinationX = PositionX
    DestinationY = PositionY

    Memory = {}
    table.insert(Memory, {x=PositionX, y=PositionY})      
end

function TakeStep()
    if CurrentEnergy < 0 then
        die()
    end

    if state_init then
        -- wait for base
    elseif not Moving then
        if PositionX ~= DestinationX and PositionY ~= DestinationY then
            move() 
        elseif state_to_base then
            depositOres()
        elseif state_pick_up then
            pickUpOre()
        elseif state_forward_message then
            forwardMessage()
        elseif state_return_to_base then
            -- Do nothing
        end
    end
end

function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)

    if eventDescription == INIT then
        BaseID = sourceID
        state_init = false
	elseif eventDescription == FULL then
        local baseFullId = eventTable[BASEID]
        if baseFullId == BaseID then
            state_forward_message = true
            say("Transporter #: " .. ID .. " received base full from " .. baseFullId .. " forwarding and returning to base")
        end

        -- TODO: Add logic to handle coordination mode
	end
end

function forwardMessage(eventTable)
    local ids = getIdsInRange()
    for i=1, #ids do
        local targetID = ids[i]
        Event.emit{targetID=targetID, description=eventDescription, table={baseID = BaseID}}
        CurrentEnergy = CurrentEnergy - MessageCost
        say("Transporter #: " .. ID .. " forwarding message to " .. targetID)
    end
    state_return_to_base = true
    DestinationX = Memory[1].x
    DestinationY = Memory[1].y
end

function depositOres()
    say("Transporter #: " .. ID .. " depositing " .. OreCount .. " ores to: " .. BaseID)
    Event.emit{targetID=BaseID, description=ORE, table={ore=OreCount}}
    OreCount = 0
    CurrentEnergy = Energy
    state_to_base = false
end

function pickUpOre()
    Map.modifyColor(PositionX, PositionY, background_color)
    OreCount = OreCount + 1
    say("Transporter #: " .. ID .. " picked up ore, current ore count: " .. OreCount)
    state_pick_up = false
end

function die()
    say("Transporter #: " .. ID .. " died.")
    GridMove = false
    Collision.reinitializeGrid()
    Agent.removeAgent(ID)
end

function getIdsInRange()
    id_table = {}
    x_init = math.floor(PositionX - CommunicationScope/2) 
    x_end = math.floor(PositionX + CommunicationScope/2) 
    x_scan = {}
    if x_init < 0 then 
        for i = x_init,0,1 do
            table.insert(x_scan,(ENV_WIDTH-1+i))
        end    
        for i = 0, x_end do
            table.insert(x_scan,i)
        end     
    elseif x_end > (ENV_WIDTH-1) then
        for i = x_end,ENV_WIDTH,-1 do
            table.insert(x_scan,(i-ENV_WIDTH))
        end
        for i = x_init, (ENV_WIDTH-1) do
            table.insert(x_scan,i)
        end 
    else
        for  i = x_init, x_end do 
            table.insert(x_scan,i)
        end
    end 

    y_init =  math.floor(PositionY - CommunicationScope/2)
    y_end = math.floor(PositionY + CommunicationScope/2)
    y_scan = {}
    if y_init < 0 then 
        for i = y_init,0,1 do
            table.insert(y_scan,(ENV_WIDTH-1+i))
        end    
        for i = 0, y_end do
            table.insert(y_scan,i)
        end     
    elseif y_end > (ENV_WIDTH-1) then
        for i = y_end,ENV_WIDTH,-1 do
            table.insert(y_scan,(i-ENV_WIDTH))
        end
        for i = y_init, (ENV_WIDTH-1) do
            table.insert(y_scan,i)
        end 
    else
        for  i = y_init, y_end do 
            table.insert(y_scan,i)
        end
    end
    
    for i=1, #x_scan do
       
        for j=1, #y_scan do
			ids = Collision.checkPosition(x_scan[i],y_scan[j])

			for k=1, #ids do 
		    	table.insert(id_table, ids[k])
		    end
        end
	end
 
	return id_table
end