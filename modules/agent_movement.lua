local agentMovement={}

function agentMovement.calc_min_distance(pos, goal)

    local distAB = 0
	local distBA = 0

    if pos < goal then
        distAB = goal - pos - ENV_HEIGHT
        distBA = pos - goal 
    else 
        distAB = goal-pos 
        distBA = pos -goal - ENV_HEIGHT
    end

    if math.abs(distAB) < math.abs(distBA) then
    	return distAB
    else
    	return distBA * -1
    end
        
end

function agentMovement.get_delta_x(pos_x, x_goal)
    dist = agentMovement.calc_min_distance(pos_x,x_goal)
    d_x =  dist / math.abs(dist)
    if x_goal == pos_x then 
        d_x = 0
    end
  --  l_print("delta x "..d_x)
    return d_x


end



function agentMovement.get_delta_y(pos_y, y_goal)
    dist = agentMovement.calc_min_distance(pos_y,y_goal)
    d_y = dist / math.abs(dist)
    
    if y_goal == pos_y then 
        d_y = 0
    end
  --  l_print("delta y "..d_y)
    return d_y

end
--
function agentMovement.advance_position(d_x,d_y)
  -- say("deltas values "..d_x.." "..d_y)
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

function agentMovement.dist_to_base()
    dis_x = math.abs(agentMovement.calc_min_distance(PositionX,memory_S[1].x))
    dis_y = math.abs(agentMovement.calc_min_distance(PositionY,memory_S[1].y))
    return dis_x + dis_y
end

function agentMovement.get_new_position()
    PositionX = math.floor(PositionX)
    PositionY = math.floor(PositionY)
    position_table = {}
    table.insert(position_table, 1, {x = PositionX + PerceptionScope, y = PositionY})
    table.insert(position_table, 2, {x = PositionX - PerceptionScope, y = PositionY})
    table.insert(position_table, 3, {x = PositionX, y = PositionY - PerceptionScope})
    table.insert(position_table, 4, {x = PositionX, y = PositionY + PerceptionScope}) 
    goal = position_table[Stat.randomInteger(1,#position_table)]
    if goal.x >= 200 then 
        goal.x = goal.x - ENV_WIDTH -1 
    elseif goal.x <= 0 then
        goal.x = goal.x + ENV_WIDTH + 1
    end
    if goal.y >= 200 then 
        goal.y = goal.y - ENV_HEIGHT -1 
    elseif goal.y <= 0 then
        goal.y = goal.y + ENV_HEIGHT + 1
    end
    return goal

end



return agentMovement