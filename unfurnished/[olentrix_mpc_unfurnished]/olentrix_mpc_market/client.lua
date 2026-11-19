local HUB = vector3(1407.0, -706.5, 86.82)
local PSI = 76.0
local R, NG = 17.0, 18
local PERIOD = 240.0
local RANGE = 430.0

local rim, gond = nil, {}
local t0, a0 = 0, 0.0
local U = vector3(-math.sin(math.rad(PSI)), math.cos(math.rad(PSI)), 0.0)

local function load(name)
    local h = joaat(name)
    RequestModel(h)
    local n = 0
    while not HasModelLoaded(h) and n < 3000 do Wait(10); n = n + 1 end
    return HasModelLoaded(h) and h or nil
end

local function spawn()
    local hr, hgr, hgg = load('xv_wheel_rim'), load('xv_wheel_gond_r'), load('xv_wheel_gond_g')
    if not (hr and hgr and hgg) then return false end
    rim = CreateObjectNoOffset(hr, HUB.x, HUB.y, HUB.z, false, false, false)
    if rim == 0 or not DoesEntityExist(rim) then rim = nil; return false end
    FreezeEntityPosition(rim, true); SetEntityCollision(rim, false, false)
    for i = 1, NG do
        local g = CreateObjectNoOffset((i % 2 == 0) and hgr or hgg, HUB.x, HUB.y, HUB.z - R, false, false, false)
        FreezeEntityPosition(g, true); SetEntityCollision(g, true, true); SetEntityHeading(g, PSI)
        gond[i] = g
    end
    local c, n = GetCloudTimeAsInt(), 0
    while GetCloudTimeAsInt() == c and n < 120 do Wait(10); n = n + 1 end
    t0 = GetGameTimer(); a0 = ((GetCloudTimeAsInt() % math.floor(PERIOD)) / PERIOD) * 360.0
    return true
end

local function despawn()
    if rim then DeleteObject(rim); rim = nil end
    for i = 1, #gond do if gond[i] then DeleteObject(gond[i]) end end
    gond = {}
end

CreateThread(function()
    local hz, cz = math.sin(math.rad(PSI) / 2), math.cos(math.rad(PSI) / 2)
    while true do
        local d = #(GetEntityCoords(PlayerPedId()) - HUB)
        if d < RANGE and not rim then
            if not spawn() then despawn(); Wait(3000) end
        elseif d > RANGE + 40.0 and rim then despawn() end
        if rim then
            local ang = (a0 + ((GetGameTimer() - t0) / 1000.0) / PERIOD * 360.0) % 360.0
            local hx, cx = math.sin(math.rad(ang) / 2), math.cos(math.rad(ang) / 2)
            SetEntityQuaternion(rim, cz * hx, hz * hx, hz * cx, cz * cx)
            for i = 1, NG do
                local a = math.rad(ang + (i - 1) * 360.0 / NG)
                local p = HUB + U * (R * math.cos(a)) + vector3(0.0, 0.0, R * math.sin(a))
                SetEntityCoordsNoOffset(gond[i], p.x, p.y, p.z, false, false, false)
            end
            Wait(0)
        else
            Wait(2000)
        end
    end
end)

exports('gondolas', function() return gond end)

AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() then despawn() end end)
