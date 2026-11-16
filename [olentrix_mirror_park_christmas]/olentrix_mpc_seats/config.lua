Config = {}

Config.Reach = 1.25
Config.SitZ = 0.03
Config.Bench = 'PROP_HUMAN_SEAT_BENCH'
Config.Chair = 'PROP_HUMAN_SEAT_CHAIR_MP_PLAYER'
Config.Taken = 0.4

Config.Wheel = {
    hub = vector3(1407.0, -706.5, 86.82), r = 17.0, psi = 76.0, n = 18, period = 360.0,
    models = { 'xv_wheel_gond_r', 'xv_wheel_gond_g' },
    reach = 2.0,
    board = 1.5,
    pose = { dict = 'amb@prop_human_seat_chair@male@generic@base', clip = 'base' },
    poseZ = 0.0,
    exit = vector3(-1.5, 0.0, -1.65),
}

Config.Clear = {
    range = 150.0,
    popAreas = 8,
    seen = 35.0,
}
