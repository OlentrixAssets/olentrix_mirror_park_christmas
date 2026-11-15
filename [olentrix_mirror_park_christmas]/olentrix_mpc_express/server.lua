local SEATS = 2 * #RailData.seats
local taken = {}

local function release(src)
    for i = 1, SEATS do if taken[i] == src then taken[i] = nil end end
end

RegisterNetEvent('olentrix_mpc_express:board', function()
    local src = source
    release(src)
    for i = 1, SEATS do
        if not taken[i] then taken[i] = src; TriggerClientEvent('olentrix_mpc_express:seat', src, i); return end
    end
    TriggerClientEvent('olentrix_mpc_express:seat', src, false)
end)

RegisterNetEvent('olentrix_mpc_express:leave', function() release(source) end)
AddEventHandler('playerDropped', function() release(source) end)
