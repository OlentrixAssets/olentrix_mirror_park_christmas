local R = json.decode(LoadResourceFile(GetCurrentResourceName(), 'ride.json'))
local N = R.n
local CAR = `xv_cst_car`
local MUTE = 'FBI_HEIST_H5_MUTE_AMBIENCE_SCENE'
local TCM = 'xv_passage'
local SIT_DICT, SIT_ANIM = 'amb@prop_human_seat_chair@male@generic@base', 'base'
local BOARD = vector3(R.board[1], R.board[2], R.board[3])
local CAR0 = vector3(R.x[1], R.y[1], R.z[1])
local riding = false
local parked = nil
local lastGo = -100000
local tcmOn, sceneOn = false, false

local function loadModel(m)
    if not IsModelInCdimage(m) then return false end
    RequestModel(m)
    local t = GetGameTimer() + 8000
    while not HasModelLoaded(m) and GetGameTimer() < t do Wait(0) end
    return HasModelLoaded(m)
end

local function idxAt(tau)
    if tau <= R.t[1] then return 1, 0.0 end
    if tau >= R.t[N] then return N - 1, 1.0 end
    local lo, hi = 1, N
    while hi - lo > 1 do
        local mid = (lo + hi) // 2
        if R.t[mid] <= tau then lo = mid else hi = mid end
    end
    return lo, (tau - R.t[lo]) / math.max(R.t[hi] - R.t[lo], 1e-6)
end

local function lerp(a, i, f) return a[i] + (a[i + 1] - a[i]) * f end

local function pose(tau)
    local i, f = idxAt(tau)
    local p = vector3(lerp(R.x, i, f), lerp(R.y, i, f), lerp(R.z, i, f))
    local fw = vector3(lerp(R.fx, i, f), lerp(R.fy, i, f), lerp(R.fz, i, f))
    local up = vector3(lerp(R.ux, i, f), lerp(R.uy, i, f), lerp(R.uz, i, f))
    fw = fw / #fw
    local rt = vector3(fw.y * up.z - fw.z * up.y, fw.z * up.x - fw.x * up.z, fw.x * up.y - fw.y * up.x)
    rt = rt / #rt
    up = vector3(rt.y * fw.z - rt.z * fw.y, rt.z * fw.x - rt.x * fw.z, rt.x * fw.y - rt.y * fw.x)
    return p, fw, rt, up, i, f
end

local function place(obj, tau)
    local p, fw, rt, up, i, f = pose(tau)
    SetEntityMatrix(obj, fw.x, fw.y, fw.z, rt.x, rt.y, rt.z, up.x, up.y, up.z, p.x, p.y, p.z)
    return p, i, f
end

local function newCar(tau)
    if not loadModel(CAR) then return nil end
    local p = pose(tau)
    local obj = CreateObjectNoOffset(CAR, p.x, p.y, p.z, false, false, false)
    SetEntityCollision(obj, false, false)
    SetEntityLodDist(obj, 500)
    FreezeEntityPosition(obj, true)
    place(obj, tau)
    return obj
end

