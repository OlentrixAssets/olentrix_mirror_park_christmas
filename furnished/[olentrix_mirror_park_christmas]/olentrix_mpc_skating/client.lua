local C = Config
local K = C.Skate
local R = C.Rink
local DICT = 'xmas_skate'
local BONES = { { model = `xv_skate_l`, bone = 14201 }, { model = `xv_skate_r`, bone = 52301 } }

local skating, falling, busy = false, false, false
local h, d, s = 0.0, 0.0, 0.0
local cur, strideAt, strideSide, turnHeld, wobbleAt = nil, 0, 1, 0.0, nil
local lastPos = nil
local lastBase, lastV, playAt = nil, nil, 0
local stats = { t0 = 0, f = 0, dt = 0.0, snaps = 0, old = 0, drift = 0.0, lost = 0, clips = 0 }
local props = {}
local soundState = {}

local function help(text)
    BeginTextCommandDisplayHelp('STRING'); AddTextComponentSubstringPlayerName(text); EndTextCommandDisplayHelp(0, false, false, -1)
end

local function note(text)
    BeginTextCommandThefeedPost('STRING'); AddTextComponentSubstringPlayerName(text); EndTextCommandThefeedPostTicker(false, false)
end

local function loadDict(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local t = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < t do Wait(0) end
    return HasAnimDictLoaded(dict)
end

local function loadModel(m)
    if HasModelLoaded(m) then return true end
    RequestModel(m)
    local t = GetGameTimer() + 5000
    while not HasModelLoaded(m) and GetGameTimer() < t do Wait(0) end
    return HasModelLoaded(m)
end

local function sdf(x, y)
    local qx = math.abs(x - R.centre.x) - (R.halfX - R.corner)
    local qy = math.abs(y - R.centre.y) - (R.halfY - R.corner)
    local ox, oy = math.max(qx, 0.0), math.max(qy, 0.0)
    return math.sqrt(ox * ox + oy * oy) + math.min(math.max(qx, qy), 0.0) - R.corner
end

local function normal(x, y)
    local e = 0.05
    local nx, ny = sdf(x + e, y) - sdf(x - e, y), sdf(x, y + e) - sdf(x, y - e)
    local l = math.sqrt(nx * nx + ny * ny)
    if l < 1e-6 then return 0.0, 0.0 end
    return nx / l, ny / l
end

local function inGate(x, y)
    return math.abs(x - C.Gate.centre.x) < C.Gate.halfWidth and y > C.Gate.centre.y - 1.5 and y < C.Gate.centre.y + 2.0
end

local function onIce(p)
    local dz = p.z - R.iceZ
    return sdf(p.x, p.y) < -0.1 and dz > 0.6 and dz < 1.5
end

local function fwd(a)
    local r = math.rad(a)
    return -math.sin(r), math.cos(r)
end

local function angDiff(a, b)
    return (a - b + 540.0) % 360.0 - 180.0
end

local function wearing()
    return LocalPlayer.state.xmasSkates == true
end

local function play(clip, flag, blend)
    if cur == clip then return end
    cur = clip; playAt = GetGameTimer(); stats.clips = stats.clips + 1
    TaskPlayAnim(PlayerPedId(), DICT, clip, blend or 6.0, blend or 6.0, -1, flag, 0.0, false, false, false)
end

local function shot(name, gain, pan)
    SendNUIMessage({ t = 'shot', n = name, g = gain * C.Sound.volume, p = pan or 0.0 })
end

local function stopSkating(clear)
    if not skating then return end
    skating = false; cur = nil; wobbleAt = nil; lastBase = nil
    local ped = PlayerPedId()
    SetPedCanLegIk(ped, true)
    if clear then ClearPedTasks(ped) end
end

local function startSkating(ped)
    if not loadDict(DICT) then return end
    skating = true; cur = nil; wobbleAt = nil; turnHeld = 0.0
    h = GetEntityHeading(ped); d = h
    local v = GetEntityVelocity(ped); local fx, fy = fwd(h)
    s = v.x * fx + v.y * fy
    lastPos = GetEntityCoords(ped); lastBase = nil
    stats = { t0 = GetGameTimer(), f = 0, dt = 0.0, snaps = 0, old = 0, drift = 0.0, lost = 0, clips = 0 }
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
    SetPedCanLegIk(ped, false)
    play('glide', 1)
end

local function fall(vx, vy)
    local ped = PlayerPedId()
    stopSkating(false)
    falling = true
    SetPedToRagdoll(ped, 1800, 2400, 0, false, false, false)
    SetEntityVelocity(ped, vx * 0.8, vy * 0.8, 0.3)
    shot('stop', 0.8)
    CreateThread(function()
        local t = GetGameTimer() + 9000
        Wait(500)
        while (IsPedRagdoll(ped) or IsPedGettingUp(ped)) and GetGameTimer() < t do Wait(100) end
        falling = false
    end)
end

local DISABLE = { 21, 22, 23, 24, 25, 30, 31, 32, 33, 34, 35, 36, 37, 44, 45, 140, 141, 142, 143, 257, 263, 264 }

local function step(ped, dt)
    for _, c in ipairs(DISABLE) do DisableControlAction(0, c, true) end
    local W, S, A, D = IsDisabledControlPressed(0, 32), IsDisabledControlPressed(0, 33), IsDisabledControlPressed(0, 34), IsDisabledControlPressed(0, 35)
    local sprint = IsDisabledControlPressed(0, 21)
    local now = GetGameTimer()
    local p = GetEntityCoords(ped)

    if wobbleAt then
        play('wobble', 1, 8.0)
        if now - wobbleAt > K.wobbleTime then
            local fx, fy = fwd(d); fall(fx * s, fy * s); return
        end
    end

    local turn = (A and 1.0 or 0.0) - (D and 1.0 or 0.0)
    local rate = K.turnSlow - (K.turnSlow - K.turnFast) * math.min(1.0, math.abs(s) / K.sprint)
    h = (h + turn * rate * dt) % 360.0
    d = d + angDiff(h, d) * math.min(1.0, K.grip * dt)

    if turn ~= 0.0 and s > K.fallTurnSpeed then turnHeld = turnHeld + dt else turnHeld = 0.0 end
    if turnHeld > K.fallTurnTime and not wobbleAt then wobbleAt = now end

    local cap = sprint and K.sprint or K.cruise
    local braking = false
    if S and s > 0.6 then
        s = s - K.brake * dt; braking = true
    elseif S then
        s = s + math.max(-1.5 * dt, math.min(1.5 * dt, -K.backSpeed - s))
    elseif W then
        local len = K.stride * 1000 / (sprint and 1.15 or 1.0)
        if now - strideAt > len or (cur ~= 'push_l' and cur ~= 'push_r') then
            strideAt = now; strideSide = -strideSide
        end
        if (now - strideAt) < 0.55 * len and s < cap then
            s = math.min(cap, s + (sprint and K.pushSprint or K.push) * dt * (s < 0 and 2.0 or 1.0))
        end
    end
    if not W and not S or (W and s > cap) then
        local dec = (K.glideDecel + K.drag * s * s) * dt
        if s > 0 then s = math.max(0.0, s - dec) elseif s < 0 then s = math.min(0.0, s + dec) end
    end

    if not wobbleAt then
        if braking then
            if cur ~= 'stop' then shot('stop', math.min(1.0, s / 5.0)) end
            play('stop', 2, 8.0)
        elseif W and not S then
            local clip = strideSide > 0 and 'push_l' or 'push_r'
            if cur ~= clip then
                play(clip, 2, 6.0)
                if sprint then SetEntityAnimSpeed(ped, DICT, clip, 1.15) end
                shot('stride', math.min(1.0, 0.4 + s / 8.0))
            end
        else
            play('glide', 1, 4.0)
        end
    end

    local fx, fy = fwd(d)
    local vx, vy = fx * s, fy * s
    local bx, by, snap = p.x, p.y, false
    if lastBase then
        local ex, ey = lastBase.x + lastV.x * dt, lastBase.y + lastV.y * dt
        local drift = math.sqrt((p.x - ex) ^ 2 + (p.y - ey) ^ 2)
        if drift > stats.drift then stats.drift = drift end
        if drift > 0.6 then bx, by, snap = ex, ey, true end
    end
    local nx_, ny_ = bx + vx * dt, by + vy * dt
    local cx, cy = 0.0, 0.0

    if not inGate(nx_, ny_) or sdf(nx_, ny_) < -K.bodyRadius - 0.3 then
        local dist = sdf(nx_, ny_) + K.bodyRadius
        if dist > 0.0 then
            local nx, ny = normal(nx_, ny_)
            local vn = vx * nx + vy * ny
            if vn > K.fallSpeed then fall(vx, vy); return end
            if vn > 0 then
                vx, vy = vx - nx * vn, vy - ny * vn
                local sp = math.sqrt(vx * vx + vy * vy)
                if sp > 0.05 then d = math.deg(math.atan(-vx, vy)); if s < 0 then d = (d + 180.0) % 360.0 end end
                s = (s < 0 and -sp or sp) * 0.97
            end
            local corr = math.min(2.0, dist / math.max(dt, 0.016))
            cx, cy = -nx * corr, -ny * corr
            nx_, ny_ = nx_ - nx * dist, ny_ - ny * dist
        end
    end

    for _, pl in ipairs(GetActivePlayers()) do
        local op = GetPlayerPed(pl)
        if op ~= ped and DoesEntityExist(op) then
            local q = GetEntityCoords(op)
            local dx, dy = q.x - nx_, q.y - ny_
            local dd = math.sqrt(dx * dx + dy * dy)
            if dd < 0.75 and dd > 0.01 and math.abs(q.z - p.z) < 1.5 then
                local ov = GetEntityVelocity(op)
                local closing = ((vx - ov.x) * dx + (vy - ov.y) * dy) / dd
                if closing > K.bumpSpeed then fall(vx, vy); return end
                if closing > 0 then
                    vx, vy = vx - dx / dd * closing, vy - dy / dd * closing
                    s = s >= 0 and math.sqrt(vx * vx + vy * vy) or -math.sqrt(vx * vx + vy * vy)
                    nx_, ny_ = bx + vx * dt, by + vy * dt
                end
            end
        end
    end

    SetEntityHeading(ped, h)
    local vz = GetEntityVelocity(ped).z
    SetEntityVelocity(ped, vx + cx, vy + cy, vz)
    if snap then
        SetEntityCoordsNoOffset(ped, bx, by, p.z, false, false, false)
        stats.snaps = stats.snaps + 1
    end
    if #(vector2(p.x, p.y) - vector2(bx + vx * dt, by + vy * dt)) > 0.25 then stats.old = stats.old + 1 end
    stats.f = stats.f + 1
    if dt > stats.dt then stats.dt = dt end
    if cur and now - playAt > 300 and not IsEntityPlayingAnim(ped, DICT, cur, 3) then stats.lost = stats.lost + 1 end
    lastBase, lastV = vector2(bx, by), vector2(vx + cx, vy + cy)
    lastPos = vector3(bx, by, p.z)

    if inGate(nx_, ny_) and ny_ > C.Gate.centre.y + 0.2 then stopSkating(true) end
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if skating then
            local p = GetEntityCoords(ped)
            if not wearing() or IsPedInAnyVehicle(ped, false) or IsEntityDead(ped) or IsPedRagdoll(ped) or (lastPos and #(p - lastPos) > 3.0) or GlobalState.xmasIceShow == 'on' then
                stopSkating(not IsPedRagdoll(ped))
            else
                step(ped, GetFrameTime())
            end
            Wait(0)
        else
            if wearing() and not falling and not busy and GlobalState.xmasIceShow ~= 'on' and not IsPedInAnyVehicle(ped, false)
                and not IsPedRagdoll(ped) and not IsPedGettingUp(ped) and not IsEntityDead(ped) and onIce(GetEntityCoords(ped)) then
                startSkating(ped)
                Wait(0)
            else
                Wait(100)
            end
        end
    end
end)

local function inSpot(p)
    for _, sp in ipairs(C.ChangeSpots) do
        local r = math.rad(sp.heading)
        local dx, dy = p.x - sp.centre.x, p.y - sp.centre.y
        local lx, ly = dx * math.cos(r) + dy * math.sin(r), -dx * math.sin(r) + dy * math.cos(r)
        if math.abs(lx) < sp.half.x + 0.4 and math.abs(ly) < sp.half.y + 0.4 and math.abs(p.z - sp.centre.z) < 2.0 then return true end
    end
    return false
end

local function drawBar(label, frac)
    DrawRect(0.5, 0.88, 0.16, 0.026, 0, 0, 0, 160)
    DrawRect(0.5 - 0.078 + 0.078 * frac, 0.88, 0.156 * frac, 0.018, 240, 240, 245, 220)
    SetTextFont(4); SetTextScale(0.0, 0.36); SetTextCentre(true); SetTextOutline()
    BeginTextCommandDisplayText('STRING'); AddTextComponentSubstringPlayerName(label); EndTextCommandDisplayText(0.5, 0.848)
end

RegisterNetEvent('olentrix_mpc_skating:go', function(wantOn)
    if busy then return end
    busy = true
    local ped = PlayerPedId()
    local seated = IsPedUsingAnyScenario(ped)
    local knelt = false
    if not seated and loadDict(C.Kneel.dict) then
        TaskPlayAnim(ped, C.Kneel.dict, C.Kneel.clip, 4.0, 4.0, -1, 1, 0.0, false, false, false); knelt = true
    end
    local t0 = GetGameTimer(); local ok = true
    while GetGameTimer() - t0 < C.ChangeTime do
        if not inSpot(GetEntityCoords(ped)) or IsPedRagdoll(ped) or IsEntityDead(ped) then ok = false; break end
        drawBar(wantOn and C.Text.puttingOn or C.Text.takingOff, (GetGameTimer() - t0) / C.ChangeTime)
        Wait(0)
    end
    if knelt then StopAnimTask(ped, C.Kneel.dict, C.Kneel.clip, 2.0) end
    if ok then TriggerServerEvent('olentrix_mpc_skating:done', wantOn) end
    busy = false
end)

RegisterNetEvent('olentrix_mpc_skating:msg', function(k)
    if C.Text[k] then note(C.Text[k]) end
end)

CreateThread(function()
    local cooldown = 0
    while true do
        local ped = PlayerPedId()
        local p = GetEntityCoords(ped)
        local wait = 500
        if #(vector2(p.x, p.y) - R.centre) < 60.0 and not skating and not busy and not IsPedInAnyVehicle(ped, false) then
            wait = 0
            local now = GetGameTimer()
            if #(vector2(p.x, p.y) - vector2(C.Counter.pos.x, C.Counter.pos.y)) < C.Counter.reach and math.abs(p.z - C.Counter.pos.z) < 2.0 then
                help('~INPUT_CONTEXT~ ' .. C.Text.buy:format(C.Price))
                if IsControlJustPressed(0, 38) and now > cooldown then cooldown = now + 2000; TriggerServerEvent('olentrix_mpc_skating:buy') end
            elseif inSpot(p) and not onIce(p) then
                help('~INPUT_DETONATE~ ' .. (wearing() and C.Text.takeOff or C.Text.putOn))
                if IsControlJustPressed(0, 47) and now > cooldown then cooldown = now + 1500; TriggerServerEvent('olentrix_mpc_skating:ask', not wearing()) end
            end
        end
        Wait(wait)
    end
end)

CreateThread(function()
    while true do
        Wait(2000)
        if wearing() and not skating and not busy then
            local p = GetEntityCoords(PlayerPedId())
            if #(vector2(p.x, p.y) - R.centre) > C.KeepRange then
                TriggerServerEvent('olentrix_mpc_skating:done', false); note(C.Text.tookOff)
            end
        end
    end
end)

local function moveOff()
    local ped = PlayerPedId()
    stopSkating(true)
    DoScreenFadeOut(300); local t = GetGameTimer() + 1000
    while not IsScreenFadedOut() and GetGameTimer() < t do Wait(0) end
    SetEntityCoords(ped, C.ShowExit.x, C.ShowExit.y, C.ShowExit.z, false, false, false, false)
    SetEntityHeading(ped, C.ShowExit.w)
    Wait(200); DoScreenFadeIn(400)
    note(C.Text.showOn)
end

AddStateBagChangeHandler('xmasIceShow', 'global', function(_, _, value)
    if value == 'soon' then
        local p = GetEntityCoords(PlayerPedId())
        if sdf(p.x, p.y) < 1.0 or (wearing() and #(vector2(p.x, p.y) - R.centre) < 40.0) then note(C.Text.showSoon) end
    end
end)

CreateThread(function()
    while true do
        Wait(250)
        if GlobalState.xmasIceShow == 'on' then
            local ped = PlayerPedId()
            if not IsPedInAnyVehicle(ped, false) and onIce(GetEntityCoords(ped)) then moveOff() end
        end
    end
end)

local function clearProps(sid)
    for _, o in ipairs(props[sid] and props[sid].objs or {}) do if DoesEntityExist(o) then DeleteEntity(o) end end
    props[sid] = nil
end

CreateThread(function()
    while true do
        local me = GetEntityCoords(PlayerPedId())
        local seen = {}
        for _, pl in ipairs(GetActivePlayers()) do
            local sid = GetPlayerServerId(pl)
            local ped = GetPlayerPed(pl)
            if Player(sid).state.xmasSkates and DoesEntityExist(ped) and #(GetEntityCoords(ped) - me) < 120.0 then
                seen[sid] = true
                local pr = props[sid]
                if not pr or pr.ped ~= ped or not DoesEntityExist(pr.objs[1]) or not DoesEntityExist(pr.objs[2]) then
                    clearProps(sid)
                    local objs = {}
                    for i, b in ipairs(BONES) do
                        if loadModel(b.model) then
                            local o = CreateObjectNoOffset(b.model, me.x, me.y, me.z - 5.0, false, false, false)
                            SetEntityCollision(o, false, false)
                            AttachEntityToEntity(o, ped, GetPedBoneIndex(ped, b.bone), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                            objs[i] = o
                        end
                    end
                    props[sid] = { ped = ped, objs = objs }
                end
            end
        end
        for sid in pairs(props) do if not seen[sid] then clearProps(sid) end end
        Wait(500)
    end
end)

CreateThread(function()
    local was = {}
    while true do
        local cam = GetFinalRenderedCamCoord()
        local cr = GetFinalRenderedCamRot(2)
        local yaw = math.rad(cr.z)
        local rx, ry = math.cos(yaw), math.sin(yaw)
        local mix = {}
        local any = false
        for _, pl in ipairs(GetActivePlayers()) do
            local sid = GetPlayerServerId(pl)
            local ped = GetPlayerPed(pl)
            if Player(sid).state.xmasSkates and DoesEntityExist(ped) then
                local q = GetEntityCoords(ped)
                local dist = #(q - cam)
                if dist < C.Sound.range and onIce(q) then
                    any = true
                    local fade = 1.0 - dist / C.Sound.range
                    local dx, dy = q.x - cam.x, q.y - cam.y
                    local l = math.max(0.01, math.sqrt(dx * dx + dy * dy))
                    local pan = math.max(-1.0, math.min(1.0, (dx * rx + dy * ry) / l))
                    local v = GetEntityVelocity(ped)
                    local sp = math.sqrt(v.x * v.x + v.y * v.y)
                    mix[#mix + 1] = { id = sid, g = math.min(1.0, sp / 6.0) * fade * fade * C.Sound.volume, p = pan }
                    if pl ~= PlayerId() then
                        local st = was[sid] or {}
                        local pushing = IsEntityPlayingAnim(ped, DICT, 'push_l', 3) or IsEntityPlayingAnim(ped, DICT, 'push_r', 3)
                        local stopping = IsEntityPlayingAnim(ped, DICT, 'stop', 3)
                        local side = IsEntityPlayingAnim(ped, DICT, 'push_l', 3) and 'l' or 'r'
                        if pushing and (not st.pushing or st.side ~= side) then shot('stride', fade * fade * math.min(1.0, 0.4 + sp / 8.0), pan) end
                        if stopping and not st.stopping then shot('stop', fade * fade * math.min(1.0, sp / 5.0), pan) end
                        was[sid] = { pushing = pushing, stopping = stopping, side = side }
                    end
                end
            end
        end
        SendNUIMessage({ t = 'mix', l = mix })
        Wait(any and 100 or 1000)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for sid in pairs(props) do clearProps(sid) end
    if skating then stopSkating(true) end
end)
