local held = {}
local W = Config.Wheel
local BASE = vector3(W.hub.x, W.hub.y, W.hub.z - W.r)

local function where(key)
    local n = key:match('^s(%d+)$')
    if n then local s = Seats[tonumber(n)]; return s and vector3(s.x, s.y, s.z), 4.0 end
    local i, k = key:match('^w(%d+):(%d+)$')
    if i and tonumber(i) >= 1 and tonumber(i) <= W.n and GondolaSeats[tonumber(k)] then return BASE, 40.0 end
end

local function releaseAll(src)
    for k, p in pairs(held) do if p == src then held[k] = nil end end
end

RegisterNetEvent('olentrix_mpc_seats:claim', function(key)
    local src = source
    if type(key) ~= 'string' then return end
    local pos, reach = where(key)
    if not pos then return end
    local ped = GetPlayerPed(src)
    local ok = ped ~= 0 and #(GetEntityCoords(ped) - pos) < reach and (held[key] == nil or held[key] == src)
    if ok then releaseAll(src); held[key] = src end
    TriggerClientEvent('olentrix_mpc_seats:granted', src, key, ok)
end)

RegisterNetEvent('olentrix_mpc_seats:leave', function(key)
    if held[key] == source then held[key] = nil end
end)

AddEventHandler('playerDropped', function() releaseAll(source) end)

CreateThread(function()
    while true do
        Wait(10000)
        for key, src in pairs(held) do
            local ped = GetPlayerPed(src)
            local pos, reach = where(key)
            if ped == 0 or not pos or #(GetEntityCoords(ped) - pos) > reach + 2.0 then held[key] = nil end
        end
    end
end)
