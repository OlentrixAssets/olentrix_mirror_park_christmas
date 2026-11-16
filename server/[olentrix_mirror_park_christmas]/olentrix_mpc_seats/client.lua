local C, W = Config, Config.Wheel

local function help(text)
    BeginTextCommandDisplayHelp('STRING'); AddTextComponentSubstringPlayerName(text); EndTextCommandDisplayHelp(0, false, false, -1)
end

local function note(text)
    BeginTextCommandThefeedPost('STRING'); AddTextComponentSubstringPlayerName(text); EndTextCommandThefeedPostTicker(false, false)
end

local function loadDict(dict)
    RequestAnimDict(dict)
    local n = 0
    while not HasAnimDictLoaded(dict) and n < 300 do Wait(10); n = n + 1 end
    return HasAnimDictLoaded(dict)
end

local function inside(x, y)
    local P = Area.poly
    if x < Area.min.x or x > Area.max.x or y < Area.min.y or y > Area.max.y then return false end
    local c, j = false, #P
    for i = 1, #P do
        local a, b = P[i], P[j]
        if (a.y > y) ~= (b.y > y) and x < (b.x - a.x) * (y - a.y) / (b.y - a.y) + a.x then c = not c end
        j = i
    end
    return c
end

local function occupied(pos)
    local me = PlayerPedId()
    for _, ped in ipairs(GetGamePool('CPed')) do
        if ped ~= me and #(GetEntityCoords(ped) - pos) < C.Taken + 0.6 and #(GetEntityCoords(ped).xy - pos.xy) < C.Taken then return true end
    end
    return false
end

local U = vector2(-math.sin(math.rad(W.psi)), math.cos(math.rad(W.psi)))
local RATE = 360.0 / W.period
local GMODEL = {}
for _, m in ipairs(W.models) do GMODEL[joaat(m)] = true end
local gondolas = {}

local function angleOf(ent)
    local p = GetEntityCoords(ent)
    return math.deg(math.atan(p.z - W.hub.z, (p.x - W.hub.x) * U.x + (p.y - W.hub.y) * U.y))
end

local function rel(ent) return (angleOf(ent) + 90.0) % 360.0 end

local function inWindow(r) return r >= 360.0 - W.window or r <= W.window end

local function scanByClock()
    local now = (GetCloudTimeAsInt() % math.floor(W.period)) / W.period * 360.0
    local found = {}
    for _, o in ipairs(GetGamePool('CObject')) do
        if GMODEL[GetEntityModel(o)] then found[math.floor((angleOf(o) - now) / (360.0 / W.n) + 0.5) % W.n + 1] = o end
    end
    return found
end

local fromMarket = false
local function scanGondolas()
    local ok, list = pcall(function() return exports['olentrix_mpc_market']:gondolas() end)
    if ok and type(list) == 'table' and next(list) then
        local found = {}
        for i = 1, W.n do if list[i] and DoesEntityExist(list[i]) then found[i] = list[i] end end
        gondolas, fromMarket = found, true
    else
        gondolas, fromMarket = scanByClock(), false
    end
end

local seat = nil
local asked = nil
local queue = nil

local function keyOf(s)
    return s.keyG and 47 or 38, s.keyG and '[G]' or '[E]'
end

local function release()
    if seat then TriggerServerEvent('olentrix_mpc_seats:leave', seat.key) end
    seat = nil
end

local function standUp()
    ClearPedTasks(PlayerPedId())
    release()
end

local function dropAnchor()
    local a = seat and seat.anchor
    if a and DoesEntityExist(a) then SetEntityAsMissionEntity(a, true, true); DeleteEntity(a) end
end

local function rideLog(what, ped, target)
    if not W.log or not seat or not seat.gond then return end
    local p = GetEntityCoords(ped); local a = seat.anchor
    TriggerServerEvent('olentrix_mpc_seats:ridelog', ('%s gondola %d (entity %d, %s) seat %d rel %.1f ped %.2f %.2f %.2f target %.2f %.2f %.2f off %.3f attached %s anchor %s'):format(
        what, seat.gond, seat.ent or 0, fromMarket and 'from the market' or 'by clock', seat.spot, DoesEntityExist(seat.ent) and rel(seat.ent) or -1,
        p.x, p.y, p.z, target and target.x or 0, target and target.y or 0, target and target.z or 0, target and #(p - target) or -1,
        tostring(a and IsEntityAttachedToEntity(ped, a)), a and (NetworkGetEntityIsNetworked(a) and ('net ' .. ObjToNet(a)) or 'local') or 'none'))
