local busy, busyUntil = nil, 0
local lastSeen = {}

local function key(src)
    return GetPlayerIdentifierByType(src, 'license') or GetPlayerIdentifierByType(src, 'license2') or ('id:' .. src)
end

local function publish()
    GlobalState.legionGorilla = { busy = busy ~= nil }
end

local function release(src)
    if busy == src then
        busy = nil
        publish()
    end
end

RegisterNetEvent('olentrix_mpc_legion_gorilla:open', function(side, u)
    local src = source
    side = side == -1 and -1 or 1
    u = math.max(-0.6, math.min(0.6, tonumber(u) or 0.0))
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 or #(GetEntityCoords(ped) - Config.Grate.pos) > Config.ServerReach then
        TriggerClientEvent('olentrix_mpc_legion_gorilla:refuse', src, 'far')
        return
    end
    if busy and os.time() < busyUntil then
        TriggerClientEvent('olentrix_mpc_legion_gorilla:refuse', src, 'busy')
        return
    end
    local k = key(src)
    local left = lastSeen[k] and (lastSeen[k] + Config.Cooldown - os.time()) or 0
    if left > 0 then
        TriggerClientEvent('olentrix_mpc_legion_gorilla:refuse', src, 'cooldown', left)
        return
    end
    lastSeen[k] = os.time()
    busy, busyUntil = src, os.time() + math.ceil(Timing.done) + 4
    publish()
    TriggerClientEvent('olentrix_mpc_legion_gorilla:go', -1, src, side, u)
end)

RegisterNetEvent('olentrix_mpc_legion_gorilla:done', function()
    release(source)
end)

AddEventHandler('playerDropped', function()
    release(source)
end)

CreateThread(function()
    publish()
    while true do
        Wait(2000)
        if busy and os.time() >= busyUntil then
            busy = nil
            publish()
        end
    end
end)
