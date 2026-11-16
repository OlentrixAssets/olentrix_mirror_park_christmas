local R = Routine
local show = nil
local skaters = {}
local calib = {}
local busy = 0
local soonUntil = 0
local kitOk = false

local rinkH = math.rad(Config.Rink.heading)
local cosH, sinH = math.cos(rinkH), math.sin(rinkH)
local origin = Config.Rink.origin
local iceZ = origin.z + Config.Rink.iceTop

local function world(x, y, z)
    return vector3(origin.x + x * cosH - y * sinH, origin.y + x * sinH + y * cosH, origin.z + z)
end

local function showTime()
    if not show then return nil end
    return (GetGameTimer() - show.t0) / 1000.0
end

local function sample(track, t)
    local n = #track // 4
    local f = t / R.dt
    local i = math.floor(f)
    if i < 0 then i, f = 0, 0 end
    if i >= n - 1 then i, f = n - 2, n - 1 end
    local a, b = f - i, i * 4
    local function at(k) return track[b + k] + (track[b + 4 + k] - track[b + k]) * a end
    return at(1), at(2), at(3), at(4)
end

local function moveIndex(moves, t)
    local idx = 1
    for k = 1, #moves do
        if t >= moves[k][1] then idx = k else break end
    end
    return idx
end

local function notify(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, false)
end

