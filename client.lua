RegisterCommand('cheatmenu', function()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
end, false)

RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

local activeCheats = {
    aimbot = false,
    drawlines = false,
    drawlinesnpc = false,
    nametags = false,
    aimbotnpc = false,
    noclip = false
}

RegisterNUICallback('toggleCheat', function(data, cb)
    local cheat = data.cheat
    local enabled = data.enabled
    if activeCheats[cheat] ~= nil then
        activeCheats[cheat] = enabled
        print(('Cheat "%s" ist jetzt %s'):format(cheat, enabled and 'aktiviert' or 'deaktiviert'))
    end
    cb('ok')
end)

local aimbotFov = 60

RegisterNUICallback('aimbotFov', function(data, cb)
    aimbotFov = tonumber(data.fov) or 60
    print(('Aimbot FOV gesetzt auf: %d'):format(aimbotFov))
    cb('ok')
end)

RegisterNUICallback('fovSlider', function(data, cb)
    aimbotFov = tonumber(data.fov) or 60
    cb('ok')
end)

local drawlinesDistance = 100.0

RegisterNUICallback('drawlinesDistance', function(data, cb)
    drawlinesDistance = tonumber(data.distance) or 100.0
    cb('ok')
end)

RegisterNUICallback('warpIntoClosedVehicle', function(data, cb)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local handle, veh = FindFirstVehicle()
    local found = false
    repeat
        if DoesEntityExist(veh) and not IsPedInAnyVehicle(playerPed, false) then
            local vehCoords = GetEntityCoords(veh)
            local dist = #(playerCoords - vehCoords)
            if dist < 30.0 and GetVehicleDoorLockStatus(veh) ~= 1 then
                TaskWarpPedIntoVehicle(playerPed, veh, -1)
                found = true
                break
            end
        end
        found, veh = FindNextVehicle(handle)
    until not found
    EndFindVehicle(handle)
    cb('ok')
end)

-- Hilfsfunktion: 3D zu 2D
local function World3DToScreen2D(x, y, z)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    return onScreen, _x, _y
end

-- Hilfsfunktion: Prüft, ob ein Ziel im POV ist
local function IsInFov(playerPed, targetPed, fov)
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords = GetEntityCoords(targetPed)
    local camRot = GetGameplayCamRot(2)
    local camForward = vector3(
        -math.sin(math.rad(camRot.z)) * math.abs(math.cos(math.rad(camRot.x))),
        math.cos(math.rad(camRot.z)) * math.abs(math.cos(math.rad(camRot.x))),
        math.sin(math.rad(camRot.x))
    )
    local toTarget = (targetCoords - playerCoords)
    local toTargetNorm = toTarget / #(toTarget)
    local dot = camForward.x * toTargetNorm.x + camForward.y * toTargetNorm.y + camForward.z * toTargetNorm.z
    local angle = math.deg(math.acos(dot))
    return angle <= (fov / 2)
end

-- Magic Bullet: Manipuliert Schüsse
local function MagicBulletTick()
    if not (activeCheats.aimbot or activeCheats.aimbotnpc) then return end
    if IsPedShooting(PlayerPedId()) then
        local playerPed = PlayerPedId()
        local camRot = GetGameplayCamRot(2)
        local camForward = vector3(
            -math.sin(math.rad(camRot.z)) * math.abs(math.cos(math.rad(camRot.x))),
            math.cos(math.rad(camRot.z)) * math.abs(math.cos(math.rad(camRot.x))),
            math.sin(math.rad(camRot.x))
        )
        local foundTarget = nil
        local minAngle = 10 -- maximal 10° Abweichung
        -- Spieler
        if activeCheats.aimbot then
            for _, pid in ipairs(GetActivePlayers()) do
                local targetPed = GetPlayerPed(pid)
                if targetPed ~= playerPed and not IsPedDeadOrDying(targetPed) and IsInFov(playerPed, targetPed, aimbotFov) then
                    local playerCoords = GetEntityCoords(playerPed)
                    local targetCoords = GetEntityCoords(targetPed)
                    local toTarget = (targetCoords - playerCoords)
                    local toTargetNorm = toTarget / #(toTarget)
                    local dot = camForward.x * toTargetNorm.x + camForward.y * toTargetNorm.y + camForward.z * toTargetNorm.z
                    local angle = math.deg(math.acos(dot))
                    if angle <= minAngle then
                        foundTarget = targetPed
                        break
                    end
                end
            end
        end
        -- NPCs
        if not foundTarget and activeCheats.aimbotnpc then
            local handle, ped = FindFirstPed()
            local finished = false
            repeat
                if DoesEntityExist(ped) and not IsPedAPlayer(ped) and not IsPedDeadOrDying(ped) and IsInFov(playerPed, ped, aimbotFov) then
                    local playerCoords = GetEntityCoords(playerPed)
                    local targetCoords = GetEntityCoords(ped)
                    local toTarget = (targetCoords - playerCoords)
                    local toTargetNorm = toTarget / #(toTarget)
                    local dot = camForward.x * toTargetNorm.x + camForward.y * toTargetNorm.y + camForward.z * toTargetNorm.z
                    local angle = math.deg(math.acos(dot))
                    if angle <= minAngle then
                        foundTarget = ped
                        break
                    end
                end
                finished, ped = FindNextPed(handle)
            until not finished
            EndFindPed(handle)
        end
        if foundTarget then
            if IsPedAPlayer(foundTarget) then
                TriggerEvent('esx:showNotification', 'Headshot bei Spielern ist auf diesem Server nicht möglich!')
            else
                SetEntityHealth(foundTarget, 0)
                ApplyDamageToPed(foundTarget, 200, true)
                local headBone = 0x796e
                local targetCoords = GetPedBoneCoords(foundTarget, headBone, 0, 0, 0)
                -- Optional: Bluteffekt
                -- StartParticleFxNonLoopedAtCoord("blood_headshot", targetCoords.x, targetCoords.y, targetCoords.z, 0.0, 0.0, 0.0, 1.0, false, false, false)
            end
        end
    end
