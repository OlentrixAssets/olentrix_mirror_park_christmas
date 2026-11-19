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
        TriggerServerEvent('olentrix_mpc_legion_coaster:done')
        return
    end
    riding = true
    if parked then DeleteEntity(parked); parked = nil end
    local car = newCar(0.0)
    if not car then riding = false; TriggerServerEvent('olentrix_mpc_legion_coaster:done'); return end
    SetEntityInvincible(ped, true)
    ClearPedTasksImmediately(ped)
    AttachEntityToEntity(ped, car, 0, 0.0, -0.5, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
    SetEntityVisible(ped, false, false)
    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamFov(cam, 72.0)
    local yaw, pit = 0.0, 0.0
    HardAttachCamToEntity(cam, car, pit, 0.0, yaw, 0.0, -0.35, 1.45, true)
    RenderScriptCams(true, true, 700, true, true)
    local snd = CSND.new(R, pose, function(m) SendNUIMessage(m) end, { rev = 0.6 })
    snd:prep()
    SendNUIMessage({ a = 'shot', k = 'bell', v = 0.9 })
    local t0 = GetGameTimer() + delay
    while true do
        local tau = (GetGameTimer() - t0) / 1000.0
        if tau < 0 then tau = 0 end
        local p, i = place(car, tau)
        DisableAllControlActions(0)
        EnableControlAction(0, 245, true); EnableControlAction(0, 249, true); EnableControlAction(0, 199, true); EnableControlAction(0, 200, true)
        yaw = math.max(-115.0, math.min(115.0, yaw - GetDisabledControlNormal(0, 1) * 6.0))
        pit = math.max(-55.0, math.min(35.0, pit - GetDisabledControlNormal(0, 2) * 6.0))
        HardAttachCamToEntity(cam, car, pit, 0.0, yaw, 0.0, -0.35, 1.45, true)
        setUnder(R.under[i] == 1)
        snd:rider(tau)
        if tau >= R.duration + 0.6 then break end
        Wait(0)
    end
    SendNUIMessage({ a = 'shot', k = 'bell', v = 0.7 })
    snd:stop('r')
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
    TriggerServerEvent('olentrix_mpc_legion_coaster:done')
end

local nextScream = 0

local function ventLevel(p, cp)
    local best, bx, by = 0.0, 0.0, 0.0
    for _, g in ipairs(R.vents or {}) do
        local dh = #(vector2(p.x, p.y) - vector2(g[1], g[2]))
        if dh < 18.0 then
            local dl = #(cp - vector3(g[1], g[2], g[3]))
            if dl < 26.0 then
                local lv = ((1.0 - dh / 18.0) ^ 1.5) * ((1.0 - dl / 26.0) ^ 2) * g[4]
                if lv > best then best, bx, by = lv, g[1], g[2] end
            end
        end
    end
    return math.min(1.0, best), bx, by
end

local function watch(src, delay)
    local me = GetEntityCoords(PlayerPedId())
    if #(me - BOARD) > 700.0 then return end
    local car = newCar(0.0)
    if not car then return end
    local clone = sitClone(src, car)
    local snd = CSND.new(R, pose, function(m) SendNUIMessage(m) end, { id = src, rev = 0.6 })
    snd:prep()
    local vbus = 'v' .. tostring(src)
    local lastVent = 0
    local t0 = GetGameTimer() + delay
    while true do
        local tau = (GetGameTimer() - t0) / 1000.0
        if tau > R.duration + 0.6 then break end
        local p, i = place(car, math.max(0.0, tau))
        local cp = GetFinalRenderedCamCoord()
        local cr = GetFinalRenderedCamRot(2)
        if riding or tau < 0.2 or #(p - cp) > 230.0 then
            snd:quiet(tau)
        else
            snd:watch(tau, cp, cr)
        end
        if GetGameTimer() - lastVent > 100 then
            lastVent = GetGameTimer()
            local v = R.v[i] or 0.0
            local vl, vx, vy = 0.0, 0.0, 0.0
            if not riding and tau >= 0.2 then vl, vx, vy = ventLevel(p, cp) end
            local vpan = 0.0
            if vl > 0.0 then
                local yw = math.rad(cr.z)
                local dv = math.max(#(vector2(vx, vy) - vector2(cp.x, cp.y)), 0.1)
                vpan = math.max(-0.8, math.min(0.8, ((vx - cp.x) * math.cos(yw) + (vy - cp.y) * math.sin(yw)) / dv))
                local sp = math.min(1.0, v / 20.0)
                if vl * sp > 0.18 and v > 12.0 and GetGameTimer() > nextScream then
                    nextScream = GetGameTimer() + math.random(2600, 4200)
                    SendNUIMessage({ a = 'shot', k = 'scream' .. math.random(1, 4), v = math.min(0.75, vl * sp * 1.1) })
                end
            end
            SendNUIMessage({ a = 'mix', b = vbus, l = { vent = { vl * (0.3 + 0.7 * math.min(1.0, v / 20.0)), 0.8 + v / 50.0, vpan } } })
        end
        Wait(0)
    end
    snd:stop('x' .. tostring(src))
    SendNUIMessage({ a = 'stop', b = vbus })
    if clone and DoesEntityExist(clone) then DeleteEntity(clone) end
    DeleteEntity(car)
end

RegisterNetEvent('olentrix_mpc_legion_coaster:go', function(src, delay)
    lastGo = GetGameTimer()
    if parked then DeleteEntity(parked); parked = nil end
    if src == GetPlayerServerId(PlayerId()) then
        CreateThread(function() ride(delay) end)
    else
        CreateThread(function() watch(src, delay) end)
    end
end)

RegisterNetEvent('olentrix_mpc_legion_coaster:wait', function(s)
    note(("The next car is on its way - about %d s"):format(s))
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
            help("Press ~INPUT_CONTEXT~ to ride The Legion Plunge")
            if IsControlJustReleased(0, 38) then
                TriggerServerEvent('olentrix_mpc_legion_coaster:ask')
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
