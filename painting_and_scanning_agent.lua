-- Import valid Rana lua libraries.
Agent = require "ranalib_agent"
Stat = require "ranalib_statistic"
Map = require "ranalib_map"
Shared = require "ranalib_shared"
Draw = require "ranalib_draw" 
Shared = require "ranalib_shared"


background_color = {0,0,0}
ore_color = {255,255,0}

D = 5 -- % ore
P = 12

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

    PositionX =  195
    PositionY = 195
    l_print("PositionX "..PositionX.." PositionY "..PositionY)
    Speed = 2
    GridMove = true
    Moving = true
    DestinationX = PositionX 
    DestinationY = Position

end


function takeStep()
    l_print("START ----------------------------")
    ore_table = {}
    x_init = math.floor(PositionX - P/2)
    x_end = math.floor(PositionX + P/2)
    x_scan = {}
    l_print("x_init "..x_init)
    l_print("x_end "..x_end)
    if x_init < 0 then 
        for i = x_init,0,1 do
            table.insert(x_scan,(ENV_WIDTH-1+i))
        end    
        for i = 1, math.floor(PositionX) do
            table.insert(x_scan,i)
        end     
    elseif x_end > (ENV_WIDTH-1) then
        l_print("dentro else if")
        for i = math.floor(PositionX), (ENV_WIDTH-1) do
            table.insert(x_scan,i)
        end 
        for i = x_end,ENV_WIDTH,-1 do
            table.insert(x_scan,(i-ENV_WIDTH))
        end
    else
        for  i = x_init, x_end do 
            table.insert(x_scan,i)
        end
    end 

    
    y_init =  math.floor(PositionY - P/2)
    y_end = math.floor(PositionY + P/2)
    l_print("y_init "..y_init)
    l_print("y_end "..y_end)
    y_scan = {}
    if y_init < 0 then 

        for i = y_init,0,1 do
            table.insert(y_scan,(ENV_WIDTH-1+i))
            l_print("table insert y init negativo  "..(ENV_WIDTH-1+i))
        end    
        for i = 1, math.floor(PositionY) do
            table.insert(y_scan,i)
        end     
    elseif y_end > (ENV_WIDTH-1) then
        for i = math.floor(PositionY), (ENV_WIDTH-1) do
            table.insert(y_scan,i)
        end 
        for i = y_end,ENV_WIDTH,-1 do
            table.insert(y_scan,(i-ENV_WIDTH))
        end
    else
        for  i = y_init, y_end do 
            table.insert(y_scan,i)
        end
    end
    
    for i=1, #x_scan do
        for j=1, #y_scan do
		--	l_print("scanning "..x_scan(i).." "..y_scan(i))
		   if Draw.compareColor(Map.checkColor(x_scan[i],y_scan[j]),ore_color) then
              table.insert(ore_table,{x_scan[i],y_scan[j]})
                l_print("ore found: "..x_scan[i].." "..y_scan[j])
		    end
        end
	end
    

end

function cleanUp()
	l_debug("Agent #: " .. ID .. " is done\n")
end
