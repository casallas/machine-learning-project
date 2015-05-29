-- Look for scripts in the same directory as this file.
require("getScriptFilename")
fn = getScriptFilename()
assert(fn, "Have to load this from file, not copy and paste, or we can't find our scripts!")
vrjLua.appendToModelSearchPath(fn)

dofile(vrjLua.findInModelSearchPath([[osgXUtils.lua]]))
require "TransparentGroup"

local debug_axis_geode = Cylinder{position={0,0,1.5}, height=3, radius=0.01}
local debug_naxis_geode = Cylinder{position={0,0,-.5}, height=1, radius=0.01}
local debug_axisup_geode = Cylinder{position={0,0,-.5}, height=1, radius=0.01}
-- Set the debug axis to black, and the negative axis to white
debug_axis_geode:getDrawable(0):setColor(osg.Vec4(0,0,0,0))
debug_naxis_geode:getDrawable(0):setColor(osg.Vec4(1,1,1,0))
debug_axisup_geode:getDrawable(0):setColor(osg.Vec4(0,1,0,0))
local debug_axisup = Transform{orientation = AngleAxis(Degrees(90), Axis{1, 0, 0}), debug_axisup_geode}

Target = {}
function Target:new(rad, pos0, phi0, gamma0, v, highlight_color, i)
  rad = rad or 0.1 -- 10 cm is the default radius
  pos0 = pos0 or {0, 0, -1} -- default is 1 m in front
  phi0 = phi0 or 0 -- the angle between the wand-target vector and the target's direction (altitude)
  gamma0 = gamma0 or 0 -- the angle around the z axis (azimuthal angle)
  v = v or {0, 0, 0.5} -- the target's velocity, default is 0.5 m/s towards wand0
  highlight_color = highlight_color or osg.Vec4f(1,0,0,1) -- the highlight color, default is red
  local highlight_geode = Sphere{radius = 1} -- the geode to highlight the target
  highlight_geode.Drawable[1]:setColor(highlight_color)
  local highlight_xform = Transform{scale=rad*1.1, highlight_geode}
  local i = 0

  local object = {
    rad = rad, -- 10 cm is the default
    pos0 = pos0, -- default is 1 m in front
    phi0 = phi0, -- the angle between the wand-target vector and the target's direction (altitude)
    gamma0 = gamma0, -- the angle around the z axis (azimuthal angle)
    v = Vec(v), -- the target's velocity, default is 0.5 m/s towards wand0
    mdl = targets[rad*10], -- the target model,
    highlight_geode = highlight_geode,
    highlight_xform = highlight_xform,
    -- a Switch group to show the highlight geode
    highlight_switch = Switch{[TransparentGroup{
      alpha = 0.25,
      highlight_xform
      }] = false
    },
    -- a Switch group to show debug axis
    debug_axis = Switch{
      [debug_axis_geode] = false,
      [debug_naxis_geode] = false,
      [debug_axisup] = false
    },
    xform_pos = Transform{
      --mdl
    },
    xform_phi = Transform{
      orientation = AngleAxis(Degrees(phi0), Axis{0, 1, 0}),
      --xform_pos,
      --debug_axis
    },
    xform_gamma = Transform{
      orientation = AngleAxis(Degrees(gamma0), Axis{0, 0, 1}),
      --xform_phi
    },
    xform_pos0 = Transform{
      position = pos0,
      --xform_gamma
    },
    xform = Transform{
      --xform_pos0
    },
    highlight_color = highlight_color,
    is_highlighted = false,
    is_vdebug = false,
    i = i,
    name = i..rad
  }
  -- xform_pos -> mdl
  --           \> highlight_switch -> highlight_xform -> highlight_geode
  object.xform_pos:addChild(object.mdl)
  object.xform_pos:addChild(object.highlight_switch)
  -- xform_phi(Ry,phi0) -> xform_pos -> mdl
  --                                 \> highlight_switch -> highlight_xform -> highlight_geode
  --                    \> debug_axis
  object.xform_phi:addChild(object.xform_pos)
  object.xform_phi:addChild(object.debug_axis)
  -- xform_gamma(Rz, gamma0) -> xform_phi(Ry,phi0) -> xform_pos -> mdl
  --                                               \> highlight_switch -> highlight_xform -> highlight_geode
  --                                               \> debug_axis
  object.xform_gamma:addChild(object.xform_phi)
  -- xform_pos0(T,pos0) -> xform_gamma(Rz, gamma0) -> xform_phi(Ry,phi0) -> xform_pos -> mdl
  --                                                                                  \> highlight_switch -> highlight_xform -> highlight_geode
  --                                                                     \> debug_axis
  object.xform_pos0:addChild(object.xform_gamma)
  -- xform -> xform_pos0(T,pos0) xform_gamma(Rz, gamma0) -> xform_phi(Ry,phi0) -> xform_pos -> mdl
  --                                                                           \> highlight_switch -> highlight_xform -> highlight_geode
  --                                                                           \> debug_axis
  object.xform:addChild(object.xform_pos0)
  setmetatable(object, { __index = Target })
  return object
