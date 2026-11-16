local elf, elfSpot
local shopCache = {}
local asking, askUntil = false, 0
local scene
local held = {}
local waking = false
local treating = false
local cooldownUntil = 0
local elfActionUntil = 0

local function state()
    return GlobalState.xmasElf or {}
end

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

local function play(ped, anim, flag)
    if ped and DoesEntityExist(ped) and loadDict(anim.dict) then
        TaskPlayAnim(ped, anim.dict, anim.clip, 4.0, -4.0, -1, flag or anim.flag or 0, 0.0, false, false, false)
    end
end

local function sameHash(a, b)
    return (a & 0xFFFFFFFF) == (b & 0xFFFFFFFF)
end

local function findShopItem(ped, item)
    local k = item.name .. ':' .. GetEntityModel(ped)
    if shopCache[k] ~= nil then return shopCache[k] end
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
    shopCache[k] = found
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

local function removeEntity(entity)
    if entity and DoesEntityExist(entity) then DeleteEntity(entity) end
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
    addText(who .. ': ' .. text)
    EndTextCommandPrint(ms or 4500, true)
end

local function notify(text)
    if GetResourceState('kora_core') == 'started' or GetResourceState('qb-core') == 'started' then
        TriggerEvent('QBCore:Notify', text, 'primary', 5000)
    elseif GetResourceState('qbx_core') == 'started' then
        exports.qbx_core:Notify(text, 'inform', 5000)
    elseif GetResourceState('ox_lib') == 'started' then
        TriggerEvent('ox_lib:notify', { description = text, type = 'inform' })
    else
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandThefeedPostTicker(false, false)
    end
end

local function waitText(seconds)
    if seconds > 60 then return Config.Text.waitMinutes:format(math.ceil(seconds / 60)) end
    return Config.Text.waitSeconds:format(math.max(1, math.ceil(seconds)))
end

local function drawText3d(text, point)
    local visible, x, y = GetScreenCoordFromWorldCoord(point.x, point.y, point.z)
    if not visible then return end
    SetTextFont(0)
    SetTextScale(0.38, 0.38)
    SetTextColour(255, 255, 255, 255)
    SetTextCentre(true)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    addText(text)
    EndTextCommandDisplayText(x, y)
end

local function sound(name, volume)
    SendNUIMessage({ t = 'play', f = name, v = volume or Config.Volume })
end

local function groundAt(s)
    local found, z = GetGroundZFor_3dCoord(s.x, s.y, s.z + 2.0, false)
    if found and math.abs(z - s.z) < 1.5 then return z end
    return s.z
end

local function spawnElf(i)
    if elf and elfSpot == i then return end
    removeEntity(elf)
    elf, elfSpot = nil, nil
    local s = Spots[i]
    if not s then return end
    local hash = loadModel(Config.Elf.model)
    if not hash then return end
    elf = CreatePed(4, hash, s.x, s.y, groundAt(s), s.heading, false, true)
    elfSpot = i
    SetModelAsNoLongerNeeded(hash)
    SetPedDefaultComponentVariation(elf)
    styleHead(elf, Config.Elf.look)
    wear(elf, Config.Elf.outfit)
    SetFacialIdleAnimOverride(elf, Config.Elf.mood, 0)
    calm(elf)
    play(elf, Config.Elf.idle, 1)
end

local function removeElf()
    removeEntity(elf)
    elf, elfSpot = nil, nil
end

local function attach(object, ped, hand)
    AttachEntityToEntity(object, ped, GetPedBoneIndex(ped, hand.bone), hand.offset.x, hand.offset.y, hand.offset.z,
        hand.rotation.x, hand.rotation.y, hand.rotation.z, true, true, false, true, 1, true)
end

local function treatOver(ped, start, stopAt)
    if GetGameTimer() >= stopAt then return true end
    if not DoesEntityExist(ped) or #(GetEntityCoords(ped) - start) > Config.Treat.moveOff then return true end
    return IsPedInAnyVehicle(ped, false) or IsPedRagdoll(ped) or IsPedShooting(ped) or IsPedJumping(ped)
end

