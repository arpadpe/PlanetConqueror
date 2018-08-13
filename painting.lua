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
            else 
               Map.modifyColor(i,j, background_color)
            end
		end
    end
end


function takeStep()
    Agent.removeAgent(ID)
end

function cleanUp()
	l_debug("Agent #: " .. ID .. " is done\n")
end
