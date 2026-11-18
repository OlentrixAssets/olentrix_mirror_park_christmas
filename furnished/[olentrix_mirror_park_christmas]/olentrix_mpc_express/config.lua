Config = {}
Config.Volume = 0.55

Config.Ride = {
    dwell = 30.0,
    speed = 3.2,
    accel = 8.0,
    range = 200.0,
    boardRange = 2.6,
    boardClose = 4.0,
    sit = { { dict = 'amb@prop_human_seat_chair@male@generic@base', anim = 'base' }, { dict = 'timetable@ron@ig_3_couch', anim = 'base' } },
    sitOffset = vector3(0.0, 0.01, -0.015),
    steam = { asset = 'core', fx = 'ent_amb_cluckb_steam', offset = vector3(0.0, -1.01, 1.52), scale = 0.4 },
    sound = { near = 6.0, far = 40.0, chuff = 0.45, bell = 0.6 },
}
