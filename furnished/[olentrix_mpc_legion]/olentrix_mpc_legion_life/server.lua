AddEventHandler('weaponDamageEvent', function(sender, ev)
    if ev and ev.weaponType == `WEAPON_SNOWBALL` then CancelEvent() end
end)

local held = {}

local function where(key)
    local n = key:match('^s(%d+)$')
    if n then local s = Seats[tonumber(n)]; return s and vector3(s.x, s.y, s.z), 4.0 end
end

local function releaseAll(src)
    for k, p in pairs(held) do if p == src then held[k] = nil end end
end

local function near(src, pos, reach)
    local ped = GetPlayerPed(src)
    return ped ~= 0 and #(GetEntityCoords(ped) - pos) < reach
end

RegisterNetEvent('olentrix_mpc_legion_life:seats:claim', function(key)
    local src = source
    if type(key) ~= 'string' or not key:match('^s%d+$') then return end
    local pos, reach = where(key)
    if not pos then return end
    local ok = near(src, pos, reach) and (held[key] == nil or held[key] == src)
    if ok then releaseAll(src); held[key] = src end
    TriggerClientEvent('olentrix_mpc_legion_life:seats:granted', src, key, ok)
end)

RegisterNetEvent('olentrix_mpc_legion_life:seats:leave', function(key)
    if held[key] == source then held[key] = nil end
end)

AddEventHandler('playerDropped', function() releaseAll(source) end)

CreateThread(function()
    while true do
        Wait(10000)
        for key, src in pairs(held) do
            local pos, reach = where(key)
            if not pos or not near(src, pos, reach + 2.0) then held[key] = nil end
        end
    end
end)
