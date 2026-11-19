local N = Neon
local SONGS = N.songs
local CYCLE = 0.0
local START = {}
for i, s in ipairs(SONGS) do
    START[i] = CYCLE
    CYCLE = CYCLE + s[2] + N.gap
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
            if off < SONGS[i][2] then return i, off end
            return nil, 0.0
        end
    end
    return nil, 0.0
end

local PAL = { { 255, 34, 51 }, { 34, 255, 85 }, { 34, 102, 255 } }
local CK = { 'r', 'g', 'b' }
local FLOOR = 0.32
local NEAR, FAR, LIGHT_R, MAX_LIGHTS = 230.0, 270.0, 70.0, 12

for _, M in ipairs(N.music) do
    M.bar = {}
    local b = 0
    for i = 1, #M.t do
        if M.k[i] == 1 then b = b + 1 end
        M.bar[i] = b
    end
end

local EL = N.el
for _, e in ipairs(EL) do e.o = {}; e.w = { 1.0, 0.0, 0.0 }; e.L = FLOOR; e.Lc = FLOOR; e.tc = 1; e.rate = 1.5 end
for _, o in ipairs(N.obj) do
    local e = EL[o.e]
    e.o[#e.o + 1] = o
    o.q = { -1, -1, -1 }; o.v = { false, false, false }
end
local GROUP = {}
for _, e in ipairs(EL) do GROUP[e.g] = (GROUP[e.g] or 0) + 1 end

local spawned, busy = false, false

local function spawn()
    busy = true
    local hashes = {}
    for _, m in ipairs({ 'tube', 'span', 'ray', 'arch' }) do
        for _, c in ipairs(CK) do
            local h = GetHashKey('lg_neon_' .. c .. '_' .. m)
            RequestModel(h)
            hashes[#hashes + 1] = h
        end
    end
    local t = GetGameTimer() + 15000
    for _, h in ipairs(hashes) do
        while not HasModelLoaded(h) and GetGameTimer() < t do Wait(20) end
    end
    for i, o in ipairs(N.obj) do
        o.ent = {}
        for c = 1, 3 do
            local h = GetHashKey('lg_neon_' .. CK[c] .. '_' .. o.m)
            local ent = CreateObjectNoOffset(h, o.p.x, o.p.y, o.p.z, false, false, false)
            SetEntityCollision(ent, false, false)
            FreezeEntityPosition(ent, true)
            if o.m == 'tube' then
                SetEntityMatrix(ent, o.f.x, o.f.y, o.f.z, o.r.x, o.r.y, o.r.z, o.u.x, o.u.y, o.u.z, o.p.x, o.p.y, o.p.z)
            else
                SetEntityHeading(ent, o.h)
            end
            SetEntityVisible(ent, false, false)
            o.ent[c] = ent; o.q[c] = -1; o.v[c] = false
        end
        if i % 6 == 0 then Wait(0) end
    end
    for _, h in ipairs(hashes) do SetModelAsNoLongerNeeded(h) end
    spawned, busy = true, false
end

local function despawn()
    for _, o in ipairs(N.obj) do
        if o.ent then
            for c = 1, 3 do if DoesEntityExist(o.ent[c]) then DeleteObject(o.ent[c]) end end
            o.ent = nil
        end
    end
    spawned = false
end

AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() then despawn() end end)

local function env(x, tau) if x < 0.0 then return 0.0 end return math.exp(-x / tau) end

local function rest(e, now)
    e.L = 0.30 + 0.08 * math.sin(now * 0.8 + e.a * 6.2832)
    e.tc = math.floor(e.a * 3 + now / 6.0) % 3 + 1
    e.rate = 1.5
end

local function chase(e, s)
    local C0 = s.bar % 3 + 1
    local C1, C2 = C0 % 3 + 1, (C0 + 1) % 3 + 1
    local pk = 0.7 + 0.3 * s.str
    local g = e.g
    e.rate = 14.0
    if g == 'pole' then
        e.tc = C2; e.L = FLOOR + (pk - FLOOR) * env(s.barT, 0.45)
    elseif g == 'gate' then
        e.tc = e.i == 1 and C0 or C1; e.L = 0.45 + 0.5 * env(s.barT, 0.6)
    else
        local n = g == 'span' and e.rn or GROUP[g]
        local idx = g == 'span' and e.r or (e.i - 1)
        local step = (s.beat - 1) % n
        local dir = (s.sec % 2 == 1) and 1 or -1
        if g == 'crown' then dir = -dir end
        local hot = dir > 0 and step or (n - 1 - step)
        if idx == hot then
            e.tc = g == 'crown' and C2 or C1; e.L = FLOOR + (pk - FLOOR) * env(s.bt, 0.30)
        else
            e.tc = C0; e.L = FLOOR
        end
    end
end

local function breathe(e, s)
    local ph = s.ph + e.a
    e.L = 0.28 + 0.42 * (0.5 - 0.5 * math.cos(6.2832 * ph))
    if e.g == 'crown' then e.L = e.L + 0.25 * env(s.barT, 1.0) end
    e.tc = math.floor(e.a * 3 + s.bar / 4) % 3 + 1
    e.rate = 1.5
end

local function alternate(e, s)
    local pk = 0.7 + 0.3 * s.str
    local g = e.g
    e.rate = 14.0
    if s.k == 1 and (g == 'crown' or g == 'gate' or g == 'pole') then
        e.tc = 3; e.L = 0.4 + 0.55 * env(s.bt, 0.4)
        return
    end
    local idx = g == 'span' and e.r or e.i
    if (idx + s.beat) % 2 == 0 then
        e.tc = 1; e.L = FLOOR + (pk - FLOOR) * env(s.bt, 0.22)
    else
        e.tc = 2; e.L = FLOOR + 0.08
    end
end

local WALTZ = { pole = 1, ray = 1, crown = 1, span = 2, gate = 2, cabin = 3 }

local function waltz(e, s)
    local C0 = s.bar % 3 + 1
    local gk = WALTZ[e.g]
    local k = (s.k - 1) % 3 + 1
    local pk = 0.7 + 0.3 * s.str
    e.tc = (C0 + gk - 2) % 3 + 1
    e.L = FLOOR
    if k >= gk then e.L = FLOOR + (pk - FLOOR) * env((k - gk) * s.bp + s.bt, 0.4) end
    if e.g == 'ray' and e.i == s.bar % 6 + 1 then e.L = math.min(1.0, e.L + 0.3) end
    e.rate = 8.0
end

local PATTERN = { A = chase, B = breathe, C = alternate, D = waltz }

local cur, p = nil, 0
local S = {}

local function state(si, off)
    local M = N.music[si]
    local T = M.t
    local ms = (off - N.lag) * 1000.0
    if si ~= cur then cur = si; p = 0 end
    if p > 0 and T[p] > ms then p = 0 end
    while p < #T and T[p + 1] <= ms do p = p + 1 end
    if p == 0 then return nil end
    local k, nb = M.k[p], M.nb[p]
    local bp = ((T[p + 1] or (T[p] + 500)) - T[p]) / 1000.0
    local d = math.max(1, p - (k - 1))
    S.bt = (ms - T[p]) / 1000.0
    S.k, S.nb, S.bp, S.beat, S.bar = k, nb, bp, p, M.bar[p]
    S.barT = (ms - T[d]) / 1000.0
    S.ph = ((k - 1) + math.min(1.0, S.bt / bp)) / nb
    S.str = M.s[p] / 9.0
    S.sec = M.sec[p]
    S.secT = (ms - M.st[S.sec]) / 1000.0
    S.pat = PATTERN[M.pat[S.sec]] or chase
    return S
end

local function apply(o, c, a)
    if a == o.q[c] then return end
    o.q[c] = a
    local ent = o.ent[c]
    if a < 12 then
        if o.v[c] then SetEntityVisible(ent, false, false); o.v[c] = false end
        return
    end
    if not o.v[c] then SetEntityVisible(ent, true, false); o.v[c] = true end
    if a >= 255 then ResetEntityAlpha(ent) else SetEntityAlpha(ent, a, false) end
end

local lit = {}
local half = 0

local function night()
    local h = GetClockHours() + GetClockMinutes() / 60.0
    if h >= 19.0 or h < 6.0 then return 1.0 end
    if h >= 17.0 then return (h - 17.0) / 2.0 end
    if h < 8.0 then return (8.0 - h) / 2.0 end
    return 0.0
end

CreateThread(function()
    while not base do Wait(200) end
    while true do
        local cp = GetFinalRenderedCamCoord()
        local d = #(cp - N.c)
        if d < NEAR and not spawned and not busy then spawn()
        elseif d > FAR and spawned then despawn() end
        local nl = {}
        if spawned and night() > 0.0 then
            for _, l in ipairs(N.lights) do
                local dl = #(cp - l.p)
                if dl < LIGHT_R then nl[#nl + 1] = { l = l, d = dl } end
            end
            table.sort(nl, function(a, b) return a.d < b.d end)
            for i = MAX_LIGHTS + 1, #nl do nl[i] = nil end
        end
        lit = nl
        Wait(500)
    end
end)

CreateThread(function()
    while not base do Wait(200) end
    while true do
        if not spawned then
            Wait(1000)
        else
            local dt = math.min(0.1, GetFrameTime())
            local now = GetGameTimer() / 1000.0
            local si, off = nowSong()
            local s = si and state(si, off) or nil
            half = 1 - half
            dt = dt * 2.0
            for n, e in ipairs(EL) do
                if n % 2 ~= half then goto skip end
                if s then
                    s.pat(e, s)
                    if s.sec > 1 and s.secT < 1.6 then
                        e.L = math.max(e.L, 0.30 + 0.40 * math.sin(3.1416 * s.secT / 1.6))
                    end
                else
                    rest(e, now)
                end
                local w, kk = e.w, math.min(1.0, dt * e.rate)
                for c = 1, 3 do w[c] = w[c] + ((c == e.tc and 1.0 or 0.0) - w[c]) * kk end
                local L = math.max(0.0, math.min(1.0, e.L))
                e.Lc = L
                for _, o in ipairs(e.o) do
                    for c = 1, 3 do apply(o, c, math.floor(L * w[c] * 15.0 + 0.5) * 17) end
                end
                ::skip::
            end
            local nf = #lit > 0 and night() or 0.0
            for i = 1, #lit do
                local l = lit[i].l
                local e = EL[l.e]
                local w = e.w
                local r = PAL[1][1] * w[1] + PAL[2][1] * w[2] + PAL[3][1] * w[3]
                local g = PAL[1][2] * w[1] + PAL[2][2] * w[2] + PAL[3][2] * w[3]
                local b = PAL[1][3] * w[1] + PAL[2][3] * w[2] + PAL[3][3] * w[3]
                DrawLightWithRange(l.p.x, l.p.y, l.p.z, math.floor(r), math.floor(g), math.floor(b), l.r, l.k * e.Lc * nf)
            end
            Wait(0)
        end
    end
end)
