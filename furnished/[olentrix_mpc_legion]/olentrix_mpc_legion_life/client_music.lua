local M = Life.music
local SONGS = M.songs
local CYCLE = 0.0
local START = {}
for i, s in ipairs(SONGS) do
    START[i] = CYCLE
    CYCLE = CYCLE + s[2] + M.gap
end
local base, g0 = nil, 0

CreateThread(function()
    local c, n = GetCloudTimeAsInt(), 0
    while GetCloudTimeAsInt() == c and n < 150 do Wait(10); n = n + 1 end
    g0 = GetGameTimer(); base = GetCloudTimeAsInt()
end)

local function nowSong()
    local t = (base + (GetGameTimer() - g0) / 1000.0) % CYCLE
    for i = #SONGS, 1, -1 do
        if t >= START[i] then
            local off = t - START[i]
            local nx = SONGS[i % #SONGS + 1][1]
            if off < SONGS[i][2] then return SONGS[i][1], off, nx end
            return nil, 0.0, nx
        end
    end
    return nil, 0.0, SONGS[1][1]
end

local function edgeDistance(x, y)
    if InPoly(x, y, M.plaza) then return 0.0 end
    local best, P = 1e9, M.plaza
    local j = #P
    for i = 1, #P do
        local ax, ay, bx, by = P[j][1], P[j][2], P[i][1], P[i][2]
        local dx, dy = bx - ax, by - ay
        local l2 = dx * dx + dy * dy
        local t = l2 > 0 and math.max(0.0, math.min(1.0, ((x - ax) * dx + (y - ay) * dy) / l2)) or 0.0
        local px, py = ax + dx * t - x, ay + dy * t - y
        best = math.min(best, px * px + py * py)
        j = i
    end
    return math.sqrt(best)
end

CreateThread(function()
    while not base do Wait(200) end
    local playing = false
    while true do
        local cp = GetFinalRenderedCamCoord()
        local d = edgeDistance(cp.x, cp.y)
        local vz = math.abs(cp.z - M.z) < 40.0
        if LocalPlayer.state.xmasCutscene then
            SendNUIMessage({ a = 'song', v = 0.0 }); playing = false
            Wait(250)
        elseif d < M.fade and vz then
            local song, off, nx = nowSong()
            local v = M.gain * math.max(0.0, 1.0 - d / M.fade) ^ 1.5
            if song then
                SendNUIMessage({ a = 'song', s = song, t = off, v = v, n = nx }); playing = true
            elseif playing then
                SendNUIMessage({ a = 'song', v = 0.0, n = nx })
            end
            Wait(250)
        else
            if playing then SendNUIMessage({ a = 'song', v = 0.0 }); playing = false end
            Wait(1000)
        end
    end
end)
