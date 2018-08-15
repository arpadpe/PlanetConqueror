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
PlanetScanner = require "modules/planet_scanner"
AgentBattery = require "modules/agent_battery"

Descriptions = require "modules/event_descriptions"

ore_table = {}
ore_send = {}
people_ID_table = {}
background_color = {0,0,0}
ore_color = {255,255,0}
last_package_sent = false
direction_base = true
transporterID = 0
MessageCost = 1
 
memory_S = {}
state_low_battery = false
state_initial = false 
stay_home = false
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


trans_contacted = {}

Energy = Shared.getNumber(5)			    	-- E
GridSize = Shared.getNumber(6)					-- G
CommunicationScope = Shared.getNumber(7)		-- I
CoordinationMode = Shared.getNumber(8)			-- M 1 Cooperation 0 Competition
NumberOfBases = Shared.getNumber(9)				-- N
PerceptionScope = Shared.getNumber(10)			-- P
MotionCost = Shared.getNumber(11)				-- Q
MemorySize = Shared.getNumber(12)-1        		-- S
NumberOfCycles = Shared.getNumber(13)			-- T
ExplorersNumber = Shared.getNumber(15)			-- X
TransportersNumber = Shared.getNumber(16)		-- Y 

NumberCyclesWaiting = 0
NumberCyclesWaitingAnswer = 0



trans_working = false
    
CurrentEnergy = Energy

robotsTable = {}
BaseID = 0
delta_y =0 
delta_x =0

function initializeAgent()


    Agent.changeColor{r=255}
    say("Explorer #: " .. ID .. " has been initialized ")
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
    
    if eventDescription == Descriptions.INIT then
        BaseID = sourceID
        table.insert(memory_S, 1, {x = math.floor(sourceX), y =math.floor(sourceY)})
        say("Explorer #: " .. ID .. " received inital position ")

        state_initial = true
    elseif eventDescription == Descriptions.FULL and not stay_home then
        local baseFullId = eventTable[Descriptions.BASEID]
        if baseFullId == BaseID then
            state_forward_full = true
            say("Explorer #: " .. ID .. " received base full for " .. baseFullId .. " forwarding and returning to base")
        end
    
            -- TODO: Add logic to handle coordination mode
       -- end
    elseif eventDescription == Descriptions.ACCEPT then 
        trans_working = true
        package_accepted = true 
        waiting_answer = false
        say("EXPLORER #: " .. ID .. " got accepted by transporter # " .. sourceID)
        if last_package_sent then
            trans_working = false
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
    elseif eventDescription == Descriptions.DONE then
        say("Explorer # "..ID.." got message DONE from "..sourceID)
        for i =1, #trans_contacted do
            if sourceID == trans_contacted[i] then 
                table.remove(trans_contacted, i)

            end
        end
	end
end

val = true

