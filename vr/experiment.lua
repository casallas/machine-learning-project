require("Actions")

-- Create a bunch of spheres
numSpheres = 3
-- Sphere radii
radii = { 0.20, 0.10, 0.05}
-- Initial position of the spheres 1mt high, 5 mt in front
initialPos = osg.Vec3d(0,1,-5)

-- Number of repetitions
numRepetitions = 20

-- Spheres shouldn't be more than 1.5 mt appart from each other
maxSeparation = 1.5
-- Sphere speed, advance in -z
sphereSpeed = osg.Vec3d(0,0,1.0)

-- Create experimental conditions, a full nxnxn experiment
-- The experimental condition table will look like radius1, radius2, radius3, repetitions
expConditions = {}
for r1 = 1,numSpheres do 
	for r2 = 1,numSpheres do
		for r3 = 1,numSpheres do
			table.insert( expConditions, {radii[r1],radii[r2],radii[r3],repetitions=numRepetitions} )
		end
	end
end

-- Returns true if at least one of the radii has remaining repetitions
function repetitionsRemaining()
	for i=1,#expConditions do
		-- Only one condition > 0 suffices
		if expConditions[i]["repetitions"] > 0 then
			return true
		end
	end
	return false
end

-- returns one of the possible experimental conditions, making sure it still has repetitions
-- the function expects that at least one experimental condition has remaining repetitions
-- else it will loop infinitely, for safety, call repetitionsRemaining before
function getRandomExpCondition()
	while true do
		local index = math.random(numSpheres)
		if expConditions[index]["repetitions"] > 0 then
			print("condition",index)
			return expConditions[index]
		end
	end
end

-- A trial is basically a row of spheres moving towards the object
sphereRow = Transform{
		position = {initialPos:x(), initialPos:y(), initialPos:z()},
	}

-- A trial is ended if the objects are behind the head (in z), or if there are no children in the row
function trialEnded(headPos)
	if sphereRow:getNumChildren() <= 0 then
		print("no more spheres on trial")
		return true
	elseif sphereRow:getPosition():z() > headPos:z() then
		print("balls bypassed user")
		return true		
	else
		return false
	end
end

-- displays a random experimental condition
-- Adds the corresponding spheres to the sphere row
function displayRandExpCondition()
	local curExpCondition = getRandomExpCondition()
	for i=1,numSpheres do
		local curX = ((maxSeparation/(numSpheres-1))*(i-1))-maxSeparation/2
		local curRad = curExpCondition[i]
		local s = Sphere{position={curX,0,0}, radius=curRad}
		-- Each sphere's name: i_radius_curX
		s:setName(tostring(i).."_"..tostring(curRad).."_"..tostring(curX))
		sphereRow:addChild(s)
	end
	curExpCondition["repetitions"] = curExpCondition["repetitions"] - 1
end

-- Tells if a point is inside an osg node
function pointInside(point,node)
	local bSphere = sphereRow:getBound()
	-- convert the center to Vec3d, since it's originally Vec3f TODO fixme
	local bCenter = osg.Vec3d(bSphere:center())
	local center2Point = point - bCenter
	-- get the square length
	local c2w_len2 = center2Point:length2()
	-- get the square radius
	local sqradius = bSphere:radius2()
	-- Apparently the square radius of the bound is overshoot by 3
	return c2w_len2 < sqradius/3
end

lastRemoved = 0

-- Eliminates the first sphere touched by the wand
-- returns true if a sphere was disappeared, false otherwise
function disappearCollidedSpheres(wandPos)
	local numChildren = sphereRow:getNumChildren()
	for i=1,numChildren do
		-- osg's children indexes are zero based
		local curSphere = sphereRow:getChild(i-1)

		if pointInside(wandPos,curSphere) then
			sphereRow:removeChild(curSphere)
			lastRemoved = i
			return true
		end
	end
	return false
end

-- Applies sphereSpeed to the sphere row
function moveSpheres(dt)
	local pos = sphereRow:getPosition()
	-- dt is delta time
	pos = pos + sphereSpeed * dt
	sphereRow:setPosition(pos)
end

-- We attach it relative to the world: we can move around it.
RelativeTo.World:addChild(sphereRow)

function runExperiment(dt)
	local head = gadget.PositionInterface("VJHead")
	local wand = gadget.PositionInterface("VJWand")

	while repetitionsRemaining() do
		worldHeadPos = head.position - osgnav.position
		worldWandPos = wand.position - osgnav.position
		if not trialEnded(worldHeadPos) then
			disappearCollidedSpheres(worldWandPos)
			moveSpheres(dt)
		else
			print("New trial")
			sphereRow:removeChildren(0, sphereRow:getNumChildren())
			sphereRow:setPosition(initialPos)
			displayRandExpCondition()
		end
		dt = Actions.waitForRedraw()
	end
end

Actions.addFrameAction(runExperiment)

function serializeExpConditions()
	local ans = ""
	for k,v in pairs(expConditions) do
		ans  = ans..tostring(k)
		for k2,v2 in pairs(v) do
			ans = ans..","..v2
		end
		ans = ans.."\n"
	end
	return ans
end

function writeLog(dt)
	local file_name = tostring(os.time().."_log.txt")
	local log_file = io.open(file_name,"w")
	
	log_file:write("<experimental_conditions>\n")
	log_file:write("condition_num,radius1,radius2,radius3,repetitions\n")
	log_file:write(serializeExpConditions())
	log_file:write("</experimental_conditions>\n")

	log_file:write("<experimental_data>\n")
	log_file:write("time,headPos,headOri,wandPos,wandOri,numSpheres,sphere1,sphere2,sphere3\n")

	local head = gadget.PositionInterface("VJHead")
	local wand = gadget.PositionInterface("VJWand")

	while repetitionsRemaining() do
		log_file:write(dt)
		log_file:write(",")
		log_file:write(tostring(head.position))
		log_file:write(",")
		log_file:write(tostring(head.orientation))
		log_file:write(",")
		log_file:write(tostring(wand.position))
		log_file:write(",")
		log_file:write(tostring(wand.orientation))
		log_file:write(",")
		log_file:write(sphereRow:getNumChildren())
		for i=1,sphereRow:getNumChildren() do
			log_file:write(",")
			-- On osg, indexes start in zero...
			log_file:write(sphereRow:getChild(i-1):getName())
		end
		log_file:write("\n")
		-- wait for 1/10 of a second
		dt = Actions.waitSeconds(0.1)
	end
	log_file:close()
end

Actions.addFrameAction(writeLog)


