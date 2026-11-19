Config = {}

Config.Command = 'xmasintro'
Config.Length = 136.6
Config.Fov = 50.0
Config.SkipControl = 177

Config.Night = { hour = 22, minute = 0 }

Config.Lair = {
    origin = vector3(-3150.0, 7650.0, 900.0),
    timecycle = 'xe_lair',
    shot = 14,
    model = 'u_m_m_yeti',
    pos = vector4(0.0, 5.45, 0.50, 180.0),
    anim = { dict = 'amb@prop_human_seat_chair@male@generic@base', clip = 'base', flag = 1 },
}

Config.PreloadLead = 2.0
Config.PreloadFar = 120.0

Config.Legion = vector3(196.24, -933.36, 29.2)

Config.Car = { model = 'xv_cst_car', start = 29.5 }

Config.Shots = {
    { t0 = 0.0, t1 = 2.68, from = vector3(1575, -722, 130), to = vector3(1555, -724, 128), look = vector3(1370, -745, 68) },
    { t0 = 2.68, t1 = 5.18, from = vector3(1322.9, -692.9, 68.5), to = vector3(1364.6, -706.7, 68.5), ahead = 18.0, fov = 60.0 },
    { t0 = 5.18, t1 = 7.68, from = vector3(1397.6, -740.2, 68), to = vector3(1397.6, -740.2, 92), look = vector3(1490, -735, 80), look2 = vector3(1490, -735, 97) },
    { t0 = 7.68, t1 = 10.18, from = vector3(1389, -722, 67.5), to = vector3(1391, -724, 67.5), look = vector3(1407, -706.5, 66), look2 = vector3(1407, -706.5, 86.8), fov = 55.0 },
    { t0 = 10.18, t1 = 12.68, orbit = { c = vector2(1396.5, -777.0), r = 28.0, a0 = 90.0, a1 = 62.0, z0 = 70.0, z1 = 71.0, lookz = 72.7 } },
    { t0 = 12.68, t1 = 15.18, from = vector3(1398, -740, 68), to = vector3(1372, -740, 67.5), look = vector3(1340, -740, 68) },
    { t0 = 15.18, t1 = 17.68, from = vector3(1402, -768, 67.9), to = vector3(1404, -770, 67.9), look = vector3(1409, -775.8, 67.2), anchor = vector3(1405, -770, 66.17) },
    { t0 = 17.68, t1 = 20.18, from = vector3(1396, -750, 80), to = vector3(1392, -754, 82), look = vector3(1407, -706.5, 85), fov = 55.0 },
    { t0 = 20.18, t1 = 22.68, from = vector3(1415, -733, 69), to = vector3(1431, -740.6, 67.5), look = vector3(1454, -740.6, 66.5) },
    { t0 = 22.68, t1 = 25.18, tunnel = true, eye = 1.6, ahead = 10.0, ease = 0.3, fov = 65.0 },
    { t0 = 25.18, t1 = 27.68, from = vector3(1452, -740.6, 66.9), to = vector3(1436, -740.6, 67.2), look = vector3(1397, -740, 68) },
    { t0 = 27.68, t1 = 30.18, from = vector3(1509.0, -758.2, 64.9), to = vector3(1509.0, -758.2, 72.0), look = vector3(1535, -767.5, 66), fov = 60.0 },
    { t0 = 30.18, t1 = 32.68, from = vector3(1565, -700, 123), to = vector3(1566, -701, 123.5), car = true, preloadAt = 32.5 },
    { t0 = 32.68, t1 = 35.18, from = vector3(-3145.6, 7646.7, 902.4), to = vector3(-3146.3, 7647.3, 902.2), look = vector3(-3150.6, 7652.6, 900.9), fov = 50.0, anchor = vector3(-3150.0, 7650.0, 900.0), lead = 2, preloadAt = 35.15 },
    { t0 = 35.18, t1 = 37.68, from = vector3(1312.2, -739.2, 67.6), to = vector3(1313.5, -740.2, 67.5), look = vector3(1312.8, -742.6, 67.0) },
    { t0 = 37.68, t1 = 40.18, from = vector3(1420.96, -725.34, 67.7), to = vector3(1422.6, -725.9, 67.6), look = vector3(1424.63, -724.6, 67.47), anchor = vector3(1422.9, -725.7, 66.17), lead = 2 },
    { t0 = 40.18, t1 = 42.68, orbit = { c = vector2(1396.5, -777.0), r = 28.0, a0 = -5.0, a1 = 20.0, z0 = 70.0, z1 = 71.0, lookz = 72.7 } },
    { t0 = 42.68, t1 = 45.18, from = vector3(1370, -712, 92), to = vector3(1385, -722, 85), look = vector3(1385, -745, 66) },
    { t0 = 45.18, t1 = 47.68, from = vector3(1353.5, -705, 68), to = vector3(1353.5, -705, 80), look = vector3(1362, -716, 66) },
    { t0 = 47.68, t1 = 50.18, from = vector3(1555, -724, 128), to = vector3(1580, -722, 132), look = vector3(1370, -745, 68) },
    { t0 = 50.18, t1 = 52.68, from = vector3(1580, -722, 132), to = vector3(1588, -722, 134), look = vector3(1370, -745, 68) },
    { t0 = 52.68, t1 = 58.4, from = vector3(1262, -806, 92), to = vector3(1262, -818, 88), look = vector3(1262, -836, 76), ease = 0.3 },
    { t0 = 58.4, t1 = 64.0, from = vector3(1575, -722, 130), to = vector3(1560, -722, 134), look = vector3(1370, -745, 68), preloadAt = 63.9 },
    { t0 = 64.0, t1 = 68.92, from = vector3(262, -925, 46), to = vector3(250, -922, 40), look = vector3(196.2, -933.4, 37), ease = 0.4, anchorAt = 63.9 },
    { t0 = 68.92, t1 = 71.55, from = vector3(165, -940, 30.7), to = vector3(182, -936.5, 30.7), look = vector3(212, -931, 29.6), fov = 60.0 },
    { t0 = 71.55, t1 = 74.1, from = vector3(236.2, -951.4, 29.5), to = vector3(246.7, -922.8, 29.5), ahead = 16.0, fov = 60.0 },
    { t0 = 74.1, t1 = 76.6, from = vector3(193, -884, 31.2), to = vector3(191, -882, 31.0), look = vector3(184, -869, 29.7) },
    { t0 = 76.6, t1 = 80.6, from = vector3(190.4, -877, 33), to = vector3(192, -893, 32.5), look = vector3(196.2, -933.4, 36), ease = 0.3 },
    { t0 = 80.6, t1 = 84.88, from = vector3(170, -966, 31.2), to = vector3(201, -966, 31.2), look = vector3(172, -978, 30.8), look2 = vector3(203, -978, 30.8) },
    { t0 = 84.88, t1 = 88.5, from = vector3(190.4, -896, 31.2), to = vector3(189, -893, 31.0), look = vector3(181, -889, 30.6), fov = 55.0 },
    { t0 = 88.5, t1 = 90.68, from = vector3(256.0, -886.4, 29.6), to = vector3(256.3, -886.5, 29.9), look = vector3(258.98, -887.52, 28.0) },
    { t0 = 90.68, t1 = 93.37, orbit = { c = vector2(196.24, -933.36), r = 17.0, a0 = 20.0, a1 = 70.0, z0 = 31.2, z1 = 33.0, lookz = 38.0 } },
    { t0 = 93.37, t1 = 95.3, from = vector3(199, -944, 31.2), to = vector3(198, -941, 34), look = vector3(197, -933.4, 40) },
    { t0 = 95.3, t1 = 99.27, from = vector3(222, -868, 35), to = vector3(216, -866, 36), look = vector3(211.2, -885.8, 29.8), ease = 0.3 },
    { t0 = 99.27, t1 = 101.8, from = vector3(159.65, -901.25, 30.6), to = vector3(149.25, -929.75, 30.6), ahead = 15.0, fov = 60.0 },
    { t0 = 101.8, t1 = 103.36, from = vector3(170, -905, 33), to = vector3(172, -908, 33), look = vector3(205, -930, 30) },
    { t0 = 103.36, t1 = 107.47, from = vector3(193, -916, 30.8), to = vector3(196.5, -920, 30.5), look = vector3(199.47, -924.64, 29.9) },
    { t0 = 107.47, t1 = 110.2, from = vector3(242.9, -878.7, 30.9), to = vector3(244.5, -880.2, 30.7), look = vector3(245.3, -872.1, 29.8), look2 = vector3(245.3, -872.1, 30.6) },
    { t0 = 110.2, t1 = 115.93, from = vector3(244.5, -880.2, 30.7), to = vector3(236, -896, 37), look = vector3(245.3, -872.1, 30.3), ease = 0.3 },
    { t0 = 115.93, t1 = 117.7, from = vector3(205.5, -990, 31.5), to = vector3(204, -980, 33), look = vector3(196, -933, 36) },
    { t0 = 117.7, t1 = 119.69, from = vector3(239.4, -925.1, 29.9), to = vector3(240.3, -925.4, 29.7), look = vector3(242.18, -926.17, 28.5) },
    { t0 = 119.69, t1 = 122.9, orbit = { c = vector2(196.24, -933.36), r = 24.0, a0 = 200.0, a1 = 255.0, z0 = 34.0, z1 = 33.0, lookz = 38.0 } },
    { t0 = 122.9, t1 = 128.8, from = vector3(232, -905, 38), to = vector3(292, -858, 110), look = vector3(196, -933, 32), ease = 0.4 },
    { t0 = 128.8, t1 = 131.5, from = vector3(169, -884, 31.6), to = vector3(170, -883, 31.8), look = vector3(180, -890.3, 30.3), fov = 55.0 },
    { t0 = 131.5, t1 = 133.3, from = vector3(186, -880, 31.0), to = vector3(183.8, -883.6, 30.8), look = vector3(180, -890.5, 30.2) },
    { t0 = 133.3, t1 = 136.6, from = vector3(180, -909, 32.0), to = vector3(180, -907, 31.6), look = vector3(173.8, -900, 27.5) },
}

Config.Fades = {
    { t = 32.2, out = 250 },
    { t = 33.05, inn = 300 },
    { t = 34.9, out = 250 },
    { t = 35.5, inn = 300 },
    { t = 56.7, out = 400 },
    { t = 58.4, inn = 300 },
    { t = 63.5, out = 400 },
    { t = 65.3, inn = 400 },
    { t = 134.9, out = 500 },
}
Config.Text = {
    inVehicle = 'Get out of your vehicle first.',
    busy = 'The intro is already running.',
}