end

-- Neuer FOV-Kreis als echtes Overlay mit World3dToScreen2d und DrawLine
local function DrawFovCircle(fov)
    local ped = PlayerPedId()
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local radius = 6.0 -- Standardradius, kann angepasst werden
    local segments = 100
    local heading = math.rad(camRot.z)
    local pitch = math.rad(camRot.x)
    local prevScreenX, prevScreenY
    for i = 0, segments do
        local angle = (i / segments) * 2 * math.pi
        -- Kreis im Sichtfeld vor der Kamera
        local x = camCoords.x + radius * math.cos(angle) * math.cos(pitch)
        local y = camCoords.y + radius * math.sin(angle) * math.cos(pitch)
        local z = camCoords.z + radius * math.sin(pitch)
        -- Drehe den Kreis entsprechend der Kamera
        local dx = x - camCoords.x
        local dy = y - camCoords.y
        local dz = z - camCoords.z
        local rotX = dx * math.cos(heading) - dy * math.sin(heading)
        local rotY = dx * math.sin(heading) + dy * math.cos(heading)
        x = camCoords.x + rotX
        y = camCoords.y + rotY
        local onScreen, screenX, screenY = World3dToScreen2d(x, y, z)
        if onScreen and prevScreenX and prevScreenY then
            DrawLine(screenX, screenY, 0.0, prevScreenX, prevScreenY, 0.0, fovColor.r, fovColor.g, fovColor.b, fovColor.a)
        end
        prevScreenX, prevScreenY = screenX, screenY
    end
end

local fovColor = {r=231, g=76, b=60, a=200}
local drawlinesColor = {r=255, g=0, b=0, a=255}
local drawlinesNpcColor = {r=0, g=255, b=0, a=255}

local function hexToRgba(hex, alpha)
    hex = hex:gsub('#','')
    return {
        r = tonumber(hex:sub(1,2),16),
        g = tonumber(hex:sub(3,4),16),
        b = tonumber(hex:sub(5,6),16),
        a = alpha or 255
    }
end

local showFovOverlay = false

RegisterNUICallback('fovOverlay', function(data, cb)
    showFovOverlay = data.enabled == true
    cb('ok')
end)

-- Overlay-Thread (nur Kreis)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if showFovOverlay then
            DrawFovCircle(aimbotFov)
        end
    end
end)

