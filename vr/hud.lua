require("Text")

function clearHUD()
  if HUD then
    --RelativeTo.Room:removeChild(HUD)
    RelativeTo.World:removeChild(HUD)
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
        RelativeTo.World:addChild(HUD)
	--RelativeTo.Room:addChild(HUD)
end

function setHUDColor(a)
  a = a or {0,0,0,1}
  HUD.Drawable[1]:setColor(osg.Vec4f(unpack(a)))
end