local function inPoly(x, y, poly)
    local inside, j = false, #poly
    for i = 1, #poly do
        local xi, yi, xj, yj = poly[i][1], poly[i][2], poly[j][1], poly[j][2]
        if ((yi > y) ~= (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi) then inside = not inside end
        j = i
    end
    return inside
end

local function setUnder(on)
    if on and not tcmOn then SetExtraTimecycleModifier(TCM); SetExtraTimecycleModifierStrength(1.0); tcmOn = true
    elseif not on and tcmOn then ClearExtraTimecycleModifier(); tcmOn = false end
    if on and not IsAudioSceneActive(MUTE) then StartAudioScene(MUTE); sceneOn = true
    elseif not on and sceneOn then StopAudioScene(MUTE); sceneOn = false end
end

local function help(msg)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function note(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, false)
end

local function sitClone(src, obj)
    local pl = GetPlayerFromServerId(src)
    if pl == -1 then return nil end
    local sp = GetPlayerPed(pl)
    if sp == 0 or not DoesEntityExist(sp) then return nil end
    local c = ClonePed(sp, false, false, false)
    if c == 0 then return nil end
    SetEntityCollision(c, false, false)
    SetEntityInvincible(c, true)
    SetBlockingOfNonTemporaryEvents(c, true)
    AttachEntityToEntity(c, obj, 0, 0.0, -0.5, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
    RequestAnimDict(SIT_DICT)
    local t = GetGameTimer() + 3000
    while not HasAnimDictLoaded(SIT_DICT) and GetGameTimer() < t do Wait(0) end
    if HasAnimDictLoaded(SIT_DICT) then TaskPlayAnim(c, SIT_DICT, SIT_ANIM, 8.0, -8.0, -1, 1, 0, false, false, false) end
    return c
end

local function ride(delay)
    local ped = PlayerPedId()
    if riding or IsPedInAnyVehicle(ped, false) or IsEntityDead(ped) then
        TriggerServerEvent('olentrix_mpc_coaster:done')
        return
    end
    riding = true
    if parked then DeleteEntity(parked); parked = nil end
    local car = newCar(0.0)
    if not car then riding = false; TriggerServerEvent('olentrix_mpc_coaster:done'); return end
    SetEntityInvincible(ped, true)
    ClearPedTasksImmediately(ped)
    AttachEntityToEntity(ped, car, 0, 0.0, -0.5, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
    SetEntityVisible(ped, false, false)
    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamFov(cam, 72.0)
    local yaw, pit = 0.0, 0.0
    HardAttachCamToEntity(cam, car, pit, 0.0, yaw, 0.0, -0.35, 1.45, true)
    RenderScriptCams(true, true, 700, true, true)
    SendNUIMessage({ a = 'shot', k = 'bell', v = 0.9 })
    local t0 = GetGameTimer() + delay
    local nextEv = 1
    local stage = 'station'
    local lastMix = 0
    while true do
        local tau = (GetGameTimer() - t0) / 1000.0
        if tau < 0 then tau = 0 end
        local p, i = place(car, tau)
        DisableAllControlActions(0)
        EnableControlAction(0, 245, true); EnableControlAction(0, 249, true); EnableControlAction(0, 199, true); EnableControlAction(0, 200, true)
        yaw = math.max(-115.0, math.min(115.0, yaw - GetDisabledControlNormal(0, 1) * 6.0))
        pit = math.max(-55.0, math.min(35.0, pit - GetDisabledControlNormal(0, 2) * 6.0))
        HardAttachCamToEntity(cam, car, pit, 0.0, yaw, 0.0, -0.35, 1.45, true)
        while nextEv <= #R.events and R.events[nextEv][1] <= tau do
            local k = R.events[nextEv][2]
            if k == 'launch' or k == 'boost' then SendNUIMessage({ a = 'shot', k = 'launch', v = 1.0 })
            elseif k == 'portal_out' or k == 'portal_in' then SendNUIMessage({ a = 'shot', k = 'whoosh', v = 0.9 })
            elseif k == 'open' and stage == 'chain' then SendNUIMessage({ a = 'shot', k = 'sparkle', v = 0.9 })
            elseif k == 'trim' or k == 'brake' or k == 'otrim' then SendNUIMessage({ a = 'shot', k = 'brake', v = k == 'brake' and 0.9 or 0.6 })
            end
            stage = k
            nextEv = nextEv + 1
        end
        if GetGameTimer() - lastMix > 100 then
            lastMix = GetGameTimer()
            local v = R.v[i] or 0.0
            local under = R.under[i] == 1
            setUnder(under)
            local moving = tau > 0.2 and tau < R.duration
            local inPower = stage == 'launch' or stage == 'power'
            local inChain = stage == 'chain' or stage == 'portal_out'
            local run = moving and v > 0.6
            SendNUIMessage({ a = 'mix', l = {
                roar = { run and math.min(1.0, 0.3 + (v / 22.0) ^ 1.2 + (stage == 'loop' and 0.15 or 0.0)) or 0.0, 0.55 + v / 32.0, 0.0 },
                rattle = { run and math.min(0.85, 0.15 + v / 30.0) or 0.0, 0.8 + v / 60.0, 0.0 },
                roll = { moving and math.min(0.7, 0.15 + v / 30.0) or 0.0, 0.7 + v / 28.0, 0.0 },
                wind = { moving and math.min(1.0, (v / 26.0) ^ 1.5) * (under and 0.35 or 1.0) or 0.0, 0.8 + v / 60.0, 0.0 },
                power = { inPower and 0.55 or 0.0, 1.0, 0.0 },
                chain = { (inChain and v < 6.0) and 0.8 or 0.0, math.max(0.6, math.min(1.6, v / 4.5)), 0.0 },
                tunnel = { (under and moving) and 0.45 or 0.0, 1.0, 0.0 },
            } })
        end
        if tau >= R.duration + 0.6 then break end
        Wait(0)
    end
    SendNUIMessage({ a = 'shot', k = 'bell', v = 0.7 })
    SendNUIMessage({ a = 'stop' })
    DetachEntity(ped, true, false)
    SetEntityCoordsNoOffset(ped, R.exit[1], R.exit[2], R.exit[3], false, false, false)
    SetEntityHeading(ped, R.exit[4])
    SetEntityVisible(ped, true, false)
    SetEntityInvincible(ped, false)
    RenderScriptCams(false, true, 800, true, true)
    DestroyCam(cam, false)
    DeleteEntity(car)
    setUnder(false)
    riding = false
    TriggerServerEvent('olentrix_mpc_coaster:done')
end

local function watch(src, delay)
    local me = GetEntityCoords(PlayerPedId())
    if #(me - BOARD) > 700.0 then return end
    local car = newCar(0.0)
    if not car then return end
    local clone = sitClone(src, car)
    local t0 = GetGameTimer() + delay
    local nextEv, stage, lastMix = 1, 'station', 0
    while true do
        local tau = (GetGameTimer() - t0) / 1000.0
        if tau > R.duration + 0.6 then break end
        local p, i = place(car, math.max(0.0, tau))
        while nextEv <= #R.events and R.events[nextEv][1] <= tau do stage = R.events[nextEv][2]; nextEv = nextEv + 1 end
        if GetGameTimer() - lastMix > 100 then
            lastMix = GetGameTimer()
            local cp = GetFinalRenderedCamCoord()
            local cr = GetFinalRenderedCamRot(2)
            local d = #(p - cp)
            local v = R.v[i] or 0.0
            if riding or d > 230.0 or tau < 0.2 then
                SendNUIMessage({ a = 'mix', l = { xroar = { 0.0, 1.0 }, xrattle = { 0.0, 1.0 }, xchain = { 0.0, 1.0 } } })
            else
                local yaw = math.rad(cr.z)
                local rx, ry = math.cos(yaw), math.sin(yaw)
                local dx, dy = (p.x - cp.x) / math.max(d, 0.1), (p.y - cp.y) / math.max(d, 0.1)
                local pan = math.max(-0.9, math.min(0.9, dx * rx + dy * ry))
                local fall = math.max(0.0, 1.0 - d / 220.0) ^ 2
                local hid = (R.under[i] == 1) and 0.15 or 1.0
                local spd = math.min(1.0, v / 20.0)
                local inChain = (stage == 'chain' or stage == 'portal_out') and v < 6.0
                SendNUIMessage({ a = 'mix', l = {
                    xroar = { v > 0.6 and fall * (0.12 + 0.55 * spd) * hid or 0.0, 0.55 + v / 32.0, pan },
                    xrattle = { v > 1.5 and fall * 0.3 * spd * hid or 0.0, 0.8 + v / 60.0, pan },
                    xchain = { inChain and fall * 0.45 or 0.0, math.max(0.6, math.min(1.6, v / 4.5)), pan },
                } })
            end
        end
        Wait(0)
    end
    SendNUIMessage({ a = 'xstop' })
    if clone and DoesEntityExist(clone) then DeleteEntity(clone) end
    DeleteEntity(car)
end

RegisterNetEvent('olentrix_mpc_coaster:go', function(src, delay)
    lastGo = GetGameTimer()
    if parked then DeleteEntity(parked); parked = nil end
    if src == GetPlayerServerId(PlayerId()) then
        CreateThread(function() ride(delay) end)
    else
        CreateThread(function() watch(src, delay) end)
    end
end)

RegisterNetEvent('olentrix_mpc_coaster:wait', function(s)
    note(("The sleigh is on its way back - about %d s"):format(s))
end)

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local me = GetEntityCoords(ped)
        local d = #(me - BOARD)
        if d < 160.0 and not parked and GetGameTimer() - lastGo > 9000 then
            parked = newCar(0.0)
        elseif (d > 190.0 or GetGameTimer() - lastGo < 9000) and parked then
            DeleteEntity(parked); parked = nil
        end
        if not riding then
            local inside = (inPoly(me.x, me.y, R.hall.poly) and me.z > R.hall.z0 and me.z < R.hall.z1)
                or (inPoly(me.x, me.y, R.corridor.poly) and me.z > R.corridor.z0 and me.z < R.corridor.z1)
            setUnder(inside)
        end
        Wait(d < 6.0 and 0 or 500)
        if not riding and d < 2.2 and not IsPedInAnyVehicle(ped, false) then
            help("Press ~INPUT_CONTEXT~ to ride Santa's Sleigh Run")
            if IsControlJustReleased(0, 38) then
                TriggerServerEvent('olentrix_mpc_coaster:ask')
                Wait(1000)
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if parked then DeleteEntity(parked) end
    setUnder(false)
    if riding then
        local ped = PlayerPedId()
        DetachEntity(ped, true, false)
        SetEntityCoordsNoOffset(ped, BOARD.x, BOARD.y, BOARD.z, false, false, false)
        SetEntityVisible(ped, true, false)
        SetEntityInvincible(ped, false)
        RenderScriptCams(false, false, 0, true, true)
    end
end)
