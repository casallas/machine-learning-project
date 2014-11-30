-- Look for scripts in the same directory as this file.
require("getScriptFilename")
fn = getScriptFilename()
assert(fn, "Have to load this from file, not copy and paste, or we can't find our scripts!")
vrjLua.appendToModelSearchPath(fn)

dofile(vrjLua.findInModelSearchPath([[target.lua]]))
dofile(vrjLua.findInModelSearchPath([[osgXUtils.lua]]))

local debug_axis_geode = Cylinder{position={0,0,1.5}, height=3, radius=0.01}
local debug_naxis_geode = Cylinder{position={0,0,-.5}, height=1, radius=0.01}
-- Set the debug axis to black, and the negative axis to white
debug_axis_geode:getDrawable(0):setColor(osg.Vec4(0,0,0,0))
debug_naxis_geode:getDrawable(0):setColor(osg.Vec4(1,1,1,0))

TargetArray = {}
function TargetArray:new(highlightDistance)
  highlightDistance = highlightDistance or 1
  local object = {
    xform = Transform{
      -- targets
    },
    targets = {}, -- All the targets in the world
    goalTargets = {}, -- The targets that should be picked
    highlightDistance = highlightDistance,
  }
  setmetatable(object, { __index = TargetArray })
  return object
end

function TargetArray:move(dt)
  for i, t in pairs(self.targets) do
    t:move(dt)
  end
end

function TargetArray:highlightGoals()
  local ans = false
  for i, t in ipairs(self.goalTargets) do
    -- TODO check why getD(t.xform) != getD(self.xform)
    if(t:getD(t.xform) <= self.highlightDistance) then
      t:highlight(true)
      ans = ans or true
    else
      t:highlight(false)
    end
  end
  return ans
end

function TargetArray:resetTargets()
  for i, t in pairs(self.targets) do
    t:reset()
  end
end

-- TODO check why ... (arg) is not working
function TargetArray:addTargets(targets)
  self.targets = targets
  for i, t in ipairs(self.targets) do
    self.xform:addChild(t.xform)
  end
end

function TargetArray.EquilateralTriangularArray(D0)
  D0 = D0 or 1
  local ans = TargetArray:new(D0)
  local t1 = Target:new()
  local t2 = Target:new()
  local t3 = Target:new()

  t1.xform:setAttitude(AngleAxis(Degrees(-30), Axis{0, 1, 0}))
  t1:setD0(D0)
  t2.xform:setAttitude(AngleAxis(Degrees(30), Axis{0, 1, 0}))
  t2:setD0(D0)
  t3.xform:setAttitude(AngleAxis(math.atan(math.sqrt(2)), Axis{1, 0, 0}))
  t3:setD0(D0)

  ans.xform:setAttitude(AngleAxis(-math.atan(math.sqrt(2))/2, Axis{1, 0, 0}))
  
  ans:addTargets({t1, t2, t3})
  ans.goalTargets = {t1}
  return ans
end

