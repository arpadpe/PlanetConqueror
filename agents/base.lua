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

ORE = "ore"
FULL = "full"

-- Initialization of the agent.
function InitializeAgent()
	
	say("Agent #: " .. ID .. " : has been initialized")

	PositionX = math.floor(PositionY)
	PositionY = math.floor(PositionY)

	GridMove = true
	StepMultiple = 1000

	OreCapacity = 100 			-- C
	OreCount = 0
	CommunicationScope = 20 	-- I
end

function TakeStep()
	if OreCount < OreCapacity then
		sendFull()
	end
end

function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)	
	if eventDescription == ORE then
		if OreCount < OreCapacity then
			local oreNo = eventTable[ORE]
			if OreCount + oreNo > OreCapacity then
				OreCount = OreCapacity
			else
				OreCount = OreCount + oreNo
			end
			say("Base #: " .. ID .. " received " .. oreNo .. " ores from: " .. sourceID .. " current ore count: " .. OreCount)
		end
	end
end

function sendFull()
	say("Base #: " .. ID .. " is full, sending messages")
	local ids = getIdsInRange()
	for i=1, #ids do
		local targetID = ids[i]
		Event.emit{targetID=targetID, description=FULL}
		say("Base #: " .. ID .. " sending full message to " .. targetID)
	end
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