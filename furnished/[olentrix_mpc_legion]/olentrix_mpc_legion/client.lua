local AMBIENT = { [1] = true, [2] = true, [3] = true, [4] = true, [5] = true }
local blocks, pops, applied = {}, {}, false
local Z0, Z1 = Area.min.z, Area.max.z

local function inside(x, y)
    if x < Area.min.x or x > Area.max.x or y < Area.min.y or y > Area.max.y then return false end
    local P, c, j = Area.poly, false, #Area.poly
    for i = 1, #P do
        local a, b = P[i], P[j]
        if (a.y > y) ~= (b.y > y) and x < (b.x - a.x) * (y - a.y) / (b.y - a.y) + a.x then c = not c end
        j = i
    end
    return c
end

local function apply(on)
    for i, b in ipairs(Area.boxes) do
        local x0, y0, x1, y1 = b[1], b[2], b[3], b[4]
        if on then
            blocks[#blocks + 1] = AddScenarioBlockingArea(x0, y0, Z0, x1, y1, Z1, false, true, true, true)
            if i <= Area.popAreas then pops[#pops + 1] = AddPopMultiplierArea(x0, y0, Z0, x1, y1, Z1, 0.0, 0.0, false) end
            SetPedPathsInArea(x0, y0, Z0, x1, y1, Z1, false)
        else
            SetPedPathsBackToOriginal(x0, y0, Z0, x1, y1, Z1)
        end
    end
    if not on then
        for _, h in ipairs(blocks) do RemoveScenarioBlockingArea(h, false) end
        for _, h in ipairs(pops) do if h and h >= 0 then RemovePopMultiplierArea(h, false) end end
        blocks, pops = {}, {}
    end
    applied = on
end

local function ambient(ped)
    return AMBIENT[GetEntityPopulationType(ped)] and not IsEntityAMissionEntity(ped) and NetworkHasControlOfEntity(ped)
end

local function unseen(ped, cam)
    return not IsEntityOnScreen(ped) or #(GetEntityCoords(ped) - cam) > Area.seen
end

CreateThread(function()
    local mid = vector2((Area.min.x + Area.max.x) / 2, (Area.min.y + Area.max.y) / 2)
    local reach = #(vector2(Area.max.x, Area.max.y) - mid) + Area.range
    apply(true)
    while true do
        local p = GetEntityCoords(PlayerPedId())
        if #(p.xy - mid) < reach then
            local cam = GetFinalRenderedCamCoord()
            for _, ped in ipairs(GetGamePool('CPed')) do
                if not IsPedAPlayer(ped) and not IsPedInAnyVehicle(ped, true) and ambient(ped) then
                    local c = GetEntityCoords(ped)
                    if c.z > Z0 and c.z < Z1 and inside(c.x, c.y) and unseen(ped, cam) then
                        SetEntityAsMissionEntity(ped, true, true)
                        DeleteEntity(ped)
                    end
                end
            end
            Wait(1000)
        else
            Wait(4000)
        end
    end
end)

AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() and applied then apply(false) end
end)
