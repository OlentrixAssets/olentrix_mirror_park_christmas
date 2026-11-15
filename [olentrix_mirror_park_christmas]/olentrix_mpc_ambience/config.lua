Config = {}

Config.Volume = 0.6
Config.SiteCentre = vector3(1372.0, -735.0, 66.2)

Config.Workshop = { pos = vector3(1311.6, -687.5, 66.17), heading = 90.0 }
Config.Train = {
    track = { cx = -0.4636, cy = -1.7154, a = 0.1682, r = 0.6021, z = 0.9255 },
    cars = { { model = 'xv_wtrain_l', gap = 0.0 }, { model = 'xv_wtrain_t', gap = 0.054 }, { model = 'xv_wtrain_c', gap = 0.054 }, { model = 'xv_wtrain_c', gap = 0.0675 } },
    speed = 0.07,
    range = 45.0,
}

Config.Effects = {
    { name = 'steam', asset = 'core', fx = 'ent_amb_cluckb_steam', pos = vector3(1389.64, -720.68, 67.64), scale = 0.55, range = 60.0 },
    { name = 'fire', asset = 'core', fx = 'ent_amb_beach_campfire', pos = vector3(1297.32, -757.76, 66.47), scale = 1.1, range = 70.0,
      light = { offset = vector3(0.18, 0.26, 0.55), colour = { 255, 140, 60 }, range = 7.0, intensity = 2.6 } },
    { name = 'firebase', asset = 'core', fx = 'ent_amb_barrel_fire', pos = vector3(1297.5, -757.5, 66.45), scale = 1.0, range = 50.0 },
    { name = 'globesnow1', asset = 'core', fx = 'env_snow_flakes', pos = vector3(1535.0, -767.5, 80.0), scale = 3.0, range = 50.0 },
    { name = 'globesnow2', asset = 'core', fx = 'env_snow_flakes', pos = vector3(1547.0, -767.5, 78.0), scale = 3.0, range = 50.0 },
    { name = 'globesnow3', asset = 'core', fx = 'env_snow_flakes', pos = vector3(1523.0, -767.5, 78.0), scale = 3.0, range = 50.0 },
    { name = 'globesnow4', asset = 'core', fx = 'env_snow_flakes', pos = vector3(1535.0, -755.5, 78.0), scale = 3.0, range = 50.0 },
    { name = 'globesnow5', asset = 'core', fx = 'env_snow_flakes', pos = vector3(1535.0, -779.5, 78.0), scale = 3.0, range = 50.0 },
}

Config.Sounds = {
    music = { file = 'music.ogg', pos = vector3(1357.74, -706.32, 67.5), near = 9.0, far = 38.0, gain = 0.55,
              playlist = { 'music.ogg', 'carol_jingle_bells.ogg', 'carol_silent_night.ogg', 'carol_we_wish_you.ogg', 'carol_deck_the_halls.ogg' } },
    bells = { file = 'bells.ogg', pos = vector3(1397.6, -740.2, 69.0), near = 5.0, far = 24.0, gain = 0.45 },
    fire  = { file = 'fire.ogg',  pos = vector3(1297.5, -757.5, 66.6), near = 2.5, far = 16.0, gain = 0.8 },
}

Config.Ceremony = {
    Duration = 56.0,
    Command = 'xmasceremony',
    GameHours = { 18, 20, 22 },
    RealTimes = { '19:00', '21:00' },
    CooldownMinutes = 20,
    PlayersNear = 220.0,
    Sound = { file = 'ceremony.ogg', near = 75.0, far = 170.0, gain = 0.8, duck = 0.3 },
    DrawRange = 260.0,
    Gate = { star = vector3(1397.6, -740.2, 72.05), piers = { vector3(1397.6, -742.98, 68.2), vector3(1397.6, -737.42, 68.2) } },
    Routes = {
        { points = { vector2(1397.6, -740.2), vector2(1409.0, -740.2), vector2(1419.5, -740.2), vector2(1419.5, -736.5), vector2(1418.6, -728.5),
                     vector2(1414.0, -722.0), vector2(1407.5, -718.6), vector2(1404.5, -716.0) },
          marks = { { s = 16.0, pos = vector3(1413.6, -740.2, 70.4) }, { s = 29.1, pos = vector3(1419.2, -733.0, 70.6) }, { s = 37.3, pos = vector3(1414.18, -727.19, 69.57) } } },
        { points = { vector2(1397.6, -740.2), vector2(1409.0, -740.2), vector2(1419.5, -740.2), vector2(1419.5, -744.0), vector2(1418.0, -752.0),
                     vector2(1412.0, -760.5), vector2(1404.5, -766.0), vector2(1404.8, -770.2) },
          marks = { { s = 16.0, pos = vector3(1413.6, -740.2, 70.4) }, { s = 29.3, pos = vector3(1419.1, -747.6, 70.6) }, { s = 39.6, pos = vector3(1416.99, -758.37, 69.57) } } },
    },
    Tree = { base = vector3(1396.5, -777.0, 66.17), z0 = 0.7, h = 12.6, r = 4.1, layers = 6, perLayer = 3, star = vector3(1396.5, -777.0, 79.77) },
    Wheel = { hub = vector3(1407.0, -706.5, 86.82), r = 17.0, psi = 76.0, n = 18, period = 360.0 },
}

