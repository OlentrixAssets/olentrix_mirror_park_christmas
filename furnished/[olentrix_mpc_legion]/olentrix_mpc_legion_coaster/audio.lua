CSND = {}
local M = {}
M.__index = M
local G = 9.81

local function clamp(x, a, b) if x < a then return a elseif x > b then return b end return x end
local function sm(x, a, b)
    local t = clamp((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)
end
local function r3(x) return math.floor(x * 1000.0 + 0.5) / 1000.0 end

local NAMES = { 'roar_lo', 'roar_mid', 'roar_hi', 'struct', 'wind_hi', 'rattle', 'grind', 'squeal', 'drive', 'chain_motor', 'whine', 'brake' }
local LAUNCH = { launch = true, boost = true, boost2 = true }
local POWER = { power = true, climb = true }
local CHAIN = { chain = true, portal_out = true }
local BRAKE = { trim = true, brake = true, otrim = true }

function CSND.new(R, pose, send, cfg)
    local S = setmetatable({}, M)
    S.R, S.pose, S.send = R, pose, send
    S.cfg = cfg or {}
    S.rev = S.cfg.rev or 0.5
    S.id = S.cfg.id
    S.jointGap = S.cfg.jointGap or 8.3
    local cum, n = { 0.0 }, R.n
    for i = 2, n do
        local dx, dy, dz = R.x[i] - R.x[i - 1], R.y[i] - R.y[i - 1], R.z[i] - R.z[i - 1]
        cum[i] = cum[i - 1] + math.sqrt(dx * dx + dy * dy + dz * dz)
    end
    S.cum = cum
    S.nextEv, S.stage, S.lastMix = 1, 'station', -1.0
    S.f = { v = 0.0, ta = 0.0, fl = 0.0, fv = 1.0, roll = 0.0, upz = 1.0, acc = 0.0 }
    S.pz, S.airT, S.lastDrop, S.lastThud, S.lastLand, S.started = 0.0, 0.0, -10.0, -10.0, -10.0, false
    S.dprev, S.vr, S.pan = nil, 0.0, 0.0
    return S
end

function M:speedAt(tau)
    local R = self.R
    local i, f = self:index(tau)
    local a, b = R.v[i] or 0.0, R.v[i + 1] or R.v[i] or 0.0
    return a + (b - a) * f
end

function M:index(tau)
    local R = self.R
    local N = R.n
    if tau <= R.t[1] then return 1, 0.0 end
    if tau >= R.t[N] then return N - 1, 1.0 end
    local lo, hi = 1, N
    while hi - lo > 1 do
        local mid = (lo + hi) // 2
        if R.t[mid] <= tau then lo = mid else hi = mid end
    end
    return lo, (tau - R.t[lo]) / math.max(R.t[hi] - R.t[lo], 1e-6)
end

function M:dist(tau)
    local i, f = self:index(tau)
    local c = self.cum
    return c[i] + ((c[i + 1] or c[i]) - c[i]) * f
end

function M:features(tau, dt)
    local pose = self.pose
    local h = 0.2
    local _, fw, rt, up, i, f = pose(tau)
    local _, fw1, _, up1 = pose(tau + h)
    local _, fw0, _, up0 = pose(math.max(tau - h, 0.0))
    local k = 1.0 / (2.0 * h)
    local ox, oy, oz = (fw1.x - fw0.x) * k, (fw1.y - fw0.y) * k, (fw1.z - fw0.z) * k
    local ux, uy, uz = (up1.x - up0.x) * k, (up1.y - up0.y) * k, (up1.z - up0.z) * k
    local v = self:speedAt(tau)
    local wl = ox * rt.x + oy * rt.y + oz * rt.z
    local wv = ox * up.x + oy * up.y + oz * up.z
    local roll = ux * rt.x + uy * rt.y + uz * rt.z
    local ta = v * wl
    local fl = (ta + G * rt.z) / G
    local fv = (v * wv + G * up.z) / G
    local acc = (self:speedAt(tau + 0.4) - self:speedAt(math.max(tau - 0.4, 0.0))) / 0.8
    local F = self.f
    local a = 1.0 - math.exp(-dt / 0.12)
    local b = 1.0 - math.exp(-dt / 0.06)
    F.v, F.ta, F.fl, F.roll, F.acc = v, F.ta + (ta - F.ta) * a, F.fl + (fl - F.fl) * a, F.roll + (roll - F.roll) * a, F.acc + (acc - F.acc) * a
    F.fv = F.fv + (fv - F.fv) * b
    F.upz = up.z
    F.pz = fw.z
    F.i = i
    return F
end

function M:amounts(F, under)
    local v = F.v
    local A = {}
    A.mov = sm(v, 0.3, 3.0)
    A.spd = sm(v, 1.0, 26.0)
    A.air = 1.0 - sm(F.fv, 0.15, 0.6)
    A.duck = 1.0 - 0.85 * A.air
    A.comp = sm(F.fv, 2.2, 4.6)
    A.inv = sm(-F.upz, 0.0, 0.7)
    A.grind = sm(math.abs(F.ta), 6.0, 16.0) * sm(v, 3.0, 9.0)
    A.squeal = sm(math.abs(F.ta), 11.0, 23.0) * sm(v, 8.0, 15.0)
    A.creak = math.max(sm(math.abs(F.fl), 0.4, 1.1), sm(math.abs(F.roll), 0.5, 1.3)) * sm(v, 3.0, 9.0)
    A.u = v / 14.0
    A.under = under and 1.0 or 0.0
    return A
end

function M:events(tau, shotbus)
    local R = self.R
    while self.nextEv <= #R.events and R.events[self.nextEv][1] <= tau do
        local k = R.events[self.nextEv][2]
        if shotbus then
            if LAUNCH[k] then self.send({ a = 'shot', k = 'launch', v = 0.95, b = shotbus })
            elseif k == 'portal_out' or k == 'portal_in' then self.send({ a = 'shot', k = 'whoosh', v = 0.9, b = shotbus })
            elseif k == 'open' and self.stage == 'chain' then self.send({ a = 'shot', k = 'clunk', v = 0.85, b = shotbus })
            elseif BRAKE[k] then self.send({ a = 'shot', k = 'valve', v = k == 'brake' and 0.9 or 0.6, b = shotbus })
            elseif k == 'arrive' then self.send({ a = 'shot', k = 'lapbar', v = 0.8, b = shotbus })
            end
        end
        self.stage = k
        self.nextEv = self.nextEv + 1
    end
end

function M:triggers(tau, F, A, bus)
    local v = F.v
    if v > 7.0 and F.pz < -0.42 and self.pz >= -0.42 and tau - self.lastDrop > 3.0 then
        self.lastDrop = tau
        self.send({ a = 'shot', k = 'drop', v = r3(clamp(v / 22.0, 0.35, 1.0)), b = bus })
    end
    self.pz = F.pz
    if v > 6.0 and F.fv < 0.3 then
        self.airT = self.airT + (tau - (self.lastTick or tau))
    elseif self.airT > 0.0 and F.fv > 0.7 then
        if self.airT > 0.25 and tau - self.lastLand > 0.8 then
            self.lastLand = tau
            self.send({ a = 'shot', k = 'land', v = r3(clamp(0.4 + self.airT * 0.4, 0.4, 1.0)), b = bus })
        end
        self.airT = 0.0
    end
    if F.fv < 2.3 then self.lastLow = tau end
    if v > 8.0 and F.fv > 3.4 and tau - (self.lastLow or -10.0) < 0.9 and tau - self.lastThud > 2.0 then
        self.lastThud = tau
        self.send({ a = 'shot', k = 'thud', v = r3(clamp((F.fv - 2.8) / 2.5, 0.4, 1.0)), b = bus })
    end
    self.lastTick = tau
end

function M:rider(tau)
    local dt = tau - self.lastMix
    if self.lastMix >= 0 and dt < 0.08 then return end
    if self.lastMix < 0 then dt = 0.08 end
    self.lastMix = tau
    local R = self.R
    local F = self:features(tau, dt)
    local i = F.i
    local under = R.under[i] == 1
    local A = self:amounts(F, under)
    local stage = self.stage
    local v = F.v
    local u = A.u
    if not self.started and tau > 0.35 then
        self.started = true
        self.send({ a = 'shot', k = 'lapbar', v = 0.8, b = 'r' })
    end
    self:events(tau, 'r')
    stage = self.stage
    self:triggers(tau, F, A, 'r')
    local moving = tau > 0.2 and tau < R.duration
    local mov = moving and A.mov or 0.0
    local ub = 1.0 + 0.2 * A.under
    local inLaunch = LAUNCH[stage] and F.acc > 2.0
    local inPower = POWER[stage]
    local inChain = CHAIN[stage] and v < 6.5 and v > 0.4
    local brk = BRAKE[stage] and sm(-F.acc, 0.8, 4.0) or 0.0
    local side = F.ta > 0 and -1.0 or 1.0
    local gp = clamp(side * 0.38 * math.min(1.0, A.grind * 1.3), -0.4, 0.4)
    local l = {
        roar_lo = { 0.55 * mov * (0.45 + 0.55 * sm(v, 2.0, 18.0)) * A.duck * ub + 0.25 * A.comp * mov, clamp(0.62 + 0.38 * u, 0.65, 1.35), 0.0 },
        roar_mid = { 0.6 * sm(v, 2.0, 14.0) * mov * (1.0 + 0.45 * A.grind) * A.duck * (1.0 - 0.25 * A.inv) * ub, clamp(0.5 + 0.5 * u, 0.55, 1.6), 0.0 },
        roar_hi = { 0.42 * sm(v, 9.0, 26.0) * mov * (1.0 + 0.35 * A.grind + 0.4 * A.inv) * A.duck, clamp(0.6 + 0.4 * u, 0.6, 1.5), 0.0 },
        struct = { clamp(0.5 * sm(v, 2.0, 14.0) * mov * (0.6 + 0.4 * A.under) * (0.6 + 0.8 * A.comp), 0.0, 1.0), clamp(0.85 + 0.15 * u, 0.85, 1.2), 0.0 },
        wind_lo = { 0.62 * (sm(v, 5.0, 28.0) ^ 1.4) * mov * (under and 0.5 or 1.0), clamp(0.6 + 0.5 * u, 0.6, 1.7), 0.0 },
        wind_hi = { 0.5 * (sm(v, 11.0, 30.0) ^ 1.4) * mov * (under and 0.4 or 1.0), clamp(0.7 + 0.4 * u, 0.7, 1.6), 0.0 },
        rattle = { 0.55 * sm(v, 2.0, 13.0) * mov * A.duck * (1.0 + 0.8 * A.inv + 0.3 * A.grind), clamp(0.8 + 0.2 * u, 0.8, 1.3), 0.0 },
        grind = { 0.7 * (A.grind ^ 1.2) * mov * A.duck, clamp(0.65 + 0.5 * u, 0.7, 1.5), gp },
        squeal = { 0.42 * A.squeal * mov, clamp(0.8 + 0.5 * sm(math.abs(F.ta), 10.0, 28.0) + 0.2 * u, 0.8, 1.55), gp },
        creak = { 0.5 * A.creak * mov, 0.85 + 0.3 * sm(math.abs(F.fl), 0.2, 1.5), clamp(-side * 0.2 * A.creak, -0.3, 0.3) },
        boom = { 0.6 * A.comp * mov, 1.0, 0.0 },
        drive = { inPower and 0.55 or 0.0, 0.9 + v / 30.0, 0.0 },
        chain_motor = { inChain and 0.7 or 0.0, clamp(v / 4.5, 0.6, 1.6), 0.0 },
        whine = { inLaunch and 0.5 * sm(v, 1.0, 10.0) or 0.0, clamp(0.4 + v / 11.0, 0.5, 3.0), 0.0 },
        brake = { 0.8 * brk, 0.85 + 0.3 * sm(v, 2.0, 20.0), 0.0 },
    }
    for _, e in pairs(l) do e[1] = r3(e[1]); e[2] = r3(e[2]); e[3] = r3(e[3]) end
    local jg = mov * (0.4 + 0.6 * sm(v, 3.0, 12.0)) * A.duck * 0.75
    if v < 1.2 then jg = 0.0 end
    self.send({
        a = 'mix', b = 'r', l = l,
        rev = r3(under and self.rev or 0.05),
        lp = under and 8000 or 18000,
        mv = r3(v), ms = r3(self:dist(tau)),
        jg = r3(jg), ck = inChain and 0.7 or 0.0,
        js = self.jointGap, cs = 0.33,
    })
end

function M:watch(tau, cp, cr)
    local dt = tau - self.lastMix
    if self.lastMix >= 0 and dt < 0.08 then return end
    if self.lastMix < 0 then dt = 0.08 end
    self.lastMix = tau
    self.silent = false
    local R = self.R
    local b = 'x' .. tostring(self.id or 0)
    local p = self.pose(tau)
    local F = self:features(tau, dt)
    local i = F.i
    local under = R.under[i] == 1
    local A = self:amounts(F, under)
    local v = F.v
    local u = A.u
    self:events(tau, nil)
    local stage = self.stage
    local dx, dy, dz = p.x - cp.x, p.y - cp.y, p.z - cp.z
    local d = math.sqrt(dx * dx + dy * dy + dz * dz)
    local vr = 0.0
    if self.dprev then vr = (d - self.dprev) / dt end
    self.dprev = d
    self.vr = self.vr + (vr - self.vr) * (1.0 - math.exp(-dt / 0.2))
    local dop = clamp(343.0 / (343.0 + self.vr), 0.85, 1.18)
    local yaw = math.rad(cr.z)
    local hd = math.max(math.sqrt(dx * dx + dy * dy), 0.1)
    local pan = clamp((dx * math.cos(yaw) + dy * math.sin(yaw)) / hd, -0.9, 0.9)
    local fall = clamp(1.0 - d / 230.0, 0.0, 1.0)
    local f1, f2 = fall ^ 1.6, fall ^ 0.8
    local hid = under and 0.3 or 1.0
    local moving = tau > 0.2 and tau < R.duration
    local mov = moving and A.mov or 0.0
    local inLaunch = LAUNCH[stage] and F.acc > 2.0
    local inPower = POWER[stage]
    local inChain = CHAIN[stage] and v < 6.5 and v > 0.4
    local brk = BRAKE[stage] and sm(-F.acc, 0.8, 4.0) or 0.0
    local l = {
        roar_lo = { 0.5 * mov * sm(v, 1.0, 20.0) * f2 * hid * A.duck, clamp(0.62 + 0.38 * u, 0.65, 1.35) * dop, pan },
        roar_mid = { 0.55 * sm(v, 2.0, 14.0) * mov * f1 * hid * A.duck * (1.0 + 0.4 * A.grind), clamp(0.5 + 0.5 * u, 0.55, 1.6) * dop, pan },
        roar_hi = { 0.38 * sm(v, 9.0, 26.0) * mov * f1 * hid * A.duck, clamp(0.6 + 0.4 * u, 0.6, 1.5) * dop, pan },
        struct = { 0.25 * sm(v, 2.0, 14.0) * mov * f2 * hid, 1.0 * dop, pan },
        wind_hi = { 0.3 * (sm(v, 12.0, 30.0) ^ 1.3) * mov * f1 * hid, clamp(0.7 + 0.4 * u, 0.7, 1.6) * dop, pan },
        rattle = { 0.35 * sm(v, 2.0, 13.0) * mov * f1 * hid * A.duck, clamp(0.8 + 0.2 * u, 0.8, 1.3) * dop, pan },
        grind = { 0.7 * (A.grind ^ 1.2) * mov * f2 * hid * A.duck, clamp(0.65 + 0.5 * u, 0.7, 1.5) * dop, pan },
        squeal = { 0.6 * A.squeal * mov * (fall ^ 0.6) * (under and 0.5 or 1.0), clamp(0.8 + 0.5 * sm(math.abs(F.ta), 10.0, 28.0) + 0.2 * u, 0.8, 1.55) * dop, pan },
        drive = { inPower and 0.45 * f1 * hid or 0.0, (0.9 + v / 30.0) * dop, pan },
        chain_motor = { inChain and 0.55 * f1 * hid or 0.0, clamp(v / 4.5, 0.6, 1.6) * dop, pan },
        whine = { inLaunch and 0.5 * sm(v, 1.0, 10.0) * f2 * hid or 0.0, clamp(0.4 + v / 11.0, 0.5, 3.0) * dop, pan },
        brake = { 0.7 * brk * f2 * hid, (0.85 + 0.3 * sm(v, 2.0, 20.0)) * dop, pan },
    }
    for _, e in pairs(l) do e[1] = r3(e[1]); e[2] = r3(e[2]); e[3] = r3(e[3]) end
    local cut = 900.0 + 17000.0 * (fall ^ 2)
    if under then cut = math.min(cut, 500.0) end
    self.send({
        a = 'mix', b = b, l = l, lp = math.floor(cut), rev = 0.0,
        mv = r3(v), ms = r3(self:dist(tau)), mp = r3(pan),
        jg = (v > 1.2) and r3(0.75 * mov * (0.4 + 0.6 * sm(v, 3.0, 12.0)) * f1 * hid * A.duck) or 0.0,
        ck = inChain and r3(0.7 * f1 * hid) or 0.0,
        js = self.jointGap, cs = 0.33,
    })
end

function M:quiet(tau)
    self:events(tau, nil)
    local dt = tau - self.lastMix
    if self.lastMix >= 0 and dt < 0.08 then return end
    self.lastMix = tau
    self.dprev = nil
    if self.silent then return end
    self.silent = true
    local l = {}
    for _, k in ipairs(NAMES) do l[k] = { 0.0, 1.0, 0.0 } end
    self.send({ a = 'mix', b = 'x' .. tostring(self.id or 0), l = l, rev = 0.0, jg = 0.0, ck = 0.0, mv = 0.0, ms = 0.0, js = self.jointGap, cs = 0.33 })
end

function M:stop(bus)
    self.send({ a = 'stop', b = bus })
end

function M:prep()
    self.send({ a = 'prep' })
end
