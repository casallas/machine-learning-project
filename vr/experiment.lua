math.randomseed( 777 )

inspect = require "inspect"
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
dofile(vrjLua.findInModelSearchPath([[hud.lua]]))
dofile(vrjLua.findInModelSearchPath([[soundFX.lua]]))
dofile(vrjLua.findInModelSearchPath([[targetArray.lua]]))

-- Create a bunch of spheres
numSpheres = 3
-- Sphere radii in m
radii = {0.2, 0.1}
-- Sphere phi angles in Degrees
phis = {15, 30, 45}
-- Sphere speeds in m/s
vs = {.5, 1, 1.5}
-- Range of possible aziumuth angles
gammaRange = {180, 360}

-- Reachable distance in m
reachDist = 1
-- Radius of the origin in m
ori_rad = .05
-- Origin position
ori_pos = Vec{0, 1, 0}

-- Number of repetitions per condition
numRepetitions = 1
-- Number of training positions
numTrainPos = 3
-- Wait time in seconds
waitTime = 1

--- origin
initialPos = osg.Vec3d(0,0,0)
---metal
--initialPos = osg.Vec3d(2,0,0)

vdebug_tArray = false

-- preload the targets
print("Loading target models")
local enzo = Transform{
  -- The model is aligned with the x axis
  orientation = AngleAxis(Degrees(-90), Axis{0.0, 1.0, 0.0}),
  Transform{
    -- rotate a little bit to make the model symmetric
    orientation = AngleAxis(Degrees(10), Axis{1.0, 0.0, 0.0}),
    Model("model/enzo10_low.osg")
  }
}
local enzo10 = Transform{
  scale = 1,
  enzo
}
local enzo20 = Transform{
  scale = 2,
  enzo
}
targets = { enzo10, enzo20}
print("Target models loaded")

function setOriginPosition()
  -- Set the origin to the wand's tip pos
  ori_pos:set(magicWand:getTipPos())
end

-- Create experimental conditions, a full nxnxn experiment
-- The experimental condition table will look like radius1, radius2, radius3, repetitions
expConditions = {}
function createExperimentalConditions()
  expConditions = {}
  if numSpheres == 1 then
    for goalT = 1, numTrainPos do
      --i, rad, phi0, v
      for _, r in pairs(radii) do
        for _, phi in pairs(phis) do
          for _, v in pairs(vs) do
            table.insert( expConditions, {
                            goal = goalT,
                            rad = r,
                            phi = phi,
                            v = v,
                            repetitions=numRepetitions
                        })
          end -- rof v
        end -- rof phi
      end -- rof r
    end -- rof goalT
  else
    for goalT = 1, numSpheres do
      --i, rad, phi0, v
      for _, r in pairs(radii) do
        for _, phi in pairs(phis) do
          for _, v in pairs(vs) do
            table.insert( expConditions, {
                            goal = goalT,
                            rad = r,
                            phi = phi,
                            v = v,
                            repetitions=numRepetitions
                        })
          end -- rof v
        end -- rof phi
      end -- rof r
    end -- rof goalT
  end -- fi
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

-- A trial is ended if the objects are behind the head (in z), or if there are no children in the row
function trialEnded(headPos)
  if #tArray.goalTargets <= 0 then
    logEntry("no_more_spheres")
    return true
  elseif tArray.goalTargets[1].is_highlighted and
           ((math.abs(tArray.goalTargets[1]:getWPos():z() - headPos:z()) > 2) or
             (math.abs(tArray.goalTargets[1]:getWPos():y() - headPos:y()) > 2) or
             (math.abs(tArray.goalTargets[1]:getWPos():x() - headPos:x()) > 2)) then
    local pos = tArray.goalTargets[1]:getWPos()
    playPassSound( pos )
    logEntry("balls_bypassed_user")
    return true    
  else
    return false
  end
end

function displayNumSpheres(numS)
  if numS == 3 then
    tArray = TargetArray.EquilateralTriangularArray()
    --TargetArray.EquilateralTriangularArray(tArray)
  elseif numS == 6 then
    tArray = TargetArray.HexagonalArray()
    --TargetArray.HexagonalArray(tArray)
  else
    print("ERROR! Don't know how to create "..numS.." spheres")
  end
  tArray.xform:setPosition(ori_pos)
end

-- displays a random experimental condition
-- Adds the corresponding spheres to the sphere row
function displayRandExpCondition()
  local curExpCondition = getRandomExpCondition()
  -- Create a red material for all the spheres
  local material = createColoredMaterial(osg.Vec4(1.0,0,0,0))
  if numSpheres==1 then
    displayNumSpheres(numTrainPos)
  else
    displayNumSpheres(numSpheres)
  end
  tArray:setExpCondition(curExpCondition)
  if numSpheres==1 then
    tArray:removeTargetsExcept(curExpCondition.goal)
  end
  curExpCondition["repetitions"] = curExpCondition["repetitions"] - 1
  RelativeTo.World:addChild(tArray.xform)
  tArray:move(-waitTime)
  if vdebug_tArray then tArray:vdebug(true) end
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
  --local numChildren = sphereRow:getNumChildren()
  local prevTargets = {} -- shallow copy of the current targets
  for i, t in ipairs(tArray.targets) do
    prevTargets[i] = t
  end
  for i, t in ipairs(prevTargets) do
    if t:pointInside(wandPos) then --pointInsideSphere(wandPos,curSphere) then
      logEntry("collision sphere="..t.name)--curSphere:getName())
      --sphereRow:removeChild(curSphere)
      tArray:removeTarget(t)
      --play or "trigger" the sound
      playCollisionSound( wandPos )
      lastRemoved = i
      return true
    end
  end
  return false
