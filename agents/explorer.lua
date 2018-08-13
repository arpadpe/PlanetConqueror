-- Import valid Rana lua libraries.
Agent = require "ranalib_agent"
Collision = require "ranalib_collision"
Stat = require "ranalib_statistic"
Move = require "ranalib_movement"
Map = require "ranalib_map"
Shared = require "ranalib_shared"
Draw = require "ranalib_draw" 
Shared = require "ranalib_shared"
Event = require "ranalib_event"

ore_table = {}
ore_send = {}
people_ID_table = {}
background_color = {0,0,0}
ore_color = {255,255,0}
last_package_sent = false

transporterID = 0

D = 30 -- % ore
P = 7-- minimum value scope = 3
Y = 2 --number of transporters
X = 2 --number of explorers 
MemorySize = 3--Y + X -2 
memory_S = {}
state_initial = false 
state_moving = false
state_scanning = false
state_increase_scope = false
state_waiting = false
state_sending = false 
get_number_packages = true
waiting_answer = false
total_number_packages = 0
package_accepted = false 
count_packages = 0 
map_size = ENV_WIDTH

trans_contacted = {}

NumberCyclesWaiting = 0
NumberCyclesWaitingAnswer = 0
CommunicationScope = 50     -- I
PerceptionScope = 5         -- P
CostMoving = 15
FULL = "full"
BASEID = "baseID"
INIT = "init"
ORE_POS = "ore_pos"
ACCEPT = "accept"
ROBOTS = "robots"
list_transporters = {}
baseID = 0
delta_y =0 
delta_x =0

function initializeAgent()

	--l_debug("Enviroment : " .. ID .. " has been initialized")
    Agent.changeColor{r=255}
    --Drawing the map--
	--[[for i = 0, ENV_WIDTH -1 do
        for j = 0, ENV_HEIGHT -1 do
            if D >= Stat.randomInteger(1,100) then
                Map.modifyColor(i,j, ore_color)
               -- l_print("ore PAINTED: "..i.." "..j)

            else 
               Map.modifyColor(i,j, background_color)
            end
		end
    end]]

    --l_print("PositionX "..PositionX.." PositionY "..PositionY)
	--Speed = 2
	GridMove = true
    Moving = true
    --StepMultiple = 10000
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
        state_initial = true
    elseif eventDescription == FULL then
        local baseFullId = eventTable[BASEID]
        if baseFullId == BaseID then
            --state_forward_message = true
            --TODO: explorer need state_foward_message 
            say("EXPLORER #: " .. ID .. " received base full from " .. baseFullId .. " forwarding and returning to base")
        end
    
            -- TODO: Add logic to handle coordination mode
       -- end
    elseif eventDescription == ACCEPT then 
        package_accepted = true 
        waiting_answer = false
        say("EXPLORER #: " .. ID .. " got accepted by transporter # " .. sourceID)
        if last_package_sent then
            say("Explorer #: " .. ID .. " has sent all the packages in this position")
            state_sending = false
            state_moving = true
            get_number_packages = true
            count_packages = 0
            last_package_sent = false
            trans_accp = 0
            trans_ign = 0
        else
            state_scanning = true 
            state_sending = false 
        end
    
	end
end

val = true

