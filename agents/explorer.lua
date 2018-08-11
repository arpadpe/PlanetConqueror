-- Import valid Rana lua libraries.
Agent = require "ranalib_agent"
Collision = require "ranalib_collision"
Stat = require "ranalib_statistic"
Move = require "ranalib_movement"
Map = require "ranalib_map"
Shared = require "ranalib_shared"
Draw = require "ranalib_draw" 
Shared = require "ranalib_shared"


background_color = {0,0,0}
ore_color = {255,255,0}

D = 5 -- % ore
P = 9-- minimum value scope = 3
Y = 2 --number of transporters
X = 2 --number of explorers 
size_memory = Y + X -1
memory_S = {}
state_moving = true
state_scanning = false
state_increase_scope = false
state_waiting = false
state_sending = false 
map_size = ENV_WIDTH

function initializeAgent()

	l_debug("Enviroment : " .. ID .. " has been initialized")

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
    PositionY = ENV_HEIGHT/2 
    l_print("PositionX "..PositionX.." PositionY "..PositionY)
	Speed = 2
	GridMove = true
    Moving = true
    DestinationX = PositionX 
    DestinationY = PositionY
    -- we suppose that we are born in the base so our initial position == base postion 
    table.insert(memory_S, {PositionX,PositionY}) -- save base position 

end


function takeStep()
  
    -------------------------------------------------------------------------------------------------------
    --MOVING-----------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------

    if state_moving then
        --we suppose that each time that we start a new moving cycle (after finishing the seding all the messages)
        --in our memory only have the base position, we have use table.remove, 
        if memory_S[2] == nil then
            x_rand = 115-- Stat.randomInteger(110,120)
            y_rand = 130 --Stat.randomInteger(110,120)
         --   l_print("xrand ".. x_rand.." y rand "..y_rand)
            --save desired position 
            table.insert(memory_S, {x_rand,y_rand})
           l_print("memoryyy xrand ".. memory_S[2][1].." y rand "..memory_S[2][2])
        else
        
            
            PositionX = math.floor(PositionX)
            PositionY = math.floor(PositionY)
            -- if we are not in the desired position
            if PositionX ~= memory_S[2][1] or PositionY ~= memory_S[2][2] then
                if not Moving then
                    local delta_y
                    local delta_x
                   -- l_print("BEFORE PositionX "..PositionX.." PositionY "..PositionY)

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
                    
                    --choose square
                    if memory_S[2][1] == PositionX then 
                        delta_x = 0
                    elseif memory_S[2][1]> PositionX then
                        delta_x = 1 
                    else -- memory_S[2]<PositionX 
                        delta_x= -1
                    end
                    if memory_S[2][2]==PositionY then 
                        delta_y = 0
                    elseif memory_S[2][2]>PositionY then
                        delta_y = 1 
                    else --memory_S[2][2]<PositionX 
                        delta_y= -1
                    end
                    -- move when the square is empty
                    if not Collision.checkCollision(PositionX+delta_x,PositionY+delta_y) then 
                        Move.to{x=PositionX+delta_x, y=PositionY+delta_y}
                    end
                end 
            else 
                table.remove{memory_S,2}
                state_moving = false
                state_scanning = true
            end
        end
    -------------------------------------------------------------------------------------------------------
    --SCANING----------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------
    elseif state_scanning then 
        l_print("START SCANNING ")
        ore_table = scanning(PositionX,PositionY, "ore")

        state_scanning = false 

        if #ore_table == 0 then --list is empty increase scope
            state_increase_scope = true
        else --list is full -> find people
            people_ID_table = scanning(PositionX,PositionY, "people")
            if #people_ID_table == 0 then -- no transporters in my communication scope
                state_waiting = true 
            else -- I have a list and tranporters close to me
                state_sending = true
            end
        end
    -------------------------------------------------------------------------------------------------------
    --INCREASING SCOPE----------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------
    elseif state_increase_scope then
        l_print("INCREASING SCOPE ")

    end

end
    



function cleanUp()
	l_debug("Agent #: " .. ID .. " is done\n")
end


function scanning(pos_x, pos_y, mood)

    ore_found = {}
    people_found = {}
    x_init = math.floor(pos_x - P/2) 
    x_end = math.floor(pos_x + P/2) 
    x_scan = {}
    l_print("x_init "..x_init)
    l_print("x_end "..x_end)
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

    
    y_init = math.floor(pos_y - P/2)
    y_end = math.floor(pos_y + P/2)
    l_print("y_init "..y_init)
    l_print("y_end "..y_end)
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
    if mood == "ore" then
        for i=1, #x_scan do
            for j=1, #y_scan do
                if Draw.compareColor(Map.checkColor(x_scan[i],y_scan[j]),ore_color) then
                    table.insert(ore_found,{x_scan[i],y_scan[j]})
                   -- l_print("ore found: "..x_scan[i].." "..y_scan[j])
                end
		    end
        end
        return ore_found
    elseif mood == "people" then
        people_found = {}
       local person = {}
        for i=1, #x_scan do
            for j=1, #y_scan do
            --    person = Collision.checkPosition(x_scan[i],y_scan[j])
               --if #person ~= 0 then 
               --    l_print("size .. "..#person)
                   -- table.insert(people_found,person)
              --  end

		    end
        end
       -- l_print("total persons "..#people_found)
        return people_found

    end

end