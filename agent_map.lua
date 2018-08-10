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

function initializeAgent()

	l_debug("Enviroment : " .. ID .. " has been initialized")
	count = 0
	for i = 0, ENV_WIDTH -1 do
        for j = 0, ENV_HEIGHT -1 do
            random = Stat.randomInteger(1,100)
           -- l_print("random  "..random)
            if D >= random then
                Map.modifyColor(i,j, ore_color)
            --    l_print("ore PAINTED: "..i.." "..j)
                count = count +1
            else 
               Map.modifyColor(i,j, background_color)
            end
		end
    end
    l_print("count = "..count)
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
 Agent.removeAgent(ID)
end

function cleanUp()
	l_debug("Agent #: " .. ID .. " is done\n")
end