end

local function stepOff()
    local ped = PlayerPedId()
    rideLog('off', ped)
    DetachEntity(ped, true, false); FreezeEntityPosition(ped, false); SetEntityCollision(ped, true, true); ClearPedTasksImmediately(ped)
    dropAnchor()
    SetEntityCoords(ped, W.point.x, W.point.y, W.point.z + 1.0, false, false, false, false)
    SetEntityHeading(ped, W.exitHeading)
    release()
end

local function sitFixed(s)
    local ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    TaskStartScenarioAtPosition(ped, s.chair and C.Chair or C.Bench, s.x, s.y, s.z + C.SitZ, s.h, 0, true, true)
end

local RIDE_ANIM = 1 + 512 + 2048
local function pose(ped)
    TaskPlayAnim(ped, W.pose.dict, W.pose.clip, 1000.0, -4.0, -1, RIDE_ANIM, 0.0, false, false, false)
end

local function seatOn(g, k)
    local sp = GondolaSeats[k]
    return GetOffsetFromEntityInWorldCoords(g, sp.x, sp.y, sp.z + W.poseZ), (GetEntityHeading(g) + sp.h) % 360.0
end

local function attach(ped, a)
    AttachEntityToEntity(ped, a, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
end

local function sitGondola(g, k)
    local ped = PlayerPedId()
    if not loadDict(W.pose.dict) then return nil end
    local h = joaat(W.anchor); RequestModel(h)
    local n = 0
    while not HasModelLoaded(h) and n < 300 do Wait(10); n = n + 1 end
    if not HasModelLoaded(h) then return nil end
    local w, hd = seatOn(g, k)
    local a = CreateObjectNoOffset(h, w.x, w.y, w.z, true, true, false)
    SetModelAsNoLongerNeeded(h)
    if not a or a == 0 then return nil end
    SetEntityVisible(a, false, false); SetEntityCollision(a, false, false); FreezeEntityPosition(a, true); SetEntityHeading(a, hd)
    ClearPedTasksImmediately(ped)
    SetEntityCollision(ped, false, false)
    attach(ped, a)
    pose(ped)
    return a
end

RegisterNetEvent('olentrix_mpc_seats:granted', function(key, ok)
    if key ~= asked then if ok then TriggerServerEvent('olentrix_mpc_seats:leave', key) end return end
    asked = nil
    if not ok then note('Someone is already sitting there.'); return end
    local s = Seats[tonumber(key:sub(2))]
    seat = { key = key, fixed = s, since = GetGameTimer() }
    sitFixed(s)
end)

RegisterNetEvent('olentrix_mpc_seats:boarded', function(i, k)
    if asked ~= 'w' .. i then if k then TriggerServerEvent('olentrix_mpc_seats:leave', ('w%d:%d'):format(i, k)) end return end
    asked = nil
    if not k then if queue then queue.tried[i] = true end return end
    local key = ('w%d:%d'):format(i, k)
    local g = gondolas[i]
    local a = queue and g and DoesEntityExist(g) and inWindow(rel(g)) and sitGondola(g, k)
    if not a then TriggerServerEvent('olentrix_mpc_seats:leave', key); return end
    queue = nil
    seat = { key = key, gond = i, spot = k, ent = g, anchor = a, since = GetGameTimer(), last = rel(g), logAt = 0 }
    rideLog('on', PlayerPedId(), (seatOn(g, k)))
end)

local near, nearWheel = {}, false
CreateThread(function()
    while true do
        local p = GetEntityCoords(PlayerPedId())
        local list = {}
        for i, s in ipairs(Seats) do
            if math.abs(s.x - p.x) < 20.0 and math.abs(s.y - p.y) < 20.0 then
                s.key = s.key or ('s' .. i); s.pos = s.pos or vector3(s.x, s.y, s.z)
                list[#list + 1] = s
            end
        end
        near = list
        nearWheel = #(p - W.point) < 25.0
        if nearWheel then scanGondolas() end
        Wait(500)
    end
end)

local function ride(ped)
    local g, a = seat.ent, seat.anchor
    DisableControlAction(0, 22, true); DisableControlAction(0, 24, true); DisableControlAction(0, 25, true)
    if IsEntityDead(ped) or not DoesEntityExist(g) or not DoesEntityExist(a) then stepOff(); return end
    local w, hd = seatOn(g, seat.spot)
    SetEntityCoordsNoOffset(a, w.x, w.y, w.z, false, false, false); SetEntityHeading(a, hd)
    if not IsEntityAttachedToEntity(ped, a) then attach(ped, a) end
    if not IsEntityPlayingAnim(ped, W.pose.dict, W.pose.clip, 3) then pose(ped) end
    if GetGameTimer() > seat.logAt then seat.logAt = GetGameTimer() + W.logEvery * 1000; rideLog('ride', ped, w) end
    local r = rel(g)
    local round = GetGameTimer() - seat.since > W.period * 500.0 and seat.last > 270.0 and r < 90.0
    seat.last = r
    if round then stepOff(); return end
    if inWindow(r) then
        help('[Backspace] Get off')
        if IsControlJustReleased(0, W.offKey) then stepOff(); return end
    end
end

local function queueStep(p)
    if #(p.xy - W.point.xy) > W.reach + 1.5 or IsControlJustReleased(0, W.offKey) then queue = nil; return end
    local nextIn
    for i, g in pairs(gondolas) do
        if DoesEntityExist(g) and not queue.tried[i] then
            local r = rel(g)
            if inWindow(r) then
                if not asked then asked = 'w' .. i; TriggerServerEvent('olentrix_mpc_seats:board', i) end
                nextIn = 0
            else
                local t = ((360.0 - W.window) - r) / RATE
                if t > 0 and (not nextIn or t < nextIn) then nextIn = t end
            end
        end
    end
    if nextIn and nextIn > 0 then help(('Next gondola in %d s   [Backspace] Cancel'):format(math.ceil(nextIn)))
    else help('Boarding the Ferris wheel...') end
end

local function wheelPrompt(ped, p)
    if #(p - W.point) < 30.0 then
        DrawMarker(25, W.point.x, W.point.y, W.point.z + 0.03, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.3, 1.3, 1.0, 235, 190, 90, 150, false, false, 2, false, nil, nil, false)
    end
    if #(p.xy - W.point.xy) < W.reach and math.abs(p.z - W.point.z - 1.0) < 1.5 then
        help('[E] Ride the Ferris wheel')
        if IsControlJustReleased(0, 38) then queue = { tried = {} } end
        return true
    end
end

CreateThread(function()
    local MOVE = { 32, 33, 34, 35 }
    while true do
        local ped = PlayerPedId()
        local p = GetEntityCoords(ped)
        if seat and seat.gond then
            ride(ped)
            Wait(0)
        elseif seat then
            local key, label = keyOf(seat.fixed)
            local moved = false
            for _, c in ipairs(MOVE) do if IsControlJustPressed(0, c) then moved = true end end
            local settled = GetGameTimer() - seat.since > 3000
            if IsEntityDead(ped) or IsPedInAnyVehicle(ped, true) or IsPedRagdoll(ped)
                or (settled and (not IsPedUsingAnyScenario(ped) or #(p.xy - seat.fixed.pos.xy) > 1.0)) then
                release()
            else
                help(label .. ' Stand up')
                if moved or IsControlJustReleased(0, key) then standUp() end
            end
            Wait(0)
        elseif queue then
            if IsEntityDead(ped) or IsPedInAnyVehicle(ped, true) then queue = nil else queueStep(p) end
            Wait(0)
        elseif (#near > 0 or nearWheel) and not IsPedInAnyVehicle(ped, true) and not IsEntityDead(ped) then
            if not (nearWheel and wheelPrompt(ped, p)) and not asked then
                local best, bestD
                for _, s in ipairs(near) do
                    local d = #(p.xy - s.pos.xy)
                    if d < C.Reach and d < (bestD or 99.0) and math.abs(p.z - s.z) < 1.6 then best, bestD = s, d end
                end
                if best then
                    local key, label = keyOf(best)
                    help(label .. ' Sit')
                    if IsControlJustReleased(0, key) then
                        if occupied(best.pos) then note('Someone is already sitting there.')
                        else asked = best.key; TriggerServerEvent('olentrix_mpc_seats:claim', best.key) end
                    end
                end
            end
            Wait(0)
        else
            Wait(250)
        end
    end
end)

CreateThread(function()
    while true do
        local a = asked
        Wait(4000)
        if a and asked == a then asked = nil end
    end
end)

local AMBIENT = { [1] = true, [2] = true, [3] = true, [4] = true, [5] = true }
local blocks, pops, applied = {}, {}, false
local Z0, Z1 = Area.min.z, Area.max.z

local function apply(on)
    for i, b in ipairs(Area.boxes) do
        local x0, y0, x1, y1 = b[1], b[2], b[3], b[4]
        if on then
            blocks[#blocks + 1] = AddScenarioBlockingArea(x0, y0, Z0, x1, y1, Z1, false, true, true, true)
            SetAllVehicleGeneratorsActiveInArea(x0, y0, Z0, x1, y1, Z1, false, false)
            RemoveVehiclesFromGeneratorsInArea(x0, y0, Z0, x1, y1, Z1, false)
            if i <= C.Clear.popAreas then pops[#pops + 1] = AddPopMultiplierArea(x0, y0, Z0, x1, y1, Z1, 0.0, 0.0, false) end
            if b.spur then
                SetRoadsInArea(x0, y0, Z0, x1, y1, Z1, false, false)
                SetPedPathsInArea(x0, y0, Z0, x1, y1, Z1, false)
            end
        else
            SetAllVehicleGeneratorsActiveInArea(x0, y0, Z0, x1, y1, Z1, true, false)
            if b.spur then
                SetRoadsBackToOriginal(x0, y0, Z0, x1, y1, Z1)
                SetPedPathsBackToOriginal(x0, y0, Z0, x1, y1, Z1)
            end
        end
    end
    if not on then
        for _, h in ipairs(blocks) do RemoveScenarioBlockingArea(h, false) end
        for _, h in ipairs(pops) do if h and h >= 0 then RemovePopMultiplierArea(h, false) end end
        blocks, pops = {}, {}
    end
    applied = on
end

local function playerCar(veh)
    for s = -1, GetVehicleMaxNumberOfPassengers(veh) - 1 do
        local p = GetPedInVehicleSeat(veh, s)
        if p ~= 0 and IsPedAPlayer(p) then return true end
    end
    local last = GetLastPedInVehicleSeat(veh, -1)
    return last ~= 0 and IsPedAPlayer(last)
end

local function ambient(ent)
    return AMBIENT[GetEntityPopulationType(ent)] and not IsEntityAMissionEntity(ent) and NetworkHasControlOfEntity(ent)
end

local function inArea(ent)
    local c = GetEntityCoords(ent)
    return c.z > Z0 and c.z < Z1 and inside(c.x, c.y)
end

local function unseen(ent, cam)
    return not IsEntityOnScreen(ent) or #(GetEntityCoords(ent) - cam) > C.Clear.seen
end

local function remove(ent)
    SetEntityAsMissionEntity(ent, true, true)
    DeleteEntity(ent)
end

CreateThread(function()
    local mid = vector2((Area.min.x + Area.max.x) / 2, (Area.min.y + Area.max.y) / 2)
    local reach = #(vector2(Area.max.x, Area.max.y) - mid) + C.Clear.range
    apply(true)
    while true do
        local p = GetEntityCoords(PlayerPedId())
        if #(p.xy - mid) < reach then
            local cam = GetFinalRenderedCamCoord()
            for _, ped in ipairs(GetGamePool('CPed')) do
                if not IsPedAPlayer(ped) and not IsPedInAnyVehicle(ped, true) and ambient(ped) and inArea(ped) and unseen(ped, cam) then
                    remove(ped)
                end
            end
            for _, veh in ipairs(GetGamePool('CVehicle')) do
                local class = GetVehicleClass(veh)
                if class ~= 21 and class ~= 15 and class ~= 16 and ambient(veh) and not playerCar(veh) and inArea(veh) then
                    local driver = GetPedInVehicleSeat(veh, -1)
                    if driver == 0 or unseen(veh, cam) then
                        for s = -1, GetVehicleMaxNumberOfPassengers(veh) - 1 do
                            local o = GetPedInVehicleSeat(veh, s)
                            if o ~= 0 and not IsPedAPlayer(o) and not IsEntityAMissionEntity(o) then remove(o) end
                        end
                        remove(veh)
                    end
                end
            end
            Wait(1000)
        else
            Wait(4000)
        end
    end
end)

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    if seat then
        local ped = PlayerPedId()
        ClearPedTasksImmediately(ped)
        if seat.gond then
            DetachEntity(ped, true, false); FreezeEntityPosition(ped, false); SetEntityCollision(ped, true, true); dropAnchor()
            SetEntityCoords(ped, W.point.x, W.point.y, W.point.z + 1.0, false, false, false, false)
        end
    end
    if applied then apply(false) end
end)
