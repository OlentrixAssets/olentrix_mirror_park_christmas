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
local GMODEL = {}
for _, m in ipairs(W.models) do GMODEL[joaat(m)] = true end
local gondolas = {}

local function gondolaIndex(ent)
    local p = GetEntityCoords(ent)
    local a = math.deg(math.atan(p.z - W.hub.z, (p.x - W.hub.x) * U.x + (p.y - W.hub.y) * U.y))
    local now = (GetCloudTimeAsInt() % math.floor(W.period)) / W.period * 360.0
    return math.floor((a - now) / (360.0 / W.n) + 0.5) % W.n + 1
end

local function atBottom(ent)
    return GetEntityCoords(ent).z < W.hub.z - W.r + W.board
end

local function scanGondolas()
    gondolas = {}
    for _, o in ipairs(GetGamePool('CObject')) do
        if GMODEL[GetEntityModel(o)] then gondolas[gondolaIndex(o)] = o end
    end
end

local seat = nil
local asked = nil

local function keyOf(s)
    return s.keyG and 47 or 38, s.keyG and '~INPUT_DETONATE~' or '~INPUT_CONTEXT~'
end

local function release()
    if seat then TriggerServerEvent('olentrix_mpc_seats:leave', seat.key) end
    seat = nil
end

local function standUp()
    local ped = PlayerPedId()
    if seat and seat.gond then
        local g = gondolas[seat.gond]
        DetachEntity(ped, true, false); ClearPedTasksImmediately(ped)
        if g and DoesEntityExist(g) then
            local p = GetOffsetFromEntityInWorldCoords(g, W.exit.x, W.exit.y, W.exit.z)
            SetEntityCoords(ped, p.x, p.y, p.z, false, false, false, false)
            SetEntityHeading(ped, GetEntityHeading(g) + 90.0)
        end
    else
        ClearPedTasks(ped)
    end
    release()
end

local function sitFixed(s)
    local ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    TaskStartScenarioAtPosition(ped, s.chair and C.Chair or C.Bench, s.x, s.y, s.z + C.SitZ, s.h, 0, true, true)
end

local function sitGondola(g, k)
    local ped = PlayerPedId(); local sp = GondolaSeats[k]
    if not loadDict(W.pose.dict) then return false end
    ClearPedTasksImmediately(ped)
    AttachEntityToEntity(ped, g, 0, sp.x, sp.y, sp.z + W.poseZ, 0.0, 0.0, sp.h, false, false, false, false, 2, true)
    TaskPlayAnim(ped, W.pose.dict, W.pose.clip, 4.0, -4.0, -1, 1, 0.0, false, false, false)
    return true
end

RegisterNetEvent('olentrix_mpc_seats:granted', function(key, ok)
    if key ~= asked then if ok then TriggerServerEvent('olentrix_mpc_seats:leave', key) end return end
    asked = nil
    if not ok then note('Someone is already sitting there.'); return end
    local kind, a, b = key:match('^(%a)(%d+):?(%d*)$')
    if kind == 's' then
        local s = Seats[tonumber(a)]
        seat = { key = key, fixed = s, since = GetGameTimer() }
        sitFixed(s)
    else
        local g = gondolas[tonumber(a)]
        if not g or not DoesEntityExist(g) or not atBottom(g) or not sitGondola(g, tonumber(b)) then
            TriggerServerEvent('olentrix_mpc_seats:leave', key); return
        end
        seat = { key = key, gond = tonumber(a), since = GetGameTimer() }
    end
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
        nearWheel = #(p.xy - W.hub.xy) < 30.0 and math.abs(p.z - (W.hub.z - W.r)) < 8.0
        if nearWheel or (seat and seat.gond) then scanGondolas() end
        Wait(500)
    end
end)

CreateThread(function()
    local MOVE = { 32, 33, 34, 35 }
    while true do
        local ped = PlayerPedId()
        if seat then
            local key, label = 38, '~INPUT_CONTEXT~'
            if seat.fixed then key, label = keyOf(seat.fixed) end
            if seat.gond then
                local g = gondolas[seat.gond]
                DisableControlAction(0, 22, true); DisableControlAction(0, 24, true); DisableControlAction(0, 25, true)
                if IsEntityDead(ped) or not g or not DoesEntityExist(g) or not IsEntityAttachedToEntity(ped, g) then
                    DetachEntity(ped, true, false); release()
                elseif atBottom(g) then
                    help('Press ' .. label .. ' to step off the Ferris wheel')
                    if IsControlJustReleased(0, key) then standUp() end
                elseif not IsEntityPlayingAnim(ped, W.pose.dict, W.pose.clip, 3) then
                    TaskPlayAnim(ped, W.pose.dict, W.pose.clip, 4.0, -4.0, -1, 1, 0.0, false, false, false)
                end
            else
                local moved = false
                for _, c in ipairs(MOVE) do if IsControlJustPressed(0, c) then moved = true end end
                local settled = GetGameTimer() - seat.since > 3000
                if IsEntityDead(ped) or IsPedInAnyVehicle(ped, true) or IsPedRagdoll(ped)
                    or (settled and (not IsPedUsingAnyScenario(ped) or #(GetEntityCoords(ped).xy - seat.fixed.pos.xy) > 1.0)) then
                    release()
                else
                    help('Press ' .. label .. ' to stand up')
                    if moved or IsControlJustReleased(0, key) then standUp() end
                end
            end
            Wait(0)
        elseif (#near > 0 or nearWheel) and not IsPedInAnyVehicle(ped, true) and not IsEntityDead(ped) and not asked then
            local p = GetEntityCoords(ped)
            local best, bestD, bestPos
            for _, s in ipairs(near) do
                local d = #(p.xy - s.pos.xy)
                if d < C.Reach and d < (bestD or 99.0) and math.abs(p.z - s.z) < 1.6 then best, bestD, bestPos = s, d, s.pos end
            end
            if nearWheel then
                for i, g in pairs(gondolas) do
                    if DoesEntityExist(g) and atBottom(g) then
                        for k, sp in ipairs(GondolaSeats) do
                            local w = GetOffsetFromEntityInWorldCoords(g, sp.x, sp.y, sp.z)
                            local d = #(p.xy - w.xy)
                            if d < W.reach and d < (bestD or 99.0) and math.abs(p.z - w.z) < 1.8 then
                                best, bestD, bestPos = { key = ('w%d:%d'):format(i, k) }, d, w
                            end
                        end
                    end
                end
            end
            if best then
                local key, label = keyOf(best)
                help('Press ' .. label .. ' to sit')
                if IsControlJustReleased(0, key) then
                    if occupied(bestPos) then note('Someone is already sitting there.')
                    else asked = best.key; TriggerServerEvent('olentrix_mpc_seats:claim', best.key) end
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
        if seat.gond then DetachEntity(ped, true, false) end
        ClearPedTasksImmediately(ped)
    end
    if applied then apply(false) end
end)
