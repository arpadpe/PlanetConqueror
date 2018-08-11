-- Import valid Rana lua libraries.
Agent = require "ranalib_agent"
Collision = require "ranalib_collision"
Stat = require "ranalib_statistic"
Move = require "ranalib_movement"
Map = require "ranalib_map"
Shared = require "ranalib_shared"
Draw = require "ranalib_draw" 
Shared = require "ranalib_shared"

ore_table = {}
ore_send = {}
people_ID_table = {}
background_color = {0,0,0}
ore_color = {255,255,0}

D = 3 -- % ore
P = 3-- minimum value scope = 3
Y = 2 --number of transporters
X = 2 --number of explorers 
MemorySize = Y + X -1
memory_S = {}
state_initial = false 
state_moving = true
state_scanning = false
state_increase_scope = false
state_waiting = false
state_sending = false 
map_size = ENV_WIDTH

CommunicationScope = 20     -- I
PerceptionScope = 2         -- P
CostMoving = 15
FULL = "full"
BASEID = "baseID"
INIT = "init"
 
baseID = 0
delta_y =0 
delta_x =0

function initializeAgent()

	l_debug("Enviroment : " .. ID .. " has been initialized")
    Agent.changeColor{r=255}
    --Drawing the map--
	for i = 0, ENV_WIDTH -1 do
        for j = 0, ENV_HEIGHT -1 do
            if D >= Stat.randomInteger(1,100) then
                Map.modifyColor(i,j, ore_color)
               -- l_print("ore PAINTED: "..i.." "..j)

            else 
               Map.modifyColor(i,j, background_color)
            end
		end
    end


    PositionX = ENV_WIDTH/2 
    PositionY =  ENV_HEIGHT/2 
    l_print("PositionX "..PositionX.." PositionY "..PositionY)
	Speed = 2
	GridMove = true
    Moving = true
    DestinationX = PositionX 
    DestinationY = PositionY
    -- we suppose that we are born in the base so our initial position == base postion 
    table.insert(memory_S, {x = PositionX, y =PositionY}) -- save base position 

end

function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)
    
    if eventDescription == INIT then
        baseID = sourceID
        table.insert(memory_S, {x = eventTable.x, y =eventTable.y})
        say("Explorer #: " .. ID .. " received inital position ")
        delta_x = get_delta_x(PositionX, eventTable.x)
        delta_y = get_delta_y(PositionY, eventTable.y)
    
    elseif eventDescription == FULL then
            local baseFullId = eventTable[BASEID]
            if baseFullId == BaseID then
                --state_forward_message = true
                --TODO: explorer need state_foward_message 
                say("EXPLORER #: " .. ID .. " received base full from " .. baseFullId .. " forwarding and returning to base")
            end
    
            -- TODO: Add logic to handle coordination mode
       -- end
	end
end

