Config = {}

Config.Rink = {
    origin = vector3(1357.5, -776.1, 66.17),
    heading = 0.0,
    iceTop = 0.12,
}

Config.Start = {
    position = vector3(1361.38, -763.2, 66.17),
    reach = 1.5,
    labelRange = 12.0,
    labelHeight = 1.1,
    key = 38,
}

Config.Cooldown = 600
Config.Lead = 60
Config.ShowRange = 120.0

Config.Text = {
    label = 'Ice show',
    prompt = 'Press ~INPUT_CONTEXT~ to start the ice show',
    running = 'The ice show is on',
    soon = 'The ice show starts in %d s',
    cooldown = 'The next ice show can start in %d min',
    busy = 'An ice show is already on',
}

Config.Skaters = {
    her = {
        model = 'a_f_y_bevhills_04',
        components = { { 0, 0, 2 }, { 2, 0, 2 }, { 3, 0, 2 }, { 4, 0, 2 } },
    },
    him = {
        model = 's_m_y_waiter_01',
        components = { { 0, 0, 0 }, { 2, 0, 0 }, { 3, 0, 0 }, { 4, 0, 0 }, { 8, 1, 0 } },
    },
}
Config.StandHeight = 0.98

Config.Skates = {
    models = { { 'xv_skate_l', 14201 }, { 'xv_skate_r', 52301 } },
    lift = 0.05,
}

Config.Sound = {
    file = 'audio/show.ogg',
    near = 30.0,
    far = 65.0,
    volume = 0.85,
}

Config.Lights = {
    poles = {
        { pos = vector3(-7.5, 10.62, 6.0), follow = 'her' },
        { pos = vector3(7.5, -10.62, 6.0), follow = 'her' },
        { pos = vector3(7.5, 10.62, 6.0), follow = 'him' },
        { pos = vector3(-7.5, -10.62, 6.0), follow = 'him' },
    },
    colour = { 255, 236, 210 },
    finale = { { 230, 40, 50 }, { 40, 200, 80 }, { 255, 190, 60 } },
    distance = 40.0,
    brightness = 12.0,
    hardness = 0.0,
    radius = 9.0,
    falloff = 1.0,
    drawRange = 150.0,
}
