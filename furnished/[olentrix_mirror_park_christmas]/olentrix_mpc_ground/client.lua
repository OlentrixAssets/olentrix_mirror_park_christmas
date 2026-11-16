local RABBITS = { [`a_c_rabbit_01`] = true, [`a_c_rabbit_02`] = true }
local X1, X2, Y1, Y2 = 1240.0, 1450.0, -810.0, -650.0

CreateThread(function()
    while true do
        local me = GetEntityCoords(PlayerPedId())
        if me.x > X1 - 300 and me.x < X2 + 300 and me.y > Y1 - 300 and me.y < Y2 + 300 then
            for _, ped in ipairs(GetGamePool('CPed')) do
                if RABBITS[GetEntityModel(ped)] then
                    local p = GetEntityCoords(ped)
                    if p.x > X1 and p.x < X2 and p.y > Y1 and p.y < Y2 and not IsPedAPlayer(ped) then
                        SetEntityAsMissionEntity(ped, true, true)
                        DeleteEntity(ped)
                    end
                end
            end
            Wait(500)
        else
            Wait(5000)
        end
    end
end)
