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

local function playSoon(ped, anim, flag, wanted)
    if HasAnimDictLoaded(anim.dict) then
        TaskPlayAnim(ped, anim.dict, anim.clip, 4.0, -4.0, -1, flag, 0.0, false, false, false)
        return
    end
    RequestAnimDict(anim.dict)
    CreateThread(function()
        local tries = 0
        while not HasAnimDictLoaded(anim.dict) and tries < 300 do Wait(10); tries = tries + 1 end
        if HasAnimDictLoaded(anim.dict) and DoesEntityExist(ped) and (not wanted or wanted()) then
            TaskPlayAnim(ped, anim.dict, anim.clip, 4.0, -4.0, -1, flag, 0.0, false, false, false)
        end
    end)
end

local preloaded = false
local function preloadVisit()
    if preloaded then return end
    preloaded = true
    RequestAnimDict(Config.Lap.sit.dict)
    for _, list in ipairs({ Config.Poses, Config.LapPoses }) do
        for _, pose in ipairs(list) do RequestAnimDict(pose.dict) end
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
            SetFacialIdleAnimOverride(ped, Config.Carollers.face, 0)
        end
    end
end

local function between(range)
    return math.floor((range[1] + math.random() * (range[2] - range[1])) * 1000)
end

local function turnHead(i, ped, hold)
    local look, pick, me = Config.Carollers.look, math.random(), PlayerPedId()
    local here = GetEntityCoords(ped)
    if pick < 0.3 then
        TaskClearLookAt(ped)
    elseif pick < 0.45 and #(GetEntityCoords(me) - here) < look.playerReach then
        TaskLookAtEntity(ped, me, hold, 2048, 3)
    elseif pick < 0.65 then
        local other = singers[i % #Config.Carollers.singers + 1] or singers[i - 1]
        if other and DoesEntityExist(other) then TaskLookAtEntity(ped, other, hold, 2048, 3) else TaskClearLookAt(ped) end
    else
        local f = GetEntityForwardVector(ped)
        local side = (math.random() - 0.5) * 4.0
        local p = here + f * look.ahead + vector3(-f.y, f.x, 0.0) * side
        TaskLookAtCoord(ped, p.x, p.y, Config.Carollers.centre.z + look.height, hold, 0, 2)
    end
end

CreateThread(function()
    local chatter, nextChatter, nextLook = Config.Carollers.chatter, {}, {}
    while true do
        if next(singers) then
            loadDict(chatter.dict)
            local now = GetGameTimer()
            for i, ped in pairs(singers) do
                if DoesEntityExist(ped) then
                    if now >= (nextChatter[ped] or 0) then
                        PlayFacialAnim(ped, chatter.clip, chatter.dict)
                        nextChatter[ped] = now + between(chatter.every)
                    end
                    if now >= (nextLook[ped] or 0) then
                        local hold = between(Config.Carollers.look.every)
                        turnHead(i, ped, hold)
                        nextLook[ped] = now + hold
                    end
                end
            end
            Wait(250)
        else
            nextChatter, nextLook = {}, {}
            Wait(1000)
        end
    end
end)

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
    local right = unit(vector3(side.x, side.y, 0.0))
    local target = hip + (knee - hip) * lap.along + UP * lap.raise + right * lap.shift
    local off = GetOffsetFromEntityGivenWorldCoords(santa, target.x, target.y, target.z)
    AttachEntityToEntity(me, santa, 0, off.x, off.y, off.z, 0.0, 0.0, lap.turn, false, false, false, false, 2, true, 2)
end

local flow, currentPose
local photoBusyUntil, photoAskedAt, cardUntil, turnUntil = 0, 0, 0, 0
local lineState = GlobalState.xmasSantaLine

AddStateBagChangeHandler('xmasSantaLine', 'global', function(_, _, value)
    lineState = value
end)

local function placeAt(ped, s)
    SetEntityCoords(ped, s.x, s.y, s.z + 1.0, false, false, false, false)
    SetEntityHeading(ped, s.heading)
end

local function addText(text)
    while #text > 99 do
        local cut = text:sub(1, 99):match('^.*()%s') or 99
        AddTextComponentSubstringPlayerName(text:sub(1, cut))
        text = text:sub(cut + 1)
    end
    AddTextComponentSubstringPlayerName(text)
end

local function say(who, text, ms)
    BeginTextCommandPrint('STRING')
    addText((who == 'santa' and Config.Text.santaName or Config.Text.elfName) .. ': ' .. text)
    EndTextCommandPrint(ms or Config.Flow.subtitleMs, true)
end

local function pressed(control)
    return IsDisabledControlJustPressed(0, control)
end

local function backPressed()
    return pressed(Config.Flow.keys.leave.control) and not IsDisabledControlJustPressed(0, 200) and not IsPauseMenuActive()
end

local function blockFlowControls()
    for _, control in ipairs(Config.Flow.block) do DisableControlAction(0, control, true) end
end

local function active()
    if flow then
        flow.idleSince = GetGameTimer()
        flow.warnUntil = nil
    end
end

local function leaveSpot(stay)
    local spot = mySpot
    if not spot then return end
    mySpot = nil
    menu = nil
    flow = nil
    currentPose = nil
    TriggerServerEvent('olentrix_mpc_santa:leave')
    local me = PlayerPedId()
    if IsEntityAttached(me) then DetachEntity(me, true, false) end
    FreezeEntityPosition(me, false)
    ClearPedTasks(me)
    if not stay then placeAt(me, exits[spot]) end
end

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
    menu = nil
    currentPose = nil
    flow = { posed = false, photos = 0, wished = false, idleSince = GetGameTimer() }
    if spot == 'lap' then
        attachToLap(me, santa)
        playSoon(me, Config.Lap.sit, 1, function() return mySpot == 'lap' end)
    else
        placeAt(me, stands[spot])
        Wait(400)
        FreezeEntityPosition(me, true)
    end
    say('santa', Config.Text.welcome)
end

local function holderOf(spot)
    local holders = GlobalState.xmasSantaSpots
    return holders and holders[spot] or false
end

local function heldFor(spot)
    return lineState and lineState.reserved and lineState.reserved[spot] or false
end

local function myLine()
    if not lineState then return nil end
    local me = GetPlayerServerId(PlayerId())
    for spot, id in pairs(lineState.reserved or {}) do
        if id == me then return spot, 0 end
    end
    for spot, list in pairs(lineState.queues or {}) do
        for i, id in ipairs(list) do
            if id == me then return spot, i end
        end
    end
end

local function openMain()
    local me = GetPlayerServerId(PlayerId())
    local items = {}
    for _, spot in ipairs({ 'lap', 'left', 'right' }) do
        local words = Config.Text.spots[spot]
        local holder, held = holderOf(spot), heldFor(spot)
        local item = { label = words.label, desc = words.desc, spot = spot }
        if (holder and holder ~= me) or (held and held ~= me) then
            item.label = item.label .. Config.Text.taken
            item.desc = Config.Text.takenDesc
        end
        items[#items + 1] = item
    end
    items[#items + 1] = { label = Config.Text.notNow, close = true }
    menu = { title = Config.Text.menuTitle, items = items, index = 1 }
end

local function posesFor(spot)
    if spot == 'lap' then return Config.LapPoses end
    local list, seen = {}, {}
    for _, pose in ipairs(Config.Poses) do
        list[#list + 1] = pose
        seen[pose.label] = true
    end
    for _, pose in ipairs(Config.LapPoses) do
        if not seen[pose.label] then list[#list + 1] = pose end
    end
    return list
end

local function openPoses()
    local items = {}
    for _, pose in ipairs(posesFor(mySpot)) do items[#items + 1] = { label = pose.label, pose = pose } end
    items[#items + 1] = { label = Config.Text.noPose, clear = true }
    items[#items + 1] = { label = Config.Text.allDone, leave = true }
    menu = { title = Config.Text.posesTitle, items = items, index = 1 }
end

local function setPose(pose)
    local me = PlayerPedId()
    if currentPose then StopAnimTask(me, currentPose.dict, currentPose.clip, 2.0) end
    currentPose = pose
    if mySpot == 'lap' then
        local sit = Config.Lap.sit
        if not IsEntityPlayingAnim(me, sit.dict, sit.clip, 3) then playSoon(me, sit, 1, function() return mySpot == 'lap' end) end
    end
    if pose then playSoon(me, pose, pose.flag, function() return currentPose == pose and mySpot ~= nil end) end
    if flow then flow.posed = true end
    active()
end

local function goodbye(nextVisitor)
    if not flow or flow.leaving then return end
    flow.leaving = true
    menu = nil
    local spot, delay = mySpot, math.floor(Config.Flow.goodbyeDelay * 1000)
    say('santa', nextVisitor and Config.Text.nextVisitor or Config.Text.goodbye, delay + 1500)
    SetTimeout(delay, function()
        if mySpot ~= spot or not flow or not flow.leaving then return end
        leaveSpot(false)
        cardUntil = GetGameTimer() + math.floor(Config.Flow.cardSeconds * 1000)
    end)
end

local function choose(item)
    menu = nil
    active()
    if item.leave then
        goodbye(false)
    elseif item.pose then
        setPose(item.pose)
    elseif item.clear then
        setPose(nil)
    elseif item.spot then
        TriggerServerEvent('olentrix_mpc_santa:take', item.spot)
    end
end

local function outlineFor(r, g, b)
    if (r or 255) + (g or 255) + (b or 255) > 380 then SetTextOutline() end
end

local function drawText(text, x, y, scale, centre, r, g, b)
    SetTextFont(0)
    SetTextScale(scale, scale)
    SetTextColour(r or 255, g or 255, b or 255, 255)
    SetTextCentre(centre)
    outlineFor(r, g, b)
    BeginTextCommandDisplayText('STRING')
    addText(text)
    EndTextCommandDisplayText(x, y)
end

local function drawRight(text, right, y, scale, r, g, b)
    SetTextFont(0)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, 255)
    SetTextJustification(2)
    SetTextWrap(0.0, right)
    outlineFor(r, g, b)
    BeginTextCommandDisplayText('STRING')
    addText(text)
    EndTextCommandDisplayText(0.0, y)
end

local function drawWrapped(text, x, y, scale, width)
    SetTextFont(0)
    SetTextScale(scale, scale)
    SetTextColour(255, 255, 255, 255)
    SetTextCentre(true)
    SetTextWrap(x - width / 2, x + width / 2)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    addText(text)
    EndTextCommandDisplayText(x, y)
end

local function drawText3d(text, point)
    local visible, x, y = GetScreenCoordFromWorldCoord(point.x, point.y, point.z)
    if visible then drawText(text, x, y, 0.38, true) end
end

local function drawMenu()
    local x, y, width, row, sub = 0.83, 0.28, 0.28, 0.04, 0.028
    DrawRect(x, y, width, row * 1.2, 140, 22, 32, 240)
    drawText(menu.title, x, y - 0.017, 0.45, true, 255, 226, 150)
    local top, left = y + row * 0.6, x - width / 2 + 0.01
    for i, item in ipairs(menu.items) do
        local height = item.desc and row + sub or row
        local selected = i == menu.index
        if selected then DrawRect(x, top + height / 2, width, height, 245, 240, 228, 245) else DrawRect(x, top + height / 2, width, height, 18, 40, 26, 225) end
        if selected then
            drawText(item.label, left, top + row / 2 - 0.016, 0.38, false, 20, 20, 20)
            if item.desc then drawText(item.desc, left, top + row - 0.004, 0.31, false, 70, 70, 70) end
        else
            drawText(item.label, left, top + row / 2 - 0.016, 0.38, false)
            if item.desc then drawText(item.desc, left, top + row - 0.004, 0.31, false, 255, 226, 150) end
        end
        top = top + height
    end
    DrawRect(x, top + row * 0.45, width, row * 0.9, 10, 10, 10, 220)
    drawText(Config.Text.menuHint, x, top + row * 0.45 - 0.013, 0.3, true, 230, 230, 230)
end

local panelStyle = {
    current = { 245, 240, 228, 235, 20, 20, 20 },
    todo = { 18, 40, 26, 205, 255, 255, 255 },
    done = { 18, 40, 26, 205, 150, 175, 155 },
    note = { 18, 40, 26, 205, 255, 226, 150 },
    warn = { 140, 22, 32, 235, 255, 226, 150 },
}

local function drawPanel(rows)
    local x, width, row, bottom = 0.5, 0.32, 0.036, 0.86
    local head = row * 1.2
    local top = bottom - head - row * #rows
    DrawRect(x, top + head / 2, width, head, 140, 22, 32, 240)
    drawText(Config.Text.panelTitle, x, top + head / 2 - 0.017, 0.45, true, 255, 226, 150)
    local left, right = x - width / 2 + 0.01, x + width / 2 - 0.01
    for i, r in ipairs(rows) do
        local s = panelStyle[r.state]
        local cy = top + head + row * (i - 0.5)
        DrawRect(x, cy, width, row, s[1], s[2], s[3], s[4])
        drawText(r.text, left, cy - 0.015, 0.36, false, s[5], s[6], s[7])
        if r.state == 'done' then
            drawRight(Config.Text.done, right, cy - 0.015, 0.36, 120, 200, 140)
        elseif r.key then
            drawRight(r.key, right, cy - 0.015, 0.36, s[5], s[6], s[7])
        end
    end
end

local function drawCard()
    local x, y, width, head, body = 0.5, 0.72, 0.34, 0.04, 0.07
    DrawRect(x, y, width, head, 140, 22, 32, 235)
    drawText(Config.Text.cardTitle, x, y - 0.017, 0.46, true, 255, 226, 150)
    DrawRect(x, y + head / 2 + body / 2, width, body, 18, 40, 26, 215)
    drawWrapped(Config.Text.cardBody, x, y + head / 2 + 0.008, 0.38, width - 0.03)
end

local function visitRows(now)
    local keys, words, rows = Config.Flow.keys, Config.Text, {}
    if flow.warnUntil then
        rows[#rows + 1] = { text = words.fairUse:format(math.max(0, math.ceil((flow.warnUntil - now) / 1000))), state = 'warn' }
    end
    if flow.photos == 0 then
        rows[#rows + 1] = { text = '1  ' .. words.stepPose, key = keys.pose.glyph, state = flow.posed and 'done' or 'current' }
        rows[#rows + 1] = { text = '2  ' .. words.stepPhoto, key = keys.photo.glyph, state = flow.posed and 'current' or 'todo' }
        rows[#rows + 1] = { text = '3  ' .. words.stepLeave, key = keys.leave.glyph, state = 'todo' }
    else
        if flow.posed then rows[#rows + 1] = { text = '1  ' .. words.stepPose, state = 'done' } end
        rows[#rows + 1] = { text = '2  ' .. words.stepPhoto, state = 'done' }
        rows[#rows + 1] = { text = words.again, key = keys.photo.glyph, state = 'current' }
        rows[#rows + 1] = { text = words.newPose, key = keys.pose.glyph, state = 'todo' }
        rows[#rows + 1] = { text = words.allDone, key = keys.leave.glyph, state = 'todo' }
    end
    if not flow.wished then rows[#rows + 1] = { text = words.wish, key = keys.wish.glyph, state = 'note' } end
    return rows
end

local function lineRows(place, now)
    local keys, words, rows = Config.Flow.keys, Config.Text, {}
    if place == 0 then
        local text = words.yourTurn
        if turnUntil > now then text = text .. words.turnSeconds:format(math.ceil((turnUntil - now) / 1000)) end
        rows[1] = { text = text, key = keys.pose.glyph, state = 'current' }
    else
        rows[1] = { text = place == 1 and words.lineNext or words.linePlace:format(place), state = 'note' }
    end
    rows[2] = { text = words.leaveLine, key = keys.leave.glyph, state = 'todo' }
    return rows
end

local function fairUse(now)
    local list = lineState and lineState.queues and lineState.queues[mySpot]
    if list and #list > 0 and now - flow.idleSince >= Config.Flow.idleSeconds * 1000 then
        flow.warnUntil = flow.warnUntil or now + Config.Flow.warnSeconds * 1000
        if now >= flow.warnUntil then goodbye(true) end
    else
        flow.warnUntil = nil
    end
end

local function handleMenu()
    DisableControlAction(0, 27, true)
    DisableControlAction(0, 199, true)
    DisableControlAction(0, 200, true)
    for _, control in ipairs({ 14, 15, 16, 17, 37 }) do DisableControlAction(0, control, true) end
    drawMenu()
    if pressed(172) or pressed(15) or pressed(17) then
        menu.index = menu.index > 1 and menu.index - 1 or #menu.items
        active()
    end
    if pressed(173) or pressed(14) or pressed(16) then
        menu.index = menu.index < #menu.items and menu.index + 1 or 1
        active()
    end
    if pressed(201) or pressed(Config.Flow.keys.pose.control) then choose(menu.items[menu.index]) return end
    if pressed(202) then
        menu = nil
        active()
    end
end

local function askLetter()
    AddTextEntry('OLENTRIX_MPC_LETTER', Config.Text.letterTitle)
    DisplayOnscreenKeyboard(1, 'OLENTRIX_MPC_LETTER', '', '', '', '', '', Config.Letters.maxLength)
    while UpdateOnscreenKeyboard() == 0 do
        DisableAllControlActions(0)
        Wait(0)
    end
    if UpdateOnscreenKeyboard() ~= 1 then return nil end
    local text = GetOnscreenKeyboardResult()
    if text and text:match('%S') then return text end
end

local function makeWish()
    local text = askLetter()
    if text and mySpot then TriggerServerEvent('olentrix_mpc_santa:wish', text) end
    active()
end

local function handleVisit(now)
    blockFlowControls()
    if not flow or flow.leaving or now < photoBusyUntil then return end
    fairUse(now)
    if flow.leaving then return end
    drawPanel(visitRows(now))
    if menu then
        handleMenu()
        return
    end
    local keys = Config.Flow.keys
    if pressed(keys.pose.control) then
        active()
        openPoses()
    elseif pressed(keys.photo.control) then
        active()
        if now - photoAskedAt > 1500 then
            photoAskedAt = now
            TriggerServerEvent('olentrix_mpc_santa:photo')
        end
    elseif pressed(keys.wish.control) and not flow.wished then
        makeWish()
    elseif backPressed() then
        goodbye(false)
    end
end

local function handleGrotto(position, now)
    if menu and not mySpot and #(position - prompt) > Config.PromptDistance + 2.0 then menu = nil end
    if mySpot then
        handleVisit(now)
        return
    end
    if menu then
        handleMenu()
        return
    end
    local spot, place = myLine()
    if spot then
        drawPanel(lineRows(place, now))
        if place == 0 and pressed(Config.Flow.keys.pose.control) then
            TriggerServerEvent('olentrix_mpc_santa:take', spot)
            return
        end
        if backPressed() then TriggerServerEvent('olentrix_mpc_santa:unqueue') end
    end
    if #(position - prompt) < Config.PromptDistance then
        drawText3d(Config.Text.prompt .. '  ' .. Config.Flow.keys.pose.glyph, prompt)
        if pressed(Config.Flow.keys.pose.control) then openMain() end
    end
end

local function writeLetter()
    local text = askLetter()
    if text then TriggerServerEvent('olentrix_mpc_santa:letter', text) end
end

local letterSpots = {}
if Config.Letters.position then letterSpots[#letterSpots + 1] = Config.Letters.position end
for _, spot in ipairs(Config.Letters.spots or {}) do letterSpots[#letterSpots + 1] = spot end

local function handleLetters(position, box)
    local point = vector3(box.x, box.y, box.z + 1.0)
    if #(position - point) < Config.Letters.promptDistance then
        drawText3d(Config.Text.letterPrompt, point)
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
        if distance < Config.SpawnDistance then spawnElf(); preloadVisit() elseif distance > Config.DespawnDistance then removeElf() end
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
            local now = GetGameTimer()
            drawFlash()
            if now < cardUntil then drawCard() end
            if santaPed() then handleGrotto(position, now) elseif menu then menu = nil end
        end
        for _, box in ipairs(letterSpots) do
            if #(position - box) < 10.0 then
                wait = 0
                handleLetters(position, box)
            end
        end
        Wait(wait)
    end
end)

RegisterNetEvent('olentrix_mpc_santa:granted', function(spot)
    occupy(spot)
end)

RegisterNetEvent('olentrix_mpc_santa:denied', function()
    notify(Config.Text.denied)
end)

RegisterNetEvent('olentrix_mpc_santa:queued', function(_, place)
    say('elf', place == 1 and Config.Text.queueNext or Config.Text.queuePlace:format(place))
end)

RegisterNetEvent('olentrix_mpc_santa:turn', function(_, seconds)
    turnUntil = GetGameTimer() + (seconds or Config.Flow.turnWindow) * 1000
    PlaySoundFrontend(-1, Config.Flow.chime.name, Config.Flow.chime.set, true)
    say('elf', Config.Text.yourTurn .. ' ' .. Config.Flow.keys.pose.glyph)
end)

RegisterNetEvent('olentrix_mpc_santa:missed', function()
    say('elf', Config.Text.missedTurn)
end)

RegisterNetEvent('olentrix_mpc_santa:photoWait', function()
    say('elf', Config.Text.photoWait)
end)

RegisterNetEvent('olentrix_mpc_santa:wished', function(ok)
    if ok and flow then flow.wished = true end
    say('santa', ok and Config.Text.wishThanks or Config.Text.wishWait)
end)

RegisterNetEvent('olentrix_mpc_santa:photo', function(posed)
    local me = GetPlayerServerId(PlayerId())
    local lead = math.floor((Config.Flow.elfLead + Config.Photo.countdown) * 1000)
    shutterAt = GetGameTimer() + lead
    if elf then
        local dict = 'amb@world_human_paparazzi@male@idle_a'
        if loadDict(dict) then TaskPlayAnim(elf, dict, 'idle_a', 4.0, -4.0, -1, 0, 0.0, false, false, false) end
        SetTimeout(lead + 2500, function()
            if elf then play(elf, Config.Elf.pose, 1) end
        end)
    end
    local mine = false
    for _, id in ipairs(posed) do
        if id == me then mine = true end
    end
    if not mine then return end
    local shot = shutterAt
    local stop = shot + math.floor(Config.Photo.hideSeconds * 1000)
    photoBusyUntil = stop
    menu = nil
    say('elf', Config.Text.elfSqueeze, lead)
    CreateThread(function()
        local counted, snapped
        while GetGameTimer() < stop do
            local now = GetGameTimer()
            if now < shot then
                if shot - now <= Config.Photo.countdown * 1000 then
                    local n = math.ceil((shot - now) / 1000)
                    if n ~= counted then
                        counted = n
                        PlaySoundFrontend(-1, '3_2_1', 'HUD_MINI_GAME_SOUNDSET', true)
                    end
                    drawText(tostring(n), 0.5, 0.36, 2.2, true, 255, 230, 160)
                end
            else
                HideHudAndRadarThisFrame()
                if not snapped then
                    snapped = true
                    ClearPrints()
                    PlaySoundFrontend(-1, 'Camera_Shoot', 'Phone_Soundset_Franklin', true)
                end
                local alpha = 1.0 - (now - shot) / 450
                if alpha > 0 then DrawRect(0.5, 0.5, 1.0, 1.0, 255, 255, 255, math.floor(alpha * 255)) end
            end
            Wait(0)
        end
        if flow and mySpot then
            flow.photos = flow.photos + 1
            active()
            say('elf', Config.Text.gotIt, Config.Flow.gotItMs)
        end
    end)
end)

RegisterNetEvent('olentrix_mpc_santa:posted', function(ok)
    if ok then notify(Config.Text.letterPosted) else notify(Config.Text.letterWait) end
end)

RegisterNetEvent('olentrix_mpc_santa:letters', function(lines)
    for _, line in ipairs(lines) do print(line) end
    notify(Config.Text.lettersPrinted)
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
