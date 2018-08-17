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
TableHelper = require "modules/table_helper"

state_set_positions = true
state_log_progress = true

TimeFull = nil

-- Initialization of the agent.
function InitializeAgent()
	
	say("Base #: " .. ID .. " has been initialized")

	PositionX = math.floor(PositionX)
	PositionY = math.floor(PositionY)

	Agent.changeColor{r=255, g=255, b=255}

	GridMove = true

	OreCapacity = Shared.getNumber(3)				-- C
	OreDensity = Shared.getNumber(4)				-- D
	RobotEnergy = Shared.getNumber(5)				-- E
	GridSize = Shared.getNumber(6)					-- G
	CommunicationScope = Shared.getNumber(7)		-- I
	CoordinationMode = Shared.getNumber(8)			-- M
	NumberOfBases = Shared.getNumber(9)				-- N
	PerceptionScope = Shared.getNumber(10)			-- P
	MotionCost = Shared.getNumber(11)				-- Q
	MemorySize = Shared.getNumber(12)				-- S
	NumberOfCycles = Shared.getNumber(13)			-- T
	CarriageCapacity = Shared.getNumber(14)			-- W
	ExplorersNumber = Shared.getNumber(15)			-- X
	TransportersNumber = Shared.getNumber(16)		-- Y  

	OreCount = 0

	if ID == 1 then
		checkParameters() 
		Agent.addAgent("painting.lua")
		
		os.execute( "mkdir results" )
	end

	File = io.open("results/simulation_ID:" .. ID.. "_C:" .. OreCapacity .. "_D:" .. OreDensity .. "_E:" 
		.. RobotEnergy .. "_G:" .. GridSize .. "_I:" .. CommunicationScope .. "_M:" .. CoordinationMode .. "_N:" .. NumberOfBases .. "_P:" 
		.. PerceptionScope .. "_Q:" .. MotionCost .. "_S:" .. MemorySize .. "_T:" .. NumberOfCycles .. "_W:" .. CarriageCapacity .. "_X:" 
		.. ExplorersNumber .. "_Y:" .. TransportersNumber .. ".csv", "a")

	--Initialize Explorers
	explorers = {}
	for i = 1, ExplorersNumber do
		local agentID = Agent.addAgent("agents/explorer.lua", PositionX, PositionY)
		explorers[agentID] = agentID
	end

	--Initialize Transporters
	transporters = {}
	for i = 1, TransportersNumber do
		local agentID = Agent.addAgent("agents/transporter.lua", PositionX, PositionY)
		transporters[agentID] = agentID
	end

	sentReturn = {}
	ownRobots = {}

	ShareTable()
end

function checkParameters()
	--Share default parameters if not set
	if OreCapacity == "no_value" then
		OreCapacity = 50
		Shared.storeNumber(3, OreCapacity)
	end

	if OreDensity == "no_value" then
		OreDensity = 50
		Shared.storeNumber(4, 5)
	end

	if RobotEnergy == "no_value" then
		RobotEnergy = 150
		Shared.storeNumber(5, RobotEnergy)
	end

	if GridSize == "no_value" then
		GridSize = 200
		Shared.storeNumber(6, GridSize)
	end

	if CommunicationScope == "no_value" then
		CommunicationScope = 25
		Shared.storeNumber(7, CommunicationScope)
	end

	if CoordinationMode == "no_value" then
		CoordinationMode = 1
		Shared.storeNumber(8, CoordinationMode)
	end

	if NumberOfBases == "no_value" then
		NumberOfBases = 1
		Shared.storeNumber(9, NumberOfBases)
	end

	if PerceptionScope == "no_value" then
		PerceptionScope = 5
		Shared.storeNumber(10, PerceptionScope)
	end

	if MotionCost == "no_value" then
		MotionCost = 1
		Shared.storeNumber(11, MotionCost)
	end

	if MemorySize == "no_value" then
		MemorySize = 5
		Shared.storeNumber(12, MemorySize)
	end

	if NumberOfCycles == "no_value" then
		NumberOfCycles = 200
		Shared.storeNumber(13, NumberOfCycles)
	end

	if CarriageCapacity == "no_value" then
		CarriageCapacity = 10
		Shared.storeNumber(14, CarriageCapacity)
	end

	if ExplorersNumber == "no_value" then
		ExplorersNumber = 2
		Shared.storeNumber(15, ExplorersNumber)
	end

	if TransportersNumber == "no_value" then
		TransportersNumber = 3
		Shared.storeNumber(16, TransportersNumber)
	end