local function giveTreat(src)
    local player = GetPlayerFromServerId(src)
    if player == -1 then return end
    local ped = GetPlayerPed(player)
    local mine = player == PlayerId()
    local tr = Config.Treat
    if mine then
        treating = true
        say(Config.Text.elfName, Config.Text.niceLine)
        play(ped, tr.take, 48)
    end
    if elf then
        elfActionUntil = GetGameTimer() + tr.handOverMs + 2500
        play(elf, tr.give, 0)
    end
    local hash = loadModel(tr.model)
    local cane
    if hash then
        cane = CreateObject(hash, GetEntityCoords(elf or ped), false, false, false)
        SetModelAsNoLongerNeeded(hash)
        SetEntityCollision(cane, false, false)
        held[cane] = true
        if elf then attach(cane, elf, tr.elfHand) else attach(cane, ped, tr.playerHand) end
    end
    CreateThread(function()
        Wait(tr.handOverMs)
        if cane and DoesEntityExist(cane) then
            DetachEntity(cane, false, false)
            if DoesEntityExist(ped) then attach(cane, ped, tr.playerHand) end
        end
        if mine then notify(Config.Text.treatNotify) end
        local start = DoesEntityExist(ped) and GetEntityCoords(ped) or vector3(0.0, 0.0, 0.0)
        local stopAt = GetGameTimer() + tr.holdSeconds * 1000
        local eatAt = GetGameTimer() + tr.eatDelayMs
        local stage = 'hold'
        while not treatOver(ped, start, stopAt) do
            local now = GetGameTimer()
            if mine then
                if stage == 'hold' and now >= eatAt then
                    stage = 'intro'
                    say(Config.Text.elfName, Config.Text.thanks)
                    play(ped, tr.eat.intro, 48)
                    eatAt = now + tr.eat.introMs
                elseif stage == 'intro' and now >= eatAt then
                    stage = 'loop'
                    play(ped, tr.eat.loop, 49)
                elseif stage == 'loop' and now >= stopAt - tr.eat.outroMs then
                    stage = 'outro'
                    play(ped, tr.eat.outro, 48)
                end
                if IsControlJustPressed(0, 24) or IsControlJustPressed(0, 25) or IsControlJustPressed(0, 22) then break end
            end
            Wait(0)
        end
        if mine and DoesEntityExist(ped) then
            for _, a in ipairs({ tr.take, tr.eat.intro, tr.eat.loop, tr.eat.outro }) do StopAnimTask(ped, a.dict, a.clip, 2.0) end
        end
        if cane then
            held[cane] = nil
            removeEntity(cane)
        end
        if mine then treating = false end
    end)
end

local function offsetPair(dict, attackerClip, victimClip, origin, heading)
    local a = GetAnimInitialOffsetPosition(dict, attackerClip, origin.x, origin.y, origin.z, 0.0, 0.0, heading, 0.0, 2)
    local v = GetAnimInitialOffsetPosition(dict, victimClip, origin.x, origin.y, origin.z, 0.0, 0.0, heading, 0.0, 2)
    local ar = GetAnimInitialOffsetRotation(dict, attackerClip, origin.x, origin.y, origin.z, 0.0, 0.0, heading, 0.0, 2)
    local vr = GetAnimInitialOffsetRotation(dict, victimClip, origin.x, origin.y, origin.z, 0.0, 0.0, heading, 0.0, 2)
    local shift = origin - a
    return v + shift, vr.z + (heading - ar.z)
end

local runScene, endScene

local function knock(src)
    local player = GetPlayerFromServerId(src)
    if player == -1 then return end
    local k = Config.Knock
    if not loadDict(k.dict) then return end
    local mine = player == PlayerId()
    if elf then
        elfActionUntil = GetGameTimer() + 4000
        TaskPlayAnim(elf, k.dict, k.elf, 8.0, -4.0, -1, 0, 0.0, false, false, false)
    end
    if not mine then return end
    local me = PlayerPedId()
    say(Config.Text.elfName, Config.Text.naughtyLine, 2500)
    if elf then
        local spot = GetEntityCoords(elf)
        local pos, heading = offsetPair(k.dict, k.elf, k.victim, spot, GetEntityHeading(elf))
        SetEntityCoordsNoOffset(me, pos.x, pos.y, spot.z, false, false, false)
        SetEntityHeading(me, heading)
    end
    ClearPedTasksImmediately(me)
    TaskPlayAnim(me, k.dict, k.victim, 8.0, -4.0, -1, 2, 0.0, false, false, false)
    SetTimeout(350, function() sound(k.sound) end)
    CreateThread(function()
        local ok, err = pcall(runScene)
        if not ok then
            print(('olentrix_mpc_elf: scene stopped: %s'):format(err))
            endScene(true)
            waking = false
        end
    end)
