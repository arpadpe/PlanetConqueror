local planetMovement = {}

function planetMovement.get_distance_to(position)

	return math.abs(planetMovement.calc_min_dist(PositionX, position.x, ENV_WIDTH)) + math.abs(planetMovement.calc_min_dist(PositionY, position.y, ENV_HEIGHT))
end

function planetMovement.get_distance_between(position1, position2)

	return math.abs(planetMovement.calc_min_dist(position1.x, position.x, ENV_WIDTH)) + math.abs(planetMovement.calc_min_dist(position1.y, position.y, ENV_HEIGHT))
end

function planetMovement.get_delta_x(pos_x, x_goal)

    local dist = planetMovement.calc_min_dist(pos_x, x_goal, ENV_WIDTH)

    return dist / math.abs(dist)

end

function planetMovement.get_delta_y(pos_y, y_goal)

    local dist = planetMovement.calc_min_dist(pos_y, y_goal, ENV_HEIGHT)

    return dist / math.abs(dist)

end

function planetMovement.calc_min_dist(pos, goal, limit)

	local distAB = 0
	local distBA = 0

	if pos < goal then
        distAB = goal - pos - ENV_WIDTH
        distBA = pos - goal
    else
        distAB = goal - pos
        distBA = pos - goal - ENV_WIDTH
    end

    if math.abs(distAB) < math.abs(distBA) then
    	return distAB
    else
    	return distBA * -1
    end
end

function planetMovement.advance_position(d_x, d_y)
    
    if PositionX > ENV_WIDTH - 2 then 		-- if it is 199 or bigger
        PositionX = 0 						-- make it 0
    elseif PositionX < 1 then 				-- if it is 0  
        PositionX = ENV_WIDTH -1 			-- make it 199
    end     

    if PositionY > ENV_HEIGHT -2 then 
        PositionY = 0
    elseif PositionY < 1  then
        PositionY = ENV_HEIGHT -1 
    end
    
    -- move when the square is empty
    if not Collision.checkCollision(PositionX+d_x,PositionY+d_y) then
        Move.to{x=PositionX+d_x, y=PositionY+d_y}
        return true
    else 
        return false
    end
end

return planetMovement