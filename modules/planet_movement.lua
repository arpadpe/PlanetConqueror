local planetMovement = {}

function planetMovement.get_distance_to(position)

	return math.abs(planetMovement.calc_min_dist(PositionX, position.x, ENV_WIDTH)) + math.abs(planetMovement.calc_min_dist(PositionY, position.y, ENV_HEIGHT))
end

function planetMovement.get_distance_between(position1, position2)

	return math.abs(planetMovement.calc_min_dist(position1.x, position2.x, ENV_WIDTH)) + math.abs(planetMovement.calc_min_dist(position1.y, position2.y, ENV_HEIGHT))
end

function planetMovement.get_delta_position(position, goal)
	local delta_x = planetMovement.get_delta_x(position.x, goal.x)
	local delta_y = planetMovement.get_delta_y(position.y, goal.y)

	return {x=delta_x, y=delta_y}
end

function planetMovement.get_second_delta_position(position, goal)
	
	local delta = planetMovement.get_delta_position(position, goal)

	local random = Stat.randomInteger(0, 1)

	if delta.x ~= 0 and delta.y ~= 0 then
		if Stat.randomInteger(0, 1) == 0 then
			delta.x = 0
		else
			delta.y = 0
		end
	elseif delta.x ~= 0 and delta.y == 0 then
		if Stat.randomInteger(0, 1) == 0 then
			delta.y = 1
		else
			delta.y = -1
		end
	elseif delta.x == 0 and delta.y ~= 0 then
		if Stat.randomInteger(0, 1) == 0 then
			delta.x = 1
		else
			delta.y = -1
		end
	end

	return delta

end

function planetMovement.get_delta_x(pos_x, x_goal)

	if pos_x == x_goal then
		return 0
	end

    local dist = planetMovement.calc_min_dist(math.floor(pos_x), math.floor(x_goal), ENV_WIDTH)

    return dist / math.abs(dist)

end

function planetMovement.get_delta_y(pos_y, y_goal)

	if pos_y == y_goal then
		return 0
	end

    local dist = planetMovement.calc_min_dist(math.floor(pos_y), math.floor(y_goal), ENV_HEIGHT)

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

    -- move if the square is empty
    if (BasePosition.x == PositionX+d_x and BasePosition.y == PositionY+d_y) or not Collision.checkCollision(PositionX+d_x,PositionY+d_y) then
        Move.to{x=PositionX+d_x, y=PositionY+d_y}
        return true
    else 
        return false
    end
end

function planetMovement.get_random_pos(range)
	local random = Stat.randomInteger(0, 7)

	local random_pos = {}

	if random == 0 then
		random_pos = {x=PositionX+range % ENV_WIDTH, y=PositionY % ENV_HEIGHT}
	elseif random == 1 then
		random_pos = {x=PositionX+range % ENV_WIDTH, y=PositionY+range % ENV_HEIGHT}
	elseif random == 2 then
		random_pos = {x=PositionX % ENV_WIDTH, y=PositionY+range % ENV_HEIGHT}
	elseif random == 3 then
		random_pos = {x=PositionX-range % ENV_WIDTH, y=PositionY+range % ENV_HEIGHT}
	elseif random == 4 then
		random_pos = {x=PositionX-range % ENV_WIDTH, y=PositionY % ENV_HEIGHT}
	elseif random == 5 then
		random_pos = {x=PositionX-range % ENV_WIDTH, y=PositionY-range % ENV_HEIGHT}
	elseif random == 6 then
		random_pos = {x=PositionX % ENV_WIDTH, y=PositionY-range % ENV_HEIGHT}
	elseif random == 7 then
		random_pos = {x=PositionX+range % ENV_WIDTH, y=PositionY-range % ENV_HEIGHT}
	end

	return random_pos
end

return planetMovement