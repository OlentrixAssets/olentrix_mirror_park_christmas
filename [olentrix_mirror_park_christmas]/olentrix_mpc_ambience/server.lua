local C = Config.Ceremony
local running, startedAt, lastRun = false, 0, -math.huge

local function begin(by)
    if running then return false end
    running, startedAt, lastRun = true, GetGameTimer(), os.time()
    TriggerClientEvent('olentrix_mpc_ambience:ceremony', -1, 0)
    print(('[olentrix_mpc_ambience] light ceremony started (%s)'):format(by))
    SetTimeout(math.floor(C.Duration * 1000), function() running = false end)
    return true
end

RegisterNetEvent('olentrix_mpc_ambience:sync', function()
    if running then TriggerClientEvent('olentrix_mpc_ambience:ceremony', source, GetGameTimer() - startedAt) end
end)

RegisterCommand(C.Command, function(src)
    local ok = begin(src == 0 and 'console' or ('player ' .. src))
    local msg = ok and 'Light ceremony started.' or 'A light ceremony is already running.'
    if src == 0 then print('[olentrix_mpc_ambience] ' .. msg) else TriggerClientEvent('chat:addMessage', src, { args = { 'Market', msg } }) end
end, true)

local function someoneNear()
    local players = GetPlayers()
    if #players == 0 then return false end
    for _, id in ipairs(players) do
        local ped = GetPlayerPed(id)
        if ped == 0 then return true end
        local p = GetEntityCoords(ped)
        if #(p - Config.SiteCentre) < C.PlayersNear then return true end
    end
    return false
end

local function due()
    local t = GlobalState.currentTime
    if type(t) == 'table' and t.hour then
        for _, h in ipairs(C.GameHours) do if t.hour == h and (t.minute or 0) < 5 then return true end end
        return false
    end
    local now = os.date('%H:%M')
    for _, hm in ipairs(C.RealTimes) do if now == hm then return true end end
    return false
end

CreateThread(function()
    while true do
        Wait(15000)
        if not running and os.time() - lastRun >= C.CooldownMinutes * 60 and due() and someoneNear() then begin('schedule') end
    end
end)
