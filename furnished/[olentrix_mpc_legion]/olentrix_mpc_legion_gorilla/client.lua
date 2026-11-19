local G = Config.Grate
local H = math.rad(G.heading)
local UX = vector3(math.cos(H), math.sin(H), 0.0)
local VY = vector3(-math.sin(H), math.cos(H), 0.0)
local UP = vector3(0.0, 0.0, 1.0)
local WX, WY = vector3(1.0, 0.0, 0.0), vector3(0.0, 1.0, 0.0)

local plate, well
local show, scene
local pending = 0
local cooldownUntil = 0

local function dot(a, b) return a.x * b.x + a.y * b.y + a.z * b.z end
local function cross(a, b) return vector3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x) end
local function unit(v)
    local l = #v
    if l < 1e-6 then return vector3(0.0, 1.0, 0.0) end
    return v / l
end
local function rot(v, k, a)
    local c, s = math.cos(a), math.sin(a)
    return v * c + cross(k, v) * s + k * (dot(k, v) * (1.0 - c))
end
local function clamp(x, a, b) return math.max(a, math.min(b, x)) end
local function lerp(a, b, t) return a + (b - a) * t end
local function easeOut(t) t = clamp(t, 0.0, 1.0); return 1.0 - (1.0 - t) ^ 3 end
local function easeBack(t)
    t = clamp(t, 0.0, 1.0)
    local c = 1.9
    return 1.0 + (c + 1.0) * (t - 1.0) ^ 3 + c * (t - 1.0) ^ 2
end
local function heading(dir) return math.deg(math.atan(-dir.x, dir.y)) % 360.0 end
local function wobble(t, f, seed) return math.sin(t * f * 6.2832 + seed) * 0.6 + math.sin(t * f * 2.71 * 6.2832 + seed * 1.7) * 0.4 end

local function place(obj, pos, x, y, z)
    SetEntityMatrix(obj, y.x, y.y, y.z, x.x, x.y, x.z, z.x, z.y, z.z, pos.x, pos.y, pos.z)
end

local function aimBasis(fwd, upHint)
    local y = unit(fwd)
    local x = unit(cross(y, upHint or UP))
    return x, y, cross(x, y)
end

local function loadModel(name)
    local hash = GetHashKey(name)
    if not IsModelInCdimage(hash) then return nil end
    RequestModel(hash)
    local tries = 0
    while not HasModelLoaded(hash) and tries < 300 do Wait(10); tries = tries + 1 end
    return HasModelLoaded(hash) and hash or nil
end

local function spawn(name, pos)
    local hash = loadModel(name)
    if not hash then return nil end
    local obj = CreateObjectNoOffset(hash, pos.x, pos.y, pos.z, false, false, false)
    SetModelAsNoLongerNeeded(hash)
    FreezeEntityPosition(obj, true)
    return obj
end

local function remove(e)
    if e and DoesEntityExist(e) then DeleteEntity(e) end
end

local function loadDict(dict)
    RequestAnimDict(dict)
    local tries = 0
    while not HasAnimDictLoaded(dict) and tries < 300 do Wait(10); tries = tries + 1 end
    return HasAnimDictLoaded(dict)
end

local function hingePose(obj, centre, ux, vy, side, deg)
    local phi = -side * math.rad(deg)
    local hinge = centre + vy * (side * G.halfShort)
    place(obj, hinge + rot(centre - hinge, ux, phi), ux, rot(vy, ux, phi), rot(UP, ux, phi))
end

local function plateClosed()
    if not plate or not DoesEntityExist(plate) then return end
    SetEntityCoordsNoOffset(plate, G.pos.x, G.pos.y, G.pos.z, false, false, false)
    SetEntityRotation(plate, 0.0, 0.0, G.heading, 2, false)
end

local function setPlate(side, deg)
    if not plate or not DoesEntityExist(plate) then return end
    if deg <= 0.001 then plateClosed() else hingePose(plate, G.pos, UX, VY, side, deg) end
end

local function addText(text)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
end

local function drawText3d(text, point)
    local visible, x, y = GetScreenCoordFromWorldCoord(point.x, point.y, point.z)
    if not visible then return end
    SetTextFont(0)
    SetTextScale(0.38, 0.38)
    SetTextColour(255, 255, 255, 255)
    SetTextCentre(true)
    SetTextOutline()
    addText(text)
    EndTextCommandDisplayText(x, y)
