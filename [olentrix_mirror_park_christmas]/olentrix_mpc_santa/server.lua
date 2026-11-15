local resource = GetCurrentResourceName()
local grotto = vector3(Spots.origin[1], Spots.origin[2], Spots.origin[3])
local santa
local holders = { lap = false, left = false, right = false }
local lastPhoto = 0
local lastLetter = {}
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

local function anyoneWithin(range)
    for _, id in ipairs(GetPlayers()) do
        if near(id, grotto, range) then return true end
    end
    return false
end

local function freeSpotsOf(src)
    local changed = false
    for spot, holder in pairs(holders) do
        if holder == src then
            holders[spot] = false
            changed = true
        end
    end
    if changed then publish() end
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
    publish()
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

RegisterNetEvent('olentrix_mpc_santa:take', function(spot)
    local src = source
    if holders[spot] == nil then return end
    if not santa or not near(src, grotto, Config.ServerReach) or (holders[spot] and holders[spot] ~= src) then
        TriggerClientEvent('olentrix_mpc_santa:denied', src, spot)
        return
    end
    for other, holder in pairs(holders) do
        if holder == src then holders[other] = false end
    end
    holders[spot] = src
    publish()
    TriggerClientEvent('olentrix_mpc_santa:granted', src, spot)
end)

RegisterNetEvent('olentrix_mpc_santa:leave', function()
    freeSpotsOf(source)
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
    if not holding or os.time() - lastPhoto < Config.Photo.cooldown then return end
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

RegisterNetEvent('olentrix_mpc_santa:letter', function(text)
    local src = source
    if type(text) ~= 'string' then return end
    text = text:gsub('[%c~<>]', ' '):gsub('%s+', ' '):match('^%s*(.-)%s*$')
    local length = utf8.len(text) or #text
    if length == 0 or length > Config.Letters.maxLength then return end
    if not near(src, Config.Letters.position, Config.Letters.reach) then return end
    local now = os.time()
    if lastLetter[src] and now - lastLetter[src] < Config.Letters.cooldown then
        TriggerClientEvent('olentrix_mpc_santa:posted', src, false)
        return
    end
    lastLetter[src] = now
    letters[#letters + 1] = {
        name = GetPlayerName(src),
        identifier = identifierOf(src),
        time = os.date('!%Y-%m-%d %H:%M:%S UTC', now),
        text = text,
    }
    SaveResourceFile(resource, Config.Letters.file, json.encode(letters, { indent = true }), -1)
    TriggerClientEvent('olentrix_mpc_santa:posted', src, true)
end)

RegisterCommand(Config.Letters.command, function(src)
    local lines = {}
    for i = math.max(1, #letters - Config.Letters.show + 1), #letters do
        local letter = letters[i]
        lines[#lines + 1] = ('[%s] %s (%s): %s'):format(letter.time, letter.name, letter.identifier, letter.text)
    end
    if #lines == 0 then lines[1] = 'No letters to Santa yet.' end
    if src == 0 then
        for _, line in ipairs(lines) do print(line) end
    else
        TriggerClientEvent('olentrix_mpc_santa:letters', src, lines)
    end
end, true)

AddEventHandler('playerDropped', function()
    freeSpotsOf(source)
    lastLetter[source] = nil
end)

AddEventHandler('onResourceStop', function(name)
    if name ~= resource then return end
    if santa and DoesEntityExist(santa) then DeleteEntity(santa) end
    GlobalState.xmasSanta = nil
    GlobalState.xmasSantaSpots = nil
end)
