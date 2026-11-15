local grotto = vector3(Spots.origin[1], Spots.origin[2], Spots.origin[3])
local prompt = vector3(Spots.prompt.x, Spots.prompt.y, Spots.prompt.z + 1.0)
local exits = { lap = Spots.exit_lap, left = Spots.exit_left, right = Spots.exit_right }
local stands = { left = Spots.stand_left, right = Spots.stand_right }
local UP = vector3(0.0, 0.0, 1.0)

local elf, elfCamera
local singers, books = {}, {}
local shopCache = {}
local dressedSanta, dressedAsOwner
local lookTarget
local mySpot
local menu
local shutterAt = 0

local function dot(a, b) return a.x * b.x + a.y * b.y + a.z * b.z end
local function cross(a, b) return vector3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x) end
local function unit(v) return v / #v end
local function clamp(v) return math.max(-1.0, math.min(1.0, v)) end

local function loadModel(name)
    local hash = GetHashKey(name)
    if not IsModelInCdimage(hash) then return nil end
    RequestModel(hash)
    local tries = 0
    while not HasModelLoaded(hash) and tries < 500 do Wait(10); tries = tries + 1 end
    return HasModelLoaded(hash) and hash or nil
end

local function loadDict(dict)
    RequestAnimDict(dict)
    local tries = 0
    while not HasAnimDictLoaded(dict) and tries < 500 do Wait(10); tries = tries + 1 end
    return HasAnimDictLoaded(dict)
end

local function play(ped, anim, flag, phase)
    if loadDict(anim.dict) then
        TaskPlayAnim(ped, anim.dict, anim.clip, 4.0, -4.0, -1, flag, phase or 0.0, false, false, false)
    end
end

local function notify(message)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, false)
end

local function sameHash(a, b)
    return (a & 0xFFFFFFFF) == (b & 0xFFFFFFFF)
end

local function findShopItem(ped, item)
    local key = item.name .. ':' .. GetEntityModel(ped)
    if shopCache[key] ~= nil then return shopCache[key] end
    local want, found = GetHashKey(item.name), false
    if item.prop then
        for d = 0, GetNumberOfPedPropDrawableVariations(ped, item.prop) - 1 do
            for t = 0, GetNumberOfPedPropTextureVariations(ped, item.prop, d) - 1 do
                if sameHash(GetHashNameForProp(ped, item.prop, d, t), want) then found = { d, t }; break end
            end
            if found then break end
        end
    else
        for d = 0, GetNumberOfPedDrawableVariations(ped, item.slot) - 1 do
            for t = 0, GetNumberOfPedTextureVariations(ped, item.slot, d) - 1 do
                if sameHash(GetHashNameForComponent(ped, item.slot, d, t), want) then found = { d, t }; break end
            end
            if found then break end
        end
    end
    shopCache[key] = found
    return found
end

local function wear(ped, outfit)
    for _, item in ipairs(outfit) do
        if item.name then
            local hit = findShopItem(ped, item)
            if hit and item.prop then
                SetPedPropIndex(ped, item.prop, hit[1], hit[2], true)
            elseif hit then
                SetPedComponentVariation(ped, item.slot, hit[1], hit[2], 0)
            elseif item.fallback then
                SetPedComponentVariation(ped, item.slot, item.fallback, 0, 0)
            end
        else
            SetPedComponentVariation(ped, item.slot, item.drawable, item.texture or 0, 0)
        end
    end
end

local function styleHead(ped, look)
    SetPedHeadBlendData(ped, look.face, look.face, 0, look.skin, look.skin, 0, 1.0, 1.0, 0.0, false)
    SetPedComponentVariation(ped, 2, look.hair, 0, 0)
    SetPedHairColor(ped, look.hairColour, look.hairHighlight)
    for _, overlay in ipairs(look.overlays) do
        SetPedHeadOverlay(ped, overlay.index, overlay.style, overlay.opacity)
        if overlay.colour then SetPedHeadOverlayColor(ped, overlay.index, 1, overlay.colour, overlay.colour) end
    end
end

