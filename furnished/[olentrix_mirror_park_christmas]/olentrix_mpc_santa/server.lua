local resource = GetCurrentResourceName()
local grotto = vector3(Spots.origin[1], Spots.origin[2], Spots.origin[3])
local santa
local holders = { lap = false, left = false, right = false }
local lastPhoto = 0
local lastLetter = {}
local queues = { lap = {}, left = {}, right = {} }
local reserved = { lap = false, left = false, right = false }
local letters = json.decode(LoadResourceFile(resource, Config.Letters.file) or '[]') or {}

local function publish()
    GlobalState.xmasSantaSpots = holders
end

local function playerPosition(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return nil end
    return GetEntityCoords(ped)
end

local function near(src, point, range)
    local p = playerPosition(src)
    return p ~= nil and #(p - point) <= range
end

local letterSpots = {}
if Config.Letters.position then letterSpots[#letterSpots + 1] = Config.Letters.position end
for _, spot in ipairs(Config.Letters.spots or {}) do letterSpots[#letterSpots + 1] = spot end

local function nearLetters(src)
    for _, spot in ipairs(letterSpots) do
        if near(src, spot, Config.Letters.reach) then return true end
    end
    return false
end

local function anyoneWithin(range)
    for _, id in ipairs(GetPlayers()) do
        if near(id, grotto, range) then return true end
    end
    return false
end

local function publishLine()
    local held = {}
    for spot, r in pairs(reserved) do held[spot] = r and r.id or false end
    GlobalState.xmasSantaLine = { queues = queues, reserved = held }
end

local function placeOf(src, spot)
    for i, id in ipairs(queues[spot]) do
        if id == src then return i end
    end
end

local function unqueue(src)
    local changed, freed = false, {}
    for _, list in pairs(queues) do
        for i = #list, 1, -1 do
            if list[i] == src then
                table.remove(list, i)
                changed = true
            end
        end
    end
    for spot, r in pairs(reserved) do
        if r and r.id == src then
            reserved[spot] = false
            changed = true
            freed[#freed + 1] = spot
        end
    end
    return changed, freed
end

local function offerNext(spot)
    if holders[spot] or reserved[spot] then return end
    local list, changed = queues[spot], false
    while #list > 0 do
        local id = table.remove(list, 1)
        changed = true
        if GetPlayerName(id) and near(id, grotto, Config.Flow.queueReach) then
            reserved[spot] = { id = id, expires = os.time() + Config.Flow.turnWindow }
            TriggerClientEvent('olentrix_mpc_santa:turn', id, spot, Config.Flow.turnWindow)
            break
        end
    end
    if changed then publishLine() end
end

local function leaveLine(src)
    local changed, freed = unqueue(src)
    if changed then publishLine() end
    for _, spot in ipairs(freed) do offerNext(spot) end
end

local function joinLine(src, spot)
    local at = placeOf(src, spot)
    if not at then
        leaveLine(src)
        local list = queues[spot]
        list[#list + 1] = src
        at = #list
        publishLine()
    end
    TriggerClientEvent('olentrix_mpc_santa:queued', src, spot, at)
end

local function freeSpotsOf(src)
    local freed = {}
    for spot, holder in pairs(holders) do
        if holder == src then
            holders[spot] = false
            freed[#freed + 1] = spot
        end
    end
    if #freed > 0 then publish() end
    for _, spot in ipairs(freed) do offerNext(spot) end
end

local function holds(src)
    for _, holder in pairs(holders) do
        if holder == src then return true end
    end
    return false
end

local function spawnSanta()
    local seat = Spots.seat
    local ped = CreatePed(4, GetHashKey(Config.Santa.model), seat.x, seat.y, seat.z, seat.heading, true, true)
    local started = GetGameTimer()
    while not DoesEntityExist(ped) and GetGameTimer() - started < 5000 do Wait(50) end
    if not DoesEntityExist(ped) then return end
    if SetEntityOrphanMode then SetEntityOrphanMode(ped, 2) end
    FreezeEntityPosition(ped, true)
    santa = ped
    GlobalState.xmasSanta = NetworkGetNetworkIdFromEntity(ped)
end

local function removeSanta()
    if santa and DoesEntityExist(santa) then DeleteEntity(santa) end
    santa = nil
    GlobalState.xmasSanta = nil
    holders = { lap = false, left = false, right = false }
    queues = { lap = {}, left = {}, right = {} }
    reserved = { lap = false, left = false, right = false }
    publish()
    publishLine()
end

CreateThread(function()
    publish()
    while true do
        if anyoneWithin(Config.SpawnDistance) then
            if not santa or not DoesEntityExist(santa) then spawnSanta() end
        elseif santa and not anyoneWithin(Config.DespawnDistance) then
            removeSanta()
        end
        Wait(2000)
    end
end)

CreateThread(function()
    publishLine()
    while true do
        Wait(1000)
        local now, changed = os.time(), false
        for _, list in pairs(queues) do
            for i = #list, 1, -1 do
                local id = list[i]
                if not GetPlayerName(id) or not near(id, grotto, Config.Flow.queueReach) then
                    table.remove(list, i)
                    changed = true
                end
            end
        end
        for spot, r in pairs(reserved) do
            if r and (now > r.expires or not near(r.id, grotto, Config.Flow.queueReach)) then
                reserved[spot] = false
                changed = true
                if GetPlayerName(r.id) then TriggerClientEvent('olentrix_mpc_santa:missed', r.id, spot) end
            end
        end
        if changed then publishLine() end
        for spot in pairs(queues) do offerNext(spot) end
    end
end)

RegisterNetEvent('olentrix_mpc_santa:take', function(spot)
    local src = source
    if holders[spot] == nil then return end
    if not santa or not near(src, grotto, Config.ServerReach) then
        TriggerClientEvent('olentrix_mpc_santa:denied', src, spot)
        return
    end
    offerNext(spot)
    local r = reserved[spot]
    if (holders[spot] and holders[spot] ~= src) or (r and r.id ~= src) then
        joinLine(src, spot)
        return
    end
    local _, let = unqueue(src)
    local freed = {}
    for other, holder in pairs(holders) do
        if holder == src and other ~= spot then
            holders[other] = false
            freed[#freed + 1] = other
        end
    end
    holders[spot] = src
    publish()
    publishLine()
    TriggerClientEvent('olentrix_mpc_santa:granted', src, spot)
    for _, other in ipairs(freed) do offerNext(other) end
    for _, other in ipairs(let) do offerNext(other) end
end)

RegisterNetEvent('olentrix_mpc_santa:leave', function()
    freeSpotsOf(source)
end)

RegisterNetEvent('olentrix_mpc_santa:unqueue', function()
    leaveLine(source)
end)

RegisterNetEvent('olentrix_mpc_santa:photo', function()
    local src = source
    local posed, holding = {}, false
    for _, holder in pairs(holders) do
        if holder then
            posed[#posed + 1] = holder
            if holder == src then holding = true end
        end
    end
    if not holding then return end
    if os.time() - lastPhoto < Config.Photo.cooldown then
        TriggerClientEvent('olentrix_mpc_santa:photoWait', src)
        return
    end
    lastPhoto = os.time()
    for _, id in ipairs(GetPlayers()) do
        if near(id, grotto, Config.Photo.reach) then TriggerClientEvent('olentrix_mpc_santa:photo', id, posed) end
    end
end)

local function identifierOf(src)
    local id = GetPlayerIdentifierByType and (GetPlayerIdentifierByType(src, 'license') or GetPlayerIdentifierByType(src, 'license2'))
    if id then return id end
    for _, other in ipairs(GetPlayerIdentifiers(src)) do
        if not other:find('^ip:') then return other end
    end
    return 'unknown'
end

local function fileLetter(src, text, from)
    if type(text) ~= 'string' then return nil end
    text = text:gsub('[%c~<>]', ' '):gsub('%s+', ' '):match('^%s*(.-)%s*$')
    local length = utf8.len(text) or #text
    if length == 0 or length > Config.Letters.maxLength then return nil end
    local now = os.time()
    if lastLetter[src] and now - lastLetter[src] < Config.Letters.cooldown then return false end
    lastLetter[src] = now
    letters[#letters + 1] = {
        name = GetPlayerName(src),
        identifier = identifierOf(src),
        time = os.date('!%Y-%m-%d %H:%M:%S UTC', now),
        text = text,
        source = from,
    }
    SaveResourceFile(resource, Config.Letters.file, json.encode(letters, { indent = true }), -1)
    return true
end

RegisterNetEvent('olentrix_mpc_santa:letter', function(text)
    local src = source
    if not nearLetters(src) then return end
    local ok = fileLetter(src, text)
    if ok ~= nil then TriggerClientEvent('olentrix_mpc_santa:posted', src, ok) end
end)

RegisterNetEvent('olentrix_mpc_santa:wish', function(text)
    local src = source
    if not holds(src) then return end
    local ok = fileLetter(src, text, 'grotto')
    if ok ~= nil then TriggerClientEvent('olentrix_mpc_santa:wished', src, ok) end
end)

RegisterCommand(Config.Letters.command, function(src)
    local lines = {}
    for i = math.max(1, #letters - Config.Letters.show + 1), #letters do
        local letter = letters[i]
        local from = letter.source and (' [' .. letter.source .. ']') or ''
        lines[#lines + 1] = ('[%s] %s (%s)%s: %s'):format(letter.time, letter.name, letter.identifier, from, letter.text)
    end
    if #lines == 0 then lines[1] = 'No letters to Santa yet.' end
    if src == 0 then
        for _, line in ipairs(lines) do print(line) end
    else
        TriggerClientEvent('olentrix_mpc_santa:letters', src, lines)
    end
end, true)

AddEventHandler('playerDropped', function()
    local src = source
    freeSpotsOf(src)
    leaveLine(src)
    lastLetter[src] = nil
end)

AddEventHandler('onResourceStop', function(name)
    if name ~= resource then return end
    if santa and DoesEntityExist(santa) then DeleteEntity(santa) end
    GlobalState.xmasSanta = nil
    GlobalState.xmasSantaSpots = nil
    GlobalState.xmasSantaLine = nil
end)
