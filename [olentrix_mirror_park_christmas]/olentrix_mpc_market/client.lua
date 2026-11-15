local HUB = vector3(1407.0, -706.5, 86.82)
local PSI = 76.0
local R, NG = 17.0, 18
local PERIOD = 360.0
local RANGE = 650.0

local rim, gond = nil, {}
local t0, a0 = 0, 0.0
local U = vector3(-math.sin(math.rad(PSI)), math.cos(math.rad(PSI)), 0.0)

local function load(name)
    local h = joaat(name)
    RequestModel(h)
    local n = 0
    while not HasModelLoaded(h) and n < 300 do Wait(10); n = n + 1 end
    return h
end

local function spawn()
    rim = CreateObjectNoOffset(load('xv_wheel_rim'), HUB.x, HUB.y, HUB.z, false, false, false)
    FreezeEntityPosition(rim, true); SetEntityCollision(rim, false, false)
    for i = 1, NG do
        local g = CreateObjectNoOffset(load((i % 2 == 0) and 'xv_wheel_gond_r' or 'xv_wheel_gond_g'), HUB.x, HUB.y, HUB.z - R, false, false, false)
        FreezeEntityPosition(g, true); SetEntityCollision(g, true, true); SetEntityHeading(g, PSI)
        gond[i] = g
    end
    t0 = GetGameTimer(); a0 = ((GetCloudTimeAsInt() % math.floor(PERIOD)) / PERIOD) * 360.0
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
        if d < RANGE and not rim then spawn() elseif d > RANGE + 40.0 and rim then despawn() end
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

AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() then despawn() end end)