end

-- Applies sphereSpeed to the sphere row
function moveSpheres(dt)
  --local pos = sphereRow:getPosition()
  ---- dt is delta time
  --pos = pos + sphereSpeed * dt
  --sphereRow:setPosition(pos)
  tArray:move(dt)
end

-- We attach it relative to the world: we can move around it.
-- RelativeTo.World:addChild(sphereRow)
tArray = TargetArray:new()

centerIsle = Cylinder{position={0,0,0},height = 0.1,radius = 0.25}
isleXform = Transform{
  position={initialPos:x(),0,0},
  -- METaL
  -- position={initialPos:x(),0,1.5},
  -- set the transform orientation to -90 on the x (first element of Axis values)
  orientation = AngleAxis(Degrees(-90), Axis{1.0, 0.0, 0.0}),
}
--isleMaterial = createColoredMaterial(osg.Vec4(1.0,1.0,1.0,0.0))
--centerIsle:getOrCreateStateSet():setAttribute(isleMaterial)
isleXform:addChild(centerIsle)
RelativeTo.Room:addChild(isleXform)

function serializeTargets()
  local ans = "<targetConditions>\n"
  ans = ans .. "target,radius,phi,v,gamma\n"
  for i, t in ipairs(tArray.targets) do
    ans = ans .. i .. "," .. t.rad .. "," .. t.phi0 .. "," .. t:getV() .. "," .. t.gamma0 .. "\n"
  end
  ans = ans .. "</targetConditions>\n"
  return ans
end

function waitForOriSphere()
  tArray:displayOrigin(true)
  tArray:setOriginColor(redColor)
  while not tArray:pointInsideOrigin(magicWand:getTipPos()) do
    dt = Actions.waitForRedraw()
  end
  tArray:setOriginColor(greenColor)
end

function runExperiment(dt)
  local missed = 0
  local head = gadget.PositionInterface("VJHead")
  local wand = gadget.PositionInterface("VJWand")

  displayHUD("missed: "..tostring(missed),osg.Vec3d(-1,1,-10))
  while true do
    worldHeadPos = head.position - osgnav.position
    worldWandPos = wand.position - osgnav.position
    if not trialEnded(worldHeadPos) then
      tArray:highlightGoals()
      if #tArray.goalTargets > 0 then tArray:displayOrigin(not tArray.goalTargets[1].is_highlighted) end
      disappearCollidedSpheres(magicWand:getTipPos())
      moveSpheres(dt)
    else
      tArray:unroot()
      if not repetitionsRemaining() then
        break
      end
      -- Increment the number of missed (this is just for fun)
      missed = missed + #tArray.goalTargets
      displayHUD("missed: "..tostring(missed),osg.Vec3d(-1,1,-10))
      displayRandExpCondition()

      logEntry("new_trial")
      logRawEntry(serializeTargets())

      waitForOriSphere()
    end
    dt = Actions.waitForRedraw()
  end
end

function startExperiment(dt)
  local btn1 = gadget.DigitalInterface("VJButton5")
  displayHUD("Get on the isle and\nPull trigger to continue!",Vec{-1.5, 1.5, -10})
  while not btn1.pressed do
    Actions.waitForRedraw()
  end
  clearHUD()
  Actions.waitSeconds(2)

  displayHUD("Set the tip of the wand in front of you and\nPull trigger to start!",Vec{-5, 1.5, -10})
  while not btn1.pressed do
    Actions.waitForRedraw()
  end
  clearHUD()

  setOriginPosition()
  numSpheres = 1
  -- Do only one repetition for each condition
  numRepetitions = 1
  createExperimentalConditions()
  -- hold on one sec before starting the log
  Actions.waitForRedraw()
  writeLog_thread = Actions.addFrameAction(writeLog)
  -- give the log the chance to start
  Actions.waitForRedraw()
  runExperiment()
  logEntry("1_sphere_ended")
  tArray:unroot()

  --Actions.removeFrameAction(writeLog_thread)
  displayHUD("Trial ended\nPull trigger for the next one!",Vec{-1.5, 1.5, -10})
  while not btn1.pressed do
    Actions.waitForRedraw()
  end
  clearHUD()
  numSpheres = 3
  -- Do only one repetition for each condition
  numRepetitions = 1
  createExperimentalConditions()
  writeLog_thread = Actions.addFrameAction(writeLog)
  -- give the log the chance to start
  Actions.waitForRedraw()
  runExperiment()
  logEntry("3_spheres_ended")
  tArray:unroot()

  --Actions.removeFrameAction(writeLog_thread)
  displayHUD("Trial ended\nPull trigger for the last one!",Vec{-1, 1.5, -10})
  while not btn1.pressed do
    Actions.waitForRedraw()
  end
  clearHUD()
  numSpheres = 6
  -- Do only one repetition for each condition
  numRepetitions = 1
  createExperimentalConditions()
  writeLog_thread = Actions.addFrameAction(writeLog)
  -- give the log the chance to start
  Actions.waitForRedraw()
  runExperiment()
  logEntry("6_spheres_ended")
  tArray:unroot()

  Actions.removeFrameAction(writeLog_thread)
  displayHUD("Trial ended, thanks!",Vec{-1.5, 1.5, -10})
end

Actions.addFrameAction(startExperiment)
