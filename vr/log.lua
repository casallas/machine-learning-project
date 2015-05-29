require("Actions")

log_file = nil

require("getScriptFilename")
cur_path = cur_path or string.gsub(getScriptFilename(), "%a*%.lua", "")
log_prefix = log_prefix or (cur_path.."../data/")

function serializeExpConditions()
  local ans = ""
  for i,v in ipairs(expConditions) do
    ans  = ans .. i .. "," .. 
             v["goal"] .. "," ..
             v["rad"] .. "," ..
             v["phi"] .. "," ..
             v["v"] .. "," ..
             v["repetitions"] ..
             "\n"
  end
  ans = ans.."<originPosition="..tostring(ori_pos)..">\n"
  return ans
end

-- writes a log entry
function logEntry(entry)
if runbuf["local"] then
  if log_file then
    log_file:write("<"..entry.."/>\n")
  else
    print("log file not initialized")
    print("entry: <"..entry.."/>")
  end
end
end

function logRawEntry(entry)
if runbuf["local"] then
  if log_file then
    log_file:write(entry)
  else
    print("log file not initialized")
    print("raw_entry: "..entry)
  end
end
end

function writeLog(dt)
if runbuf["local"] then
  local start_time = os.time()
  local file_name = tostring(log_prefix .. start_time .. "_" .. numSpheres .. "sph_log.txt")
  log_file = io.open(file_name,"w")
  
  logEntry("start_time="..start_time)
  logEntry("experimental_conditions")

  log_file:write("condition_num,goal,radius,phi,v,repetitions\n")
  log_file:write(serializeExpConditions())
  log_file:write("</experimental_conditions>\n")

  log_file:write("<experimental_data>\n")
  log_file:write("time,headPos,headOri,wandPos,wandOri,numSpheres")--,sphere1,sphere2,sphere3\n")
  for i, t in ipairs(tArray.targets) do
    log_file:write(",sphere" .. i)
  end
  log_file:write("\n")
  log_file:flush()

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
    log_file:write(#tArray.targets)
    for i, t in ipairs(tArray.targets) do
      log_file:write(",".. i .. "_" .. t.rad .. "_" .. tostring(t:getWPos()))
    end
    log_file:write("\n")
    dt = Actions.waitForRedraw()
  end
  log_file:write("</experimental_data>\n")
  log_file:write("<end_time="..os.time().."/>")
  log_file:close()
  log_file = nil
end
end