Config.Passage = {
    cutting = { x0 = 1431.6, x1 = 1454.5, y = -740.6, half = 1.7, z0 = 65.6, z1 = 69.8 },
    route = {
        vector3(1454.50, -740.60, 66.17), vector3(1456.50, -740.60, 66.07), vector3(1458.50, -740.70, 65.97), vector3(1460.47, -741.00, 65.86),
        vector3(1462.41, -741.49, 65.76), vector3(1464.30, -742.15, 65.66), vector3(1466.18, -742.82, 65.56), vector3(1468.06, -743.50, 65.45),
        vector3(1469.95, -744.17, 65.35), vector3(1471.83, -744.85, 65.25), vector3(1473.71, -745.52, 65.15), vector3(1475.60, -746.20, 65.04),
        vector3(1477.48, -746.88, 64.94), vector3(1479.36, -747.55, 64.84), vector3(1481.24, -748.23, 64.74), vector3(1483.13, -748.90, 64.63),
        vector3(1485.01, -749.58, 64.53), vector3(1486.89, -750.25, 64.43), vector3(1488.77, -750.93, 64.33), vector3(1490.66, -751.60, 64.22),
        vector3(1492.54, -752.28, 64.12), vector3(1494.42, -752.95, 64.02), vector3(1496.30, -753.63, 63.92), vector3(1498.19, -754.30, 63.81),
        vector3(1500.07, -754.98, 63.71), vector3(1501.95, -755.65, 63.61), vector3(1503.83, -756.33, 63.51), vector3(1505.72, -757.00, 63.40),
        vector3(1507.60, -757.68, 63.30), vector3(1509.01, -758.18, 63.22),
    },
    half = 1.7, up = 3.6,
    globe = { centre = vector3(1535.00, -767.50, 71.50), radius = 27.7, floor = 60.30 },
    modPassage = 'xv_passage', modGlobe = 'xv_globe', fade = 1.5,
    globeWeather = 'XMAS', globeSnowLevel = 0.8,
    muteScene = 'FBI_HEIST_H5_MUTE_AMBIENCE_SCENE',
}

Config.ZoneSounds = {
    passage_box = { file = 'passage_box.ogg', zone = 'passage', gain = 0.55 },
    page_snow = { file = 'page_snow.ogg', zone = 'passage', pos = vector3(1463.34, -743.34, 66.90), near = 1.6, far = 7.5, gain = 0.50 },
    page_sleigh = { file = 'page_sleigh.ogg', zone = 'passage', pos = vector3(1475.61, -744.68, 66.29), near = 1.6, far = 7.5, gain = 0.50 },
    page_bells = { file = 'page_bells.ogg', zone = 'passage', pos = vector3(1485.93, -751.44, 65.67), near = 1.6, far = 7.5, gain = 0.50 },
    page_fire = { file = 'fire.ogg', zone = 'passage', pos = vector3(1498.20, -752.78, 65.06), near = 1.6, far = 7.5, gain = 0.35 },
    globe_music = { file = 'globe_music.ogg', zone = 'globe', gain = 0.7 },
    toytrain = { file = 'toytrain.ogg', zone = 'globe', pos = vector3(1535.00, -767.50, 60.90), near = 7.0, far = 18.0, gain = 0.45 },
}

Config.GlobeTrain = {
    centre = vector3(1535.00, -767.50, 60.428), heading = -19.73, a = 6.5, b = 5.4, speed = 1.3, range = 45.0,
    cars = { { model = 'xv_globe_trainloco', gap = 0.0 }, { model = 'xv_globe_traincar', gap = 1.18 }, { model = 'xv_globe_traincar', gap = 1.0 }, { model = 'xv_globe_traincar', gap = 1.0 } },
}

Config.GlobeEffects = {
    { name = 'gsmoke1', asset = 'core', fx = 'ent_amb_smoke_general', pos = vector3(1553.58, -769.03, 65.93), scale = 0.3, range = 45.0 },
    { name = 'gsmoke2', asset = 'core', fx = 'ent_amb_smoke_general', pos = vector3(1550.94, -757.84, 67.16), scale = 0.3, range = 45.0 },
    { name = 'gsmoke3', asset = 'core', fx = 'ent_amb_smoke_general', pos = vector3(1542.29, -750.33, 65.98), scale = 0.3, range = 45.0 },
    { name = 'gsmoke4', asset = 'core', fx = 'ent_amb_smoke_general', pos = vector3(1530.72, -749.39, 65.77), scale = 0.3, range = 45.0 },
    { name = 'gsmoke5', asset = 'core', fx = 'ent_amb_smoke_general', pos = vector3(1519.15, -777.21, 66.97), scale = 0.3, range = 45.0 },
    { name = 'gsmoke6', asset = 'core', fx = 'ent_amb_smoke_general', pos = vector3(1527.63, -784.62, 66.07), scale = 0.3, range = 45.0 },
    { name = 'gsmoke7', asset = 'core', fx = 'ent_amb_smoke_general', pos = vector3(1539.23, -785.59, 65.69), scale = 0.3, range = 45.0 },
    { name = 'gsmoke8', asset = 'core', fx = 'ent_amb_smoke_general', pos = vector3(1549.08, -779.64, 67.42), scale = 0.3, range = 45.0 },
    { name = 'gcandle1', asset = 'core', fx = 'ent_amb_candle_flame', pos = vector3(1551.49, -766.84, 62.00), scale = 1.0, range = 40.0 },
    { name = 'gcandle2', asset = 'core', fx = 'ent_amb_candle_flame', pos = vector3(1539.34, -751.60, 61.87), scale = 1.0, range = 40.0 },
    { name = 'gcandle3', asset = 'core', fx = 'ent_amb_candle_flame', pos = vector3(1521.91, -777.74, 62.02), scale = 1.0, range = 40.0 },
    { name = 'gcandle4', asset = 'core', fx = 'ent_amb_candle_flame', pos = vector3(1540.82, -783.11, 61.79), scale = 1.0, range = 40.0 },
}
for _, e in ipairs(Config.GlobeEffects) do Config.Effects[#Config.Effects + 1] = e end
