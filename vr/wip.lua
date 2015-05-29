inspect = require("inspect")
--print(inspect(_G))

--tetra = Transform{
--  scale = .1,
--  Model=("model/tetrahedron.obj")
--}
--magicWand.xform:addChild(tetra)
--print(inspect(tetra))
--tetra:setScale(osg.Vec3d(1,1,1))
RelativeTo.World:removeChild(tOrigin)
t0 = Transform{
  position = {0, 0, -1},
  Group{
    targets[1],
    Transform{
      orientation = AngleAxis(Degrees(0), Axis{0, 0, 1}),
      Transform{
        orientation = AngleAxis(Degrees(20), Axis{0, 1, 0}),
        Cylinder{position={0,0,0}, height=3, radius=0.01}
      }
    }
  }
}
t0:getChild(0):getChild(1):getChild(0):getChild(0):getDrawable(0):setColor(osg.Vec4(0,0,0,0))
t1 = Transform{
  orientation = AngleAxis(Degrees(-30), Axis{0, 1, 0}),
  t0,
}
t2 = Transform{
  orientation = AngleAxis(Degrees(30), Axis{0, 1, 0}),
  t0,
}
t3 = Transform{
  orientation = AngleAxis(math.sqrt(2), Axis{1, 0, 0}),
  t0,
}
tOrigin = Transform{
  position = {magicWand:getTipPos():x(),magicWand:getTipPos():y(),magicWand:getTipPos():z()},
  orientation = AngleAxis(Degrees(-30), Axis{1, 0, 0})
}
require "TransparentGroup"
tVorigin = TransparentGroup{
  Sphere{
    radius = .10,
    position = {0,0,0}
  }
}
voriMaterial = createColoredMaterial(osg.Vec4(1,0,0,1))
tVorigin:getChild(0):getOrCreateStateSet():setAttribute(voriMaterial)

reachSph = TransparentGroup{
  alpha = 0.5,
  Sphere{
    radius = 1,
    position = {0,0,0}
  }
}

tOrigin:addChild(reachSph)
tOrigin:addChild(tVorigin)
tOrigin:addChild(t1)
tOrigin:addChild(t2)
tOrigin:addChild(t3)

RelativeTo.World:addChild(tOrigin)


function crazyRot()
while(true) do
  ang = 0
  while(ang < 360) do
    t0:getChild(0):getChild(1):setAttitude(AngleAxis(Degrees(ang), Axis{0, 0, 1}))
    ang = ang + 1
    Actions.waitForRedraw()
  end
end
end
Actions.addFrameAction(crazyRot)

tOrigin:setAttitude(AngleAxis(Degrees(-15), Axis{1,0,0}))
tOrigin:removeChild(reachSph)

RelativeTo.World:removeChild(tOrigin)


Actions.removeFrameAction(crazyRot)

tOrigin:removeChild(reachSph)

RelativeTo.World:removeChild(t1)
RelativeTo.World:removeChild(t2)
RelativeTo.World:removeChild(t3)




----------------------------------------------------------------------------------------------------------------
if tOrigin then RelativeTo.World:removeChild(tOrigin) end
if tOrigin2 then RelativeTo.World:removeChild(tOrigin2) end
inspect = require("inspect")
dofile(vrjLua.findInModelSearchPath([[target.lua]]))
t1 = Target:new()
t2 = Target:new()
t3 = Target:new()

t1.xform:setAttitude(AngleAxis(Degrees(-30), Axis{0, 1, 0}))
t2.xform:setAttitude(AngleAxis(Degrees(30), Axis{0, 1, 0}))
t3.xform:setAttitude(AngleAxis(math.atan(math.sqrt(2)), Axis{1, 0, 0}))

tOrigin = Transform{
  position = {magicWand:getTipPos():x(),magicWand:getTipPos():y(),magicWand:getTipPos():z()},
  orientation = AngleAxis(-math.atan(math.sqrt(2))/2, Axis{1, 0, 0})
}
require "TransparentGroup"
tVorigin = TransparentGroup{
  Sphere{
    radius = .10,
    position = {0,0,0}
  }
}
voriMaterial = createColoredMaterial(osg.Vec4(1,0,0,1))
tVorigin:getChild(0):getOrCreateStateSet():setAttribute(voriMaterial)

reachSph = TransparentGroup{
  alpha = 0.5,
  Sphere{
    radius = 1,
    position = {0,0,0}
  }
}

tOrigin:addChild(reachSph)
tOrigin:addChild(tVorigin)
tOrigin:addChild(t1.xform)
tOrigin:addChild(t2.xform)
tOrigin:addChild(t3.xform)

RelativeTo.World:addChild(tOrigin)

t4 = Target:new()
t5 = Target:new()
t6 = Target:new()

t4.xform:setAttitude(AngleAxis(Degrees(-30), Axis{0, 1, 0}))
t5.xform:setAttitude(AngleAxis(Degrees(30), Axis{0, 1, 0}))
t6.xform:setAttitude(AngleAxis(-math.atan(math.sqrt(2)), Axis{1, 0, 0}))

tOrigin2 = Transform{
  position = {tOrigin:getPosition():x(),tOrigin:getPosition():y(),tOrigin:getPosition():z()},
  orientation = AngleAxis(math.atan(math.sqrt(2))/4, Axis{1, 0, 0})
}

tOrigin2:addChild(t4.xform)
tOrigin2:addChild(t5.xform)
tOrigin2:addChild(t6.xform)

RelativeTo.World:addChild(tOrigin2)

ts = {t1, t2, t3, t4, t5, t6}

for _, v in pairs(ts) do
  v:setGamma(math.random(360))
  v:setPhi(math.random(3)*20)
  v.v = Vec{0, 0, (math.random(3)*.5)}
  v:move(-1)