-- Haupt-Thread für Cheats
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        MagicBulletTick()
        -- DrawLines, DrawLines NPC, NameTags etc. bleiben erhalten
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        -- DRAWLINES (mit Distanz)
        if activeCheats.drawlines then
            for _, pid in ipairs(GetActivePlayers()) do
                local targetPed = GetPlayerPed(pid)
                if targetPed ~= playerPed then
                    local targetCoords = GetEntityCoords(targetPed)
                    local dist = #(playerCoords - targetCoords)
                    if dist <= drawlinesDistance then
                        DrawLine(playerCoords.x, playerCoords.y, playerCoords.z, targetCoords.x, targetCoords.y, targetCoords.z, 255, 0, 0, 255)
                    end
                end
            end
        end
        -- DRAWLINES NPC (mit Distanz)
        if activeCheats.drawlinesnpc then
            local handle, ped = FindFirstPed()
            local finished = false
            repeat
                if DoesEntityExist(ped) and not IsPedAPlayer(ped) and not IsPedDeadOrDying(ped) then
                    local npcCoords = GetEntityCoords(ped)
                    local dist = #(playerCoords - npcCoords)
                    if dist <= drawlinesDistance then
                        DrawLine(playerCoords.x, playerCoords.y, playerCoords.z, npcCoords.x, npcCoords.y, npcCoords.z, 0, 255, 0, 255)
                    end
                end
                finished, ped = FindNextPed(handle)
            until not finished
            EndFindPed(handle)
        end
        -- NAMETAGS
        if activeCheats.nametags then
            for _, pid in ipairs(GetActivePlayers()) do
                local targetPed = GetPlayerPed(pid)
                if targetPed ~= playerPed then
                    local targetCoords = GetEntityCoords(targetPed)
                    local onScreen, _x, _y = World3dToScreen2d(targetCoords.x, targetCoords.y, targetCoords.z + 1.0)
                    if onScreen then
                        SetTextFont(0)
                        SetTextProportional(1)
                        SetTextScale(0.35, 0.35)
                        SetTextColour(255, 255, 255, 215)
                        SetTextEntry("STRING")
                        AddTextComponentString(GetPlayerName(pid))
                        DrawText(_x, _y)
                    end
                end
            end
        end
    end
end)

RegisterNUICallback('execEvent', function(data, cb)
    if data and data.event and type(data.event) == 'string' and #data.event > 0 then
        if data.arg and #data.arg > 0 then
            TriggerEvent(data.event, data.arg)
        else
            TriggerEvent(data.event)
        end
    end
    cb('ok')
end)

RegisterNUICallback('execCode', function(data, cb)
    if data and data.code and type(data.code) == 'string' and #data.code > 0 then
        local fn, err = load(data.code)
        if fn then
            local ok, result = pcall(fn)
            if not ok then
                print('[Luka_Cheat Executer] Fehler beim Ausführen:', result)
            end
        else
            print('[Luka_Cheat Executer] Syntaxfehler:', err)
        end
    end
    cb('ok')
end)

-- Noclip-Logik
local noclipSpeed = 1.5
local function NoclipTick()
    if not activeCheats.noclip then return end
    local playerPed = PlayerPedId()
    SetEntityInvincible(playerPed, true)
    SetEntityVisible(playerPed, true)
    SetEntityCollision(playerPed, false, false)
    FreezeEntityPosition(playerPed, true)
    local x, y, z = table.unpack(GetEntityCoords(playerPed, true))
    local dx, dy, dz = 0.0, 0.0, 0.0
    if IsControlPressed(0, 32) then dz = dz + noclipSpeed end -- W (vor)
    if IsControlPressed(0, 8) then dz = dz - noclipSpeed end -- S (zurück)
    if IsControlPressed(0, 44) then y = y + noclipSpeed end -- Q (hoch)
    if IsControlPressed(0, 51) then y = y - noclipSpeed end -- E (runter)
    if IsControlPressed(0, 34) then dx = dx - noclipSpeed end -- A (links)
    if IsControlPressed(0, 9) then dx = dx + noclipSpeed end -- D (rechts)
    local heading = GetGameplayCamRelativeHeading()
    local pitch = GetGameplayCamRelativePitch()
    local forward = vector3(-math.sin(math.rad(heading)), math.cos(math.rad(heading)), 0.0)
    local right = vector3(math.cos(math.rad(heading)), math.sin(math.rad(heading)), 0.0)
    local move = (forward * dz) + (right * dx) + vector3(0, 0, y)
    SetEntityCoordsNoOffset(playerPed, x + move.x, y + move.y, z + move.z, true, true, true)
end

-- Noclip-Thread
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        NoclipTick()
        if not activeCheats.noclip then
            local playerPed = PlayerPedId()
            SetEntityInvincible(playerPed, false)
            SetEntityCollision(playerPed, true, true)
            FreezeEntityPosition(playerPed, false)
        end
    end
end)

RegisterNUICallback('fovColor', function(data, cb)
    if data and data.color then
        fovColor = hexToRgba(data.color, 200)
    end
    cb('ok')
end)
RegisterNUICallback('drawlinesColor', function(data, cb)
    if data and data.color then
        drawlinesColor = hexToRgba(data.color, 255)
    end
    cb('ok')
end)
RegisterNUICallback('drawlinesNpcColor', function(data, cb)
    if data and data.color then
        drawlinesNpcColor = hexToRgba(data.color, 255)
    end
    cb('ok')
end) 