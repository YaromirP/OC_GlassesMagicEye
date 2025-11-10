local comp = require("component")
local event = require("event")
local rad = "os_entdetector"
local doska = require("serialization")
local g = comp.glasses
local computer = require("computer")

-- Координаты терминала очков
local xpos, ypos, zpos = -216926, 199, -216923

-- White list игроков, которых не надо рисовать
local wl = {"yarik1415", "Umaler"}

-- Служебные константы
local watchdogPeriod = 1.0      -- Как часто обновлять квадрат сверху слева
local globalSleepTime = 0.05    -- Длительность сна в главном цикле
local radarSleepTime = 0.05     -- Длительность сна между обработками пачек радаров
local radarsBeforeSleep = 8     -- Размер пачки радаров

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
    local lastSquareUpdateTime = computer.uptime()
    while true do
        if not interruptableSleep(globalSleepTime) then -- Если нажали ctrl+c
            goto main_end
        end

         -- Если прошло достаточно времени для обновления квадрата
        if (computer.uptime() - lastSquareUpdateTime) >= watchdogPeriod then
            drawSquare = not drawSquare
        end

        local radars = {}
        for addr, _ in pairs(comp.list(rad)) do
            table.insert(radars, comp.proxy(addr))
        end

        -- Собираем список игроков, обнаруженных радаром.
        -- Поскольку ключем в таблице является ник игрока,
        -- то мы автоматически избавляемся от проблемы дублей.
        local res = {}
        local radarsCounter = 0
        for key, radar in ipairs(radars) do
            result = radar.scanPlayers(1000000)
            for id, data in ipairs(result) do
                res[data.name] = {x = data.x, y = data.y, z = data.z}
            end

            radarsCounter = radarsCounter + 1
            if radarsCounter >= radarsBeforeSleep then
                if not interruptableSleep(radarSleepTime) then -- Если нажали ctrl+c
                    goto main_end
                end
                radarsCounter = 0
            end
        end

        setRedstone(0)
        g.removeAll()

        -- Квадрат в левом верхнем углу для отслеживания
        -- работы программы.
        if drawSquare then
            sq = g.addRect()
            sq.setColor(1, 0, 0)
            sq.setAlpha(0.4)
            sq.setPosition(20, 20)
            sq.setSize(20, 20)
        end

        for nick, cords in pairs(res) do    -- проходимся по найденым радарами игрокам
            local tf = false                -- находится ли найденый игрок в белом списке
            for n, namewl in ipairs(wl) do  -- проходимся по белому списку
                if nick == namewl then
                    tf = true
                    break
                end
            end
            if not tf then  -- если игрок не в белом списке, то рисуем его
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
    ::main_end::
end

-- чтобы "безопасно" выполнить основной код и если что можно
-- было бы вывести то, откуда появилась ошибка
s, e = xpcall(main, function(err) return err .. "\n" .. debug.traceback(); end)
if not s then
    io.stderr:write(e)
end
            g.removeAll() -- удаляем все, что понарисовали.
