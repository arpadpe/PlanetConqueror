--The following global values are set via the simulation core:
-- ------------------------------------
-- IMMUTABLES.
-- ------------------------------------
-- ID -- id of the agent.
-- STEP_RESOLUTION 	-- resolution of steps, in the simulation core.
-- EVENT_RESOLUTION	-- resolution of event distribution.
-- ENV_WIDTH -- Width of the environment in meters.
-- ENV_HEIGHT -- Height of the environment in meters.
-- ------------------------------------
-- VARIABLES.
-- ------------------------------------
-- PositionX	 	-- Agents position in the X plane.
-- PositionY	 	-- Agents position in the Y plane.
-- DestinationX 	-- Agents destination in the X plane. 
-- DestinationY 	-- Agents destination in the Y plane.
-- StepMultiple 	-- Amount of steps to skip.
-- Speed 			-- Movement speed of the agent in meters pr. second.
-- Moving 			-- Denotes wether this agent is moving (default = false).
-- GridMove 		-- Is collision detection active (default = false).
-- ------------------------------------

-- Import valid Rana lua libraries.
Stat = require "ranalib_statistic"
Move = require "ranalib_movement"
Collision = require "ranalib_collision"
Utility = require "ranalib_utility"
Agent = require "ranalib_agent"
Shared = require "ranalib_shared"
Event = require "ranalib_event"
Core = require "ranalib_core"

PlanetScanner = require "modules/planet_scanner"
Descriptions = require "modules/event_descriptions"

ROBOTS = "robots"

state_set_positions = true

-- Initialization of the agent.
function InitializeAgent()
	
	say("Base #: " .. ID .. " has been initialized")

	PositionX = math.floor(PositionX)
	PositionY = math.floor(PositionY)

	Agent.changeColor{r=255, g=255, b=255}

	os.execute( "mkdir results" )

	File = io.open("results/log_" .. os.time() .. ".csv", "w+")

	GridMove = true

	OreCapacity = 3				-- C
	CommunicationScope = 50 	-- I
	ExplorersNumber = 2			-- X
	TransportersNumber = 4		-- Y
	PerceptionScope = 8			-- P

	OreCount = 0

	if ID == 1 then
		Agent.addAgent("painting.lua")
	end

	explorers = {}
	--[[
	]]
	for i = 1, ExplorersNumber do
		local agentID = Agent.addAgent("agents/explorer.lua", PositionX, PositionY)
		table.insert(explorers, agentID)
	end

	transporters = {}
	for i = 1, TransportersNumber do
		local agentID = Agent.addAgent("agents/transporter.lua", PositionX, PositionY)
		table.insert(transporters, agentID)
	end

	sentFull = {}

	ShareTable()
end

val = true

function TakeStep()
	if state_set_positions then
		inititializeRobots()
	elseif OreCount == OreCapacity then
		sendFull()
	end
end

function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)	
	if eventDescription == Descriptions.ORE then
		if OreCount < OreCapacity then
			local oreNo = eventTable[Descriptions.ORE]
			if OreCount + oreNo > OreCapacity then
				OreCount = OreCapacity
			else
				OreCount = OreCount + oreNo
			end
			say("Base #: " .. ID .. " received " .. oreNo .. " ores from: " .. sourceID .. " current ore count: " .. OreCount)
			File:write("t:" .. Core.time() .. ",base id:" .. ID .. ",received ores:" .. oreNo .. ",from:" .. sourceID .. ",\n")
		end
	end
end

function inititializeRobots()
	for i=1, #explorers do
		local targetID = explorers[i]
		Event.emit{targetID=targetID, description=Descriptions.INIT, table=calculatePositionForExplorer(i, #explorers)}
		say("Base #: " .. ID .. " sending init message to " .. targetID)
		File:write("t:" .. Core.time() .. ",base id:" .. ID .. ",explorer send init:" .. targetID .. ",\n")
	end
	for i=1, #transporters do
		local targetID = transporters[i]
		Event.emit{targetID=targetID, description=Descriptions.INIT}
		say("Base #: " .. ID .. " sending init message to " .. targetID)
		File:write("t:" .. Core.time() .. ",base id:" .. ID .. ",transporter send init:" .. targetID .. ",\n")
		--[[
		ores = {}
		table.insert(ores, {x=PositionX+5, y=PositionY+5})
		table.insert(ores, {x=PositionX+10, y=PositionY+10})
		table.insert(ores, {x=PositionX+45, y=PositionY+15})
		Event.emit{targetID=targetID, description=Descriptions.OREPOS, table=ores}
		]]
	end
	state_set_positions = false
end

function calculatePositionForExplorer( index, totalExplorers)
	local posTable = {}
	if totalExplorers == 1 then
		posTable={x=PositionX, y=PositionY}
	elseif totalExplorers == 2 then
		if index == 1 then
			posTable={x=PositionX, y=PositionY + PerceptionScope % ENV_HEIGHT}
		else
			posTable={x=PositionX, y=PositionY - PerceptionScope % ENV_HEIGHT}
		end
	elseif totalExplorers == 3 then
		if index == 1 then
			posTable={x=PositionX + PerceptionScope % ENV_WIDTH, y=PositionY + PerceptionScope % ENV_HEIGHT}
		elseif index == 2 then
			posTable={x=PositionX - PerceptionScope % ENV_WIDTH, y=PositionY + PerceptionScope % ENV_HEIGHT}
		else
			posTable={x=PositionX, y=PositionY - PerceptionScope % ENV_HEIGHT}
		end
	else
		if index % totalExplorers == 1 then
			posTable={x=PositionX + PerceptionScope % ENV_WIDTH, y=PositionY + PerceptionScope % ENV_HEIGHT}
		elseif index % totalExplorers == 2 then
			posTable={x=PositionX - PerceptionScope % ENV_WIDTH, y=PositionY + PerceptionScope % ENV_HEIGHT}
		elseif index % totalExplorers == 3 then
			posTable={x=PositionX + PerceptionScope % ENV_WIDTH, y=PositionY - PerceptionScope % ENV_HEIGHT}
		else
			posTable={x=PositionX - PerceptionScope % ENV_WIDTH, y=PositionY - PerceptionScope % ENV_HEIGHT}
		end
	end
	return posTable
end

function sendFull()
	if #sentFull < #explorers + #transporters then

		local ids = PlanetScanner.get_ids_in_range(CommunicationScope)
		for i=1, #ids do
			local targetID = ids[i]
			if sentFull[targetID] == nil then
				sentFull[targetID] = targetID
				Event.emit{targetID=targetID, description=Descriptions.FULL, table={baseID=ID}}
				say("Base #: " .. ID .. " sending full message to " .. targetID)
			end
		end
	end
end

function ShareTable()
	local robotsTable = Shared.getTable(ROBOTS)
	if robotsTable == nil then
		robotsTable = {}
	end
	robotsTable[ID] = {explorers=explorers, transporters=transporters}
	Shared.storeTable(ROBOTS, robotsTable)
	File:write("t:" .. Core.time() .. ",base id:" .. ID .. ",sharedTable,\n")
end

function cleanUp()
	File:write("t:" .. Core.time() .. ",base id:" .. ID .. ",orecount:" .. OreCount .. ",\n")
	File:close()
end