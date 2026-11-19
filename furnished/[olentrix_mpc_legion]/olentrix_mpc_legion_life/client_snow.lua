local SN = Life.snow
local BALL = `WEAPON_SNOWBALL`
local DICT, ANIM = 'anim@mp_snowball', 'pickup_snowball'
local MAX = 10
local armed = false

local function inside(c)
    return c.z > SN.z0 and c.z < SN.z1 and InPoly(c.x, c.y, SN.poly)
end

local function nearHeap(c)
    for _, h in ipairs(SN.heaps) do
        if #(vector2(c.x, c.y) - vector2(h[1], h[2])) < 1.3 then return true end
    end
    return false
end

CreateThread(function()
    SetWeaponDamageModifier(BALL, 0.0)
    while true do
        local ped = PlayerPedId()
        local c = GetEntityCoords(ped)
        local d = #(c.xy - vector2(SN.heaps[1][1], SN.heaps[1][2]))
        if d > 40.0 then
            if armed then RemoveWeaponFromPed(ped, BALL); armed = false end
            Wait(1500)
        else
            local inn = inside(c)
            if armed and not inn then
                RemoveWeaponFromPed(ped, BALL); armed = false
            end
            if inn and nearHeap(c) and not IsPedInAnyVehicle(ped, false) and not IsPedRagdoll(ped) then
                local have = HasPedGotWeapon(ped, BALL, false) and GetAmmoInPedWeapon(ped, BALL) or 0
                if have < MAX then
                    Help('Press ~INPUT_CONTEXT~ to pick up snowballs')
                    if IsControlJustReleased(0, 38) then
                        if LoadDict(DICT) then
                            TaskPlayAnim(ped, DICT, ANIM, 8.0, -8.0, 1600, 0, 0, false, false, false)
                            Wait(1300)
                        end
                        if HasPedGotWeapon(ped, BALL, false) then AddAmmoToPed(ped, BALL, MAX - have)
                        else GiveWeaponToPed(ped, BALL, MAX, false, true) end
                        SetCurrentPedWeapon(ped, BALL, true)
                        armed = true
                    end
                end
            end
            Wait(inn and 0 or 400)
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and armed then RemoveWeaponFromPed(PlayerPedId(), BALL) end
end)
