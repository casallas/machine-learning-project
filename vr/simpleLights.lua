-- Modified by Juan Sebastian Casallas
-- originally in vancegroup/virtually-magic/Scripts/Effects/simpleLights.lua

ss = RelativeTo.World:getOrCreateStateSet()
function doLight1()

	l1 = osg.Light()
	l1:setLightNum(2)
	l1:setAmbient(osg.Vec4(1, 1, 1, 1))
	l1:setDiffuse(osg.Vec4(1, 1, 1, 1))
	l1:setSpecular(osg.Vec4(1, 1, 1, 1))
	ls1 = osg.LightSource()
	ls1:setLight(l1)
	ls1:setLocalStateSetModes(osg.StateAttribute.Values.ON)
	ss:setAssociatedModes(l1, osg.StateAttribute.Values.ON)
	RelativeTo.Room:addChild(ls1)

	l1:setPosition(osg.Vec4(0, 0, -5, 1.0))
end
function doLight1_5()

	l3 = osg.Light()
	l3:setLightNum(3)
	l3:setDiffuse(osg.Vec4(1, 1, 1, 1))
	l3:setSpecular(osg.Vec4(1, 1, 1, 1))
	
	ls3 = osg.LightSource()
	ls3:setLight(l3)
	ls3:setLocalStateSetModes(osg.StateAttribute.Values.ON)

	ss:setAssociatedModes(l3, osg.StateAttribute.Values.ON)
	
	RelativeTo.Room:addChild(ls3)
	l3:setPosition(osg.Vec4(-1.0, 2.0, 1.25, 1.0))
end
function doLight2()

	l2 = osg.Light()
	l2:setLightNum(1)
	l2:setDiffuse(osg.Vec4(1, 1, 1, 1))
	l2:setSpecular(osg.Vec4(1, 1, 1, 1))
	
	ls2 = osg.LightSource()
	ls2:setLight(l2)
	ls2:setLocalStateSetModes(osg.StateAttribute.Values.ON)

	ss:setAssociatedModes(l2, osg.StateAttribute.Values.ON)
	
	RelativeTo.Room:addChild(ls2)
	l2:setPosition(osg.Vec4(1.5, 2, 0, 1.0))
end

doLight1()
doLight1_5()
doLight2()