end

function Target:getPos()
  return self.xform_pos:getPosition()
end

function Target:getPhi()
  return self.phi0--self.xform_phi:getAttitude()
end

function Target:getV()
  return self.v:z()
end

function Target:getGamma()
  return self.gamma0--self.xform_gamma:getAttitude()
end

function Target:getWPos()
  -- Assume there's one node path between the world root and xform_pos (Item[1])
  return self.xform_pos:getWorldMatrices(RelativeTo.World).Item[1]:getTrans()
end

function Target:getD(toNode)
  toNode = toNode or RelativeTo.World
  -- Assume there's one node path between the node and xform_pos (Item[1])
  return self.xform_pos:getWorldMatrices(toNode).Item[1]:getTrans():length()
end

function Target:getD0()
  return self.xform_pos0:getPosition():length()
end

function Target:pointInside(wPt)
  return (self:getWPos() - wPt):length() <= self.rad
end

function Target:setRad(rad)
  if(targets[rad*10]) then
    self.rad = rad
    self.xform_pos:removeChild(self.mdl)
    self.mdl = targets[self.rad*10]
    self.xform_pos:addChild(self.mdl)
    self.highlight_xform:setScale(Vec{1,1,1}*self.rad*1.1)
    self:updateName()
  end
end

function Target:setPos(pos)
  return self.xform_pos:setPosition(pos)
end

function Target:setD0(D0)
  self.pos0 = {0, 0, -D0}
  self.xform_pos0:setPosition(Vec(self.pos0))
end

function Target:setPhi(phi)
  self.phi0 = phi
  return self.xform_phi:setAttitude(AngleAxis(Degrees(self.phi0), Axis{0, 1, 0}))
end

function Target:setGamma(gamma)
  self.gamma0 = gamma
  return self.xform_gamma:setAttitude(AngleAxis(Degrees(self.gamma0), Axis{0, 0, 1}))
end

function Target:setV(v)
  self.v = Vec{0, 0, v}
end

function Target:move(dt)
  -- dt is delta time in seconds
  pos = self:getPos() + self.v * dt
  self.xform_pos:setPosition(pos)
end

function Target:reset()
  self.xform_pos:setPosition(Vec(0,0,0))
end

function Target:setI(i)
  self.i = i
  self:updateName()
end

function Target:updateName()
  self.name = self.i..self.rad
end

function Target:vdebug(on)
  if(on == nil) then
    self.is_vdebug = not self.is_vdebug
  else
    self.is_vdebug = on
  end 
  if self.is_vdebug then
    self.debug_axis:setAllChildrenOn()
  else
    self.debug_axis:setAllChildrenOff()
  end
end

function Target:highlight(on, highlight_color)
  if(on == nil) then
    self.is_highlighted = not self.is_highlighted
  else
    self.is_highlighted = on
  end
  self.highlight_color = highlight_color or self.highlight_color

  if self.is_highlighted then
    -- Correct the highlighted sphere's radius and color, just in case
    --self.highlight_geode.Drawable[1].Shape.Radius = self.rad*1.1
    self.highlight_geode.Drawable[1]:setColor(self.highlight_color)
    -- Display the switch's children
    self.highlight_switch:setAllChildrenOn()
  else
    -- Display the switch's children
    self.highlight_switch:setAllChildrenOff()
  end
end

function Target:randomTargetConds(a)
  a = a or {}
  if a.radRange then
    self:setRad(math.random(unpack(a.radRange)))
  else
    local radVals = a.radVals or radii or {0.2, 0.1}
    self:setRad(radVals[math.random(#radVals)])
  end
  if a.phiRange then
    self:setPhi(math.random(unpack(a.phiRange)))
  else
    local phiVals = a.phiVals or phis or {15, 30, 45}
    self:setPhi(phiVals[math.random(#phiVals)])
  end
  if a.vRange then
    self:setV(math.random(unpack(a.vRange)))
  else
    local vVals = a.vVals or vs or {.5, 1, 1.5}
    self:setV(vVals[math.random(#vVals)])
  end
  if a.gammaVals then
    self:setGamma(a.gammaVals[math.random(#a.gammaVals)])
  else
    _gammaRange = a.gammaRange or gammaRange or {1, 360}
    self:setGamma(math.random(unpack(_gammaRange)))
  end
end

function Target:unroot()
  if #self.xform.Parent > 0 then
    self.xform.Parent[1]:removeChild(self.xform)
  end
end
