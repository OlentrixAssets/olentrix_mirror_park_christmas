local C = Config
local owned = {}
local lastBuy = {}

local function key(src)
    return GetPlayerIdentifierByType(src, 'license') or ('player:' .. src)
end

local function shops()
    return GetResourceState('xmas_shops') == 'started'
end

local function hasSkates(src)
    if shops() then
        local ok, res = pcall(function() return exports.xmas_shops:hasItem(src, C.Item) end)
        return ok and res == true
    end
    return owned[key(src)] == true
end

local function buySkates(src)
    if shops() then
        local ok, res, reason = pcall(function() return exports.xmas_shops:buy(src, C.Item, 1, C.Price) end)
        if not ok then return false, 'error' end
        return res == true, reason
    end
    owned[key(src)] = true
    return true
end

local function near(src, pos, reach)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    local p = GetEntityCoords(ped)
    return #(vector2(p.x, p.y) - vector2(pos.x, pos.y)) < reach
end

local function nearSpot(src)
    for _, s in ipairs(C.ChangeSpots) do
        if near(src, s.centre, math.max(s.half.x, s.half.y) + 3.0) then return true end
    end
    return false
end

RegisterNetEvent('olentrix_mpc_skating:buy', function()
    local src = source
    if not near(src, C.Counter.pos, C.Counter.reach + 3.0) then return end
    local now = GetGameTimer()
    if lastBuy[src] and now - lastBuy[src] < 2000 then return end
    lastBuy[src] = now
    if hasSkates(src) then TriggerClientEvent('olentrix_mpc_skating:msg', src, 'have'); return end
    local ok, reason = buySkates(src)
    if ok then
        TriggerClientEvent('olentrix_mpc_skating:msg', src, 'bought')
    else
        TriggerClientEvent('olentrix_mpc_skating:msg', src, (reason == 'money' or reason == 'space') and reason or 'error')
    end
end)

RegisterNetEvent('olentrix_mpc_skating:ask', function(wantOn)
    local src = source
    if not nearSpot(src) then return end
    if wantOn and not hasSkates(src) then TriggerClientEvent('olentrix_mpc_skating:msg', src, 'need'); return end
    TriggerClientEvent('olentrix_mpc_skating:go', src, wantOn == true)
end)

RegisterNetEvent('olentrix_mpc_skating:done', function(wantOn)
    local src = source
    local st = Player(src).state
    if wantOn then
        if not nearSpot(src) or not hasSkates(src) then return end
        st:set('xmasSkates', true, true)
    else
        st:set('xmasSkates', false, true)
    end
end)

CreateThread(function()
    while true do
        Wait(15000)
        for _, id in ipairs(GetPlayers()) do
            local src = tonumber(id)
            if Player(src).state.xmasSkates and not hasSkates(src) then Player(src).state:set('xmasSkates', false, true) end
        end
    end
end)

AddEventHandler('playerDropped', function()
    lastBuy[source] = nil
end)
