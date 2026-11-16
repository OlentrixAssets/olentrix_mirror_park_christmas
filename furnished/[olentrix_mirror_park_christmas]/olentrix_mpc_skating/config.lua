Config = {}

Config.Price = 50
Config.Item = 'xmas_skates'

Config.Rink = { centre = vector2(1357.5, -776.1), halfX = 15.0, halfY = 10.0, corner = 4.0, iceZ = 66.29 }
Config.Gate = { centre = vector2(1347.0, -765.85), halfWidth = 0.85 }
Config.Counter = { pos = vector3(1329.4, -766.35, 66.4), reach = 1.6 }
Config.ChangeSpots = {
    { centre = vector3(1343.95, -764.6, 66.3), half = vector2(1.95, 0.9), heading = 0.0 },
    { centre = vector3(1322.6, -766.0, 66.2), half = vector2(1.65, 1.0), heading = 73.6 },
}
Config.ShowExit = vector4(1343.9, -764.4, 66.3, 180.0)
Config.ChangeTime = 4000
Config.KeepRange = 200.0
Config.Kneel = { dict = 'amb@medic@standing@tendtodead@base', clip = 'base' }

Config.Skate = {
    cruise = 4.5,
    sprint = 7.0,
    push = 2.4,
    pushSprint = 3.2,
    stride = 0.77,
    glideDecel = 0.3,
    drag = 0.015,
    brake = 4.0,
    backSpeed = 0.9,
    turnSlow = 150.0,
    turnFast = 75.0,
    grip = 6.0,
    bodyRadius = 0.35,
    fallSpeed = 4.0,
    bumpSpeed = 3.0,
    fallTurnSpeed = 6.3,
    fallTurnTime = 1.0,
    wobbleTime = 600,
}

Config.Sound = { volume = 0.7, range = 30.0 }

Config.Text = {
    buy = 'Buy ice skates ($%d)',
    bought = 'You bought a pair of ice skates.',
    have = 'You already have a pair of ice skates.',
    money = "You don't have enough money for ice skates.",
    space = 'There is no room for ice skates in your pockets.',
    error = "Ice skates can't be bought right now.",
    putOn = 'Put on ice skates',
    takeOff = 'Take off ice skates',
    puttingOn = 'Putting on skates',
    takingOff = 'Taking off skates',
    need = 'You need ice skates - buy them at the Skate Hire counter.',
    tookOff = 'You took your ice skates off.',
    showSoon = 'The ice show starts in 1 minute - please leave the ice.',
    showOn = 'The ice show is on - the ice is closed until it ends.',
}
