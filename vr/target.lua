-- Look for scripts in the same directory as this file.
require("getScriptFilename")
fn = getScriptFilename()
assert(fn, "Have to load this from file, not copy and paste, or we can't find our scripts!")
vrjLua.appendToModelSearchPath(fn)

dofile(vrjLua.findInModelSearchPath([[osgXUtils.lua]]))
require "TransparentGroup"

local debug_axis_geode = Cylinder{position={0,0,1.5}, height=3, radius=0.01}
local debug_naxis_geode = Cylinder{position={0,0,-.5}, height=1, radius=0.01}
-- Set the debug axis to black, and the negative axis to white
debug_axis_geode:getDrawable(0):setColor(osg.Vec4(0,0,0,0))
debug_naxis_geode:getDrawable(0):setColor(osg.Vec4(1,1,1,0))

Target = {}
function Target:new(rad, pos0, phi0, gamma0, v, highlight_color)
  rad = rad or 0.1 -- 10 cm is the default radius
  pos0 = pos0 or {0, 0, -1} -- default is 1 m in front
  phi0 = phi0 or 0 -- the angle between the wand-target vector and the target's direction (altitude)
  gamma0 = gamma0 or 0 -- the angle around the z axis (azimuthal angle)
  v = v or {0, 0, 0.5} -- the target's velocity, default is 0.5 m/s towards wand0
  highlight_color = highlight_color or osg.Vec4f(1,0,0,1) -- the highlight color, default is red
  local highlight_geode = Sphere{radius = rad + .01} -- the geode to highlight the target
  highlight_geode.Drawable[1]:setColor(highlight_color)

  local object = {
    rad = rad, -- 10 cm is the default
    pos0 = pos0, -- default is 1 m in front
    phi0 = phi0, -- the angle between the wand-target vector and the target's direction (altitude)
    gamma0 = gamma0, -- the angle around the z axis (azimuthal angle)
    v = Vec(v), -- the target's velocity, default is 0.5 m/s towards wand0
    mdl = targets[rad*10], -- the target model,
    highlight_geode = highlight_geode,
    -- a Switch group to show the highlight geode
    highlight_switch = Switch{[TransparentGroup{
      alpha = 0.25,
      highlight_geode
      }] = false
    },
    -- a Switch group to show debug axis
    debug_axis = Switch{[debug_axis_geode] = false, [debug_naxis_geode] = false},
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
    is_vdebug = false
  }
  -- xform_pos -> mdl
  --           \> highlight_switch -> highlight_geode
  object.xform_pos:addChild(object.mdl)
  object.xform_pos:addChild(object.highlight_switch)
  -- xform_phi(Ry,phi0) -> xform_pos -> mdl
  --                                 \> highlight_switch -> highlight_geode
  --                    \> debug_axis
  object.xform_phi:addChild(object.xform_pos)
  object.xform_phi:addChild(object.debug_axis)
  -- xform_gamma(Rz, gamma0) -> xform_phi(Ry,phi0) -> xform_pos -> mdl
  --                                               \> highlight_switch -> highlight_geode
  --                                               \> debug_axis
  object.xform_gamma:addChild(object.xform_phi)
  -- xform_pos0(T,pos0) -> xform_gamma(Rz, gamma0) -> xform_phi(Ry,phi0) -> xform_pos -> mdl
  --                                                                                  \> highlight_switch -> highlight_geode
  --                                                                     \> debug_axis
  object.xform_pos0:addChild(object.xform_gamma)
  -- xform -> xform_pos0(T,pos0) xform_gamma(Rz, gamma0) -> xform_phi(Ry,phi0) -> xform_pos -> mdl
  --                                                                           \> highlight_switch -> highlight_geode
  --                                                                           \> debug_axis
  object.xform:addChild(object.xform_pos0)
  setmetatable(object, { __index = Target })
  return object
end

function Target:getPos()
  return self.xform_pos:getPosition()
end

function Target:getPhi()
  return self.xform_phi:getAttitude()
end

function Target:getGamma()
  return self.xform_gamma:getAttitude()
end

function Target:getWPos()
  -- Assume there's one node path between the world root and xform_pos (Item[1])
  return self.xform_pos:getWorldMatrices(RelativeTo.World).Item[1]:getTrans()
end

function Target:getD0()
  return self.xform_pos0:getPosition():length()
end

function Target:getD0()
  return self.xform_pos0:getPosition():length()
end


function Target:setPos(pos)
  return self.xform_pos:setPosition(pos)
end

function Target:setD0(D0)
  self.pos0 = {0, 0, -D0}
  self.xform_pos0:setPosition(Vec(self.pos0))
end

function Target:setPhi(phi)
  return self.xform_phi:setAttitude(AngleAxis(Degrees(phi), Axis{0, 1, 0}))
end

function Target:setGamma(gamma)
  return self.xform_gamma:setAttitude(AngleAxis(Degrees(gamma), Axis{0, 0, 1}))
end

function Target:move(dt)
  -- dt is delta time in seconds
  pos = self:getPos() + self.v * dt
  self.xform_pos:setPosition(pos)
end

function Target:reset()
  self.xform_pos:setPosition(Vec(0,0,0))
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
    self.highlight_geode.Drawable[1].Shape.Radius = self.rad*1.1
    self.highlight_geode.Drawable[1]:setColor(self.highlight_color)
    -- Display the switch's children
    self.highlight_switch:setAllChildrenOn()
  else
    -- Display the switch's children
    self.highlight_switch:setAllChildrenOff()
  end
end
