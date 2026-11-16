local spot = math.random(#Spots)
local talking, talkingUntil = nil, 0
local knocked = {}
local lastSeen = {}
local nextMove = 0

local function key(src)
    return GetPlayerIdentifierByType(src, 'license') or GetPlayerIdentifierByType(src, 'license2') or ('id:' .. src)
end

local function publish()
    GlobalState.xmasElf = { spot = spot, busy = talking or false }
end

local function scheduleMove()
    nextMove = os.time() + math.random(Config.Move.min, Config.Move.max)
end

local function near(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    local s = Spots[spot]
    return #(GetEntityCoords(ped) - vector3(s.x, s.y, s.z)) < Config.ServerReach
end

local function release(src)
    if talking == src then
        talking = nil
        publish()
        scheduleMove()
    end
end

local function waitLeft(src)
    local last = lastSeen[key(src)]
    if not last then return 0 end
    return math.max(0, last + Config.Cooldown - os.time())
end

RegisterNetEvent('olentrix_mpc_elf:talk', function()
    local src = source
    if not near(src) then
        TriggerClientEvent('olentrix_mpc_elf:refuse', src, 'far')
        return
    end
    if talking and talking ~= src and os.time() < talkingUntil then
        TriggerClientEvent('olentrix_mpc_elf:refuse', src, 'busy')
        return
    end
    local left = waitLeft(src)
    if left > 0 then
        TriggerClientEvent('olentrix_mpc_elf:refuse', src, 'cooldown', left)
        return
    end
    talking, talkingUntil = src, os.time() + Config.ChoiceSeconds + 2
    publish()
    TriggerClientEvent('olentrix_mpc_elf:ask', src, spot)
end)

RegisterNetEvent('olentrix_mpc_elf:cancel', function()
    release(source)
end)

RegisterNetEvent('olentrix_mpc_elf:choose', function(kind)
    local src = source
    if kind ~= 'nice' and kind ~= 'naughty' then return end
    if talking ~= src then
        TriggerClientEvent('olentrix_mpc_elf:refuse', src, 'expired')
        return
    end
    if not near(src) then
        release(src)
        TriggerClientEvent('olentrix_mpc_elf:refuse', src, 'far')
        return
    end
    lastSeen[key(src)] = os.time()
    if kind == 'naughty' then knocked[src] = os.time() + math.ceil(Config.Scene.length) + 30 end
    TriggerClientEvent('olentrix_mpc_elf:act', -1, kind, src, spot)
    talkingUntil = os.time() + 4
    SetTimeout(4000, function() release(src) end)
end)

RegisterNetEvent('olentrix_mpc_elf:woke', function()
    knocked[source] = nil
    scheduleMove()
end)

AddEventHandler('playerDropped', function()
    local src = source
    knocked[src] = nil
    release(src)
end)

CreateThread(function()
    publish()
    scheduleMove()
    while true do
        Wait(5000)
        local now = os.time()
        if talking and now >= talkingUntil then
            talking = nil
            publish()
        end
        for src, untilAt in pairs(knocked) do
            if now >= untilAt then knocked[src] = nil end
        end
        if now >= nextMove and not talking and not next(knocked) and #Spots > 1 then
            local pick = math.random(#Spots - 1)
            spot = pick >= spot and pick + 1 or pick
            publish()
            scheduleMove()
        end
    end
end)