end

function mvtest()
  local dt = 0
  while(true) do
    for _, v in pairs(ts) do
      v:move(dt)
    end
    dt = Actions.waitForRedraw()
  end
end
mvtest_th = Actions.addFrameAction(mvtest)
Actions.removeFrameAction(mvtest_th)

for _, v in pairs(ts) do
  v:reset()
end

for _, v in pairs(ts) do
  v:vdebug()
end

-----------------------------------------------------------------------------
inspect = require("inspect")
dofile(vrjLua.findInModelSearchPath([[targetArray.lua]]))

function mvtest()
  local dt = 0
  while(true) do
    tArray:move(dt)
    dt = Actions.waitForRedraw()
  end
end

function hltest()
  local dt = 0
  while(true) do
    if(tArray:highlightGoals()) then
      Actions.removeFrameAction(hltest_th)
    end
    dt = Actions.waitForRedraw()
  end
end

rmActions = {}
for i, th in ipairs(Actions._frameActions) do
  if(i > 2) then
    table.insert(rmActions, th)
  end
end
for i, th in ipairs(rmActions) do
  Actions.removeFrameAction(th)
end

gammaRange = {0, 180}
function miniExp()
  while true do
	if tArray then RelativeTo.World:removeChild(tArray.xform) end
	local btnTrigger = gadget.DigitalInterface("VJButton5")
	displayHUD("Get on the isle and\nPull trigger to start!",Vec{initialPos:x(), 1.5, -5})
	while not btnTrigger.pressed do
	  Actions.waitForRedraw()
	end

	--tArray = TargetArray.EquilateralTriangularArray()
        tArray = TargetArray.HexagonalArray()
        
        for _, t in pairs(tArray.targets) do
	  t:randomTargetConds{}
	  t:move(-1)
	end
        
	tArray.xform:setPosition(Vec{magicWand:getTipPos():x(),magicWand:getTipPos():y(),magicWand:getTipPos():z()})
  
	RelativeTo.World:addChild(tArray.xform)
        tArray:vdebug(true)
        tArray:displayOrigin()

        Actions.waitSeconds(1)

	displayHUD("Pull trigger to start!",Vec{initialPos:x(), 1.5, -5})
	while not btnTrigger.pressed do
	  Actions.waitForRedraw()
	end
        Actions.waitSeconds(1)

	--tArray:move(-1)
	mvtest_th = Actions.addFrameAction(mvtest)

	hltest_th = Actions.addFrameAction(hltest)

        while not btnTrigger.pressed do
	  Actions.waitForRedraw()
	end
        Actions.removeFrameAction(mvtest_th)
        Actions.removeFrameAction(hltest_th)

        --Actions.waitSeconds(1)
        Actions.waitForRedraw()
  end
end
miniexp_th = Actions.addFrameAction(miniExp)

rmActions = {}
for i, th in ipairs(Actions._frameActions) do
  if(i > 2) then
    table.insert(rmActions, th)
  end
end
for i, th in ipairs(rmActions) do
  Actions.removeFrameAction(th)
end

Actions.removeFrameAction(mvtest_th)
Actions.removeFrameAction(hltest_th)
Actions.removeFrameAction(miniExp_th)
print(inspect(Actions._frameActions)
-----------------------------------------------------------------------------
if tArray then RelativeTo.World:removeChild(tArray.xform) end
inspect = require("inspect")
dofile(vrjLua.findInModelSearchPath([[targetArray.lua]]))
tArray = TargetArray.HexagonalArray()
tArray.xform:setPosition(Vec{magicWand:getTipPos():x(),magicWand:getTipPos():y(),magicWand:getTipPos():z()})
RelativeTo.World:addChild(tArray.xform)

tArray:move(-1)
function mvtest()
  local dt = 0
  while(true) do
    tArray:move(dt)
    dt = Actions.waitForRedraw()
  end
end
mvtest_th = Actions.addFrameAction(mvtest)


function hltest()
  local dt = 0
  while(true) do
    if(tArray:highlightGoals()) then
      Actions.removeFrameAction(hltest_th)
    end
    dt = Actions.waitForRedraw()
  end
end
hltest_th = Actions.addFrameAction(hltest)

Actions.removeFrameAction(mvtest_th)
-----------------------------------------------------------------------------
inspect = require("inspect")
dofile(vrjLua.findInModelSearchPath([[targetArray.lua]]))
tArray = TargetArray.DblHexagonalArray()
tArray.xform:setPosition(Vec{magicWand:getTipPos():x(),magicWand:getTipPos():y(),magicWand:getTipPos():z()})
RelativeTo.World:addChild(tArray.xform)

tArray:resetTargets()
tArray:move(-1)
function mvtest()
  local dt = 0
  while(true) do
    tArray:move(dt)
    dt = Actions.waitForRedraw()
  end
end
mvtest_th = Actions.addFrameAction(mvtest)

hltest_th = nil

function hltest()
  while(true) do
    if(tArray:highlightGoals()) then
      Actions.removeFrameAction(hltest_th)
    end
    dt = Actions.waitForRedraw()
  end
end
hltest_th = Actions.addFrameAction(hltest)

Actions.removeFrameAction(mvtest_th)
Actions.removeFrameAction(hltest_th)

for i, t in pairs(tArray.targets) do
  t:randomTargetConds()
end

function insidetest()
  while(true) do
    for i, t in ipairs(tArray.targets) do
      if(t:pointInside(magicWand:getTipPos())) then
        t:highlight(true)
      else
        t:highlight(false)
      end
    end
    dt = Actions.waitForRedraw()
  end
end
insidetest_th = Actions.addFrameAction(insidetest)
Actions.removeFrameAction(insidetest_th)


