-- Function to create a cylinder easily
function Cylinder(a)
	local pos = osg.Vec3(0.0, 0.0, 0.0)
	if a.position then
		pos:set(unpack(a.position))
	end

	local drbl = osg.ShapeDrawable(osg.Cylinder(pos, a.radius or 0.025, a.height or 0.5))
	local geode = osg.Geode()
	geode:addDrawable(drbl)
	return geode
end

-- Creates a simple material with the color set as diffuse, the rest set to black
function createColoredMaterial(color)
	local material = osg.Material()
	material:setDiffuse(osg.Material.Face.FRONT,  color)
	material:setSpecular(osg.Material.Face.FRONT, osg.Vec4(0.0, 0.0, 0.0, 1.0))
	material:setAmbient(osg.Material.Face.FRONT,  osg.Vec4(0.0, 0.0, 0.0, 1.0))
	material:setEmission(osg.Material.Face.FRONT, osg.Vec4(0.0, 0.0, 0.0, 1.0))
	material:setShininess(osg.Material.Face.FRONT, 25.0)
	return material
end