function takeStep()
     -------------------------------------------------------------------------------------------------------
     --INITIAL-----------------------------------------------------------------------------------------------
     -------------------------------------------------------------------------------------------------------
    if state_initial then
        say("Explorer #: " .. ID .. " waiting for inital position ")
        if memory_S[2]~= nil then
            PositionX = math.floor(PositionX)
            PositionY = math.floor(PositionY)
            if PositionX ~= memory_S[2].x or PositionY ~= memory_S[2].y then
                if not Moving then 
                    advance_position(delta_x,delta_y) --returns true if move success                    
                end 
            else 
                table.remove{memory_S,2}
                say("Explorer #: " .. ID .. " has reached the inital position ")
                state_scanning = true
                state_initial = false
            end

        end

     -------------------------------------------------------------------------------------------------------
     --MOVING-----------------------------------------------------------------------------------------------
     -------------------------------------------------------------------------------------------------------

    elseif state_moving then
       -- l_print("state moving")
        --we suppose that each time that we start a new moving cycle (after finish sending all the messages)
        --in our memory only have the base position, we have use table.remove, 
        --l_print("START MOVEMENT")
        PositionX = math.floor(PositionX)
        PositionY = math.floor(PositionY)
        
        if memory_S[2] == nil then
            new_position = {}
            l_print("calculating new position")
            new_position = get_new_position()
            xx = new_position.x 
            yy = new_position.y 
            --l_print("new x "..xx.." new y "..yy)
            table.insert(memory_S, {x = xx, y = yy})

            delta_x = get_delta_x(PositionX, xx)
            delta_y = get_delta_y(PositionY, yy)      
        else 
            
            -- if we are not in the desired position
            if PositionX ~= memory_S[2].x or PositionY ~= memory_S[2].y then
                
                if not Moving then 
                  
                    advance_position(delta_x,delta_y) --returns true if move success                    
                end 
            else 
                --l_print("final x "..PositionX.." final y "..PositionY)
                memory_S[2] = nil
                state_moving = false
                --l_print("position reached ")
                state_scanning = true
            end
        end
     -------------------------------------------------------------------------------------------------------
     --SCANING----------------------------------------------------------------------------------------------
     -------------------------------------------------------------------------------------------------------
    elseif state_scanning then 
        l_print("START SCANNING ")
        ore_table = scanning("ore")

        
        if #ore_table == 0 then --list is empty increase scope
            l_print("ore table  = 0")
            state_increase_scope = true
            state_scanning = false 
        else --list is full -> find people
            people_ID_table = scanning("people")
            if #people_ID_table > 1 then -- I have a list and tranporters close to me (excluding me)
                state_sending = true
            else -- no transporters in my communication scope
                state_waiting = true 
            end
            state_scanning = false 
        end
    -------------------------------------------------------------------------------------------------------
    --INCREASING SCOPE----------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------
    elseif state_increase_scope then
        l_print("START INCREASING SCOPE")
        if MemorySize > (PerceptionScope*PerceptionScope/2) then
            --say("Large memory")
            if (PerceptionScope/CostMoving) > 1.5 then 
               -- say("increase scope it's to expensive better move")
                state_moving = true
                state_increase_scope = false
            else
                PerceptionScope = PerceptionScope + 1
               -- say("let's increase scope")
                if PerceptionScope > map_size/100 then -- in this case we keep the size of PErceptionScope
                    state_moving = true
                    --say("scope is max -> let's move")
                else 
                    --say("scope increased - scan again")
                    state_scanning = true
                end
                state_increase_scope = false
            end
        else 
             --say ("small memory")
            if (CostMoving/PerceptionScope) > 1.5 then 
                PerceptionScope = PerceptionScope + 1
               -- say(" moving it's to expensive let's increase scope")
                if PerceptionScope > map_size/100 then 
                    --say("scope it's at max -> let's move")
                    PerceptionScope = 1 --- TODO: Define initial scope 
                    state_moving = true
                else 
                    --say(" scope increased - let's move")
                    state_scanning = true
                    
                end
                state_increase_scope = false
            else
                --say("increasing the scope is to expensive let's move ")
                state_moving = true
                state_increase_scope = false
            end

        end 
    -------------------------------------------------------------------------------------------------------
    --SENDING----------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------
    elseif state_sending then
        say("SENDING POSITIONS TO TRANSPORTERS")
    -------------------------------------------------------------------------------------------------------
    --WAITING----------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------
    elseif state_waiting then
        say("WAITING FOR TRANSPORTERS")


    end

end

    



function cleanUp()
	l_debug("Agent #: " .. ID .. " is done\n")
end

function get_new_position()
    PositionX = math.floor(PositionX)
    PositionY = math.floor(PositionY)
    position_table = {}
    table.insert(position_table, 1, {x = PositionX + CommunicationScope, y = PositionY})
    table.insert(position_table, 2, {x = PositionX - CommunicationScope, y = PositionY})
    table.insert(position_table, 3, {x = PositionX, y = PositionY - CommunicationScope})
    table.insert(position_table, 4, {x = PositionX, y = PositionY + CommunicationScope}) 
    return position_table[Stat.randomInteger(1,#position_table)]
end

function scanning(mode)
    ore_found = {}
    id_table = {}

    if mode == "ore" then
        x_init = math.floor(PositionX - PerceptionScope/2) 
        x_end = math.floor(PositionX + PerceptionScope/2) 
        y_init =  math.floor(PositionY - PerceptionScope/2)
        y_end = math.floor(PositionY + PerceptionScope/2)
    elseif mode == "people" then
        x_init = math.floor(PositionX - CommunicationScope/2) 
        x_end = math.floor(PositionX + CommunicationScope/2) 
        y_init =  math.floor(PositionY - CommunicationScope/2)
        y_end = math.floor(PositionY + CommunicationScope/2)
    end
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
    --l_print("size x_scan "..#x_scan.." Size y_scan "..#y_scan)
    if mode == "ore" then

        for i=1, #x_scan do
            for j=1, #y_scan do

                if Draw.compareColor(Map.checkColor(x_scan[i],y_scan[j]),ore_color) then
                    table.insert(ore_found,{x_scan[i],y_scan[j]})
                    
                    --l_print("ore found: "..x_scan[i].." "..y_scan[j])
                end
            end
        end
        return ore_found
    elseif mode == "people" then
        for i=1, #x_scan do
       
            for j=1, #y_scan do
			    ids = Collision.checkPosition(x_scan[i],y_scan[j])

			    for k=1, #ids do 
                    table.insert(id_table, ids[k])
                    l_print("id found "..ids[k])
		        end
            end
	    end
        return id_table
    end

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
    if memory_S[2].x == PositionX then 
        d_x = 0
   --     l_print("dx = 0")
    end

    if memory_S[2].y == PositionY then 
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
    
    --l_print("pos X "..PositionX.." pos y "..PositionY) 

    -- move when the square is empty
    if not Collision.checkCollision(PositionX+d_x,PositionY+d_y) then 
        Move.to{x=PositionX+d_x, y=PositionY+d_y}
        return true
    else 
        return false
    end
end