end

local function notify(text)
    if GetResourceState('kora_core') == 'started' or GetResourceState('qb-core') == 'started' then
        TriggerEvent('QBCore:Notify', text, 'primary', 5000)
    elseif GetResourceState('qbx_core') == 'started' then
        exports.qbx_core:Notify(text, 'inform', 5000)
    elseif GetResourceState('ox_lib') == 'started' then
        TriggerEvent('ox_lib:notify', { description = text, type = 'inform' })
    else
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandThefeedPostTicker(false, false)
    end
end

local function sound(id, file, volume)
    SendNUIMessage({ t = 'play', id = id, f = file, v = volume })
end

local function blocked(handle)
    local result, hit = 1, false
    local tries = 0
    while result == 1 and tries < 50 do
        result, hit = GetShapeTestResult(handle)
        if result == 1 then Wait(0) end
        tries = tries + 1
    end
    return hit == 1 or hit == true
end

local function groundNear(p)
    local found, z = GetGroundZFor_3dCoord(p.x, p.y, G.pos.z + 1.5, false)
    if found and math.abs(z - G.pos.z) < 0.6 then return z, true end
    return G.pos.z, false
end

local function standSpot(side, u, out, me)
    local s = G.pos + UX * u - VY * (side * (G.frameShort + out))
    local z, ok = groundNear(s)
    if not ok then return nil end
    if me and blocked(StartShapeTestCapsule(s.x, s.y, z + 0.45, s.x, s.y, z + 1.5, 0.3, 19, me, 7)) then return nil end
    return vector3(s.x, s.y, z), heading(VY * side)
end

local function gorillaRight(side) return cross(VY * -side, UP) end

local function gapPoint(side, u) return G.pos - VY * (side * (G.halfShort + 0.03)) + UX * u + UP * 0.07 end