local function calm(ped)
    SetEntityInvincible(ped, true)
    SetEntityProofs(ped, true, true, true, true, true, true, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCanBeTargetted(ped, false)
    FreezeEntityPosition(ped, true)
end

local function attachProp(ped, prop)
    local hash = loadModel(prop.model)
    if not hash then return nil end
    local object = CreateObject(hash, GetEntityCoords(ped), false, false, false)
    AttachEntityToEntity(object, ped, GetPedBoneIndex(ped, prop.bone), prop.offset.x, prop.offset.y, prop.offset.z,
        prop.rotation.x, prop.rotation.y, prop.rotation.z, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(hash)
    return object
end

local function removeEntity(entity)
    if entity and DoesEntityExist(entity) then DeleteEntity(entity) end
end

local function santaPed()
    local net = GlobalState.xmasSanta
    if not net or not NetworkDoesNetworkIdExist(net) then return nil end
    local ped = NetworkGetEntityFromNetworkId(net)
    if ped ~= 0 and DoesEntityExist(ped) then return ped end
end

local function ownsSanta(ped)
    return NetworkGetEntityOwner(ped) == PlayerId()
end

local function dressSanta(ped, owner)
    if owner then SetPedDefaultComponentVariation(ped) end
    styleHead(ped, Config.Santa.look)
    wear(ped, Config.Santa.outfit)
    SetFacialIdleAnimOverride(ped, Config.Santa.mood, 0)
end

local function settleSanta(ped)
    calm(ped)
    local sit = Config.Santa.sit
    if IsEntityPlayingAnim(ped, sit.dict, sit.clip, 3) then return end
    local seat, offset = Spots.seat, Config.Santa.seatOffset
    local h = math.rad(seat.heading)
    local forward, right = vector3(-math.sin(h), math.cos(h), 0.0), vector3(math.cos(h), math.sin(h), 0.0)
    local spot = vector3(seat.x, seat.y, seat.z) + right * offset.x + forward * offset.y + UP * offset.z
    SetEntityCoordsNoOffset(ped, spot.x, spot.y, spot.z, false, false, false)
    SetEntityHeading(ped, seat.heading)
    play(ped, sit, 1)
end

local function lookAtNearest(ped)
    local from = GetEntityCoords(ped)
    local best, bestDistance = nil, Config.Santa.lookDistance
    for _, player in ipairs(GetActivePlayers()) do
        local other = GetPlayerPed(player)
        if other ~= 0 then
            local distance = #(GetEntityCoords(other) - from)
            if distance < bestDistance then best, bestDistance = other, distance end
        end
    end
    if best == lookTarget then return end
    lookTarget = best
    if best then TaskLookAtEntity(ped, best, -1, 2048, 3) else TaskClearLookAt(ped) end
end

local function spawnElf()
    if elf then return end
    local hash = loadModel(Config.Elf.model)
    if not hash then return end
    local s = Spots.elf
    elf = CreatePed(4, hash, s.x, s.y, s.z, s.heading, false, true)
    SetModelAsNoLongerNeeded(hash)
    SetPedDefaultComponentVariation(elf)
    styleHead(elf, Config.Elf.look)
    wear(elf, Config.Elf.outfit)
    SetFacialIdleAnimOverride(elf, 'mood_happy_1', 0)
    calm(elf)
    elfCamera = attachProp(elf, Config.Elf.camera)
    play(elf, Config.Elf.pose, 1)
end

local function removeElf()
    removeEntity(elfCamera)
    removeEntity(elf)
    elf, elfCamera = nil, nil
end

local function spawnSingers()
    if #singers > 0 then return end
    for i, singer in ipairs(Config.Carollers.singers) do
        local hash = loadModel(singer.model)
        if hash then
            local p = singer.position
            local ped = CreatePed(4, hash, p.x, p.y, p.z, p.w, false, true)
            SetModelAsNoLongerNeeded(hash)
            SetPedRandomComponentVariation(ped, 0)
            calm(ped)
            singers[i] = ped
            books[i] = attachProp(ped, Config.Carollers.book)
            play(ped, Config.Carollers.pose, 1, (i - 1) / #Config.Carollers.singers)
        end
    end
end

local function removeSingers()
    for i = 1, #Config.Carollers.singers do
        removeEntity(books[i])
        removeEntity(singers[i])
    end
    singers, books = {}, {}
end

local function attachToLap(me, santa)
    local lap = Config.Lap
    local thigh = GetPedBoneIndex(santa, lap.thighBone)
    local hip = GetWorldPositionOfEntityBone(santa, thigh)
    local knee = GetWorldPositionOfEntityBone(santa, GetPedBoneIndex(santa, lap.kneeBone))
    local otherHip = GetWorldPositionOfEntityBone(santa, GetPedBoneIndex(santa, lap.otherThighBone))
    local side = hip - otherHip
    local X = unit(knee - hip)
    local Z = unit(side - X * dot(side, X))
    local Y = cross(Z, X)
    local right = unit(vector3(side.x, side.y, 0.0))
    local forward = cross(UP, right)
    local turn = math.rad(lap.turn)
    local facing = forward * math.cos(turn) - right * math.sin(turn)
    local sitterRight = cross(facing, UP)
    local target = hip + (knee - hip) * lap.along + UP * lap.raise + right * lap.shift
    local d = target - hip
    local pitch = math.deg(math.asin(clamp(dot(Z, facing))))
    local roll = math.deg(math.atan(-dot(Z, sitterRight), dot(Z, UP)))
    local yaw = math.deg(math.atan(-dot(X, facing), dot(Y, facing)))
    AttachEntityToEntity(me, santa, thigh, dot(d, X), dot(d, Y), dot(d, Z), pitch, roll, yaw, false, false, false, false, 2, true, 2)
end

local function placeAt(ped, s)
    SetEntityCoords(ped, s.x, s.y, s.z + 1.0, false, false, false, false)
    SetEntityHeading(ped, s.heading)
end

local function leaveSpot(stay)
    local spot = mySpot
    if not spot then return end
    mySpot = nil
    menu = nil
    TriggerServerEvent('olentrix_mpc_santa:leave')
    local me = PlayerPedId()
    if IsEntityAttached(me) then DetachEntity(me, true, false) end
    FreezeEntityPosition(me, false)
    ClearPedTasks(me)
    if not stay then placeAt(me, exits[spot]) end
end

local openPoses

local function occupy(spot)
    local santa = santaPed()
    if not santa then
        TriggerServerEvent('olentrix_mpc_santa:leave')
        return
    end
    local me = PlayerPedId()
    if IsEntityAttached(me) then DetachEntity(me, true, false) end
    FreezeEntityPosition(me, false)
    ClearPedTasksImmediately(me)
    mySpot = spot
    if spot == 'lap' then
        attachToLap(me, santa)
        play(me, Config.Lap.sit, 1)
    else
        placeAt(me, stands[spot])
        Wait(400)
        FreezeEntityPosition(me, true)
        openPoses()
    end
end

local function holderOf(spot)
    local holders = GlobalState.xmasSantaSpots
    return holders and holders[spot] or false
end

local function openMain()
    local me = GetPlayerServerId(PlayerId())
    local items = {}
    for _, entry in ipairs({ { 'lap', "Sit on Santa's lap" }, { 'left', 'Stand left' }, { 'right', 'Stand right' } }) do
        local holder = holderOf(entry[1])
        local label = entry[2]
        if holder and holder ~= me then label = label .. ' (taken)' end
        items[#items + 1] = { label = label, spot = entry[1] }
    end
    items[#items + 1] = { label = 'Leave', leave = true }
    menu = { title = 'Photos with Santa', items = items, index = 1 }
end

openPoses = function()
    local items = {}
    for i, pose in ipairs(Config.Poses) do items[#items + 1] = { label = pose.label, pose = i } end
    items[#items + 1] = { label = 'Leave', leave = true }
    menu = { title = 'Strike a pose', items = items, index = 1 }
end

local function choose(item)
    menu = nil
    if item.leave then
        leaveSpot(false)
    elseif item.pose then
        local pose = Config.Poses[item.pose]
        play(PlayerPedId(), pose, pose.flag)
    elseif item.spot == mySpot and item.spot ~= 'lap' then
        openPoses()
    elseif item.spot then
        local holder = holderOf(item.spot)
        if holder and holder ~= GetPlayerServerId(PlayerId()) then
            notify('Someone is already there.')
        else
            TriggerServerEvent('olentrix_mpc_santa:take', item.spot)
        end
    end
end

local function drawText(text, x, y, scale, centre, r, g, b)
    SetTextFont(4)
    SetTextScale(scale, scale)
    SetTextColour(r or 255, g or 255, b or 255, 255)
    SetTextCentre(centre)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

local function drawText3d(text, point)
    local visible, x, y = GetScreenCoordFromWorldCoord(point.x, point.y, point.z)
    if visible then drawText(text, x, y, 0.38, true) end
end

local function drawMenu()
    local x, y, width, row = 0.84, 0.3, 0.2, 0.034
    DrawRect(x, y, width, row * 1.2, 140, 22, 32, 235)
    drawText(menu.title, x, y - 0.017, 0.46, true, 255, 226, 150)
    for i, item in ipairs(menu.items) do
        local cy = y + row * 0.1 + row * i
        local selected = i == menu.index
        if selected then DrawRect(x, cy, width, row, 245, 240, 228, 235) else DrawRect(x, cy, width, row, 18, 40, 26, 205) end
        if selected then
            drawText(item.label, x - width / 2 + 0.008, cy - 0.014, 0.36, false, 20, 20, 20)
        else
            drawText(item.label, x - width / 2 + 0.008, cy - 0.014, 0.36, false)
        end
    end
end

local function handleMenu()
    DisableControlAction(0, 27, true)
    DisableControlAction(0, 199, true)
    DisableControlAction(0, 200, true)
    drawMenu()
    if IsControlJustPressed(0, 172) then menu.index = menu.index > 1 and menu.index - 1 or #menu.items end
    if IsControlJustPressed(0, 173) then menu.index = menu.index < #menu.items and menu.index + 1 or 1 end
    if IsControlJustPressed(0, 201) then choose(menu.items[menu.index]) return end
    if IsControlJustPressed(0, 202) then menu = nil end
end

local function handleGrotto(position)
    if menu and not mySpot and #(position - prompt) > Config.PromptDistance + 2.0 then menu = nil end
    if menu then
        handleMenu()
    elseif mySpot then
        drawText3d(mySpot == 'lap' and '[E] Options  [G] Take photo' or '[E] Poses  [G] Take photo', prompt)
        if IsControlJustPressed(0, 38) then
            if mySpot == 'lap' then openMain() else openPoses() end
        elseif IsControlJustPressed(0, 47) then
            TriggerServerEvent('olentrix_mpc_santa:photo')
        end
    elseif #(position - prompt) < Config.PromptDistance then
        drawText3d('[E] Photos with Santa', prompt)
        if IsControlJustPressed(0, 38) then openMain() end
    end
end

local function writeLetter()
    AddTextEntry('OLENTRIX_MPC_LETTER', 'Dear Santa...')
    DisplayOnscreenKeyboard(1, 'OLENTRIX_MPC_LETTER', '', '', '', '', '', Config.Letters.maxLength)
    while UpdateOnscreenKeyboard() == 0 do
        DisableAllControlActions(0)
        Wait(0)
    end
    if UpdateOnscreenKeyboard() ~= 1 then return end
    local text = GetOnscreenKeyboardResult()
    if text and text:match('%S') then TriggerServerEvent('olentrix_mpc_santa:letter', text) end
end

local function handleLetters(position)
    local box = Config.Letters.position
    local point = vector3(box.x, box.y, box.z + 1.0)
    if #(position - point) < Config.Letters.promptDistance then
        drawText3d('[E] Write a letter to Santa', point)
        if IsControlJustPressed(0, 38) then writeLetter() end
    end
end

local function drawFlash()
    local since = GetGameTimer() - shutterAt
    if since < 0 or since > 150 or not elfCamera then return end
    local c = GetEntityCoords(elfCamera)
    DrawLightWithRange(c.x, c.y, c.z + 0.1, 255, 255, 255, 8.0, 30.0)
end

CreateThread(function()
    while true do
        local me = PlayerPedId()
        local position = GetEntityCoords(me)
        local distance = #(position - grotto)
        if distance < Config.SpawnDistance then spawnElf() elseif distance > Config.DespawnDistance then removeElf() end
        local toSingers = #(position - Config.Carollers.centre)
        if toSingers < Config.SpawnDistance then spawnSingers() elseif toSingers > Config.DespawnDistance then removeSingers() end
        local santa = santaPed()
        if santa then
            local owner = ownsSanta(santa)
            if santa ~= dressedSanta or (owner and not dressedAsOwner) then
                dressSanta(santa, owner)
                dressedSanta, dressedAsOwner = santa, owner
            end
            if owner then
                settleSanta(santa)
                lookAtNearest(santa)
            else
                lookTarget = nil
            end
        else
            dressedSanta, dressedAsOwner, lookTarget = nil, nil, nil
        end
        if mySpot and (distance > 12.0 or IsEntityDead(me) or not santa) then leaveSpot(true) end
        Wait(1000)
    end
end)

CreateThread(function()
    while true do
        local wait = 500
        local position = GetEntityCoords(PlayerPedId())
        if #(position - grotto) < 25.0 then
            wait = 0
            drawFlash()
            if santaPed() then handleGrotto(position) elseif menu then menu = nil end
        end
        if #(position - Config.Letters.position) < 10.0 then
            wait = 0
            handleLetters(position)
        end
        Wait(wait)
    end
end)

RegisterNetEvent('olentrix_mpc_santa:granted', function(spot)
    occupy(spot)
end)

RegisterNetEvent('olentrix_mpc_santa:denied', function()
    notify('Someone is already there.')
end)

RegisterNetEvent('olentrix_mpc_santa:photo', function(posed)
    local me = GetPlayerServerId(PlayerId())
    shutterAt = GetGameTimer() + Config.Photo.countdown * 1000
    if elf then
        local dict = 'amb@world_human_paparazzi@male@idle_a'
        if loadDict(dict) then TaskPlayAnim(elf, dict, 'idle_a', 4.0, -4.0, -1, 0, 0.0, false, false, false) end
        SetTimeout(Config.Photo.countdown * 1000 + 2500, function()
            if elf then play(elf, Config.Elf.pose, 1) end
        end)
    end
    local mine = false
    for _, id in ipairs(posed) do
        if id == me then mine = true end
    end
    if not mine then return end
    CreateThread(function()
        local shot = shutterAt
        local stop = shot + math.floor(Config.Photo.hideSeconds * 1000)
        local counted, snapped
        while GetGameTimer() < stop do
            local now = GetGameTimer()
            HideHudAndRadarThisFrame()
            if now < shot then
                local n = math.ceil((shot - now) / 1000)
                if n ~= counted then
                    counted = n
                    PlaySoundFrontend(-1, '3_2_1', 'HUD_MINI_GAME_SOUNDSET', true)
                end
                drawText(tostring(n), 0.5, 0.36, 2.2, true, 255, 230, 160)
            else
                if not snapped then
                    snapped = true
                    PlaySoundFrontend(-1, 'Camera_Shoot', 'Phone_Soundset_Franklin', true)
                end
                local alpha = 1.0 - (now - shot) / 450
                if alpha > 0 then DrawRect(0.5, 0.5, 1.0, 1.0, 255, 255, 255, math.floor(alpha * 255)) end
            end
            Wait(0)
        end
    end)
end)

RegisterNetEvent('olentrix_mpc_santa:posted', function(ok)
    if ok then notify('Your letter is on its way to the North Pole.') else notify('Santa is still reading your last letter. Try again in a minute.') end
end)

RegisterNetEvent('olentrix_mpc_santa:letters', function(lines)
    for _, line in ipairs(lines) do print(line) end
    notify('Letters to Santa printed to your F8 console.')
end)

AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then return end
    removeElf()
    removeSingers()
    if mySpot then
        local me = PlayerPedId()
        if IsEntityAttached(me) then DetachEntity(me, true, false) end
        FreezeEntityPosition(me, false)
        ClearPedTasks(me)
    end
end)
