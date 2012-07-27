require("Actions")

log_file = nil

log_prefix = "./data/"

function serializeExpConditions()
	local ans = ""
	for k,v in pairs(expConditions) do
		ans  = ans..tostring(k)
		for k2,v2 in pairs(v) do
			ans = ans..","..v2
		end
		ans = ans.."\n"
	end
	ans = ans.."<initialSpherePos="..tostring(initialPos)..">\n"
	ans = ans.."<speed="..tostring(sphereSpeed)..">\n"
	return ans
end

-- writes a log entry
function logEntry(entry)
	if log_file then
		log_file:write("<"..entry.."/>\n")
	else
		print("log file not initialized")
		print("entry: <"..entry.."/>")
	end
end

function writeLog(dt)
	local start_time = os.time()
	local file_name = tostring(log_prefix..start_time.."_"..numSpheres.."sph_log.txt")
	log_file = io.open(file_name,"w")
	
	logEntry("start_time="..start_time)
	logEntry("experimental_conditions")
	log_file:write("condition_num,radius1,radius2,radius3,repetitions\n")
	log_file:write(serializeExpConditions())
	log_file:write("</experimental_conditions>\n")

	log_file:write("<experimental_data>\n")
	log_file:write("time,headPos,headOri,wandPos,wandOri,numSpheres,sphere1,sphere2,sphere3\n")

	local head = gadget.PositionInterface("VJHead")
	local wand = gadget.PositionInterface("VJWand")

	while true do
		log_file:write(dt)
		log_file:write(",")
		log_file:write(tostring(head.position))
		log_file:write(",")
		log_file:write(tostring(head.orientation))
		log_file:write(",")
		log_file:write(tostring(wand.position))
		log_file:write(",")
		log_file:write(tostring(wand.orientation))
		log_file:write(",")
		log_file:write(sphereRow:getNumChildren())
		for i=1,sphereRow:getNumChildren() do
			log_file:write(",")
			-- On osg, indexes start in zero...
			log_file:write(sphereRow:getChild(i-1):getName().."_")
			log_file:write(tostring(spherePos(sphereRow:getChild(i-1))))
		end
		log_file:write("\n")
		dt = Actions.waitForRedraw()
	end
	log_file:write("</experimental_data>\n")
	log_file:write("<end_time="..os.time().."/>")
	log_file:close()
	log_file = nil
end