end

local function local3(v)
    local o = Config.Scene.origin
    return vector3(o.x + v.x, o.y + v.y, o.z + v.z)
end

local function blockAll()
    DisableAllControlActions(0)
    EnableControlAction(0, 249, true)
    EnableControlAction(0, 245, true)
    HideHudAndRadarThisFrame()
end

local function placeScenePed(ped, p)
    local w = local3(vector3(p.x, p.y, p.z))
    SetEntityCoordsNoOffset(ped, w.x, w.y, w.z, false, false, false)
    SetEntityHeading(ped, p.w)
end

local function lowestFoot(ped)
    local z = 1e9
    for _, bone in ipairs(Config.Scene.feetBones) do
        local c = GetPedBoneCoords(ped, bone, 0.0, 0.0, 0.0)
        if c.z < z then z = c.z end
    end
    return z
end

local function floorZ()
    return Config.Scene.origin.z
end

local function settleFeet(ped)
    if not ped or not DoesEntityExist(ped) then return 0.0 end
    local delta = floorZ() + Config.Scene.footHeight - lowestFoot(ped)
    if math.abs(delta) > Config.Scene.footTolerance and math.abs(delta) < 2.5 then
        local c = GetEntityCoords(ped)
        SetEntityCoordsNoOffset(ped, c.x, c.y, c.z + delta, false, false, false)
        return delta
    end
    return 0.0
end

endScene = function(fast)
    local s = scene
    if not s then return end
    scene = nil
    if s.cams then
        for _, cam in ipairs(s.cams) do
            if DoesCamExist(cam) then DestroyCam(cam, false) end
        end
    end
    RenderScriptCams(false, false, 0, true, true)
    ClearFocus()
    ClearTimecycleModifier()
    ClearOverrideWeather()
    removeEntity(s.creature)
    removeEntity(s.victim)
    SendNUIMessage({ t = 'stop' })
    ClearPrints()
    if fast then
        local me = PlayerPedId()
        FreezeEntityPosition(me, false)
        ClearPedTasksImmediately(me)
        DoScreenFadeIn(0)
    end
end

local function blocked(handle, me)
    local result, hitAny = 1, false
    local tries = 0
    while result == 1 and tries < 50 do
        result, hitAny = GetShapeTestResult(handle)
        if result == 1 then Wait(0) end
        tries = tries + 1
    end
    return hitAny == 1 or hitAny == true
end

local function wakeSpot(me)
    local base, heading
    if elf and DoesEntityExist(elf) then
        base, heading = GetEntityCoords(elf), GetEntityHeading(elf)
    else
        local s = Spots[state().spot or 0]
        if not s then return nil end
        base, heading = vector3(s.x, s.y, s.z + 1.0), s.heading
    end
    local front = Config.Wake.front
    for _, d in ipairs(front.distances) do
        for _, a in ipairs(front.angles) do
            local h = math.rad(heading + a)
            local x, y = base.x - math.sin(h) * d, base.y + math.cos(h) * d
            local found, gz = GetGroundZFor_3dCoord(x, y, base.z + 1.0, false)
            if found and math.abs(gz - (base.z - 1.0)) < 0.6 then
                local body = StartShapeTestCapsule(x, y, gz + 0.45, x, y, gz + 1.6, 0.32, 19, me, 7)
                local sight = StartShapeTestLosProbe(base.x, base.y, base.z + 0.2, x, y, gz + 1.0, 19, me, 7)
                if not blocked(body, me) and not blocked(sight, me) then
                    return vector3(x, y, gz), math.deg(math.atan(-(base.x - x), base.y - y)) % 360.0
                end
            end
        end
    end
    return nil
end

