local CER = Config.Ceremony
local passK = 0.0
local kP, kG = 0.0, 0.0
local zoneFiles, mixKeys = {}, { 'music', 'bells', 'fire', 'cer' }
for k, s in pairs(Config.ZoneSounds or {}) do zoneFiles[k] = s.file; mixKeys[#mixKeys + 1] = k end
table.sort(mixKeys)

local function ss(a, b, t)
    if t <= a then return 0.0 elseif t >= b then return 1.0 end
    local x = (t - a) / (b - a); return x * x * (3.0 - 2.0 * x)
end

local function camPos() return GetFinalRenderedCamCoord() end

local TR, W = Config.Train.track, Config.Workshop
local LEN = 4.0 * TR.a + 2.0 * math.pi * TR.r
local cw, sw = math.cos(math.rad(W.heading)), math.sin(math.rad(W.heading))
local cars = {}

local function trackAt(s)
    s = s % LEN
    local a, r, cx, cy = TR.a, TR.r, TR.cx, TR.cy
    if s < 2.0 * a then return cx - a + s, cy - r end
    s = s - 2.0 * a
    if s < math.pi * r then local t = -math.pi / 2 + s / r; return cx + a + r * math.cos(t), cy + r * math.sin(t) end
    s = s - math.pi * r
    if s < 2.0 * a then return cx + a - s, cy + r end
    s = s - 2.0 * a
    local t = math.pi / 2 + s / r; return cx - a + r * math.cos(t), cy + r * math.sin(t)
end

local function toWorld(x, y) return W.pos.x + x * cw - y * sw, W.pos.y + x * sw + y * cw end

local function loadModel(name)
    local h = joaat(name)
    if not IsModelValid(h) then return nil end
    RequestModel(h)
    local n = 0
    while not HasModelLoaded(h) and n < 300 do Wait(10); n = n + 1 end
    return HasModelLoaded(h) and h or nil
end

local function spawnTrain()
    for i, c in ipairs(Config.Train.cars) do
        local h = loadModel(c.model)
        if h then
            local o = CreateObjectNoOffset(h, W.pos.x, W.pos.y, W.pos.z + TR.z, false, false, false)
            FreezeEntityPosition(o, true); SetEntityCollision(o, false, false)
            cars[i] = o
        end
    end
end

local function despawnTrain()
    for i, o in pairs(cars) do if DoesEntityExist(o) then DeleteObject(o) end; cars[i] = nil end
end

local function moveTrain()
    local head = (GetGameTimer() / 1000.0 * Config.Train.speed) % LEN
    local s = head
    for i, c in ipairs(Config.Train.cars) do
        s = s - c.gap
        local o = cars[i]
        if o then
            local x1, y1 = trackAt(s + 0.05); local x0, y0 = trackAt(s - 0.05); local x, y = trackAt(s)
            local wx, wy = toWorld(x, y)
            SetEntityCoordsNoOffset(o, wx, wy, W.pos.z + TR.z, false, false, false)
            SetEntityHeading(o, W.heading + math.deg(math.atan(y1 - y0, x1 - x0)))
        end
    end
end

local fxOn = {}
local reported = false

local function startFx(e)
    RequestNamedPtfxAsset(e.asset)
    local n = 0
    while not HasNamedPtfxAssetLoaded(e.asset) and n < 300 do Wait(10); n = n + 1 end
    UseParticleFxAsset(e.asset)
    return StartParticleFxLoopedAtCoord(e.fx, e.pos.x, e.pos.y, e.pos.z, 0.0, 0.0, 0.0, e.scale, false, false, false, false)
end

local function stopFx(name)
    if fxOn[name] then StopParticleFxLooped(fxOn[name], false); fxOn[name] = nil end
end

local cerT0, cerPlaying = nil, false
local function cerElapsed() return cerT0 and (GetGameTimer() - cerT0) / 1000.0 or nil end

RegisterNetEvent('olentrix_mpc_ambience:ceremony', function(elapsedMs)
    local t0 = GetGameTimer() - (tonumber(elapsedMs) or 0)
    if cerT0 and math.abs(t0 - cerT0) < 1500 then return end
    cerT0, cerPlaying = t0, false
end)

local function gainAt(cam, pos, near, far)
    local d = #(cam - pos)
    if d <= near then return 1.0, d elseif d >= far then return 0.0, d end
    local x = 1.0 - (d - near) / (far - near); return x * x, d
end

local function panAt(cam, pos, d)
    local h = math.rad(GetFinalRenderedCamRot(2).z)
    local rx, ry = math.cos(h), math.sin(h)
    local dx, dy = pos.x - cam.x, pos.y - cam.y; local l = math.sqrt(dx * dx + dy * dy)
    if l < 0.01 then return 0.0 end
    local p = (dx * rx + dy * ry) / l * 0.75
    return p * math.min(1.0, d / 4.0)
end

CreateThread(function()
    TriggerServerEvent('olentrix_mpc_ambience:sync')
    local last = ''
    while true do
        local cam = camPos(); local el = cerElapsed()
        if el and el >= CER.Duration then cerT0, el = nil, nil; if cerPlaying then SendNUIMessage({ t = 'cerstop' }) end; cerPlaying = false end
        local duck = 1.0
        if el then
            duck = 1.0 - (1.0 - CER.Sound.duck) * ss(0.0, 3.0, el) * (1.0 - ss(50.0, 56.0, el))
            if not cerPlaying then SendNUIMessage({ t = 'cer', at = el }); cerPlaying = true end
        end
        local mix = {}
        for k, s in pairs(Config.Sounds) do
            local g, d = gainAt(cam, s.pos, s.near, s.far)
            mix[k] = { g * s.gain * ((k == 'music' or k == 'bells') and duck or 1.0) * (1.0 - passK), g > 0 and panAt(cam, s.pos, d) or 0.0 }
        end
        local cg = 0.0
        if el then cg = gainAt(cam, Config.SiteCentre, CER.Sound.near, CER.Sound.far) * CER.Sound.gain * (1.0 - passK) end
        mix.cer = { cg, 0.0 }
        for k, s in pairs(Config.ZoneSounds or {}) do
            local w = s.zone == 'globe' and kG or kP
            local g, d = 1.0, 0.0
            if s.pos then g, d = gainAt(cam, s.pos, s.near, s.far) end
            mix[k] = { g * s.gain * w, (s.pos and g > 0) and panAt(cam, s.pos, d) or 0.0 }
        end
        local key = ''
        for _, k in ipairs(mixKeys) do key = key .. ('%.2f/%.1f;'):format(mix[k][1], mix[k][2]) end
        if key ~= last then SendNUIMessage({ t = 'mix', v = Config.Volume, s = mix, f = zoneFiles, pl = Config.Sounds.music.playlist }); last = key end
        Wait(150)
    end
end)

CreateThread(function()
    while true do
        local p = GetEntityCoords(PlayerPedId())
        local dw = #(p - W.pos)
        if dw < Config.Train.range and not next(cars) then spawnTrain() elseif dw > Config.Train.range + 15.0 and next(cars) then despawnTrain() end
        local status = {}
        for _, e in ipairs(Config.Effects) do
            local d = #(p - e.pos)
            if d < e.range and not fxOn[e.name] then
                fxOn[e.name] = startFx(e)
                status[#status + 1] = e.name .. '=' .. tostring(fxOn[e.name] ~= 0 and DoesParticleFxLoopedExist(fxOn[e.name]))
            elseif d > e.range + 15.0 and fxOn[e.name] then stopFx(e.name) end
        end
        Wait(500)
    end
end)

CreateThread(function()
    while true do
        local busy = false
        if next(cars) then moveTrain(); busy = true end
        for _, e in ipairs(Config.Effects) do
            if e.light and fxOn[e.name] then
                local t = GetGameTimer() / 1000.0
                local f = 0.82 + 0.18 * (math.sin(t * 13.1) + math.sin(t * 7.3 + 1.2) + math.sin(t * 23.7 + 0.5)) / 3.0
                local q = e.pos + e.light.offset
                DrawLightWithRange(q.x, q.y, q.z, e.light.colour[1], e.light.colour[2], e.light.colour[3], e.light.range, e.light.intensity * f)
                busy = true
            end
        end
        Wait(busy and 0 or 500)
    end
end)

local routes = {}
for i, r in ipairs(CER.Routes) do
    local acc, total = { 0.0 }, 0.0
    for k = 2, #r.points do total = total + #(r.points[k] - r.points[k - 1]); acc[k] = total end
    routes[i] = { pts = r.points, acc = acc, len = total, marks = r.marks }
end

local function routeAt(rt, s)
    if s <= 0 then return rt.pts[1] end
    for k = 2, #rt.pts do
        if rt.acc[k] >= s then
            local u = (s - rt.acc[k - 1]) / math.max(0.001, rt.acc[k] - rt.acc[k - 1])
            return rt.pts[k - 1] + (rt.pts[k] - rt.pts[k - 1]) * u
        end
    end
    return rt.pts[#rt.pts]
end

local wheelBase = { c = GetCloudTimeAsInt(), g = GetGameTimer() }
local function wheelAngle()
    local P = CER.Wheel.period
    return ((wheelBase.c % P) + (GetGameTimer() - wheelBase.g) / 1000.0) / P * 360.0
end

local function light(p, c, range, i)
    if i > 0.01 then DrawLightWithRange(p.x, p.y, p.z, c[1], c[2], c[3], range, i) end
end

local GOLD, WARM, PALE, ROSE = { 255, 190, 95 }, { 255, 214, 160 }, { 255, 228, 190 }, { 255, 165, 115 }

CreateThread(function()
    while true do
        local el = cerElapsed()
        if el and el < CER.Duration and #(camPos() - Config.SiteCentre) < CER.DrawRange then
            local fo = 1.0 - ss(49.0, 56.0, el)
            local g = ss(0.0, 5.0, el) * fo
            light(CER.Gate.star, GOLD, 7.0, 7.0 * g)
            for _, q in ipairs(CER.Gate.piers) do light(q, WARM, 4.5, 3.0 * g) end
            local travel = ss(5.0, 6.0, el) * (1.0 - ss(19.0, 22.0, el))
            local markFade = 1.0 - ss(26.0, 32.0, el)
            for _, rt in ipairs(routes) do
                local head = rt.len * ss(5.0, 19.0, el)
                for k, w in ipairs({ 6.0, 3.5, 2.0 }) do
                    local s = head - (k - 1) * 2.5
                    if s > 0 and travel > 0 then local q = routeAt(rt, s); light(vector3(q.x, q.y, 68.8), WARM, 5.5, w * travel) end
                end
                for _, m in ipairs(rt.marks) do
                    local lit = math.min(1.0, math.max(0.0, (head - m.s) / 2.5)); local bump = math.exp(-((head - m.s) / 3.0) ^ 2)
                    light(m.pos, GOLD, 6.0, (2.2 * lit + 4.0 * bump) * markFade)
                end
            end
            local T = CER.Tree
            for k = 0, T.layers - 1 do
                local on = ss(20.0 + 2.5 * k, 21.6 + 2.5 * k, el) * fo
                if on > 0 then
                    local z = T.z0 + 1.1 + k * (T.h - 2.4) / (T.layers - 1)
                    local rad = T.r * (1.0 - (z - T.z0) / T.h) + 0.42
                    local col = (k % 3 == 0) and GOLD or ((k % 3 == 1) and PALE or ROSE)
                    for j = 0, T.perLayer - 1 do
                        local a = j * 2.0 * math.pi / T.perLayer + k * 0.7
                        light(T.base + vector3(math.cos(a) * rad, math.sin(a) * rad, z), col, 4.0, 2.6 * on)
                    end
                end
            end
            local st = ss(33.0, 34.5, el) * fo
            light(T.star, GOLD, 10.0, 9.0 * st * (1.0 + 0.08 * math.sin(el * 3.0)))
            local Wh = CER.Wheel
            local ang = wheelAngle(); local U = vector3(-math.sin(math.rad(Wh.psi)), math.cos(math.rad(Wh.psi)), 0.0)
            for i = 0, Wh.n - 1, 2 do
                local on = ss(34.5 + i * 0.175, 35.3 + i * 0.175, el) * fo
                if on > 0 then
                    local a = math.rad(ang + i * 360.0 / Wh.n)
                    light(Wh.hub + U * (Wh.r * math.cos(a)) + vector3(0.0, 0.0, Wh.r * math.sin(a)), (i % 4 == 0) and WARM or GOLD, 7.0, 4.0 * on)
                end
            end
            light(Wh.hub, GOLD, 9.0, 6.0 * ss(34.2, 36.0, el) * fo)
            Wait(0)
        else
            Wait(250)
        end
    end
end)

local PS = Config.Passage
local curMod, sceneOn = nil, false

local function segDist(p, a, b)
    local abx, aby = b.x - a.x, b.y - a.y; local l2 = abx * abx + aby * aby
    local t = l2 > 0 and math.max(0.0, math.min(1.0, ((p.x - a.x) * abx + (p.y - a.y) * aby) / l2)) or 0.0
    local qx, qy = a.x + abx * t, a.y + aby * t
    return math.sqrt((p.x - qx) ^ 2 + (p.y - qy) ^ 2), a.z + (b.z - a.z) * t
end

local function zoneAt(p)
    local g = PS.globe
    if #(p - g.centre) < g.radius and p.z > g.floor - 1.0 then return 'globe' end
    local c = PS.cutting
    if p.x >= c.x0 and p.x <= c.x1 and math.abs(p.y - c.y) <= c.half and p.z >= c.z0 and p.z <= c.z1 then return 'passage' end
    for i = 2, #PS.route do
        local d, z = segDist(p, PS.route[i - 1], PS.route[i])
        if d <= PS.half and p.z >= z - 0.6 and p.z <= z + PS.up then return 'passage' end
    end
    return nil
end

local snowOn, snowAt = false, 0
local function globeSnow(inside)
    if inside then
        if not snowOn or GetGameTimer() - snowAt > 2000 then
            SetOverrideWeather(PS.globeWeather); SetSnowLevel(PS.globeSnowLevel)
            SetForcePedFootstepsTracks(true)
            snowOn, snowAt = true, GetGameTimer()
        end
    elseif snowOn then
        snowOn = false
        ClearOverrideWeather(); SetSnowLevel(0.0); SetForcePedFootstepsTracks(false)
        if GlobalState.kora_weathersync then TriggerEvent('kora_weathersync:client:state', GlobalState.kora_weathersync) end
    end
end

CreateThread(function()
    while true do
        local zone = zoneAt(GetEntityCoords(PlayerPedId()))
        local want = zone == 'globe' and PS.modGlobe or (zone and PS.modPassage or nil)
        if want and curMod ~= want then SetTimecycleModifier(want); curMod = want; SetTimecycleModifierStrength(passK) end
        if zone and not sceneOn then StartAudioScene(PS.muteScene); sceneOn = true end
        local step = 0.1 / PS.fade
        local function ease(v, on) return on and math.min(1.0, v + step) or math.max(0.0, v - step) end
        kP = ease(kP, zone == 'passage'); kG = ease(kG, zone == 'globe')
        passK = math.max(kP, kG, zone and math.min(1.0, passK + step) or 0.0)
        if curMod then
            if passK <= 0.0 and not zone then
                ClearTimecycleModifier(); curMod = nil
            else
                if GetTimecycleModifierIndex() == -1 then SetTimecycleModifier(curMod) end
                SetTimecycleModifierStrength(passK)
            end
        end
        if sceneOn and not zone and passK <= 0.0 then StopAudioScene(PS.muteScene); sceneOn = false end
        globeSnow(zone == 'globe')
        Wait((zone or passK > 0.0) and 100 or 500)
    end
end)

local GT = Config.GlobeTrain
local gcars, gArc, gLen = {}, {}, 0.0
do
    local px, py
    for i = 0, 720 do
        local t = 2 * math.pi * i / 720; local x, y = GT.a * math.cos(t), GT.b * math.sin(t)
        if px then gLen = gLen + math.sqrt((x - px) ^ 2 + (y - py) ^ 2) end
        gArc[i + 1] = { gLen, t }; px, py = x, y
    end
end
local gch, gsh = math.cos(math.rad(GT.heading)), math.sin(math.rad(GT.heading))

local function gAt(s)
    s = s % gLen
    local lo, hi = 1, #gArc
    while hi - lo > 1 do local mid = (lo + hi) // 2; if gArc[mid][1] < s then lo = mid else hi = mid end end
    local a, b = gArc[lo], gArc[hi]; local t = a[2] + (b[2] - a[2]) * (s - a[1]) / math.max(1e-6, b[1] - a[1])
    local x, y = GT.a * math.cos(t), GT.b * math.sin(t); local tx, ty = -GT.a * math.sin(t), GT.b * math.cos(t)
    return GT.centre.x + x * gch - y * gsh, GT.centre.y + x * gsh + y * gch, GT.heading + math.deg(math.atan(ty, tx))
end

local function gSpawn()
    for i, c in ipairs(GT.cars) do
        local h = loadModel(c.model)
        if h then
            local o = CreateObjectNoOffset(h, GT.centre.x, GT.centre.y, GT.centre.z, false, false, false)
            FreezeEntityPosition(o, true); SetEntityCollision(o, false, false); gcars[i] = o
        end
    end
end

local function gDespawn()
    for i, o in pairs(gcars) do if DoesEntityExist(o) then DeleteObject(o) end; gcars[i] = nil end
end

CreateThread(function()
    while true do
        local d = #(GetEntityCoords(PlayerPedId()) - GT.centre)
        if d < GT.range and not next(gcars) then gSpawn() elseif d > GT.range + 15.0 and next(gcars) then gDespawn() end
        Wait(500)
    end
end)

CreateThread(function()
    while true do
        if next(gcars) then
            local s = (GetGameTimer() / 1000.0 * GT.speed) % gLen
            for i, c in ipairs(GT.cars) do
                s = s - c.gap
                local o = gcars[i]
                if o then local x, y, hd = gAt(s); SetEntityCoordsNoOffset(o, x, y, GT.centre.z, false, false, false); SetEntityHeading(o, hd) end
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    despawnTrain()
    for name in pairs(fxOn) do stopFx(name) end
    SendNUIMessage({ t = 'stop' })
    if curMod then ClearTimecycleModifier() end
    if sceneOn then StopAudioScene(PS.muteScene) end
    globeSnow(false)
    gDespawn()
end)
