require("Actions")
-- Look for scripts in the same directory as this file.
require("getScriptFilename")
fn = getScriptFilename()
assert(fn, "Have to load this from file, not copy and paste, or we can't find our scripts!")
vrjLua.appendToModelSearchPath(fn)

dofile(vrjLua.findInModelSearchPath([[osgXUtils.lua]]))

MagicWand = {}
function MagicWand:new(totalLength, tipLength)
	totalLength = totalLength or 0.5
	tipLength = tipLength or 0.05
	local baseLength = totalLength - tipLength
	local object = {
		base = Cylinder{position={0,0,baseLength/2},height = baseLength},
		tip = Cylinder{position={0,0,baseLength+(tipLength/2)},height = tipLength},
		xform = Transform{
			orientation = AngleAxis(Degrees(180), Axis{1.0, 0.0, 0.0})
		}
	}
	-- set base black
	local material = createColoredMaterial(osg.Vec4(0,0,0,1))
	object.base:getOrCreateStateSet():setAttribute(material)
	-- set tip white (emissive)
	object.tip:getDrawable(0):setColor(osg.Vec4(1,1,1,0))
	object.xform:addChild(object.base)
	object.xform:addChild(object.tip)
	setmetatable(object, { __index = MagicWand })
	return object
end

function MagicWand:on()
	-- set it orange
	self.tip:getDrawable(0):setColor(osg.Vec4(1.0,0.5,0,0))
end

function MagicWand:off()
	-- set it black
	self.tip:getDrawable(0):setColor(osg.Vec4(1.0,1.0,1.0,0))
end

function MagicWand:getTipPos()
	-- TODO check why the world matrix isn't working
	local tipBound = self.tip:getBound()
	-- Start constructing the matrix from the magic wand's parent
	local tipWXform = self.xform:getParent(0):getMatrix()
	-- Now apply the magic wand's rotation
	tipWXform:preMultRotate(self.xform:getAttitude())
	-- Finally translate to the tip of the magic wand
	tipWXform:preMultTranslate(tipBound:center())
	return tipWXform.Trans
end

magicWand = MagicWand:new(0.2,0.025)

function placeMagicWand()
	local physWand = gadget.PositionInterface("VJWand")

	-- Add a parent transform to the magic wand
	local xform = osg.MatrixTransform()
	xform:addChild(
		magicWand.xform
	)

	-- Add that transform to the world
	RelativeTo.World:addChild(xform)

	-- Update the magic wand position forever.
	while true do
		xform:setMatrix(physWand.matrix)
		Actions.waitForRedraw()
	end
end

-- This frame action draws and updates our
-- magicWand at the wand's location.
Actions.addFrameAction(placeMagicWand)

