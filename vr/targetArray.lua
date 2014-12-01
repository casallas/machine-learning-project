-- Look for scripts in the same directory as this file.
require("getScriptFilename")
fn = getScriptFilename()
assert(fn, "Have to load this from file, not copy and paste, or we can't find our scripts!")
vrjLua.appendToModelSearchPath(fn)

dofile(vrjLua.findInModelSearchPath([[target.lua]]))
dofile(vrjLua.findInModelSearchPath([[osgXUtils.lua]]))

local wireframe_mode = osg.PolygonMode()
wireframe_mode:setMode(osg.PolygonMode.Face.FRONT_AND_BACK, osg.PolygonMode.Mode.LINE)

TargetArray = {}
function TargetArray:new(highlightDistance, originRad, originColor)
  highlightDistance = highlightDistance or 1
  originRad = originRad or .05 -- the origin radius, default is 5 cm
  originColor = originColor or osg.Vec4f(0,1,0,1) -- the origin color, default is green
  local originGeode = Sphere{radius = originRad, position = {0,0,0}} -- translucent sphere
  local originGeode2 = Sphere{radius = originRad, position = {0,0,0}} -- wireframe sphere
  originGeode.Drawable[1]:setColor(originColor)
  originGeode2.Drawable[1]:setColor(originColor)
  originGeode2:getOrCreateStateSet():setAttributeAndModes(wireframe_mode)

  local object = {
    originGeode = originGeode,
    originSwitch = Switch{[TransparentGroup{
      alpha = 0.25,
      originGeode
      }] = false,
      [Transform{orientation=AngleAxis(Degrees(-90), Axis{1, 0, 0}),
      originGeode2
      }] = false
    },
    xform = Transform{
      -- targets,
      -- originSwitch
    },
    targets = {}, -- All the targets in the world
    goalTargets = {}, -- The targets that should be picked
    highlightDistance = highlightDistance,
    originColor = originColor,
    is_displayOrigin = false,
    is_vdebug = false
  }
  object.xform:addChild(object.originSwitch)
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

function TargetArray:displayOrigin(on)
  if(on == nil) then
    self.is_displayOrigin = not self.is_displayOrigin
  else
    self.is_displayOrigin = on
  end
  if self.is_displayOrigin then
    self.originSwitch:setAllChildrenOn()
  else
    self.originSwitch:setAllChildrenOff()
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

  tOrigin = Transform{orientation = AngleAxis(-math.atan(math.sqrt(2))/2, Axis{1, 0, 0}),
    t1.xform,
    t2.xform,
    t3.xform
  }

  ans.xform:addChild(tOrigin)
  
  ans.targets = {t1, t2, t3}
  ans.goalTargets = {t1}
  return ans
end

function TargetArray.HexagonalArray(D0)
  D0 = D0 or 1
  local ans = TargetArray:new(D0)
  local t1 = Target:new()
  local t2 = Target:new()
  local t3 = Target:new()
  local t4 = Target:new()
  local t5 = Target:new()
  local t6 = Target:new()

  -- First arrange the first three targets in an equilateral triangle
  t1.xform:setAttitude(AngleAxis(Degrees(-30), Axis{0, 1, 0}))
  t1:setD0(D0)
  t2.xform:setAttitude(AngleAxis(Degrees(30), Axis{0, 1, 0}))
  t2:setD0(D0)
  t3.xform:setAttitude(AngleAxis(math.atan(math.sqrt(2)), Axis{1, 0, 0}))
  t3:setD0(D0)

  tOrigin = Transform{orientation = AngleAxis(-math.atan(math.sqrt(2))/2, Axis{1, 0, 0}),
    t1.xform,
    t2.xform,
    t3.xform
  }

  -- Arrange the last targets in another equilateral triangle
  t4.xform:setAttitude(AngleAxis(Degrees(-30), Axis{0, 1, 0}))
  t4:setD0(D0)
  t5.xform:setAttitude(AngleAxis(Degrees(30), Axis{0, 1, 0}))
  t5:setD0(D0)
  t6.xform:setAttitude(AngleAxis(-math.atan(math.sqrt(2)), Axis{1, 0, 0}))
  t6:setD0(D0)

  tOrigin2 = Transform{orientation = AngleAxis(math.atan(math.sqrt(2))/4, Axis{1, 0, 0}),
    t4.xform,
    t5.xform,
    t6.xform
  }

  -- Now add the two triangles to the array's root
  ans.xform:addChild(tOrigin)
  ans.xform:addChild(tOrigin2)

  ans.targets = {t1, t2, t3, t4, t5, t6}
  ans.goalTargets = {t1}
  return ans
end