local function help(msg)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function label(p, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextCentre(true)
    SetTextOutline()
    SetTextColour(255, 255, 255, 215)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(p.x, p.y, p.z, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

local function loadModel(name)
    local h = joaat(name)
    if not IsModelInCdimage(h) then return nil end
    RequestModel(h)
    local limit = GetGameTimer() + 10000
    while not HasModelLoaded(h) and GetGameTimer() < limit do Wait(0) end
    return HasModelLoaded(h) and h or nil
end

local function loadDicts()
    for _, p in pairs(R.poses) do RequestAnimDict(p.dict) end
    local limit = GetGameTimer() + 10000
    for _, p in pairs(R.poses) do
        while not HasAnimDictLoaded(p.dict) and GetGameTimer() < limit do Wait(0) end
    end
    kitOk = HasAnimDictLoaded('xmas_skate')
end

local function spawn(key, t)
    local s = Config.Skaters[key]
    local model = loadModel(s.model)
    if not model then return nil end
    local x, y, _, h = sample(R.skaters[key].track, t)
    local p = world(x, y, Config.Rink.iceTop)
    local ped = CreatePed(4, model, p.x, p.y, p.z + 1.2, (h + Config.Rink.heading) % 360.0, false, true)
    SetModelAsNoLongerNeeded(model)
    if ped == 0 then return nil end
    SetEntityAsMissionEntity(ped, true, true)
    SetPedDefaultComponentVariation(ped)
    for _, c in ipairs(s.components) do SetPedComponentVariation(ped, c[1], c[2], c[3], 0) end
    ClearAllPedProps(ped)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCanBeTargetted(ped, false)
    SetPedKeepTask(ped, true)
    if not calib[key] then
        SetEntityVisible(ped, false, false)
        local limit, last, still = GetGameTimer() + 1500, -1.0, 0
        Wait(100)
        while GetGameTimer() < limit and DoesEntityExist(ped) do
            local z = GetEntityCoords(ped).z
            if math.abs(z - last) < 0.002 then
                still = still + 1
                if still > 5 then break end
            else
                still = 0
            end
            last = z
            Wait(30)
        end
        local off = DoesEntityExist(ped) and (GetEntityCoords(ped).z - iceZ) or 0
        calib[key] = (off > 0.85 and off < 1.15) and off or Config.StandHeight
        SetEntityVisible(ped, true, false)
    end
    FreezeEntityPosition(ped, true)
    SetEntityCollision(ped, false, false)
    SetPedCanLegIk(ped, false)
    return ped
end

local function addSkates(ped)
    local objs = {}
    for _, m in ipairs(Config.Skates.models) do
        local h = loadModel(m[1])
        if not h then
            for _, o in ipairs(objs) do DeleteEntity(o) end
            return nil
        end
        local p = GetEntityCoords(ped)
        local o = CreateObjectNoOffset(h, p.x, p.y, p.z - 5.0, false, false, false)
        SetModelAsNoLongerNeeded(h)
        SetEntityCollision(o, false, false)
        AttachEntityToEntity(o, ped, GetPedBoneIndex(ped, m[2]), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
        objs[#objs + 1] = o
    end
    return objs
end

local function clearSkaters()
    for key, st in pairs(skaters) do
        for _, o in ipairs(st.skates or {}) do
            if DoesEntityExist(o) then DeleteEntity(o) end
        end
        if DoesEntityExist(st.ped) then DeleteEntity(st.ped) end
        skaters[key] = nil
    end
end

local function play(st, t)
    local mv = R.skaters[st.key].moves[st.move]
    local p = R.poses[mv[2]]
    if p.dict == 'xmas_skate' and not kitOk then p = R.poses.glide end
    TaskPlayAnim(st.ped, p.dict, p.clip, 2.0, 2.0, -1, p.flag, 0.0, false, false, false)
    st.arms = false
    st.pose = p
    st.seek = nil
    if p.flag == 0 and t - mv[1] > 0.25 then st.seek = t - mv[1] end
end

local function updateSkaters(t)
    for key, st in pairs(skaters) do
        local x, y, z, h = sample(R.skaters[key].track, t)
        local w = world(x, y, Config.Rink.iceTop + calib[key] + st.lift + z)
        SetEntityCoordsNoOffset(st.ped, w.x, w.y, w.z, false, false, false)
        SetEntityHeading(st.ped, (h + Config.Rink.heading) % 360.0)
        local mi = moveIndex(R.skaters[key].moves, t)
        if mi ~= st.move then
            st.move = mi
            play(st, t)
        elseif st.seek and IsEntityPlayingAnim(st.ped, st.pose.dict, st.pose.clip, 3) then
            local dur = GetAnimDuration(st.pose.dict, st.pose.clip)
            if dur and dur > 0 then SetEntityAnimCurrentTime(st.ped, st.pose.dict, st.pose.clip, math.min(0.99, st.seek / dur)) end
            st.seek = nil
        elseif st.pose and st.pose.flag ~= 0 and GetGameTimer() > (st.check or 0) then
            st.check = GetGameTimer() + 1000
            if not IsEntityPlayingAnim(st.ped, st.pose.dict, st.pose.clip, 3) then play(st, t) end
        end
        local arms = false
        for _, span in ipairs(R.skaters[key].arms) do
            if t >= span[1] and t < span[2] then arms = true break end
        end
        if arms and kitOk and not st.arms and st.pose and st.pose.dict == 'xmas_skate' then
            TaskPlayAnim(st.ped, R.arms.dict, R.arms.clip, 4.0, 4.0, -1, 49, 0.0, false, false, false)
            st.arms = true
        elseif not arms and st.arms then
            ClearPedSecondaryTask(st.ped)
            st.arms = false
        end
        if t > R.fade[1] then
            local a = math.max(0, 1 - (t - R.fade[1]) / (R.fade[2] - R.fade[1]))
            SetEntityAlpha(st.ped, math.floor(255 * a), false)
            for _, o in ipairs(st.skates or {}) do SetEntityAlpha(o, math.floor(255 * a), false) end
        end
    end
end

local function smooth(u)
    u = math.max(0.0, math.min(1.0, u))
    return u * u * (3 - 2 * u)
end

local function drawLights(t)
    local L = Config.Lights
    local c = L.colour
    local cu = R.cues
    if t >= cu.finale[1] and t < cu.finale[2] then
        c = L.finale[math.floor((t - cu.finale[1]) / cu.bar) % #L.finale + 1]
    end
    local level = smooth(t / 1.5)
    if t > cu.out[1] then level = 1 - smooth((t - cu.out[1]) / (cu.out[2] - cu.out[1])) end
    if level <= 0 then return end
    local sweep = smooth((t - cu.lights[1]) / (cu.lights[2] - cu.lights[1]))
    for k, pole in ipairs(L.poles) do
        local st = skaters[pole.follow]
        local from = world(pole.pos.x, pole.pos.y, Config.Rink.iceTop + pole.pos.z)
        local target
        if st and DoesEntityExist(st.ped) then
            target = GetEntityCoords(st.ped) - vector3(0.0, 0.0, 0.3)
        else
            target = world(0.0, 0.0, Config.Rink.iceTop + 0.5)
        end
        if sweep < 1.0 then
            local a = math.rad(k * 90.0 + t * 60.0)
            local roam = world(math.cos(a) * 9.0, math.sin(a) * 5.0, Config.Rink.iceTop)
            target = roam + (target - roam) * sweep
        end
        local d = target - from
        local n = #d
        if n > 0.01 then
            d = d / n
            DrawSpotLight(from.x, from.y, from.z, d.x, d.y, d.z, c[1], c[2], c[3], L.distance, L.brightness * level, L.hardness, L.radius, L.falloff)
        end
    end
end

local lastMix, mixAt = nil, 0
local function mixAudio()
    local cam = GetFinalRenderedCamCoord()
    local src = world(0.0, 0.0, Config.Rink.iceTop + 2.0)
    local d = #(cam - src)
    local S = Config.Sound
    local g = 0.0
    if d < S.far then g = S.volume * (d <= S.near and 1.0 or (1 - (d - S.near) / (S.far - S.near)) ^ 1.5) end
    local rot = GetFinalRenderedCamRot(2)
    local h = math.rad(rot.z)
    local dir = src - cam
    local flat = math.sqrt(dir.x * dir.x + dir.y * dir.y)
    local p = 0.0
    if flat > 1.0 then p = (dir.x * math.cos(h) + dir.y * math.sin(h)) / flat * math.min(1.0, flat / 12.0) * 0.6 end
    local key = string.format('%.2f %.2f', g, p)
    if key ~= lastMix then
        lastMix = key
        SendNUIMessage({ t = 'mix', g = g, p = p })
    end
end

local function endShow()
    show = nil
    clearSkaters()
    SendNUIMessage({ t = 'stop' })
    SendNUIMessage({ t = 'mix', g = 0.0, p = 0.0 })
    lastMix = nil
end

RegisterNetEvent('olentrix_mpc_iceshow:play', function(elapsed)
    show = { t0 = GetGameTimer() - (elapsed or 0) }
    lastMix = nil
    SendNUIMessage({ t = 'play', file = Config.Sound.file, at = (elapsed or 0) / 1000.0 })
end)

RegisterNetEvent('olentrix_mpc_iceshow:soon', function(ms)
    soonUntil = GetGameTimer() + (ms or 0)
end)

RegisterNetEvent('olentrix_mpc_iceshow:notice', function(msg)
    if type(msg) == 'string' then notify(msg) end
end)

CreateThread(function()
    TriggerServerEvent('olentrix_mpc_iceshow:sync')
    while true do
        local t = showTime()
        if not t then
            Wait(500)
        elseif t >= R.length then
            endShow()
        else
            local near = #(GetFinalRenderedCamCoord() - origin) < Config.ShowRange
            if near then
                if (not skaters.her or not skaters.him) and GetGameTimer() > busy then
                    busy = GetGameTimer() + 5000
                    loadDicts()
                    for _, key in ipairs({ 'her', 'him' }) do
                        if not skaters[key] then
                            local ped = spawn(key, showTime() or t)
                            if ped then
                                local objs = addSkates(ped)
                                skaters[key] = { key = key, ped = ped, move = 0, skates = objs, lift = objs and Config.Skates.lift or 0.0 }
                            end
                        end
                    end
                end
                t = showTime()
                if t and t < R.length then
                    updateSkaters(t)
                    drawLights(t)
                end
            elseif next(skaters) then
                clearSkaters()
            end
            if GetGameTimer() > mixAt then
                mixAt = GetGameTimer() + 100
                mixAudio()
            end
            Wait(0)
        end
    end
end)

CreateThread(function()
    local debounce = 0
    local start = Config.Start
    while true do
        local wait = 1000
        local d = #(GetEntityCoords(PlayerPedId()) - start.position)
        if d < start.labelRange then
            wait = 0
            local soonLeft = math.ceil((soonUntil - GetGameTimer()) / 1000)
            local soon = GlobalState.xmasIceShow == 'soon' and soonLeft > 0
            label(start.position + vector3(0.0, 0.0, start.labelHeight), soon and Config.Text.soon:format(soonLeft) or Config.Text.label)
            if d < start.reach then
                local left = (GlobalState.xmasIceShowNext or 0) - GetCloudTimeAsInt()
                if show then
                    help(Config.Text.running)
                elseif GlobalState.xmasIceShow == 'soon' then
                    help(Config.Text.soon:format(math.max(0, soonLeft)))
                elseif left > 0 then
                    help(Config.Text.cooldown:format(math.ceil(left / 60)))
                else
                    help(Config.Text.prompt)
                    if IsControlJustReleased(0, start.key) and GetGameTimer() > debounce then
                        debounce = GetGameTimer() + 3000
                        TriggerServerEvent('olentrix_mpc_iceshow:start')
                    end
                end
            end
        end
        Wait(wait)
    end
end)

exports('isRunning', function() return show ~= nil end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    clearSkaters()
    SendNUIMessage({ t = 'stop' })
end)
