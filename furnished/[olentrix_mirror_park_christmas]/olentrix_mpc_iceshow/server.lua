local state, startedAt, nextAt, soonAt = nil, 0, 0, 0

local function publish()
    GlobalState.xmasIceShow = state
    GlobalState.xmasIceShowNext = nextAt
end

local function tell(src, msg)
    TriggerClientEvent('olentrix_mpc_iceshow:notice', src, msg)
end

local function begin(by)
    state, soonAt = 'soon', GetGameTimer()
    publish()
    TriggerClientEvent('olentrix_mpc_iceshow:soon', -1, Config.Lead * 1000)
    print(('[olentrix_mpc_iceshow] show called (%s)'):format(by))
    SetTimeout(math.floor(Config.Lead * 1000), function()
        state, startedAt = 'on', GetGameTimer()
        publish()
        TriggerClientEvent('olentrix_mpc_iceshow:play', -1, 0)
        print('[olentrix_mpc_iceshow] show started')
        SetTimeout(math.floor(Routine.length * 1000), function()
            state = nil
            nextAt = os.time() + Config.Cooldown
            publish()
            print('[olentrix_mpc_iceshow] show ended')
        end)
    end)
end

RegisterNetEvent('olentrix_mpc_iceshow:start', function()
    local src = source
    if state then return tell(src, Config.Text.busy) end
    local now = os.time()
    if now < nextAt then return tell(src, Config.Text.cooldown:format(math.ceil((nextAt - now) / 60))) end
    local ped = GetPlayerPed(src)
    if ped ~= 0 then
        local d = #(GetEntityCoords(ped) - Config.Start.position)
        if d > Config.Start.reach + 4.0 then return end
    end
    begin('player ' .. src)
end)

RegisterNetEvent('olentrix_mpc_iceshow:sync', function()
    if state == 'on' then TriggerClientEvent('olentrix_mpc_iceshow:play', source, GetGameTimer() - startedAt) end
    if state == 'soon' then TriggerClientEvent('olentrix_mpc_iceshow:soon', source, Config.Lead * 1000 - (GetGameTimer() - soonAt)) end
end)

exports('isRunning', function() return state == 'on' end)

publish()
