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

PlanetScanner = require "modules/planet_scanner"
Descriptions = require "modules/event_descriptions"

ROBOTS = "robots"

state_set_positions = true

-- Initialization of the agent.
function InitializeAgent()
	
	say("Base #: " .. ID .. " has been initialized")

	PositionX = math.floor(PositionX)
	PositionY = math.floor(PositionY)

	GridMove = true
	StepMultiple = 10000

	OreCapacity = 5 			-- C
	CommunicationScope = 50 	-- I
	ExplorersNumber = 1			-- X
	TransportersNumber = 1		-- Y
	PerceptionScope = 8			-- P

	OreCount = 0

	if ID == 1 then
		Agent.addAgent("painting.lua")
	end

	transporters = {}
	for i = 1, TransportersNumber do
		local agentID = Agent.addAgent("agents/transporter.lua", PositionX, PositionY)
		table.insert(transporters, agentID)
	end

	explorers = {}
	for i = 1, ExplorersNumber do
		local agentID = Agent.addAgent("agents/explorer.lua", PositionX, PositionY)
		table.insert(explorers, agentID)
	end

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
		end
	end
end

function inititializeRobots()
	for i=1, #explorers do
		local targetID = explorers[i]
		Event.emit{targetID=targetID, description=Descriptions.INIT, table=calculatePositionForExplorer(i, #explorers)}
		say("Base #: " .. ID .. " sending init message to " .. targetID)
	end
	for i=1, #transporters do
		local targetID = transporters[i]
		Event.emit{targetID=targetID, description=Descriptions.INIT}
		say("Base #: " .. ID .. " sending init message to " .. targetID)
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
	say("Base #: " .. ID .. " is full, sending messages")
	local ids = PlanetScanner.get_ids_in_range(CommunicationScope)
	for i=1, #ids do
		local targetID = ids[i]
		Event.emit{targetID=targetID, description=Descriptions.FULL, table={baseID=ID}}
		say("Base #: " .. ID .. " sending full message to " .. targetID)
	end
end

function ShareTable()
	local robotsTable = Shared.getTable(ROBOTS)
	if robotsTable == nil then
		robotsTable = {}
	end
	robotsTable[ID] = {explorers=explorers, transporters=transporters}
	Shared.storeTable(ROBOTS, robotsTable)
end