function takeStep()

    if val then
        Move.to{x=PositionX + 1, y=PositionY}
        val = false
    else

        if state_forward_full and not stay_home then 
            forwardMessage()
            
            table.insert(memory_S, 2, {x = memory_S[1].x, y = memory_S[1].y})
            stay_home = true 
            state_moving = true 
            state_forward_full = false 
            state_initial = false
         -------------------------------------------------------------------------------------------------------
         --INITIAL-----------------------------------------------------------------------------------------------
         -------------------------------------------------------------------------------------------------------
        elseif state_initial then
          --  say("Explorer #: " .. ID .. " waiting for inital position ")
            if memory_S[2]~= nil then
                PositionX = math.floor(PositionX)
                PositionY = math.floor(PositionY)
                if PositionX ~= memory_S[2].x or PositionY ~= memory_S[2].y then
                    if not Moving then 
                        delta_x = AgentMovement.get_delta_x(PositionX, memory_S[2].x)
                        delta_y = AgentMovement.get_delta_y(PositionY, memory_S[2].y)
                        if AgentMovement.advance_position(delta_x,delta_y) then --returns true if move success                    
                         CurrentEnergy = CurrentEnergy - MotionCost
                        end
                     end 
                else 
                    table.remove{memory_S,2}
                    say("Explorer #: " .. ID .. " has reached the inital position ")
                    
                    state_scanning = true
                    state_initial = false
                    robotsTable = Shared.getTable(Descriptions.ROBOTS)
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
                      -- say(" moving Current position "..PositionX.." "..PositionY)  
                      -- say(" goal position "..memory_S[2].x.." "..memory_S[2].y)
                        if AgentMovement.advance_position(delta_x,delta_y) then --returns true if move success                 
                            CurrentEnergy = CurrentEnergy - MotionCost
                        end
                    end 

                else 

                    if state_low_battery then 

                        memory_S[2].x = memory_S[1].x 
                        memory_S[2].y = memory_S[1].y

                        memory_S[1].x = PositionX
                        memory_S[2].y = PositionY
                        CurrentEnergy = Energy 

                        say("Explorer: #"..ID.."energy full "..CurrentEnergy)
                        memory_S[3] = nil
                        state_low_battery = false
                        direction_base = true
                    else
                    --l_print("final x "..PositionX.." final y "..PositionY)
                        memory_S[2] = nil
                        state_moving = false
                  --  say("Explorer #: " .. ID .. " has reached the new position ")
                        state_scanning = true
                    end

                    if stay_home then 
                        say("Explorer: # "..ID.." has reached home, work finish for today ")
                        state_initial = false 
                        state_moving = false 
                        state_scanning = false 
                        state_sending = false 
                        state_waiting = false 
                        state_increase_scope = false 
                        state_forward_full = false 
                    end 
                end
            end
            

         -------------------------------------------------------------------------------------------------------
         --SCANING----------------------------------------------------------------------------------------------
         -------------------------------------------------------------------------------------------------------
        elseif state_scanning then 
           -- say("Explorer #: " .. ID .. " start scanning ")
            if AgentBattery.low_battery_scanning() then 
                --nothing
            else 
                ore_table = PlanetScanner.get_ores_in_range(PerceptionScope)
                CurrentEnergy = CurrentEnergy - PerceptionScope
                if ore_table == nil then --list is empty increase scope
                -- l_print("Explorer #: " .. ID .. " has not found ore in this position")
                    state_increase_scope = true
                    state_scanning = false 


                else -- #ore_found ~= 0 then
                    people_ID_table =  get_transporters()
                    if (#people_ID_table - #trans_contacted) > 0  then -- I have a list and tranporters close to me (excluding me)
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
            --l_print("Explorer #: " .. ID .. " is increasing scope")
            if MemorySize > (PerceptionScope*PerceptionScope/2) then
                --say("Large memory")
                if (PerceptionScope/MotionCost) > 1.5 then 
                  --  say("Explorer #: " .. ID .. " decided to move instead increase scope")
                    state_moving = true
                    state_increase_scope = false
                else
                    PerceptionScope = PerceptionScope + 1
                   -- say("let's increase scope")
                    if PerceptionScope > GridSize/100 then -- in this case we keep the size of PErceptionScope
                        state_moving = true
                     --   say("Explorer #: " .. ID .. " has max scope so he moves")
                    else 
                     --   say("Explorer #: " .. ID .. " has increased scope, scan again")
                        state_scanning = true
                    end
                    state_increase_scope = false
                end
            else 
                 --say ("small memory")
                if (MotionCost/PerceptionScope) > 1.5 then 
                    PerceptionScope = PerceptionScope + 1
                  --  say("Explorer #: " .. ID .. " decided to move instead increase scope")
                    if PerceptionScope > GridSize/100 then 
                      --  say("Explorer #: " .. ID .. " has max scope so he moves")
                        PerceptionScope = 2 --- TODO: Define initial scope 
                        state_moving = true
                    else 
                      --  say("Explorer #: " .. ID .. " has increased scope, scan again")
                        state_scanning = true
                        
                    end
                    state_increase_scope = false
                else
                 --   say("Explorer #: " .. ID .. " decided to move instead increase scope")
                    state_moving = true
                    state_increase_scope = false
                end

            end 
        -------------------------------------------------------------------------------------------------------
        --SENDING----------------------------------------------------------------------------------------------
        -------------------------------------------------------------------------------------------------------
        elseif state_sending then
           -- say("Explorer #: " .. ID .. "is in state_sending")
            --- ADD BATTERY CONTROL
            if AgentBattery.low_battery_sending() then 
                --nothing
            elseif (#people_ID_table - #trans_contacted)  <= 0 and not waiting_answer then
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

                sendMessage(targetID, Descriptions.OREPOS, ore_table)
                
                say("Explorer #: " .. ID .. " sent message to ID "..targetID)
                waiting_answer = true
            end
            if waiting_answer then
              -- say("Explorer # "..ID.." is waiting an answer")
                NumberCyclesWaitingAnswer = NumberCyclesWaitingAnswer + 1
                if NumberCyclesWaitingAnswer > math.floor(1.5*CommunicationScope) + 2 then -- we have waited enough 
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
           -- say("Explorer #: " .. ID .. " is waiting for transporters")
            distance_to_base = AgentMovement.dist_to_base()
            NumberCyclesWaiting = NumberCyclesWaiting + 1
            people_ID_table =  get_transporters()
            if (#people_ID_table - #trans_contacted) > 0 then -- I have a list and tranporters close to me (excluding me)
                state_sending = true
                state_waiting = false
                NumberCyclesWaiting = 0
            end
            if NumberCyclesWaiting >= distance_to_base and not trans_working then 
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
   -- write_file()
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

function forwardMessage()
    local people = PlanetScanner.get_ids_in_range(CommunicationScope)

        for i=#people,1,-1  do
            if robotsTable[BaseID].transporters[i] == nil and robotsTable[BaseID].explorers[i] == nil then
                table.remove(people, i)
            end
        end

    for i=1, #people do
        local targetID = people[i]
        if targetID ~= ID then
            sendMessage(targetID, Descriptions.FULL, {baseID = BaseID})
        end
    end
end


function sendMessage(targetID, eventDescription, eventTable)
    CurrentEnergy = CurrentEnergy - MessageCost
    Event.emit{speed=343,targetID=targetID, description=eventDescription, table=eventTable}

end


function get_transporters()
    people = PlanetScanner.get_ids_in_range(CommunicationScope)
    if CoordinationMode then -- Cooperative 
        for i=#people,1,-1  do
            for k, v in pairs(robotsTable) do 
      
                if robotsTable[k].transporters[i] == nil then
                    table.remove(people, i)
                end
            end
        end

    else --Competitive 
        for i=#people,1,-1  do
            if robotsTable[BaseID].transporters[i] == nil then
                table.remove(people, i)
            end
        end
    end 

    return people
end
