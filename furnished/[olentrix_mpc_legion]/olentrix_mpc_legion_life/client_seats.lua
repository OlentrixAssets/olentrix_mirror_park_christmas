local REACH, SITZ, TAKEN = 1.25, 0.03, 0.4
local BENCH, CHAIR = 'PROP_HUMAN_SEAT_BENCH', 'PROP_HUMAN_SEAT_CHAIR_MP_PLAYER'

local function help(text)
    BeginTextCommandDisplayHelp('STRING'); AddTextComponentSubstringPlayerName(text); EndTextCommandDisplayHelp(0, false, false, -1)
end

local function note(text)
    BeginTextCommandThefeedPost('STRING'); AddTextComponentSubstringPlayerName(text); EndTextCommandThefeedPostTicker(false, false)
end

local function occupied(pos)
    local me = PlayerPedId()
    for _, ped in ipairs(GetGamePool('CPed')) do
        if ped ~= me and #(GetEntityCoords(ped) - pos) < TAKEN + 0.6 and #(GetEntityCoords(ped).xy - pos.xy) < TAKEN then return true end
    end
    return false
end

local seat, asked = nil, nil

local function keyOf(s)
    return s.keyG and 47 or 38, s.keyG and '[G]' or '[E]'
end

local function release()
    if seat then TriggerServerEvent('olentrix_mpc_legion_life:seats:leave', seat.key) end
    seat = nil
end

local function standUp()
    ClearPedTasks(PlayerPedId())
    release()
end

local function sitFixed(s)
    local ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    TaskStartScenarioAtPosition(ped, s.chair and CHAIR or BENCH, s.x, s.y, s.z + SITZ, s.h, 0, true, true)
end

RegisterNetEvent('olentrix_mpc_legion_life:seats:granted', function(key, ok)
    if key ~= asked then if ok then TriggerServerEvent('olentrix_mpc_legion_life:seats:leave', key) end return end
    asked = nil
    if not ok then note('Someone is already sitting there.'); return end
    local s = Seats[tonumber(key:sub(2))]
    seat = { key = key, fixed = s, since = GetGameTimer() }
    sitFixed(s)
end)

local near = {}
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
        Wait(500)
    end
end)

CreateThread(function()
    local MOVE = { 32, 33, 34, 35 }
    while true do
        local ped = PlayerPedId()
        local p = GetEntityCoords(ped)
        if seat then
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
        elseif #near > 0 and not IsPedInAnyVehicle(ped, true) and not IsEntityDead(ped) then
            if not asked then
                local best, bestD
                for _, s in ipairs(near) do
                    local d = #(p.xy - s.pos.xy)
                    if d < REACH and d < (bestD or 99.0) and math.abs(p.z - s.z) < 1.6 then best, bestD = s, d end
                end
                if best then
                    local key, label = keyOf(best)
                    help(label .. ' Sit')
                    if IsControlJustReleased(0, key) then
                        if occupied(best.pos) then note('Someone is already sitting there.')
                        else asked = best.key; TriggerServerEvent('olentrix_mpc_legion_life:seats:claim', best.key) end
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

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    if seat then ClearPedTasksImmediately(PlayerPedId()) end
end)