end

function TakeStep()

	--Initialize Robots state
	if state_set_positions then
		inititializeRobots()

	--Base full state
	elseif OreCount == OreCapacity and Core.time() < NumberOfCycles then
		sendFull()
		
	--Time up state
	elseif Core.time() >= NumberOfCycles then
		sendTimeUp()

	end
end

function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)	

	--handle the deposition of ores
	if eventDescription == Descriptions.ORE then
		if OreCount < OreCapacity then
			local oreNo = eventTable[Descriptions.ORE]
			if OreCount + oreNo > OreCapacity then
				OreCount = OreCapacity

				--save current time for analysis
				TimeFull = Core.time()
			else
				OreCount = OreCount + oreNo
			end
			say("Base #: " .. ID .. " received " .. oreNo .. " ores from: " .. sourceID .. " current ore count: " .. OreCount)
		end
	end
end

function inititializeRobots()

	--initialize the agents

	for i, v in pairs(explorers) do
		local targetID = v
		Event.emit{targetID=targetID, description=Descriptions.INIT, table=calculatePositionForExplorer(i, #explorers)}
		say("Base #: " .. ID .. " sending init message to " .. targetID)
	end

	for i, v in pairs(transporters) do
		local targetID = v
		Event.emit{targetID=targetID, description=Descriptions.INIT}
		say("Base #: " .. ID .. " sending init message to " .. targetID)
	end
	state_set_positions = false
end

function calculatePositionForExplorer( index, totalExplorers)
	--calculate the initial positions of the explorers based on the number of explorers and the Perception scope

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

	-- prevent negative positions
	if posTable.x < 0 then
		posTable.x = ENV_WIDTH + posTable.x
	elseif posTable.y < 0 then
		posTable.y = ENV_HEIGHT - posTable.y
	end

	return posTable
end

function sendFull()
	if TableHelper.tablelength(sentReturn) < TableHelper.tablelength(explorers) + TableHelper.tablelength(transporters) then

		local ids = PlanetScanner.get_ids_in_range(CommunicationScope)
		for i=1, #ids do
			local targetID = ids[i]
			if sentReturn[targetID] == nil then

				Event.emit{targetID=targetID, description=Descriptions.FULL, table={baseID=ID}}
				say("Base #: " .. ID .. " sending full message to " .. targetID)
				sentReturn[targetID] = targetID

				-- if a related robot receives the event, it is believed to have returned
				if explorers[targetID] ~= nil or transporters[targetID] ~= nil then
					ownRobots[targetID] = targetID
				end

			end
		end
	end
end

function sendTimeUp()
	if TableHelper.tablelength(sentReturn) < TableHelper.tablelength(explorers) + TableHelper.tablelength(transporters) then

		local ids = PlanetScanner.get_ids_in_range(CommunicationScope)
		for i=1, #ids do
			local targetID = ids[i]
			if sentReturn[targetID] == nil then

				Event.emit{targetID=targetID, description=Descriptions.TIMEUP, table={baseID=ID}}
				say("Base #: " .. ID .. " sending times up message to " .. targetID)
				sentReturn[targetID] = targetID

				-- if a related robot receives the event, it is believed to have returned
				if explorers[targetID] ~= nil or transporters[targetID] ~= nil then
					ownRobots[targetID] = targetID
				end

			end
		end
	end
end

function ShareTable()
	local robotsTable = Shared.getTable(Descriptions.ROBOTS)
	if robotsTable == nil then
		robotsTable = {}
	end
	robotsTable[ID] = {explorers=explorers, transporters=transporters}
	Shared.storeTable(Descriptions.ROBOTS, robotsTable)
end

function cleanUp()
	if TimeFull ~= nil then
		File:write(Shared.getNumber(2) .. "," .. TimeFull .. "," .. ID .. "," .. TableHelper.tablelength(ownRobots) .. "," .. TableHelper.tablelength(explorers) + TableHelper.tablelength(transporters) .. "," .. OreCount .. "," .. OreCapacity .. "\n")
	else
		File:write(Shared.getNumber(2) .. "," .. Core.time() .. "," .. ID .. "," .. TableHelper.tablelength(ownRobots) .. "," .. TableHelper.tablelength(explorers) + TableHelper.tablelength(transporters) .. "," .. OreCount .. "," .. OreCapacity .. "\n")
	end
	File:close()
end