local function wakeUp()
    local w = Config.Wake
    local me = PlayerPedId()
    waking = true
    RequestCollisionAtCoord(GetEntityCoords(me))
    local tries = 0
    while not HasCollisionLoadedAroundEntity(me) and tries < 100 do Wait(50); tries = tries + 1 end
    FreezeEntityPosition(me, false)
    ClearPedTasksImmediately(me)
    local spot, facing = wakeSpot(me)
    if spot then
        SetEntityCoords(me, spot.x, spot.y, spot.z + 1.0, false, false, false, false)
        SetEntityHeading(me, facing)
    end
    RequestAnimSet(w.clipset)
    loadDict(w.getUp.dict)
    TaskPlayAnim(me, w.getUp.dict, w.getUp.clip, 4.0, -4.0, w.getUp.ms, 0, 0.0, false, false, false)
    SetTimecycleModifier(w.timecycle)
    SetTimecycleModifierStrength(1.0)
    ShakeGameplayCam(w.shake, w.shakeAmount)
    sound(w.sound)
    DoScreenFadeIn(w.fadeMs)
    tries = 0
    while not HasAnimSetLoaded(w.clipset) and tries < 100 do Wait(10); tries = tries + 1 end
    if HasAnimSetLoaded(w.clipset) then SetPedMovementClipset(me, w.clipset, 1.0) end
    TriggerServerEvent('olentrix_mpc_elf:woke')
    local stop = GetGameTimer() + w.seconds * 1000
    while GetGameTimer() < stop and waking do
        local left = (stop - GetGameTimer()) / (w.seconds * 1000)
        SetTimecycleModifierStrength(math.min(1.0, left * 1.6))
        Wait(100)
    end
    StopGameplayCamShaking(false)
    ClearTimecycleModifier()
    ResetPedMovementClipset(PlayerPedId(), 1.0)
    waking = false
end

local function wake()
    local ok, err = pcall(wakeUp)
    if not ok then
        print(('olentrix_mpc_elf: wake-up stopped: %s'):format(err))
        local me = PlayerPedId()
        FreezeEntityPosition(me, false)
        StopGameplayCamShaking(true)
        ClearTimecycleModifier()
        ResetPedMovementClipset(me, 0.0)
        DoScreenFadeIn(500)
        TriggerServerEvent('olentrix_mpc_elf:woke')
        waking = false
    end
end

