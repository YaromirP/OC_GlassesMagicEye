local comp = require("component")
local event = require("event")
local rad = "os_entdetector"
local doska = require("serialization")
local term = require("term")
local g = comp.glasses

-- Координаты терминала очков
local xpos, ypos, zpos = -216926, 199, -216923

-- White list игроков, которых не надо рисовать
local wl = {"yarik1415", "Umaler"}

function setRedstone(power)
    local rs = comp.redstone
    if rs ~= nil then
        rs.setOutput({power, power, power, power, power, power})
    end
end

function interruptableSleep(time) -- Альтернатива os.sleep, которая нормально работает с ctrl+c, а не только ctrl+alt+c
    local e = {event.pull(time, "interrupted")}
    if #e > 0 then
        return false
    end
    return true
end

function main()
    local drawSquare = true
    while true do
        if not interruptableSleep(0.05) then -- Если нажали ctrl+c
            break   -- то выходим из главного цикла и из проги как следствие
        end
        if drawSquare then
            sq = g.addRect()
            sq.setColor(1, 0, 0)
            sq.setAlpha(0.4)
            sq.setPosition(20, 20)
            sq.setSize(20, 20)
        end
        drawSquare = not drawSquare
        local radars = {}
        for addr, _ in pairs(comp.list(rad)) do
            table.insert(radars, comp.proxy(addr))
        end
        setRedstone(0)
        g.removeAll()
        local res = {}

        for key, radar in ipairs(radars) do
            result = radar.scanPlayers(1000000)
            term.clear()
            for id, data in ipairs(result) do
                res[data.name] = {x = data.x, y = data.y, z = data.z}
            end
        end
        for nick, cords in pairs(res) do
            local tf = false
            for n, namewl in ipairs(wl) do
                if nick == namewl then
                    tf = true
                    break
                end
            end
            if not tf then
                setRedstone(1)
                c = g.addCube3D()
                c.set3DPos(cords.x - xpos, cords.y - ypos + 1, cords.z - zpos)
                c.setScale(1)
                c.setAlpha(0.4)

                t = g.addFloatingText()
                t.set3DPos(cords.x - xpos, cords.y - ypos + 1, cords.z - zpos)
                t.setColor(0, 1, 0)
                t.setText(nick)
            end
        end
    end
end

-- чтобы "безопасно" выполнить основной код и если что можно
-- было бы вывести то, откуда появилась ошибка
s, e = xpcall(main, function(err) return err .. "\n" .. debug.traceback(); end)
if not s then
    io.stderr:write(e)
end
            g.removeAll() -- удаляем все, что понарисовали.