local function ik(S, T, pole)
    local l1, l2 = Config.Arm.upper, Config.Arm.grip
    local d = T - S
    local dist = clamp(#d, math.abs(l1 - l2) + 0.01, l1 + l2 - 0.002)
    local dr = unit(d)
    local a = (l1 * l1 + dist * dist - l2 * l2) / (2.0 * l1 * dist)
    local h = l1 * math.sqrt(math.max(0.0, 1.0 - a * a))
    local pd = unit(pole - dr * dot(pole, dr))
    return S + dr * (l1 * a) + pd * h, S + dr * dist
end

local function placeArm(arm, S, T, pole)
    local E, Tc = ik(S, T, pole)
    local x, y, z = aimBasis(E - S)
    place(arm[1], S, x, y, z)
    x, y, z = aimBasis(Tc - E)
    place(arm[2], E, x, y, z)
end

local function armVisible(arm, on)
    SetEntityVisible(arm[1], on, false)
    SetEntityVisible(arm[2], on, false)
end

local function spawnArms(at)
    local list = {}
    for _, pair in ipairs({ { Config.Models.uarmR, Config.Models.farmR }, { Config.Models.uarmL, Config.Models.farmL } }) do
        local a = { spawn(pair[1], at), spawn(pair[2], at) }
        for _, e in ipairs(a) do
            SetEntityCollision(e, false, false)
            SetEntityVisible(e, false, false)
        end
        list[#list + 1] = a
    end
    if not (list[1][1] and list[1][2] and list[2][1] and list[2][2]) then error('arm models missing') end
    return list
end

local function removeArms(list)
    if not list then return end
    for _, a in ipairs(list) do
        remove(a[1])
        remove(a[2])
    end
end

local function headBasis(pitch, yaw)
    return aimBasis(rot(rot(WY, WX, math.rad(pitch)), UP, math.rad(yaw)))
end

local function hpt(H, x, y, z, v) return H + x * v.x + y * v.y + z * v.z end

local function plateAngle(t)
    local T = Timing
    if t < T.knock then return 0.0 end
    if t < T.knock + 0.08 then return Config.Lift.knock * (t - T.knock) / 0.08 end
    if t < T.burst then return lerp(Config.Lift.knock, 1.0, easeOut((t - T.knock - 0.08) / 0.3)) end
    if t < T.burst + 0.08 then return lerp(1.0, Config.Lift.open, (t - T.burst) / 0.08) end
    if t < T.shut then return Config.Lift.open + 0.4 * math.sin((t - T.burst) * 23.0) * math.max(0.0, 1.0 - (t - T.burst) / 0.6) end
    if t < T.shut + 0.09 then return Config.Lift.open * (1.0 - (t - T.shut) / 0.09) end
    if t < T.shut + 0.25 then return 0.7 * math.sin((t - T.shut - 0.09) / 0.16 * math.pi) end
    return 0.0
end

local function handTargets(s)
    local ped = s.ped
    local right = gorillaRight(s.side)
    local gp = gapPoint(s.side, s.u)
    local toward = VY * -s.side
    local fallback = {
        gp + toward * 0.38 + right * 0.2 + UP * 0.12,
        gp + toward * 0.38 - right * 0.2 + UP * 0.12,
    }
    if ped and ped ~= 0 and DoesEntityExist(ped) and IsEntityVisible(ped) then
        local l = GetPedBoneCoords(ped, 18905, 0.0, 0.0, 0.0)
        local r = GetPedBoneCoords(ped, 57005, 0.0, 0.0, 0.0)
        if #(l - fallback[1]) < 1.2 then fallback[1] = l end
        if #(r - fallback[2]) < 1.2 then fallback[2] = r end
    end
    return fallback
end

local function runShow(s)
    local T = Timing
    s.arms = spawnArms(G.pos - UP * 3.0)
    local right = gorillaRight(s.side)
    local gp = gapPoint(s.side, s.u)
    local inward = VY * s.side
    local targets
    while show == s do
        local t = (GetGameTimer() - s.t0) / 1000.0
        if t >= T.done then break end
        setPlate(s.side, plateAngle(t))
        if t >= T.burst and t < T.black + 0.2 then
            if t < T.black then targets = handTargets(s) end
            local k = t < T.black and easeBack((t - T.burst) / 0.13) or 1.0 - easeOut((t - T.black) / 0.15)
            for i, a in ipairs(s.arms) do
                local sx = i == 1 and 1.0 or -1.0
                local S = gp + inward * 0.45 - UP * 0.12 + right * (sx * 0.25)
                local inside = gp + inward * 0.12 - UP * 0.06 + right * (sx * 0.2)
                armVisible(a, k > 0.02)
                placeArm(a, S, lerp(inside, targets[i], k), -UP + right * (sx * 0.6))
            end
        elseif t >= T.black + 0.2 then
            for _, a in ipairs(s.arms) do armVisible(a, false) end
        end
        if not s.mine and s.audio then
            local d = #(GetEntityCoords(PlayerPedId()) - G.pos)
            local v = Config.Volume * clamp(1.0 - d / Config.HearDistance, 0.0, 1.0) ^ 1.4
            if math.abs(v - s.vol) > 0.02 then
                s.vol = v
                SendNUIMessage({ t = 'vol', id = 'nearby', v = v })
            end
        end
        Wait(0)
    end
    removeArms(s.arms)
    s.arms = nil
    plateClosed()
    if show == s then show = nil end
end

local function pitPos(v) return Config.Pit.origin + v end

local function camLook(cam, pos, look, fov, shake, t)
    local p = pos
    local d = unit(look - pos)
    local pitch, yaw, roll = math.deg(math.asin(clamp(d.z, -1.0, 1.0))), heading(d), 0.0
    if shake > 0.0 then
        p = p + vector3(wobble(t, 9.0, 1.0), wobble(t, 8.0, 2.0), wobble(t, 10.0, 3.0)) * (0.025 * shake)
        pitch = pitch + wobble(t, 7.0, 4.0) * 2.5 * shake
        yaw = yaw + wobble(t, 6.0, 5.0) * 2.5 * shake
        roll = wobble(t, 5.0, 6.0) * 3.0 * shake
    end
    SetCamCoord(cam, p.x, p.y, p.z)
    SetCamRot(cam, pitch, roll, yaw, 2)
    SetCamFov(cam, fov)
end

local function light(p, c, range, intensity)
    if intensity > 0.01 then DrawLightWithRange(p.x, p.y, p.z, c[1], c[2], c[3], range, intensity) end
end

local function blockAll()
    DisableAllControlActions(0)
    EnableControlAction(0, 249, true)
    EnableControlAction(0, 245, true)
    HideHudAndRadarThisFrame()
end

local function endScene(fast)
    local s = scene
    if not s then return end
    scene = nil
    if s.cam and DoesCamExist(s.cam) then DestroyCam(s.cam, false) end
    RenderScriptCams(false, false, 0, true, true)
    ClearFocus()
    ClearTimecycleModifier()
    for _, e in pairs(s.objs) do remove(e) end
    if fast then SendNUIMessage({ t = 'stop' }) end
    local me = PlayerPedId()
    if s.hidden and s.wake and not IsEntityDead(me) then
        SetEntityCoords(me, s.wake.x, s.wake.y, s.wake.z + 1.0, false, false, false, false)
        SetEntityHeading(me, s.wakeHeading)
    end
    SetEntityVisible(me, true, false)
    SetEntityCollision(me, true, true)
    FreezeEntityPosition(me, false)
    SetEntityInvincible(me, s.wasInvincible)
    if fast then
        StopGameplayCamShaking(true)
        if IsScreenFadedOut() or IsScreenFadingOut() then DoScreenFadeIn(300) end
    end
    TriggerServerEvent('olentrix_mpc_legion_gorilla:done')
end

local function hidePlayer(s)
    local me = s.ped
    ClearPedTasksImmediately(me)
    SetEntityVisible(me, false, false)
    SetEntityCollision(me, false, false)
    FreezeEntityPosition(me, true)
    s.hidden = true
end

local function poseGorilla(s, H, pitch, yaw, jaw, hands, poles)
    local o = s.objs
    local x, y, z = headBasis(pitch, yaw)
    place(o.head, H, x, y, z)
    local a = -math.rad(jaw)
    place(o.jaw, H + y * 0.04 + z * 0.02, x, rot(y, x, a), rot(z, x, a))
    local sh = Config.Arm.shoulder
    for i, sx in ipairs({ 1.0, -1.0 }) do
        placeArm(s.arms[i], hpt(H, x, y, z, vector3(sx * sh.x, sh.y, sh.z)), hands[i], poles[i])
    end
    return x, y, z
end

local function pitShot(s, t)
    local T = Timing
    local o = s.objs
    place(o.pit, Config.Pit.origin, WX, WY, UP)
    SetEntityVisible(o.pit, true, false)
    SetEntityVisible(o.hatch, true, false)
    local cam, look, fov, shake = nil, nil, 50.0, 0.0
    local hatchDeg = t < T.shut and Config.Lift.open or (t < T.shut + 0.09 and Config.Lift.open * (1.0 - (t - T.shut) / 0.09) or 0.0)
    hingePose(o.hatch, pitPos(Config.Pit.hatch), WX, WY, 1, hatchDeg)
    light(pitPos(vector3(0.0, 0.6, 2.25)), { 200, 215, 255 }, 3.5, 6.0 * hatchDeg / Config.Lift.open)
    local on = true
    if t < T.drag then
        cam, look, fov = pitPos(vector3(0.15, 0.35, 0.22)), pitPos(vector3(0.0, 1.25, 2.4)), 62.0
        on = false
        if t >= T.shut then shake = 1.2 * math.max(0.0, 1.0 - (t - T.shut) / 0.6) end
        light(pitPos(vector3(0.0, 1.6, 1.4)), { 140, 160, 200 }, 4.0, 0.5)
    elseif t < T.still then
        local p = (t - T.drag) / (T.still - T.drag)
        local n = math.min(math.floor(p * 3.0), 2)
        local f = (n + easeOut(math.min(1.0, (p * 3.0 - n) / 0.35))) / 3.0
        cam = pitPos(vector3(0.0, 0.9 - 1.5 * f, 0.3 + 0.02 * math.sin(t * 9.0)))
        look = cam + vector3(0.0, -2.0, -0.12)
        fov = 58.0
        local pull = (p * 3.0) % 1.0
        local heave = pull < 0.35 and math.sin(pull / 0.35 * math.pi) or 0.0
        shake = 0.25 + 0.8 * heave
        local H = cam + vector3(0.0, -1.3 - 0.12 * heave, 0.42 + 0.05 * heave)
        poseGorilla(s, H, -32.0, wobble(t, 1.5, 2.0) * 4.0, 8.0 + 10.0 * heave,
            { cam + vector3(0.15, -0.78 + 0.05 * heave, -0.27), cam + vector3(-0.15, -0.78 + 0.05 * heave, -0.27) },
            { vector3(1.0, 0.0, -0.4), vector3(-1.0, 0.0, -0.4) })
        light(pitPos(vector3(0.0, 1.6, 1.5)), { 150, 170, 210 }, 4.5, 2.0)
        light(cam + vector3(0.0, -0.35, 0.35), { 130, 150, 190 }, 1.6, 1.5)
    elseif t < T.scare then
        local p = (t - T.still) / (T.scare - T.still)
        cam = pitPos(vector3(0.0, -0.6, 0.3))
        look = pitPos(vector3(0.25 - 0.25 * easeOut(p), -2.1, 0.75))
        fov = 55.0
        shake = 0.15
        local H = pitPos(vector3(0.0, -2.05, 0.6))
        local x, y, z = poseGorilla(s, H, -10.0, 0.0, 4.0, { pitPos(vector3(0.3, -1.75, 0.05)), pitPos(vector3(-0.3, -1.75, 0.05)) },
            { vector3(1.0, 0.0, -0.3), vector3(-1.0, 0.0, -0.3) })
        light(pitPos(vector3(0.0, 1.6, 1.5)), { 150, 170, 210 }, 4.5, 0.4)
        if t >= T.still + 0.55 then
            for _, ex in ipairs({ 0.046, -0.046 }) do
                light(hpt(H, x, y, z, vector3(ex, 0.185, 0.163)), { 255, 175, 110 }, 0.06, 3.0)
            end
        end
    elseif t < T.thrash then
        local dt = t - T.scare
        cam = pitPos(vector3(0.0, -0.6, 0.28))
        local k = easeBack(dt / 0.14)
        local H = lerp(pitPos(vector3(0.0, -2.05, 0.6)), pitPos(vector3(0.0, -1.15, 0.46)), k) + vector3(wobble(t, 22.0, 1.0), 0.0, wobble(t, 19.0, 2.0)) * 0.006
        local ka = easeOut(dt / 0.12)
        local hands = {
            lerp(pitPos(vector3(0.75, -1.2, 0.35)), cam + vector3(0.28, -0.12, -0.04), ka),
            lerp(pitPos(vector3(-0.75, -1.2, 0.35)), cam + vector3(-0.28, -0.12, -0.04), ka),
        }
        local x, y, z = poseGorilla(s, H, -10.0 - 18.0 * clamp(k, 0.0, 1.2), wobble(t, 3.0, 3.0) * 4.0,
            lerp(6.0, 38.0, easeOut(dt / 0.2)) + wobble(t, 18.0, 4.0) * 3.0, hands, { vector3(1.0, 0.0, 0.6), vector3(-1.0, 0.0, 0.6) })
        look, fov = hpt(H, x, y, z, vector3(0.0, 0.17, 0.12)), 52.0
        shake = 1.0 - 0.65 * clamp(dt / 1.0, 0.0, 1.0)
        light(cam + vector3(0.0, -0.05, 0.35), { 200, 215, 255 }, 3.0, 45.0 * math.exp(-dt / 0.12) + 2.5)
        light(pitPos(vector3(0.0, -0.9, 0.02)), { 180, 25, 15 }, 2.5, 3.0)
        if dt < 0.12 then DrawRect(0.5, 0.5, 1.0, 1.0, 255, 255, 255, math.floor(220 * (1.0 - dt / 0.12)), false) end
    else
        local dt = t - T.thrash
        local yaw = 14.0 * math.sin(dt * 2.8 * 6.2832)
        local H = pitPos(vector3(0.0, -1.15, 0.46)) + vector3(0.03 * math.sin(dt * 2.8 * 6.2832), 0.0, 0.0)
        cam = pitPos(vector3(0.16, -0.72, 0.16))
        local bx, by, bz = headBasis(-20.0, yaw)
        local final = t >= T.bang - 0.25
        local hands = {}
        for i, sx in ipairs({ 1.0, -1.0 }) do
            if final then
                hands[i] = cam + vector3(sx * 0.2, -0.12, 0.0)
            else
                local w = 0.5 + 0.5 * math.sin(dt * 4.25 * 6.2832 + (i == 2 and math.pi or 0.0))
                hands[i] = lerp(hpt(H, bx, by, bz, vector3(sx * 0.2, 0.15, -0.42)), hpt(H, bx, by, bz, vector3(sx * 0.48, 0.3, -0.12)), w)
            end
        end
        local x, y, z = poseGorilla(s, H, -20.0, yaw, 26.0 + 13.0 * math.sin(dt * 5.0 * 6.2832), hands,
            { vector3(1.0, 0.0, -0.3), vector3(-1.0, 0.0, -0.3) })
        look, fov = hpt(H, x, y, z, vector3(0.0, 0.17, 0.12)), 48.0
        shake = 0.6
        light(pitPos(vector3(0.0, -0.9, 0.02)), { 180, 25, 15 }, 2.5, 3.0)
        light(pitPos(vector3(0.5, -0.4, 1.6)), { 170, 190, 230 }, 3.5, (math.random() < 0.6) and 3.5 or 0.3)
    end
    SetEntityVisible(o.head, on, false)
    SetEntityVisible(o.jaw, on, false)
    for _, a in ipairs(s.arms) do armVisible(a, on) end
    camLook(s.cam, cam, look, fov, shake, t)
end

local function wakeUp(s)
    local me = s.ped
    RequestCollisionAtCoord(s.wake.x, s.wake.y, s.wake.z)
    local tries = 0
    while not HasCollisionLoadedAroundEntity(me) and tries < 60 do
        RequestCollisionAtCoord(s.wake.x, s.wake.y, s.wake.z)
        Wait(50)
        tries = tries + 1
    end
    SetEntityCoords(me, s.wake.x, s.wake.y, s.wake.z + 1.0, false, false, false, false)
    SetEntityHeading(me, s.wakeHeading)
    s.hidden = false
    endScene(false)
    ClearPedTasksImmediately(me)
    ShakeGameplayCam('HAND_SHAKE', 0.8)
    DoScreenFadeIn(800)
    SetTimeout(1800, function() StopGameplayCamShaking(false) end)
end

local function runScene(s)
    local T = Timing
    local me = s.ped
    local origin = Config.Pit.origin
    for _, name in ipairs({ Config.Models.pit, Config.Models.plate, Config.Models.head, Config.Models.jaw, Config.Models.uarmR, Config.Models.farmR, Config.Models.uarmL, Config.Models.farmL }) do
        loadModel(name)
    end
    loadDict(Config.Kneel.enter.dict)
    loadDict(Config.Kneel.base.dict)
    s.arms = spawnArms(origin)
    s.objs = {
        pit = spawn(Config.Models.pit, origin),
        hatch = spawn(Config.Models.plate, origin),
        head = spawn(Config.Models.head, origin),
        jaw = spawn(Config.Models.jaw, origin),
        upperR = s.arms[1][1],
        foreR = s.arms[1][2],
        upperL = s.arms[2][1],
        foreL = s.arms[2][2],
    }
    for _, e in pairs(s.objs) do
        SetEntityCollision(e, false, false)
        SetEntityVisible(e, false, false)
    end
    local o = s.objs
    if not (o.pit and o.hatch and o.head and o.jaw) then error('models missing') end
    place(o.pit, origin, WX, WY, UP)
    SetEntityVisible(o.pit, true, false)
    SetEntityVisible(o.hatch, true, false)
    s.wasInvincible = GetPlayerInvincible(PlayerId())
    SetEntityInvincible(me, true)
    ClearPedTasksImmediately(me)
    SetEntityCoords(me, s.kneel.x, s.kneel.y, s.kneel.z + 1.0, false, false, false, false)
    SetEntityHeading(me, s.kneelHeading)
    TaskPlayAnim(me, Config.Kneel.enter.dict, Config.Kneel.enter.clip, 8.0, -8.0, -1, 0, 0.0, false, false, false)
    s.cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 50.0, false, 2)
    local right = gorillaRight(s.side)
    local gp = gapPoint(s.side, s.u)
    local worldCam = s.kneel + right * 0.9 - VY * (s.side * 1.1) + UP * 1.45
    local worldLook = gp + UP * 0.05 - VY * (s.side * 0.1)
    camLook(s.cam, worldCam, worldLook, 50.0, 0.0, 0.0)
    SetCamActive(s.cam, true)
    RenderScriptCams(true, true, 600, true, true)
    local based, yanked, cut, focus = false, false, false, false
    while scene == s do
        local t = (GetGameTimer() - s.t0) / 1000.0
        if IsEntityDead(me) or PlayerPedId() ~= me then
            print('olentrix_mpc_legion_gorilla: scene stopped (player dead or changed)')
            endScene(true)
            return
        end
        if t > T.done + 5.0 then error('scene overran') end
        RequestCollisionAtCoord(s.kneel.x, s.kneel.y, s.kneel.z)
        if t < T.black then
            if not based and t >= 1.15 then
                based = true
                TaskPlayAnim(me, Config.Kneel.base.dict, Config.Kneel.base.clip, 4.0, -4.0, -1, 1, 0.0, false, false, false)
            end
            local shake, fov = 0.0, 50.0
            if t >= T.knock then shake = 0.3 * math.max(0.0, 1.0 - (t - T.knock) / 0.4) end
            if t >= T.burst then
                local dt = t - T.burst
                shake = 1.1 * math.max(0.25, 1.0 - dt / 0.5)
                fov = lerp(50.0, 38.0, easeOut(dt / 0.1))
            end
            if not yanked and t >= T.yank then
                yanked = true
                ClearPedTasksImmediately(me)
                SetPedToRagdoll(me, 1500, 1500, 0, false, false, false)
                local pull = VY * s.side
                ApplyForceToEntityCenterOfMass(me, 1, pull.x * 7.0, pull.y * 7.0, -3.0, false, false, true, false)
            end
            camLook(s.cam, worldCam, worldLook, fov, shake, t)
        elseif t < T.cut then
            if not cut then
                cut = true
                DoScreenFadeOut(60)
            end
            if not s.hidden and t >= T.black + 0.12 then hidePlayer(s) end
            DrawRect(0.5, 0.5, 1.0, 1.0, 0, 0, 0, 255, false)
        elseif t < T.bang then
            if not s.hidden then hidePlayer(s) end
            if not focus then
                focus = true
                SetFocusPosAndVel(origin.x, origin.y, origin.z + 1.0, 0.0, 0.0, 0.0)
                SetTimecycleModifier(Config.Pit.timecycle)
                SetTimecycleModifierStrength(1.0)
                pitShot(s, t)
                DoScreenFadeIn(120)
            end
            pitShot(s, t)
        else
            DrawRect(0.5, 0.5, 1.0, 1.0, 0, 0, 0, 255, false)
            if not IsScreenFadedOut() and not IsScreenFadingOut() then DoScreenFadeOut(0) end
            if t >= T.wake then
                wakeUp(s)
                return
            end
        end
        blockAll()
        Wait(0)
    end
end

local function startScene(side, u)
    local me = PlayerPedId()
    local kneel, kh = standSpot(side, u, Config.Kneel.out, nil)
    if not kneel then kneel, kh = vector3(GetEntityCoords(me).x, GetEntityCoords(me).y, G.pos.z), heading(VY * side) end
    local wake, wh = standSpot(side, u, 1.15, me)
    if not wake then wake, wh = standSpot(side, u, 0.7, me) end
    if not wake then wake, wh = kneel, kh end
    local s = { ped = me, side = side, u = u, kneel = kneel, kneelHeading = kh, wake = wake, wakeHeading = wh, objs = {}, t0 = GetGameTimer() }
    scene = s
    sound('scare', 'scare.ogg', Config.Volume)
    CreateThread(function()
        local ok, err = pcall(runScene, s)
        if not ok then
            print(('olentrix_mpc_legion_gorilla: scene stopped: %s'):format(err))
            if scene == s then endScene(true) end
        end
    end)
end

local function sideFor(p)
    local b = dot(p - G.pos, VY)
    return b < 0.0 and 1 or -1
end

local function nearGrate(p)
    local d = p - G.pos
    local a, b = dot(d, UX), dot(d, VY)
    local dx, dy = math.max(math.abs(a) - G.frameLong, 0.0), math.max(math.abs(b) - G.frameShort, 0.0)
    return math.sqrt(dx * dx + dy * dy) <= Config.PromptDistance and math.abs(d.z) < 2.0, a
end

CreateThread(function()
    while true do
        local d = #(GetEntityCoords(PlayerPedId()) - G.pos)
        if d < Config.SpawnDistance and not plate then
            well = spawn(Config.Models.well, G.pos)
            if well then
                SetEntityCollision(well, false, false)
                SetEntityRotation(well, 0.0, 0.0, G.heading, 2, false)
            end
            plate = spawn(Config.Models.plate, G.pos)
            plateClosed()
        elseif d > Config.DespawnDistance and plate and not show then
            remove(plate)
            remove(well)
            plate, well = nil, nil
        end
        Wait(1000)
    end
end)

CreateThread(function()
    while true do
        local wait = 500
        if plate and not show and not scene then
            local me = PlayerPedId()
            local p = GetEntityCoords(me)
            if #(p - G.pos) < 8.0 then wait = 0 end
            local near, a = nearGrate(p)
            if near and not IsPedInAnyVehicle(me, false) and not IsEntityDead(me) then
                local top = G.pos + vector3(0.0, 0.0, 0.35)
                local left = math.ceil((cooldownUntil - GetGameTimer()) / 1000)
                if (GlobalState.legionGorilla or {}).busy then
                    drawText3d(Config.Text.busy, top)
                elseif left > 0 then
                    drawText3d(Config.Text.wait:format(left), top)
                elseif GetGameTimer() > pending then
                    drawText3d(Config.Text.open, top)
                    if IsControlJustPressed(0, 38) then
                        pending = GetGameTimer() + 3000
                        local side, u = sideFor(p), clamp(a, -0.6, 0.6)
                        if not standSpot(side, u, Config.Kneel.out, me) and standSpot(-side, u, Config.Kneel.out, me) then side = -side end
                        TriggerServerEvent('olentrix_mpc_legion_gorilla:open', side, u)
                    end
                end
            end
        end
        Wait(wait)
    end
end)

RegisterNetEvent('olentrix_mpc_legion_gorilla:go', function(src, side, u)
    local mine = src == GetPlayerServerId(PlayerId())
    if mine then
        pending = 0
        cooldownUntil = GetGameTimer() + Config.Cooldown * 1000
    end
    local d = #(GetEntityCoords(PlayerPedId()) - G.pos)
    if not mine and (d > Config.WatchDistance or not plate) then return end
    if show then show = nil; Wait(0) end
    local player = GetPlayerFromServerId(src)
    local s = { side = side, u = u, mine = mine, ped = player ~= -1 and GetPlayerPed(player) or 0, t0 = GetGameTimer(), vol = 0.0 }
    show = s
    if mine then
        startScene(side, u)
    elseif d < Config.HearDistance then
        s.audio = true
        s.vol = Config.Volume * clamp(1.0 - d / Config.HearDistance, 0.0, 1.0) ^ 1.4
        sound('nearby', 'nearby.ogg', s.vol)
    end
    CreateThread(function()
        local ok, err = pcall(runShow, s)
        if not ok then
            print(('olentrix_mpc_legion_gorilla: show stopped: %s'):format(err))
            removeArms(s.arms)
            plateClosed()
            if show == s then show = nil end
        end
    end)
end)

RegisterNetEvent('olentrix_mpc_legion_gorilla:refuse', function(reason, seconds)
    pending = 0
    if reason == 'cooldown' then
        cooldownUntil = GetGameTimer() + (seconds or 0) * 1000
        notify(Config.Text.cooldown:format(seconds or 0))
    else
        notify(Config.Text[reason] or Config.Text.busy)
    end
end)

AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then return end
    if scene then endScene(true) end
    if show then removeArms(show.arms) end
    show = nil
    remove(plate)
    remove(well)
    plate, well = nil, nil
end)
