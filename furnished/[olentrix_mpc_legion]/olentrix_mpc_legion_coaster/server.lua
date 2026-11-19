local GAP = 15000
local last = -GAP
local riding = {}

RegisterNetEvent('olentrix_mpc_legion_coaster:ask', function()
    local src = source
    if riding[src] and GetGameTimer() - riding[src] < 90000 then return end
    local now = GetGameTimer()
    local wait = GAP - (now - last)
    if wait > 0 then
        TriggerClientEvent('olentrix_mpc_legion_coaster:wait', src, math.ceil(wait / 1000))
        return
    end
    last = now
    riding[src] = now
    TriggerClientEvent('olentrix_mpc_legion_coaster:go', -1, src, 1500)
end)

RegisterNetEvent('olentrix_mpc_legion_coaster:done', function()
    riding[source] = nil
end)

AddEventHandler('playerDropped', function()
    riding[source] = nil
end)
