require("Text")

function clearHUD()
	if HUD then
		RelativeTo.Room:removeChild(HUD)
	end
end

function displayHUD(text, pos)
	clearHUD()
	pos = pos or osg.Vec3(0,1,-2)
	HUD = TextGeode{
			text,
			position = {pos:x(), pos:y(), pos:z()},
			font = Font("DroidSansBold"),
		}
	RelativeTo.Room:addChild(HUD)
end