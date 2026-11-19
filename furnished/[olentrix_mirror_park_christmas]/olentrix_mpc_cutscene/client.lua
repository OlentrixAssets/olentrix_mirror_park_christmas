local playing = false
local radarWas = nil
local savedPed = nil

local function restoreRadar()
    if radarWas ~= nil then
        DisplayRadar(radarWas)
        radarWas = nil
    end
end

local clock = nil

local function restoreClock()
    if clock and clock.applied then
        if clock.running then
            NetworkClearClockTimeOverride()
        else
            NetworkOverrideClockTime(clock.h, clock.m, clock.s)
        end
    end
    clock = nil
end

local loaded, started = false, false

RegisterNUICallback('loaded', function(_, cb) loaded = true cb('ok') end)
RegisterNUICallback('started', function(_, cb) started = true cb('ok') end)

local function notify(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, false)
end

local function loadModel(name)
    local h = joaat(name)
    if not IsModelInCdimage(h) then return nil end
    RequestModel(h)
    local limit = GetGameTimer() + 8000
    while not HasModelLoaded(h) and GetGameTimer() < limit do Wait(0) end
    return HasModelLoaded(h) and h or nil
end

local function smooth(u) return u * u * (3.0 - 2.0 * u) end

local function eased(u, ease)
    ease = ease or 0.5
    return u + (smooth(u) - u) * ease
end

local function lerp3(a, b, f) return a + (b - a) * f end

local function parkPed(ped, p)
    SetEntityCoordsNoOffset(ped, p.x, p.y, p.z, false, false, false)
end

local function normalise(v)
    local l = #v
    if l < 1e-6 then return v end
    return v / l
end

