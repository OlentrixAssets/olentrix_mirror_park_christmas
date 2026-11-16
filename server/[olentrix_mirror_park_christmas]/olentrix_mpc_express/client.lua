local RD, C = RailData, Config.Ride

local N = #RD.line
local function lineAt(s)
    s = s % RD.length
    local f = s / RD.step; local i = math.floor(f) % N + 1
    local a, b = RD.line[i], RD.line[i % N + 1]
    return a + (b - a) * (f - math.floor(f))
end
local mid = vector2(0.0, 0.0)
for _, p in ipairs(RD.line) do mid = mid + vector2(p.x, p.y) / N end

local RUN = RD.length
local A = C.speed / C.accel
local TRUN = RUN / C.speed + C.accel
local CYCLE = C.dwell + TRUN

local function along(tau)
    if tau <= 0 then return 0.0, 0.0 end
    if tau >= TRUN then return RUN, 0.0 end
    if tau < C.accel then return 0.5 * A * tau * tau, A * tau end
    if tau > TRUN - C.accel then local r = TRUN - tau; return RUN - 0.5 * A * r * r, A * r end
    return 0.5 * C.speed * C.accel + C.speed * (tau - C.accel), C.speed
end

local clock0, game0 = GetCloudTimeAsInt(), GetGameTimer()
local function state()
    local t = ((clock0 % 100000) + (GetGameTimer() - game0) / 1000.0) % CYCLE
    if t < C.dwell then return 'station', RD.stop, 0.0, C.dwell - t end
    t = t - C.dwell
    local x, v = along(t); return 'run', RD.stop + x, v, TRUN - t
end

local cars = {}
local function loadModel(name)
    local h = joaat(name)
    if not IsModelValid(h) then return nil end
    RequestModel(h)
    local n = 0
    while not HasModelLoaded(h) and n < 500 do Wait(10); n = n + 1 end
    return HasModelLoaded(h) and h or nil
end

local steamFx = nil
local function spawn()
    local p0 = lineAt(RD.stop)
    for i, c in ipairs(RD.cars) do
        local h = loadModel(c.model)
        if h then
            local o = CreateObjectNoOffset(h, p0.x, p0.y, p0.z, false, false, false)
            FreezeEntityPosition(o, true); SetEntityCollision(o, false, false); cars[i] = o
        end
    end
    local st = C.steam
    if cars[1] then
        RequestNamedPtfxAsset(st.asset)
        local n = 0
        while not HasNamedPtfxAssetLoaded(st.asset) and n < 300 do Wait(10); n = n + 1 end
        UseParticleFxAsset(st.asset)
        steamFx = StartParticleFxLoopedOnEntity(st.fx, cars[1], st.offset.x, st.offset.y, st.offset.z, 0.0, 0.0, 0.0, st.scale, false, false, false)
    end
end

local function despawn()
    if steamFx then StopParticleFxLooped(steamFx, false); steamFx = nil end
    for i, o in pairs(cars) do if DoesEntityExist(o) then DeleteObject(o) end; cars[i] = nil end
end

local function place(front)
    local s = front
    for i, c in ipairs(RD.cars) do
        local o = cars[i]
        local centre = s - c.length / 2
        if o then
            local half = math.max(0.3, c.length / 2 - 0.4)
            local b, a = lineAt(centre - half), lineAt(centre + half)
            local m = (a + b) * 0.5; local d = vector2(a.x - b.x, a.y - b.y); local len = #d
            SetEntityCoordsNoOffset(o, m.x, m.y, m.z, false, false, false)
            SetEntityRotation(o, -math.deg(math.atan(a.z - b.z, len)), 0.0, math.deg(math.atan(d.x, -d.y)), 2, false)
        end
        s = s - c.length - RD.gap
    end
end

local mySeat, sitAnim = nil, nil
local COACH0 = 3

local function help(text)
    BeginTextCommandDisplayHelp('STRING'); AddTextComponentSubstringPlayerName(text); EndTextCommandDisplayHelp(0, false, false, -1)
end

local function sitPose()
    if sitAnim then return sitAnim end
    for _, a in ipairs(C.sit) do
        RequestAnimDict(a.dict)
        local n = 0
        while not HasAnimDictLoaded(a.dict) and n < 150 do Wait(10); n = n + 1 end
        if HasAnimDictLoaded(a.dict) then sitAnim = a; return a end
    end
