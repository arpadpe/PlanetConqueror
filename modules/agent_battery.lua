local agentBattery={}


function agentBattery.low_battery_sending()
    if (AgentMovement.dist_to_base()*MotionCost + 2) >= CurrentEnergy * 0.7 and not state_low_battery then -- Running low on energy, return to base
        --say("Explorer #: " .. ID .. " is low on energy, returning to base "..CurrentEnergy)
  
        PositionX = math.floor(PositionX)
        PositionY = math.floor(PositionY)
        if direction_base then
         --   say("Base position "..memory_S[1].x.." "..memory_S[1].y)
            state_low_battery = true 
            state_moving = true
            state_sending = false
            direction_base = false 
            agentBattery.swapMemory()
            --[[table.insert(memory_S, 3, {x=PositionX, y=PositionY})  
            table.insert(memory_S, 2, {x=memory_S[1].x, y=memory_S[1].y}) ]]

        end
        return true 
    else 
        return false 
    end 

end 


function agentBattery.low_battery_scanning()
    if (AgentMovement.dist_to_base()*MotionCost + 1 + PerceptionScope) >= CurrentEnergy * 0.7 and not state_low_battery then -- Running low on energy, return to base
        --say("Explorer #: " .. ID .. " is low on energy, returning to base "..CurrentEnergy)
  
        PositionX = math.floor(PositionX)
        PositionY = math.floor(PositionY)
        if direction_base then
         --   say("Base position "..memory_S[1].x.." "..memory_S[1].y)
            state_low_battery = true 
            state_moving = true 
            state_scanning = false
            direction_base = false 
            agentBattery.swapMemory()

            --[[table.insert(memory_S, 3, {x=PositionX, y=PositionY})  
            table.insert(memory_S, 2, {x=memory_S[1].x, y=memory_S[1].y}) ]]

        end
        return true
    else 
        return false 
    end 
end 

function agentBattery.low_battery_moving()
    if (AgentMovement.dist_to_base()*MotionCost + 1) >= CurrentEnergy * 0.7 and not state_low_battery then -- Running low on energy, return to base
        --say("Explorer #: " .. ID .. " is low on energy, returning to base "..CurrentEnergy)
  
        PositionX = math.floor(PositionX)
        PositionY = math.floor(PositionY)
        if direction_base then
          --  say("Base position "..memory_S[1].x.." "..memory_S[1].y)
            state_low_battery = true 

            direction_base = false 
            agentBattery.swapMemory()
            
            --[[table.insert(memory_S, 3, {x=PositionX, y=PositionY})  
            table.insert(memory_S, 2, {x=memory_S[1].x, y=memory_S[1].y}) ]]

        end
        return true 
    else 
        return false 
    end 
end 

function agentBattery.die()
    say("Explorer #: " .. ID .. " died.")
    GridMove = false
    Collision.reinitializeGrid()
    Agent.removeAgent(ID)
end

function agentBattery.swapMemory()
 
    table.insert(memory_S, 2, {x=memory_S[1].x, y=memory_S[1].y}) 

    table.insert(memory_S, 1, {x=PositionX, y=PositionY}) 
end 
return agentBattery
