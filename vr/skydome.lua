-- Look for models in the same directory as this file.
require("getScriptFilename")
fn = getScriptFilename()
assert(fn, "Have to load this from file, not copy and paste, or we can't find our models!")
vrjLua.appendToModelSearchPath(fn)

-- Add simple lights
dofile(vrjLua.findInModelSearchPath([[simpleLights.lua]]))

-- Skydome model transform, we need this to rotate -90 on x, and shift it up 2m
skydomeXform = Transform{
	position = {0, 2, 0},
	-- set the transform orientation to -90 on the x (first element of Axis values)
	orientation = AngleAxis(Degrees(-90), Axis{1.0, 0.0, 0.0}),
}
-- Load the skydome model
local m = Model("model/skydome11.osg")

-- Add the model to the transform
skydomeXform:addChild(m)

-- Add the transform to the world
RelativeTo.World:addChild(skydomeXform)
