require("Actions")
-- Look for models in the same directory as this file.
require("getScriptFilename")
fn = getScriptFilename()
assert(fn, "Have to load this from file, not copy and paste, or we can't find our scripts!")
vrjLua.appendToModelSearchPath(fn)

dofile(vrjLua.findInModelSearchPath([[skydome.lua]]))
dofile(vrjLua.findInModelSearchPath([[magicWand.lua]]))
dofile(vrjLua.findInModelSearchPath([[osgXUtils.lua]]))
dofile(vrjLua.findInModelSearchPath([[log.lua]]))

-- Create a bunch of spheres
numSpheres = 3
-- Sphere radii
radii = { 0.2, 0.1, 0.05}
-- Initial position of the spheres 1mt high, 5 mt in front
--initialPos = osg.Vec3d(0,1,-5)
--metal
initialPos = osg.Vec3d(2,1.5,-5)

-- Number of repetitions
numRepetitions = 10

-- Spheres shouldn't be more than 1.5 mt appart from each other
maxSeparation = 1
-- Sphere speed, advance in -z
sphereSpeed = osg.Vec3d(0,0,1.5)

positions = { "left", "center", "right" }

-- Create experimental conditions, a full nxnxn experiment
-- The experimental condition table will look like radius1, radius2, radius3, repetitions
expConditions = {}
function createExperimentalConditions()
	expConditions = {}
	if numSpheres == 1 then
		for pos = 1,#positions do
			table.insert( expConditions, {radii[1],position=positions[pos],
				repetitions=numRepetitions} )
			table.insert( expConditions, {radii[2],position=positions[pos],
				repetitions=numRepetitions} )
		end
	elseif numSpheres == 2 then
		for r1 = 1,numSpheres do
			for r2 = 1,numSpheres do
				for pos = 1,#positions do
					table.insert( expConditions, {radii[r1],radii[r2],
						position=positions[pos],
						repetitions=numRepetitions} )
				end
			end
		end
	-- for 3 spheres do a 2^3 experiment, not 3^3
	else
		for r1 = 1,numSpheres-1 do
			for r2 = 1,numSpheres-1 do
				for r3 = 1,numSpheres-1 do
					for pos = 1,#positions do
						table.insert( expConditions, {radii[r1],radii[r2],radii[r3],
							position=positions[pos],
							repetitions=numRepetitions} )
					end
				end
			end
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
		local index = math.random(#expConditions)
		if expConditions[index]["repetitions"] > 0 then
			logEntry("condition="..tostring(index))
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
		logEntry("no_more_spheres")
		return true
	elseif sphereRow:getPosition():z() > headPos:z() then
		logEntry("balls_bypassed_user")
		return true		
	else
		return false
	end
end

-- displays a random experimental condition
-- Adds the corresponding spheres to the sphere row
function displayRandExpCondition()
	local curExpCondition = getRandomExpCondition()
	-- Create a red material for all the spheres
	local material = createColoredMaterial(osg.Vec4(1.0,0,0,0))
	for i=1,numSpheres do
		local curX = ((maxSeparation/(numSpheres-1))*(i-1))
		-- one sphere is a special case, we want it in the left
		if numSpheres == 1 then curX = maxSeparation/2 end

		-- spheres start on the right, adjust for center and left
		if curExpCondition["position"] == "center" then
			curX = curX - maxSeparation/2
		elseif curExpCondition["position"] == "left" then
			curX = curX - maxSeparation
		end

		local curRad = curExpCondition[i]
		local s = Sphere{position={curX,0,0}, radius=curRad}
		-- Each sphere's name: i_radius
		s:setName(tostring(i).."_"..tostring(curRad))
		-- Give the spheres a material
		s:getOrCreateStateSet():setAttribute(material)
		sphereRow:addChild(s)
	end
	curExpCondition["repetitions"] = curExpCondition["repetitions"] - 1
end

function spherePos(sphere)
	-- TODO check why the world matrix isn't working
	local bSphere = sphere:getBound()
	-- Start constructing the matrix with the identity
	local sphereWXform = osg.Matrix.identity()
	-- Now premultiply the sphere's parent's rotation
	sphereWXform:preMultRotate(sphere:getParent(0):getAttitude())
	-- Now premultiply the sphere's parent's position
	sphereWXform:preMultTranslate(sphere:getParent(0):getPosition())
	-- Finally translate to the tip of the sphere
	sphereWXform:preMultTranslate(bSphere:center())
	return sphereWXform.Trans
end

-- Tells if a point is inside one of the spheres
function pointInsideSphere(point,sphere)
	local sphCenter = spherePos(sphere)
	local center2Point = point - sphCenter
	-- get the square length
	local c2w_len2 = center2Point:length2()
	-- get the square radius
	local sqradius = sphere:getBound():radius2()
	-- Apparently the square radius of the bound is overshoot by 3
	return c2w_len2 < sqradius--/3
end

lastRemoved = 0

-- Eliminates the first sphere touched by the wand
-- returns true if a sphere was disappeared, false otherwise
function disappearCollidedSpheres(wandPos)
	local numChildren = sphereRow:getNumChildren()
	for i=1,numChildren do
		-- osg's children indexes are zero based
		local curSphere = sphereRow:getChild(i-1)
		if pointInsideSphere(wandPos,curSphere) then
			logEntry("collision sphere="..curSphere:getName())
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
			disappearCollidedSpheres(magicWand:getTipPos())
			moveSpheres(dt)
		else
			logEntry("new_trial")
			sphereRow:removeChildren(0, sphereRow:getNumChildren())
			sphereRow:setPosition(initialPos)
			displayRandExpCondition()
		end
		dt = Actions.waitForRedraw()
	end
end

function startExperiment(dt)
	local btn1 = gadget.DigitalInterface("VJButton1")
	while not btn1.pressed do
		Actions.waitForRedraw()
	end
	numSpheres = 1
	sphereSpeed = osg.Vec3d(0,0,2)
	createExperimentalConditions()
	Actions.addFrameAction(writeLog)
	-- give the log the chance to start
	Actions.waitForRedraw()
	runExperiment()
	logEntry("1_sphere_ended")
	sphereRow:removeChildren(0, sphereRow:getNumChildren())

	Actions.removeFrameAction(writeLog)
	while not btn1.pressed do
		Actions.waitForRedraw()
	end
	numSpheres = 2
	sphereSpeed = osg.Vec3d(0,0,1.5)
	createExperimentalConditions()
	Actions.addFrameAction(writeLog)
	-- give the log the chance to start
	Actions.waitForRedraw()
	runExperiment()
	logEntry("2_spheres_ended")
	sphereRow:removeChildren(0, sphereRow:getNumChildren())

	-- Don't vary position for 3 spheres
	positions = { "center" }
	Actions.removeFrameAction(writeLog)
	while not btn1.pressed do
		Actions.waitForRedraw()
	end
	numSpheres = 3
	sphereSpeed = osg.Vec3d(0,0,1.5)
	createExperimentalConditions()
	Actions.addFrameAction(writeLog)
	-- give the log the chance to start
	Actions.waitForRedraw()
	runExperiment()
	logEntry("3_spheres_ended")
	sphereRow:removeChildren(0, sphereRow:getNumChildren())

	-- Return to initial values
	positions = { "left", "center", "right" }
end

Actions.addFrameAction(startExperiment)