function takeStep()

    if val then
        Move.to{x=PositionX + 1, y=PositionY}
        val = false
    else
         -------------------------------------------------------------------------------------------------------
         --INITIAL-----------------------------------------------------------------------------------------------
         -------------------------------------------------------------------------------------------------------
        if state_initial then
          --  say("Explorer #: " .. ID .. " waiting for inital position ")
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
                    list_robots = Shared.getTable(ROBOTS)
                    list_transporters = list_robots[baseID].transporters
                    print("Number of transporters " .. #list_transporters)
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
                l_print("Explorer #: " .. ID .. " is going to a NEW POSITION ")
                
                new_position = get_new_position()
                xx = memory_S[1].x --new_position.x 
                yy = memory_S[1].y --new_position.y 
                l_print("new x "..xx.." new y "..yy)
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
                    say("Explorer #: " .. ID .. " has reached the new position ")
                    state_scanning = true
                end
            end
         -------------------------------------------------------------------------------------------------------
         --SCANING----------------------------------------------------------------------------------------------
         -------------------------------------------------------------------------------------------------------
        elseif state_scanning then 
            say("Explorer #: " .. ID .. " start scanning ")
            ore_table = scanning("ore")

            if ore_table == nil then --list is empty increase scope
                l_print("Explorer #: " .. ID .. " has not found ore in this position")
                state_increase_scope = true
                state_scanning = false 


            else -- #ore_found ~= 0 then
                people_ID_table = scanning("people")
                if (#people_ID_table - #trans_contacted) > 0 then -- I have a list and tranporters close to me (excluding me)
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
            l_print("Explorer #: " .. ID .. " is increasing scope")
            if MemorySize > (PerceptionScope*PerceptionScope/2) then
                --say("Large memory")
                if (PerceptionScope/CostMoving) > 1.5 then 
                    say("Explorer #: " .. ID .. " decided to move instead increase scope")
                    state_moving = true
                    state_increase_scope = false
                else
                    PerceptionScope = PerceptionScope + 1
                   -- say("let's increase scope")
                    if PerceptionScope > map_size/100 then -- in this case we keep the size of PErceptionScope
                        state_moving = true
                        say("Explorer #: " .. ID .. " has max scope so he moves")
                    else 
                        say("Explorer #: " .. ID .. " has increased scope, scan again")
                        state_scanning = true
                    end
                    state_increase_scope = false
                end
            else 
                 --say ("small memory")
                if (CostMoving/PerceptionScope) > 1.5 then 
                    PerceptionScope = PerceptionScope + 1
                    say("Explorer #: " .. ID .. " decided to move instead increase scope")
                    if PerceptionScope > map_size/100 then 
                        say("Explorer #: " .. ID .. " has max scope so he moves")
                        PerceptionScope = 2 --- TODO: Define initial scope 
                        state_moving = true
                    else 
                        say("Explorer #: " .. ID .. " has increased scope, scan again")
                        state_scanning = true
                        
                    end
                    state_increase_scope = false
                else
                    say("Explorer #: " .. ID .. " decided to move instead increase scope")
                    state_moving = true
                    state_increase_scope = false
                end

            end 
        -------------------------------------------------------------------------------------------------------
        --SENDING----------------------------------------------------------------------------------------------
        -------------------------------------------------------------------------------------------------------
        elseif state_sending then
            say("Explorer #: " .. ID .. "is in state_sending")


            --targetID = people_ID_table[#people_ID_table - #trans_contacted] --Last transporter in the list
            if (#people_ID_table - #trans_contacted) <= 0 then
                state_sending = false
                state_waiting = true 
            elseif not waiting_answer then
               -- say("trans_contacted size "..#trans_contacted)
                --say("SENDING POSITIONS TO TRANSPORTERS")
                if #trans_contacted == 0 then 
        
                    targetID = people_ID_table[1]
                    table.insert(trans_contacted, targetID)
                    --say("set target ID "..targetID)
                else
                    differences = 0 
                    for i = 1, #people_ID_table  do  
                        for j =1, #trans_contacted do
                            if people_ID_table[i] ~= trans_contacted[j] then 
                                differences = differences +1 
        
                            end
                        end
                        if differences == #trans_contacted then
                            differences = 0
                            targetID = people_ID_table[i]
                            table.insert(trans_contacted, targetID)
                            break
                        end
                        differences = 0    
                    end
                end

                sendMessage(targetID, ORE_POS, ore_table)
                say("Explorer #: " .. ID .. " sent message to ID "..targetID)
                waiting_answer = true
                
            elseif waiting_answer then
                say("Explorer # "..ID.." is waiting an answer")
                NumberCyclesWaitingAnswer = NumberCyclesWaitingAnswer + 1
                if NumberCyclesWaitingAnswer > math.floor(1.5*CommunicationScope) then -- we have waited enough 
                    say("Explorer # "..ID.." was IGNORED")
                    waiting_answer = false 
                    NumberCyclesWaitingAnswer = 0
                end
            end
            
            if package_accepted  then 

                for i = 1, #ore_table do -- clean ore position table 
                    --l_print("ORE IN STATE SCANNING "..i.." position x "..ore_table[i].x.." position y "..ore_table[i].y)
                    if last_package_sent then
                        ore_send[i]=nil
                    end
                end      

                package_accepted = false
            end

        -------------------------------------------------------------------------------------------------------
        --WAITING----------------------------------------------------------------------------------------------
        -------------------------------------------------------------------------------------------------------
        elseif state_waiting then
            say("Explorer #: " .. ID .. " is waiting for transporters")
            distance_to_base = math.abs(PositionX - memory_S[1].x) + math.abs(PositionY - memory_S[1].y)
            NumberCyclesWaiting = NumberCyclesWaiting + 1
            people_ID_table = scanning("people")
            if #people_ID_table > 0 then -- I have a list and tranporters close to me (excluding me)
                state_sending = true
                state_waiting = false
                NumberCyclesWaiting = 0
            end
            if NumberCyclesWaiting >= distance_to_base then 
                say("Explorer #: " .. ID .. " has waited enough, it moves")
                state_moving = true -- ¿ Maybe it's useful to do a clever movement ...  
                state_sending = false 
                NumberCyclesWaiting = 0
            end
            
            

        end
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
    l_print("size x_scan "..#x_scan.." Size y_scan "..#y_scan)
    if mode == "ore" then
        total_ores = 0 
        for i=1, #x_scan do
            for j=1, #y_scan do

                if Draw.compareColor(Map.checkColor(x_scan[i],y_scan[j]),ore_color) then
                    table.insert(ore_found,{x = x_scan[i],y = y_scan[j]})
                    
                    l_print("ore found: "..x_scan[i].." "..y_scan[j])
                    total_ores = total_ores + 1 
                end
            end
        end
        -- GET NUMBER OF PACKAGES 

        if get_number_packages then
            if total_ores%MemorySize == 0 then --exact number of packages
                total_number_packages = total_ores/MemorySize
            --[[else 
                total_number_packages = math.floor(#ore_table/MemorySize)]]
               -- l_print("total number packages "..total_ores/MemorySize)
            end 
            
            get_number_packages = false
        end
       -- RETURN ORE FOUND IN MEMORY SIZE SLOTS
        
        if #ore_found <= MemorySize and #ore_found ~= 0 then 
          --  l_print(" we have plenty of memory")
            last_package_sent = true
            return ore_found
        elseif #ore_send == 0 and #ore_found ~= 0 then 
          --  l_print("first time we sent things ") 
            for i = 1 , MemorySize do 
                table.insert(ore_send, ore_found[i])
            end 
            count_packages = count_packages + 1 
            return ore_send
        elseif #ore_send ~= 0 and #ore_found ~= 0 then
            index_list = {}
         --   l_print("sedond time we sent things")
        
            for i = 1 , MemorySize do 
                for j = #ore_found, 1, -1 do
                    if ore_send[i].x == ore_found[j].x and ore_send[i].y ==ore_found[j].y then 
                       table.insert(index_list, j)
                    end
                end

            end
            max_index = math.max(unpack(index_list))
           -- l_print("max index "..max_index)
            index_list = nil
            
            
           -- l_print("remainings "..(#ore_found - max_index))
            if (#ore_found - max_index) < MemorySize then 
                for i = MemorySize, (#ore_found - max_index)+1, -1 do
                    ore_send[i]=nil--table.remove(ore_send,i)
                end
                for i = 1, (#ore_found - max_index) do     
                    ore_send[i].x = ore_found[max_index + i].x
                    ore_send[i].y = ore_found[max_index + i].y
                end 
                last_package_sent = true
            else

                for i = 1, MemorySize do
                    ore_send[i].x = ore_found[max_index + i].x
                    ore_send[i].y = ore_found[max_index + i].y

                end

                count_packages = count_packages + 1 
                if count_packages ==total_number_packages then 
                    last_package_sent = true 
                end



            end
            return ore_send
        end
        
    elseif mode == "people" then
        for i=1, #x_scan do
       
            for j=1, #y_scan do
			    ids = Collision.checkPosition(x_scan[i],y_scan[j])

                for k=1, #ids do 
                    if ids[k]~= ID  then 
                        table.insert(id_table, ids[k])
                        l_print("id found "..ids[k])
                        break
                    end
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



function sendMessage(targetID, eventDescription, eventTable)
   -- CurrentEnergy = CurrentEnergy - MessageCost
    Event.emit{speed=343,targetID=targetID, description=eventDescription, table=eventTable}
end