end

local function seatOf(idx)
    local per = #RD.seats
    return cars[COACH0 + (idx - 1) // per], RD.seats[(idx - 1) % per + 1]
end

local function stepOff()
    local ped = PlayerPedId()
    local coach, seat = seatOf(mySeat)
    DetachEntity(ped, true, false); ClearPedTasksImmediately(ped)
    if coach and DoesEntityExist(coach) then
        local sx = RD.platformSide > 0 and 1.25 or -1.25
        local p = GetOffsetFromEntityInWorldCoords(coach, sx, seat.y, 0.0)
        SetEntityCoords(ped, p.x, p.y, RD.lawn + RD.platformTop + 0.05, false, false, false, false)
        SetEntityHeading(ped, GetEntityHeading(coach) + (sx > 0 and 90.0 or -90.0))
    end
    mySeat = nil
    TriggerServerEvent('olentrix_mpc_express:leave')
end

RegisterNetEvent('olentrix_mpc_express:seat', function(idx)
    if not idx then BeginTextCommandThefeedPost('STRING'); AddTextComponentSubstringPlayerName('The Christmas Express is full - catch the next one.'); EndTextCommandThefeedPostTicker(false, false); return end
    local coach, seat = seatOf(idx)
    if not coach or not DoesEntityExist(coach) then TriggerServerEvent('olentrix_mpc_express:leave'); return end
    local ped = PlayerPedId(); local o = C.sitOffset
    mySeat = idx
    AttachEntityToEntity(ped, coach, 0, seat.x + o.x, seat.y + o.y, seat.z + o.z, 0.0, 0.0, 180.0, false, false, false, false, 2, true)
    local a = sitPose()
    if a then TaskPlayAnim(ped, a.dict, a.anim, 4.0, 4.0, -1, 1, 0.0, false, false, false) end
end)

local function snd(t) SendNUIMessage(t) end

local lastPhase, nextSnd = nil, 0
CreateThread(function()
    while true do
        local ped = PlayerPedId(); local p = GetEntityCoords(ped)
        local near = #(vector2(p.x, p.y) - mid) < C.range
        if near and not next(cars) then spawn() elseif not near and next(cars) and not mySeat then despawn() end
        if next(cars) then
            local phase, east, v, left = state()
            place(east)
            local e = cars[1] and GetEntityCoords(cars[1]) or vector3(mid.x, mid.y, RD.lawn)
            local d = #(GetFinalRenderedCamCoord() - e)
            local g = d <= C.sound.near and 1.0 or math.max(0.0, 1.0 - (d - C.sound.near) / (C.sound.far - C.sound.near)) ^ 2
            if lastPhase and phase ~= lastPhase and g > 0 then snd({ t = 'bell', g = g * C.sound.bell, v = Config.Volume }) end
            lastPhase = phase
            if GetGameTimer() > nextSnd then
                nextSnd = GetGameTimer() + 150
                snd({ t = 'chuff', g = g * C.sound.chuff * (v / C.speed), r = 0.75 + 0.35 * (v / C.speed), v = Config.Volume })
            end
            if mySeat then
                DisableControlAction(0, 22, true); DisableControlAction(0, 23, true); DisableControlAction(0, 24, true); DisableControlAction(0, 25, true)
                if IsEntityDead(ped) then stepOff()
                elseif phase == 'station' then
                    help('Press ~INPUT_CONTEXT~ to step off the Christmas Express')
                    if IsControlJustReleased(0, 38) then stepOff() end
                end
            elseif phase == 'station' and left > C.boardClose and not IsPedInAnyVehicle(ped, false) then
                for i = COACH0, #RD.cars do
                    local o = cars[i]
                    if o and #(p - GetEntityCoords(o)) < C.boardRange then
                        help('Press ~INPUT_CONTEXT~ to board the Mirror Park Christmas Express')
                        if IsControlJustReleased(0, 38) then TriggerServerEvent('olentrix_mpc_express:board') end
                        break
                    end
                end
            end
            Wait(0)
        else
            Wait(1000)
        end
    end
end)

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    if mySeat then DetachEntity(PlayerPedId(), true, false); ClearPedTasksImmediately(PlayerPedId()) end
    despawn()
    snd({ t = 'stop' })
end)
