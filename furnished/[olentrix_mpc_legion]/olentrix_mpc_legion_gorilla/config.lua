Config = {}

Config.Grate = {
    pos = vector3(258.981, -887.517, 28.0859),
    heading = 69.77,
    halfLong = 1.055,
    halfShort = 0.71,
    frameLong = 1.115,
    frameShort = 0.77,
}

Config.PromptDistance = 1.0
Config.SpawnDistance = 120.0
Config.DespawnDistance = 150.0
Config.HearDistance = 45.0
Config.WatchDistance = 90.0
Config.ServerReach = 4.0
Config.Cooldown = 60
Config.Volume = 0.95

Config.Lift = { knock = 2.5, open = 9.0 }

Config.Arm = { upper = 0.42, grip = 0.626, shoulder = vector3(0.40, 0.02, -0.30) }

Config.Kneel = {
    enter = { dict = 'amb@medic@standing@tendtodead@enter', clip = 'enter' },
    base = { dict = 'amb@medic@standing@tendtodead@base', clip = 'base' },
    out = 0.45,
}

Config.Models = {
    plate = 'lg_gor_plate',
    well = 'lg_gor_well',
    pit = 'lg_gor_pit',
    head = 'lg_gor_head',
    jaw = 'lg_gor_jaw',
    uarmL = 'lg_gor_uarml',
    uarmR = 'lg_gor_uarmr',
    farmL = 'lg_gor_farml',
    farmR = 'lg_gor_farmr',
}

Config.Pit = {
    origin = vector3(-3400.0, 7000.0, 1300.0),
    hatch = vector3(0.0, 1.2, 2.412),
    timecycle = 'lg_gor_pit',
}

Config.Text = {
    open = '[E] Open',
    wait = 'Come back in %d s',
    busy = 'Something is moving down there...',
    far = 'Get closer to the grate.',
    cooldown = 'The grate will not budge. Come back in %d s.',
}
