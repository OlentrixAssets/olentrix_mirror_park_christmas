local held = {}
local W = Config.Wheel

local function where(key)
    local n = key:match('^s(%d+)$')
    if n then local s = Seats[tonumber(n)]; return s and vector3(s.x, s.y, s.z), 4.0 end
    local i, k = key:match('^w(%d+):(%d+)$')
    if i and tonumber(i) >= 1 and tonumber(i) <= W.n and GondolaSeats[tonumber(k)] then return W.point, 40.0 end
end

local function releaseAll(src)
    for k, p in pairs(held) do if p == src then held[k] = nil end end
end

local function near(src, pos, reach)
    local ped = GetPlayerPed(src)
    return ped ~= 0 and #(GetEntityCoords(ped) - pos) < reach
end

RegisterNetEvent('olentrix_mpc_seats:claim', function(key)
    local src = source
    if type(key) ~= 'string' or not key:match('^s%d+$') then return end
    local pos, reach = where(key)
    if not pos then return end
    local ok = near(src, pos, reach) and (held[key] == nil or held[key] == src)
    if ok then releaseAll(src); held[key] = src end
    TriggerClientEvent('olentrix_mpc_seats:granted', src, key, ok)
end)

RegisterNetEvent('olentrix_mpc_seats:board', function(i)
    local src = source
    i = math.tointeger(tonumber(i))
    if not i or i < 1 or i > W.n then return end
    local seat = false
    if near(src, W.point, W.reach + 4.0) then
        releaseAll(src)
        for k = 1, #GondolaSeats do
            local key = ('w%d:%d'):format(i, k)
            if not held[key] then held[key] = src; seat = k; break end
        end
    end
    TriggerClientEvent('olentrix_mpc_seats:boarded', src, i, seat)
end)

RegisterNetEvent('olentrix_mpc_seats:leave', function(key)
    if held[key] == source then held[key] = nil end
end)

local logged = {}
RegisterNetEvent('olentrix_mpc_seats:ridelog', function(line)
    local src = source
    if not W.log or type(line) ~= 'string' or #line > 400 then return end
    local now = GetGameTimer()
    if logged[src] and now - logged[src] < 2000 then return end
    logged[src] = now
    print(('[olentrix_mpc_seats] %s (%d): %s'):format(GetPlayerName(src) or '?', src, line))
end)

AddEventHandler('playerDropped', function() releaseAll(source); logged[source] = nil end)

CreateThread(function()
    while true do
        Wait(10000)
        for key, src in pairs(held) do
            local pos, reach = where(key)
            if not pos or not near(src, pos, reach + 2.0) then held[key] = nil end
        end
    end
end)
