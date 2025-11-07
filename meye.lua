local comp = require("component")
local event = require("event")
local rad = "os_entdetector"
local os = require("os") 
local doska = require("serialization")
local term = require("term")

while true do
os.sleep(1)
  local radars = {}
  for addr, _ in pairs(comp.list(rad)) do
      table.insert(radars, comp.proxy(addr))
  end
 
local wl = {"yarik141"}
local res = {}
  
  for key, radar in ipairs(radars) do
  result = radar.scanPlayers(1000000)
  term.clear
    for id, data in ipairs(result) do
    res[data.name] = {x=data.x, y=data.y, z=data.z}
    end
  end
  for nick, cords in pairs(res) do
local tf = false
  for n, namewl in ipairs(wl) do
      if nick == namewl then do 
          tf = true
      end
  end
if not tf then 
        print(nick, cords.x, cords.y, cords.z)
  end

end