local tunnelLen, tunnelTotal = {}, 0.0
do
    local pts = Data.tunnel
    tunnelLen[1] = 0.0
    for i = 2, #pts do
        local a, b = pts[i - 1], pts[i]
        tunnelLen[i] = tunnelLen[i - 1] + #(vector3(b[1], b[2], b[3]) - vector3(a[1], a[2], a[3]))
    end
    tunnelTotal = tunnelLen[#pts]
end

local function tunnelAt(d)
    local pts = Data.tunnel
    d = math.max(0.0, math.min(tunnelTotal, d))
    for i = 2, #pts do
        if d <= tunnelLen[i] then
            local f = (d - tunnelLen[i - 1]) / math.max(tunnelLen[i] - tunnelLen[i - 1], 1e-6)
            local a, b = pts[i - 1], pts[i]
            return vector3(a[1] + (b[1] - a[1]) * f, a[2] + (b[2] - a[2]) * f, a[3] + (b[3] - a[3]) * f)
        end
    end
    local l = pts[#pts]
    return vector3(l[1], l[2], l[3])
end

local function carPose(tau)
    local c = Data.car
    local i = 1
    while i < #c - 1 and c[i + 1][1] <= tau do i = i + 1 end
    local a, b = c[i], c[i + 1]
    local f = math.max(0.0, math.min(1.0, (tau - a[1]) / math.max(b[1] - a[1], 1e-6)))
    local function at(k) return a[k] + (b[k] - a[k]) * f end
    local p = vector3(at(2), at(3), at(4))
    local fw = normalise(vector3(at(5), at(6), at(7)))
    local up = vector3(at(8), at(9), at(10))
    local rt = normalise(vector3(fw.y * up.z - fw.z * up.y, fw.z * up.x - fw.x * up.z, fw.x * up.y - fw.y * up.x))
    up = vector3(rt.y * fw.z - rt.z * fw.y, rt.z * fw.x - rt.x * fw.z, rt.x * fw.y - rt.y * fw.x)
    return p, fw, rt, up
end

local function shotPose(s, t)
    local u = math.max(0.0, math.min(1.0, (t - s.t0) / (s.t1 - s.t0)))
    local e = eased(u, s.ease)
    if s.orbit then
        local o = s.orbit
        local a = math.rad(o.a0 + (o.a1 - o.a0) * e)
        local pos = vector3(o.c.x + o.r * math.cos(a), o.c.y + o.r * math.sin(a), o.z0 + (o.z1 - o.z0) * e)
        return pos, vector3(o.c.x, o.c.y, o.lookz)
    elseif s.tunnel then
        local pos = tunnelAt(tunnelTotal * e)
        local d = tunnelTotal * e + s.ahead
        local ahead = tunnelAt(d)
        if d > tunnelTotal then
            local n = #Data.tunnel
            local q, r = Data.tunnel[n - 1], Data.tunnel[n]
            ahead = tunnelAt(tunnelTotal) + normalise(vector3(r[1] - q[1], r[2] - q[2], r[3] - q[3])) * (d - tunnelTotal)
        end
        return pos + vector3(0.0, 0.0, s.eye), ahead + vector3(0.0, 0.0, s.eye)
    end
    local pos = lerp3(s.from, s.to, e)
    local look
    if s.ahead then
        look = pos + normalise(s.to - s.from) * s.ahead
    else
        local l0 = s.look or s.to
        look = lerp3(l0, s.look2 or l0, e)
    end
    return pos, look
end

local function shotAt(t)
    for i, s in ipairs(Config.Shots) do
        if t >= s.t0 and t < s.t1 then return i, s end
    end
    return #Config.Shots, Config.Shots[#Config.Shots]
end

local function anchorOf(s)
    if s.anchor then return s.anchor end
    if s.orbit then return vector3(s.orbit.c.x, s.orbit.c.y, s.orbit.z0 - 1.0) end
    if s.tunnel then
        local p = Data.tunnel[1]
        return vector3(p[1], p[2], p[3])
    end
    return vector3(s.from.x, s.from.y, s.from.z - 1.0)
end

local function waitScene(p, ped, ms)
    SetFocusPosAndVel(p.x, p.y, p.z, 0.0, 0.0, 0.0)
    RequestCollisionAtCoord(p.x, p.y, p.z)
    NewLoadSceneStartSphere(p.x, p.y, p.z, 150.0, 0)
    local limit = GetGameTimer() + ms
    while GetGameTimer() < limit and not IsNewLoadSceneLoaded() do Wait(50) end
    NewLoadSceneStop()
end

local function run()
    if playing then return notify(Config.Text.busy) end
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then return notify(Config.Text.inVehicle) end
    playing = true
    loaded, started = false, false

    local savedPos, savedHeading = GetEntityCoords(ped), GetEntityHeading(ped)
    savedPed = { pos = savedPos, heading = savedHeading }
    local cam, car
    local extras = {}
    local yeti

    local function cleanup()
        if cam then
            RenderScriptCams(false, false, 0, true, true)
            SetCamActive(cam, false)
            DestroyCam(cam, false)
            cam = nil
        end
        SendNUIMessage({ t = 'stop' })
        NewLoadSceneStop()
        ClearFocus()
        ClearTimecycleModifier()
        ClearOverrideWeather()
        if yeti and DoesEntityExist(yeti) then DeleteEntity(yeti) end
        if car and DoesEntityExist(car) then DeleteEntity(car) end
        ped = PlayerPedId()
        SetEntityCoordsNoOffset(ped, savedPos.x, savedPos.y, savedPos.z, false, false, false)
        SetEntityHeading(ped, savedHeading)
        RequestCollisionAtCoord(savedPos.x, savedPos.y, savedPos.z)
        local limit = GetGameTimer() + 4000
        while GetGameTimer() < limit and not HasCollisionLoadedAroundEntity(ped) do Wait(50) end
        FreezeEntityPosition(ped, false)
        SetEntityCollision(ped, true, true)
        SetEntityVisible(ped, true, false)
        NetworkSetEntityInvisibleToNetwork(ped, false)
        SetEntityInvincible(ped, false)
        restoreRadar()
        restoreClock()
        LocalPlayer.state:set('xmasCutscene', false, false)
        savedPed = nil
        DoScreenFadeIn(600)
        playing = false
    end

    local ok, err = pcall(function()
        DoScreenFadeOut(600)
        while not IsScreenFadedOut() do Wait(0) end

        FreezeEntityPosition(ped, true)
        SetEntityCollision(ped, false, false)
        SetEntityVisible(ped, false, false)
        NetworkSetEntityInvisibleToNetwork(ped, true)
        SetEntityInvincible(ped, true)
        radarWas = not IsRadarHidden()
        LocalPlayer.state:set('xmasCutscene', true, false)
        DisplayRadar(false)
        clock = { h = GetClockHours(), m = GetClockMinutes(), s = GetClockSeconds(), t = GetGameTimer(), applied = false, running = false }

        CreateThread(function()
            while playing do
                DisplayRadar(false)
                HideHudAndRadarThisFrame()
                for i = 1, 22 do HideHudComponentThisFrame(i) end
                DisableAllControlActions(0)
                Wait(0)
            end
        end)

        SendNUIMessage({ t = 'load', file = 'audio/song.mp3' })

        local lair = Config.Lair
        local lo = lair.origin
        parkPed(ped, lo)
        waitScene(lo, ped, 5000)
        local ym = loadModel(lair.model)
        RequestAnimDict(lair.anim.dict)
        local limit = GetGameTimer() + 4000
        while not HasAnimDictLoaded(lair.anim.dict) and GetGameTimer() < limit do Wait(50) end
        if ym then
            yeti = CreatePed(4, ym, lo.x + lair.pos.x, lo.y + lair.pos.y, lo.z + lair.pos.z, lair.pos.w, false, true)
            SetModelAsNoLongerNeeded(ym)
            if yeti ~= 0 then
                SetEntityAsMissionEntity(yeti, true, true)
                SetEntityInvincible(yeti, true)
                SetBlockingOfNonTemporaryEvents(yeti, true)
                SetPedCanRagdoll(yeti, false)
                SetPedFleeAttributes(yeti, 0, false)
                FreezeEntityPosition(yeti, true)
                SetEntityCoordsNoOffset(yeti, lo.x + lair.pos.x, lo.y + lair.pos.y, lo.z + lair.pos.z, false, false, false)
                SetEntityHeading(yeti, lair.pos.w)
                TaskPlayAnim(yeti, lair.anim.dict, lair.anim.clip, 4.0, -4.0, -1, lair.anim.flag, 0.0, false, false, false)
                local waitCol = GetGameTimer() + 3000
                while GetGameTimer() < waitCol and not HasCollisionLoadedAroundEntity(yeti) do
                    RequestAdditionalCollisionAtCoord(lo.x, lo.y, lo.z)
                    Wait(0)
                end
            else
                yeti = nil
            end
        end

        local cm = loadModel(Config.Car.model)
        if cm then
            local cp = carPose(Config.Car.start)
            car = CreateObjectNoOffset(cm, cp.x, cp.y, cp.z, false, false, false)
            SetModelAsNoLongerNeeded(cm)
            SetEntityCollision(car, false, false)
            SetEntityLodDist(car, 500)
            FreezeEntityPosition(car, true)
            SetEntityVisible(car, false, false)
        end

        local lg = Config.Legion
        parkPed(ped, lg)
        waitScene(lg, ped, 5000)

        local lastShot = 0
        local anchors = {}
        for j, shot in ipairs(Config.Shots) do
            if j > 1 then
                local at = shot.anchorAt or Config.Shots[math.max(1, j - (shot.lead or 1))].t0
                anchors[#anchors + 1] = { t = at, j = j }
            end
        end
        table.sort(anchors, function(a, b) if a.t == b.t then return a.j < b.j end return a.t < b.t end)
        local nextAnchor = 1
        local nextFade = 1
        local preloaded, loadScene = 0, false

        cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        local pos, look = shotPose(Config.Shots[1], 0.0)
        SetCamCoord(cam, pos.x, pos.y, pos.z)
        PointCamAtCoord(cam, look.x, look.y, look.z)
        SetCamFov(cam, Config.Shots[1].fov or Config.Fov)
        SetCamActive(cam, true)
        RenderScriptCams(true, false, 0, true, true)
        parkPed(ped, anchorOf(Config.Shots[1]))
        waitScene(pos, ped, 4000)

        local wait = GetGameTimer() + 8000
        while not loaded and GetGameTimer() < wait do Wait(50) end

        local since = GetGameTimer() - clock.t
        if since < 2600 then Wait(2600 - since) end
        clock.running = (GetClockHours() ~= clock.h) or (GetClockMinutes() ~= clock.m)
        NetworkOverrideClockTime(Config.Night.hour, Config.Night.minute, 0)
        clock.applied = true

        started = false
        SendNUIMessage({ t = 'play', file = 'audio/song.mp3' })
        wait = GetGameTimer() + 4000
        while not started and GetGameTimer() < wait do Wait(0) end
        local t0 = GetGameTimer()
        DoScreenFadeIn(300)
        lastShot = 1

        while true do
            local t = (GetGameTimer() - t0) / 1000.0
            if t >= Config.Length then break end
            if IsDisabledControlJustPressed(0, Config.SkipControl) then break end
            local i, s = shotAt(t)
            while anchors[nextAnchor] and t >= anchors[nextAnchor].t do
                parkPed(ped, anchorOf(Config.Shots[anchors[nextAnchor].j]))
                nextAnchor = nextAnchor + 1
            end
            while Config.Fades[nextFade] and t >= Config.Fades[nextFade].t do
                local f = Config.Fades[nextFade]
                if f.out then DoScreenFadeOut(f.out) else DoScreenFadeIn(f.inn) end
                nextFade = nextFade + 1
            end
            if i ~= lastShot then
                local prev = lastShot
                lastShot = i
                if loadScene then
                    NewLoadSceneStop()
                    loadScene = false
                end
                if i == Config.Lair.shot then
                    SetTimecycleModifier(Config.Lair.timecycle)
                    SetTimecycleModifierStrength(1.0)
                    SetOverrideWeather('EXTRASUNNY')
                elseif prev == Config.Lair.shot then
                    ClearTimecycleModifier()
                    ClearOverrideWeather()
                end
            end
            local p, l = shotPose(s, t)
            SetFocusPosAndVel(p.x, p.y, p.z, 0.0, 0.0, 0.0)
            local nxt = Config.Shots[i + 1]
            if nxt and preloaded ~= i + 1 and t >= (s.preloadAt or (s.t1 - Config.PreloadLead)) then
                local np = shotPose(nxt, nxt.t0)
                if #(np - p) > Config.PreloadFar then
                    if loadScene then NewLoadSceneStop() end
                    NewLoadSceneStartSphere(np.x, np.y, np.z, 100.0, 0)
                    loadScene = true
                end
                preloaded = i + 1
            end
            if car then
                if s.car then
                    local cp, fw, rt, up = carPose(Config.Car.start + (t - s.t0))
                    SetEntityMatrix(car, fw.x, fw.y, fw.z, rt.x, rt.y, rt.z, up.x, up.y, up.z, cp.x, cp.y, cp.z)
                    SetEntityVisible(car, true, false)
                    l = cp + up * 0.6
                else
                    SetEntityVisible(car, false, false)
                end
            end
            SetCamCoord(cam, p.x, p.y, p.z)
            PointCamAtCoord(cam, l.x, l.y, l.z)
            SetCamFov(cam, s.fov or Config.Fov)
            Wait(0)
        end
        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do Wait(0) end
    end)

    if not ok then print('[olentrix_mpc_cutscene] error: ' .. tostring(err)) end
    cleanup()
end

RegisterCommand(Config.Command, function() CreateThread(run) end, false)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() or not playing then return end
    RenderScriptCams(false, false, 0, true, true)
    ClearFocus()
    ClearTimecycleModifier()
    ClearOverrideWeather()
    restoreClock()
    LocalPlayer.state:set('xmasCutscene', false, false)
    local ped = PlayerPedId()
    if savedPed then
        SetEntityCoordsNoOffset(ped, savedPed.pos.x, savedPed.pos.y, savedPed.pos.z, false, false, false)
        SetEntityHeading(ped, savedPed.heading)
        RequestCollisionAtCoord(savedPed.pos.x, savedPed.pos.y, savedPed.pos.z)
        local limit = GetGameTimer() + 1500
        while GetGameTimer() < limit and not HasCollisionLoadedAroundEntity(ped) do Wait(0) end
        savedPed = nil
    end
    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, true, true)
    SetEntityVisible(ped, true, false)
    NetworkSetEntityInvisibleToNetwork(ped, false)
    SetEntityInvincible(ped, false)
    restoreRadar()
    DoScreenFadeIn(300)
end)
