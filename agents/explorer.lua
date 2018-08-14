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

AgentMovement = require "modules/agent_movement"
AgentScanner = require "modules/agent_scanner"
AgentBattery = require "modules/agent_battery"

ore_table = {}
ore_send = {}
people_ID_table = {}
background_color = {0,0,0}
ore_color = {255,255,0}
last_package_sent = false
direction_base = true
transporterID = 0

D = 30 -- % ore
P = 7-- minimum value scope = 3
Y = 2 --number of transporters
X = 2 --number of explorers 
MemorySize = 3--Y + X -2 
memory_S = {}
state_low_battery = false
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
CostMoving = 2

Energy = 150                -- E
CurrentEnergy = Energy
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


    Agent.changeColor{r=255}

	GridMove = true
    Moving = true
    --StepMultiple = 10000
    DestinationX = PositionX 
    DestinationY = PositionY
    -- we suppose that we are born in the base so our initial position == base postion 
    table.insert(memory_S, {x = PositionX, y =PositionY}) -- save base position 
    file = io.open("results/energytest.csv", "w")

end

function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)
    
    if eventDescription == INIT then
        baseID = sourceID
        table.insert(memory_S, {x = eventTable.x, y =eventTable.y})
        say("Explorer #: " .. ID .. " received inital position ")

        state_initial = true
    elseif eventDescription == FULL then
        local baseFullId = eventTable[Descriptions.BASEID]
        if baseFullId == BaseID then
            state_forward_full = true
            say("Explorer #: " .. ID .. " received base full for " .. baseFullId .. " forwarding and returning to base")
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
                        delta_x = AgentMovement.get_delta_x(PositionX, memory_S[2].x)
                        delta_y = AgentMovement.get_delta_y(PositionY, memory_S[2].y)
                        if AgentMovement.advance_position(delta_x,delta_y) then --returns true if move success                    
                         CurrentEnergy = CurrentEnergy - CostMoving
                        end
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
                
                new_position = AgentMovement.get_new_position()
                xx = new_position.x 
                yy = new_position.y 
               -- l_print("new x "..xx.." new y "..yy)
                table.insert(memory_S,2, {x = xx, y = yy})
     
            else 
                
                -- if we are not in the desired position
                if AgentBattery.low_battery_moving() then 
                    -- Nothin
            
                elseif PositionX ~= memory_S[2].x or PositionY ~= memory_S[2].y then

                    if not Moving then 
                        delta_x = AgentMovement.get_delta_x(PositionX, memory_S[2].x)
                        delta_y = AgentMovement.get_delta_y(PositionY, memory_S[2].y)
                       -- 
                   --    say(" moving Current position "..PositionX.." "..PositionY)  
                     --  say(" goal position "..memory_S[2].x.." "..memory_S[2].y)
                        if AgentMovement.advance_position(delta_x,delta_y) then --returns true if move success                 
                            CurrentEnergy = CurrentEnergy - CostMoving
                        end
                     end 
                else 

                    if state_low_battery then 
                        memory_S[2].x = memory_S[3].x 
                        memory_S[2].y = memory_S[3].y
                        CurrentEnergy = Energy 
                        say("energy full "..CurrentEnergy)
                        memory_S[3] = nil
                        state_low_battery = false
                        direction_base = true
                    else
                    --l_print("final x "..PositionX.." final y "..PositionY)
                    memory_S[2] = nil
                    state_moving = false
                    say("Explorer #: " .. ID .. " has reached the new position ")
                    state_scanning = true
                    end
                end
            end
            

         -------------------------------------------------------------------------------------------------------
         --SCANING----------------------------------------------------------------------------------------------
         -------------------------------------------------------------------------------------------------------
        elseif state_scanning then 
            say("Explorer #: " .. ID .. " start scanning ")
            if AgentBattery.low_battery_scanning() then 
                --nothing
            else 
            ore_table = AgentScanner.scanning("ore")
            CurrentEnergy = CurrentEnergy - PerceptionScope
            if ore_table == nil then --list is empty increase scope
                l_print("Explorer #: " .. ID .. " has not found ore in this position")
                state_increase_scope = true
                state_scanning = false 


            else -- #ore_found ~= 0 then
                people_ID_table = AgentScanner.scanning("people")
                if (#people_ID_table - #trans_contacted) > 0 then -- I have a list and tranporters close to me (excluding me)
                    state_sending = true
                else -- no transporters in my communication scope
                    state_waiting = true 
                end
                state_scanning = false

            end
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
            --- ADD BATTERY CONTROL
            if AgentBattery.low_battery_sending() then 
                --nothing
            elseif (#people_ID_table - #trans_contacted) <= 0 then
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
                CurrentEnergy = CurrentEnergy - MessageCost
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
            distance_to_base = AgentMovement.dist_to_base()
            NumberCyclesWaiting = NumberCyclesWaiting + 1
            people_ID_table = AgentScanner.scanning("people")
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
                for i = 1, #ore_table do -- clean ore position table 
                    ore_send[i]=nil
                end
            end
            
            

        end
    end
    write_file()
    if CurrentEnergy <= 0 then
        AgentBattery.die()
    end

end

    

        

function write_file()
    
    file:write(CurrentEnergy..",\n")
    
end 


function cleanUp()
    l_debug("Agent #: " .. ID .. " is done\n")
    file:close()
end




function sendMessage(targetID, eventDescription, eventTable)
    -- CurrentEnergy = CurrentEnergy - MessageCost
     Event.emit{speed=343,targetID=targetID, description=eventDescription, table=eventTable}
 end
 
