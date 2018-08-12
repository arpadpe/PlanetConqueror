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
state_moving = false

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
        say("Transporter #: " .. ID .. " received init from " .. sourceID)
        table.insert(Memory, {x=sourceX, y=sourceY}) 
	elseif eventDescription == FULL and not (state_return_to_base or state_forward_message) then
        local baseFullId = eventTable[BASEID]
        if baseFullId == BaseID then
            state_forward_message = true
            say("Transporter #: " .. ID .. " received base full for " .. baseFullId .. " forwarding and returning to base")
        end

        -- TODO: Add logic to handle coordination mode
	end
end

function forwardMessage()
    local ids = getIdsInRange()
    for i=1, #ids do
        local targetID = ids[i]
        if targetID ~= ID then
            say("Transporter #: " .. ID .. " forwarding message to " .. targetID)
            sendMessage(targetID, FULL, {baseID = BaseID})
        end
    end
    Memory[2] = Memory[1]
    state_moving = true
    state_forward_message = false
    state_return_to_base = true
end

function sendMessage(targetID, eventDescription, eventTable)
    CurrentEnergy = CurrentEnergy - MessageCost
    Event.emit{targetID=targetID, description=eventDescription, table=eventTable}
end

function depositOres()
    say("Transporter #: " .. ID .. " depositing " .. OreCount .. " ores to: " .. BaseID)
    sendMessage(BaseID, ORE, {ore=OreCount})
    OreCount = 0
    CurrentEnergy = Energy
    state_to_base = false
end

function pickUpOre()
    Map.modifyColor(PositionX, PositionY, background_color)
    OreCount = OreCount + 1
    say("Transporter #: " .. ID .. " picked up ore, current ore count: " .. OreCount)
    state_pick_up = false
    if Memory[2] ~= nil then
        state_moving = true
    end
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

    y_init = math.floor(PositionY - CommunicationScope/2)
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

function move()
    local delta_x = get_delta_x(PositionX, Memory[2].x)
    local delta_y = get_delta_y(PositionY, Memory[2].y)

    if advance_position(delta_x, delta_y) then
        CurrentEnergy = CurrentEnergy - MotionCost
        if PositionX == Memory[2].x and PositionY == Memory[2].y then
            shiftMemory()
            state_moving = false
        end
    end
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

function get_delta_x(pos_x, x_goal)

    if pos_x < x_goal then
        distAB_x = x_goal - pos_x - ENV_WIDTH
        --l_print("distAB_x "..distAB_x)
        distBA_x = pos_x - x_goal
        --l_print("distBA_x "..distBA_x)
    else
        distAB_x = x_goal - pos_x
        --l_print("distAB_x "..distAB_x)
        distBA_x = pos_x - x_goal - ENV_WIDTH
        --l_print("distBA_x "..distBA_x)
    end


    if math.abs(distAB_x) < math.abs(distBA_x) then
        if distAB_x < 0  then
            d_x = -1
        else 
            d_x = 1
        end
    
    else --if math.abs(distAB_x) > math.abs(distBA_x) then 
        if distBA_x < 0 then
            d_x = 1
        else  
            d_x = -1
        end
    end
  --  l_print("delta x "..d_x)
    return d_x


end

function get_delta_y(pos_y, y_goal)

    if pos_y < y_goal then
        distAB_y = y_goal - pos_y - ENV_HEIGHT
        --l_print("disAB_y "..distAB_y)
        distBA_y = pos_y - y_goal 
        --l_print("disBA_y "..distBA_y)
    else 
        distAB_y = y_goal-pos_y 
        --l_print("disAB_y "..distAB_y)
        distBA_y = pos_y -y_goal - ENV_HEIGHT
        --l_print("disBA_y "..distBA_y)
    end

    if math.abs(distAB_y) < math.abs(distBA_y) then
        if distAB_y < 0   then
            d_y = -1
        else
            d_y = 1
        end
    else -- if math.abs(distAB_y) > math.abs(distBA_y) then 
        if distBA_y < 0  then
            d_y = 1
        else
            d_y = -1
        end
    end
  --  l_print("delta y "..d_y)
    return d_y

end

function advance_position(d_x,d_y)
    if Memory[1].x == PositionX then 
        d_x = 0
   --     l_print("dx = 0")
    end

    if Memory[1].y == PositionY then 
        d_y = 0
 --       l_print("dy = 0")
    end

    if PositionX > ENV_WIDTH - 2 then -- if it is 199 or bigger
        PositionX = 0 -- make it 0
    elseif PositionX < 1 then -- if it is 0  
        PositionX = ENV_WIDTH -1 -- make it 199
    end     

    if PositionY > ENV_HEIGHT -2 then 
        PositionY = 0
    elseif PositionY < 1  then
        PositionY = ENV_HEIGHT -1 
    end
    
    l_print("pos X "..d_x.." pos y "..d_y) 

    -- move when the square is empty
    if not Collision.checkCollision(PositionX+d_x,PositionY+d_y) then
        l_print("moving to pos X "..PositionX+d_x.." pos y "..PositionY+d_y)
        Move.to{x=PositionX+d_x, y=PositionY+d_y}
        return true
    else 
        return false
    end
end