local function sceneCam(shot)
    local c = shot.cam
    local a = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, c.fov, false, 2)
    local from = local3(c.from)
    SetCamCoord(a, from.x, from.y, from.z)
    local look = local3(c.look)
    PointCamAtCoord(a, look.x, look.y, look.z)
    scene.cams[#scene.cams + 1] = a
    return a, c
end

local function sceneShot(i, shot, nextAt)
    local s = scene
    local a, c = sceneCam(shot)
    if c.to then
        local b = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, c.fov, false, 2)
        local to = local3(c.to)
        SetCamCoord(b, to.x, to.y, to.z)
        local look = local3(c.lookTo or c.look)
        PointCamAtCoord(b, look.x, look.y, look.z)
        s.cams[#s.cams + 1] = b
        SetCamActive(a, true)
        RenderScriptCams(true, false, 0, true, true)
        SetCamActiveWithInterp(b, a, math.floor((nextAt - shot.at) * 1000), 1, 1)
    else
        SetCamActive(a, true)
        RenderScriptCams(true, false, 0, true, true)
    end
    s.settleAt = GetGameTimer() + 400
    if shot.creature then
        if shot.creature.pos then placeScenePed(s.creature, shot.creature.pos) end
        if shot.creature.anim then play(s.creature, shot.creature.anim) end
    end
    if shot.victim then
        if shot.victim.pos then placeScenePed(s.victim, shot.victim.pos) end
        if shot.victim.anim then play(s.victim, shot.victim.anim) end
    end
    if shot.takedown then
        local t = shot.takedown
        if loadDict(t.dict) then
            for _, ped in ipairs({ s.creature, s.victim }) do
                FreezeEntityPosition(ped, false)
                ClearPedTasksImmediately(ped)
            end
            local o = local3(vector3(t.origin.x, t.origin.y, t.origin.z))
            local id = CreateSynchronizedScene(o.x, o.y, o.z, 0.0, 0.0, t.origin.w, 2)
            SetSynchronizedSceneHoldLastFrame(id, true)
            TaskSynchronizedScene(s.creature, id, t.dict, t.creature, 1000.0, -8.0, 0, 0, 1000.0, 0)
            TaskSynchronizedScene(s.victim, id, t.dict, t.victim, 1000.0, -8.0, 0, 0, 1000.0, 0)
            SetSynchronizedScenePhase(id, 0.0)
            s.sync, s.syncOrigin, s.syncRot, s.syncChecked = id, o, t.origin.w, false
        end
    end
end

runScene = function()
    local k, sc = Config.Knock, Config.Scene
    local me = PlayerPedId()
    Wait(k.fadeAfterMs)
    DoScreenFadeOut(k.fadeMs)
    Wait(k.fadeMs + 100)
    FreezeEntityPosition(me, true)
    loadDict(k.out.dict)
    TaskPlayAnim(me, k.out.dict, k.out.clip, 8.0, -8.0, -1, 1, 0.0, false, false, false)
    scene = { cams = {} }
    local origin = sc.origin
    SetFocusPosAndVel(origin.x, origin.y, origin.z, 0.0, 0.0, 0.0)
    NewLoadSceneStartSphere(origin.x, origin.y, origin.z, 40.0, 0)
    local hash = loadModel(sc.creature.model)
    for _, shot in ipairs(sc.shots) do
        for _, part in ipairs({ shot.creature, shot.victim }) do
            if part and part.anim then RequestAnimDict(part.anim.dict) end
        end
        if shot.takedown then RequestAnimDict(shot.takedown.dict) end
    end
    local stop = GetGameTimer() + sc.loadSeconds * 1000
    while GetGameTimer() < stop and not IsNewLoadSceneLoaded() and scene do Wait(50) end
    NewLoadSceneStop()
    if not scene then return end
    SetOverrideWeather('EXTRASUNNY')
    if hash then
        scene.creature = CreatePed(4, hash, origin.x, origin.y, origin.z, 0.0, false, true)
        SetModelAsNoLongerNeeded(hash)
        calm(scene.creature)
    end
    scene.victim = ClonePed(me, false, false, true)
    calm(scene.victim)
    local waitCol = GetGameTimer() + 3000
    while scene and GetGameTimer() < waitCol and not (scene.creature and HasCollisionLoadedAroundEntity(scene.creature)) do
        RequestAdditionalCollisionAtCoord(origin.x, origin.y, origin.z)
        Wait(0)
    end
    if not scene then return end
    SetTimecycleModifier(sc.timecycle)
    sound(sc.music)
    local shots = sc.shots
    local t0 = GetGameTimer()
    local current, lineShown, hit, faded = 0, {}, {}, false
    DoScreenFadeIn(500)
    while scene do
        local t = (GetGameTimer() - t0) / 1000.0
        if t >= sc.length then break end
        local nextIndex = current + 1
        if shots[nextIndex] and t >= shots[nextIndex].at then
            current = nextIndex
            local shot = shots[current]
            local nextAt = shots[current + 1] and shots[current + 1].at or sc.length
            sceneShot(current, shot, nextAt)
        end
        local shot = shots[current]
        if shot then
            if shot.line and not lineShown[current] and t >= shot.at + shot.line.at then
                lineShown[current] = true
                say(sc.creature.name, shot.line.text, shot.line.ms)
            end
            if scene.settleAt and GetGameTimer() >= scene.settleAt then
                scene.settleAt = nil
                if not shot.takedown then
                    local dc, dv = settleFeet(scene.creature), settleFeet(scene.victim)
                end
            end
            if shot.takedown and scene.sync and not scene.syncChecked and t >= shot.at + 0.1 then
                scene.syncChecked = true
                local delta = floorZ() + Config.Scene.footHeight - math.min(lowestFoot(scene.creature), lowestFoot(scene.victim))
                if math.abs(delta) > Config.Scene.footTolerance and math.abs(delta) < 2.5 then
                    local o = scene.syncOrigin
                    SetSynchronizedSceneOrigin(scene.sync, o.x, o.y, o.z + delta, 0.0, 0.0, scene.syncRot, true)
                end
            end
            if shot.takedown and not hit[current] and t >= shot.at + shot.takedown.contact then
                hit[current] = true
                sound(Config.Knock.sound)
            end
            if shot.fadeAt and not faded and t >= shot.at + shot.fadeAt then
                faded = true
                DoScreenFadeOut(600)
            end
        end
        RequestAdditionalCollisionAtCoord(origin.x, origin.y, origin.z)
        for _, l in ipairs(sc.lights) do
            local p = local3(l.pos)
            DrawLightWithRange(p.x, p.y, p.z, l.colour[1], l.colour[2], l.colour[3], l.range, l.intensity)
        end
        blockAll()
        Wait(0)
    end
    if not scene then return end
    if not IsScreenFadedOut() then
        DoScreenFadeOut(500)
        Wait(600)
    end
    endScene(false)
    wake()
end

local function nearElf(position)
    if not elf or not DoesEntityExist(elf) then return false end
    return #(position - GetEntityCoords(elf)) < Config.PromptDistance
end

CreateThread(function()
    while true do
        local st = state()
        local s = st.spot and Spots[st.spot]
        if s then
            local distance = #(GetEntityCoords(PlayerPedId()) - vector3(s.x, s.y, s.z))
            if distance < Config.SpawnDistance then
                if elfSpot ~= st.spot then spawnElf(st.spot) end
                local idle = Config.Elf.idle
                if elf and GetGameTimer() >= elfActionUntil and not IsEntityPlayingAnim(elf, idle.dict, idle.clip, 3) then play(elf, idle, 1) end
            elseif distance > Config.DespawnDistance then
                removeElf()
            end
        end
        Wait(1000)
    end
end)

CreateThread(function()
    while true do
        local wait = 500
        if elf and not scene then
            local me = PlayerPedId()
            local position = GetEntityCoords(me)
            local head = GetEntityCoords(elf) + vector3(0.0, 0.0, 1.05)
            if #(position - head) < 12.0 then wait = 0 end
            if asking then
                for _, control in ipairs(Config.Keys.block) do DisableControlAction(0, control, true) end
                local keys, words = Config.Keys, Config.Text
                drawText3d(keys.nice.glyph .. ' ' .. words.nice .. '      ' .. keys.naughty.glyph .. ' ' .. words.naughty, head)
                if IsDisabledControlJustPressed(0, keys.nice.control) then
                    asking = false
                    TriggerServerEvent('olentrix_mpc_elf:choose', 'nice')
                elseif IsDisabledControlJustPressed(0, keys.naughty.control) then
                    asking = false
                    TriggerServerEvent('olentrix_mpc_elf:choose', 'naughty')
                elseif GetGameTimer() > askUntil or not nearElf(position) or IsEntityDead(me) then
                    asking = false
                    ClearPrints()
                    TriggerServerEvent('olentrix_mpc_elf:cancel')
                end
            elseif nearElf(position) and not waking and not treating and not IsPedInAnyVehicle(me, false) then
                local busy = state().busy
                local left = (cooldownUntil - GetGameTimer()) / 1000
                if left > 0 then
                    drawText3d(waitText(left), head)
                elseif not busy or busy == GetPlayerServerId(PlayerId()) then
                    drawText3d(Config.Keys.talk.glyph .. ' ' .. Config.Text.talk, head)
                    if IsControlJustPressed(0, Config.Keys.talk.control) then TriggerServerEvent('olentrix_mpc_elf:talk') end
                else
                    drawText3d(Config.Text.busyPrompt, head)
                end
            end
        end
        Wait(wait)
    end
end)

RegisterNetEvent('olentrix_mpc_elf:ask', function()
    asking = true
    askUntil = GetGameTimer() + Config.ChoiceSeconds * 1000
    say(Config.Text.elfName, Config.Text.question, Config.ChoiceSeconds * 1000)
    if elf then TaskLookAtEntity(elf, PlayerPedId(), Config.ChoiceSeconds * 1000, 2048, 3) end
end)

RegisterNetEvent('olentrix_mpc_elf:refuse', function(reason, seconds)
    local text
    if reason == 'cooldown' then
        cooldownUntil = GetGameTimer() + seconds * 1000
        text = Config.Text.cooldown:format(waitText(seconds))
    else
        text = Config.Text[reason] or Config.Text.busy
    end
    say(Config.Text.elfName, text)
    notify(text)
end)

RegisterNetEvent('olentrix_mpc_elf:act', function(kind, src, spot)
    if spot ~= elfSpot and src ~= GetPlayerServerId(PlayerId()) then return end
    if src == GetPlayerServerId(PlayerId()) then
        ClearPrints()
        cooldownUntil = GetGameTimer() + Config.Cooldown * 1000
    end
    if kind == 'nice' then giveTreat(src) else knock(src) end
end)

AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then return end
    removeElf()
    for object in pairs(held) do removeEntity(object) end
    if treating then
        local me = PlayerPedId()
        local tr = Config.Treat
        for _, a in ipairs({ tr.take, tr.eat.intro, tr.eat.loop, tr.eat.outro }) do StopAnimTask(me, a.dict, a.clip, 2.0) end
        treating = false
    end
    if scene then
        endScene(true)
    end
    if waking then
        waking = false
        StopGameplayCamShaking(true)
        ClearTimecycleModifier()
        ResetPedMovementClipset(PlayerPedId(), 0.0)
    end
    if IsScreenFadedOut() or IsScreenFadingOut() then DoScreenFadeIn(0) end
end)
