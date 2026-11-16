Spots = json.decode(LoadResourceFile(GetCurrentResourceName(), 'spots.json'))

Config = {}

Config.SpawnDistance = 90.0
Config.DespawnDistance = 110.0
Config.PromptDistance = 2.2
Config.ServerReach = 6.0
Config.ChoiceSeconds = 20
Config.Cooldown = 60
Config.Move = { min = 300, max = 600 }
Config.Volume = 0.8

Config.Keys = {
    talk = { control = 38, glyph = '[E]' },
    nice = { control = 38, glyph = '[E]' },
    naughty = { control = 47, glyph = '[G]' },
    block = { 38, 47, 51, 58, 140, 141, 142, 263, 264 },
}

Config.Elf = {
    model = 'mp_f_freemode_01',
    look = {
        face = 21,
        skin = 21,
        hair = 15,
        hairColour = 4,
        hairHighlight = 4,
        overlays = {},
    },
    outfit = {
        { slot = 11, name = 'DLC_MP_XMAS_F_JBIB1_1' },
        { slot = 3, drawable = 5 },
        { slot = 4, name = 'DLC_MP_XMAS_F_LEGS0_1' },
        { slot = 6, name = 'DLC_MP_XMAS_F_FEET0_0' },
        { slot = 8, drawable = 14 },
        { prop = 0, name = 'DLC_MP_XMAS_F_HAT1_0' },
    },
    idle = { dict = 'amb@world_human_stand_impatient@female@no_sign@base', clip = 'base' },
    mood = 'mood_happy_1',
}

Config.Treat = {
    model = 'xe_candycane',
    give = { dict = 'mp_common', clip = 'givetake1_a' },
    take = { dict = 'mp_common', clip = 'givetake1_b' },
    elfHand = { bone = 28422, offset = vector3(0.0, 0.0, 0.0), rotation = vector3(0.0, 0.0, 0.0) },
    playerHand = { bone = 28422, offset = vector3(0.0, 0.0, 0.0), rotation = vector3(0.0, 0.0, 0.0) },
    handOverMs = 1100,
    holdSeconds = 8,
    eatDelayMs = 1300,
    moveOff = 0.8,
    eat = {
        intro = { dict = 'mp_player_inteat@pnq', clip = 'intro' },
        loop = { dict = 'mp_player_inteat@pnq', clip = 'loop' },
        outro = { dict = 'mp_player_inteat@pnq', clip = 'outro' },
        introMs = 900,
        outroMs = 1200,
    },
}

Config.Knock = {
    dict = 'melee@unarmed@streamed_variations',
    elf = 'plyr_takedown_front_slap',
    victim = 'victim_takedown_front_slap',
    fadeAfterMs = 1500,
    fadeMs = 600,
    out = { dict = 'missarmenian2', clip = 'drunk_loop' },
    sound = 'bonk.ogg',
}

Config.Wake = {
    seconds = 9,
    timecycle = 'Drunk',
    shake = 'DRUNK_SHAKE',
    shakeAmount = 1.0,
    clipset = 'move_m@drunk@verydrunk',
    getUp = { dict = 'misscarsteal4@actor', clip = 'dazed_idle', ms = 3500 },
    sound = 'wake.ogg',
    fadeMs = 1500,
    front = { distances = { 1.75, 1.5, 2.0 }, angles = { 0, 20, -20, 40, -40 } },
}

Config.Text = {
    elfName = '~g~Elf~s~',
    talk = 'Talk to the elf',
    question = 'Have you been naughty or nice?',
    nice = 'Nice',
    naughty = 'Naughty',
    niceLine = "Nice! Here's a candy cane. Don't tell the reindeer.",
    naughtyLine = 'Naughty? Oh dear. Somebody wants a word with you...',
    thanks = 'Enjoy it! And stay on the nice list!',
    treatNotify = 'You got a candy cane from the elf.',
    cooldown = "I've already seen you! %s.",
    waitSeconds = 'Come back in %d s',
    waitMinutes = 'Come back in %d min',
    busy = 'One at a time, please!',
    busyPrompt = 'The elf is busy',
    far = 'Come a little closer!',
    expired = 'Too slow! Ask me again.',
}

Config.Scene = {
    origin = vector3(-3150.0, 7650.0, 900.0),
    timecycle = 'xe_lair',
    music = 'scene.ogg',
    loadSeconds = 5,
    footHeight = 0.04,
    footTolerance = 0.03,
    feetBones = { 14201, 52301, 2108, 20781 },
    length = 25.0,
    creature = { model = 'u_m_m_yeti', name = '~b~Grumbold~s~' },
    lights = {
        { pos = vector3(3.0, 0.6, 1.2), colour = { 255, 140, 60 }, range = 9.0, intensity = 6.0 },
        { pos = vector3(-1.5, 1.0, 3.6), colour = { 150, 190, 255 }, range = 10.0, intensity = 3.0 },
        { pos = vector3(0.0, 5.0, 3.0), colour = { 255, 200, 140 }, range = 7.0, intensity = 3.0 },
    },
    shots = {
        {
            at = 0.0,
            cam = { from = vector3(4.4, -3.3, 2.4), to = vector3(3.7, -2.7, 2.2), look = vector3(-0.6, 2.6, 0.9), fov = 50.0 },
            creature = { pos = vector4(0.0, 5.45, 0.50, 180.0), anim = { dict = 'amb@prop_human_seat_chair@male@generic@base', clip = 'base', flag = 1 } },
            victim = { pos = vector4(-1.7, -0.6, 1.0, 300.0), anim = { dict = 'missarmenian2', clip = 'drunk_loop', flag = 1 } },
            line = { at = 0.8, text = 'Hmph. The elf sent me ANOTHER one.', ms = 4400 },
        },
        {
            at = 5.5,
            cam = { from = vector3(1.1, 2.6, 1.5), to = vector3(0.8, 3.0, 1.45), look = vector3(0.0, 5.3, 1.35), fov = 42.0 },
            creature = { anim = { dict = 'gestures@m@standing@casual', clip = 'gesture_displeased', flag = 48 } },
            line = { at = 0.3, text = "Naughty, are we? Join the club. It's a very small club. It's just me.", ms = 5200 },
        },
        {
            at = 11.0,
            cam = { from = vector3(0.57, 0.40, 1.60), to = vector3(0.25, 0.32, 1.58), look = vector3(-1.66, -0.19, 1.45), fov = 45.0 },
            creature = { pos = vector4(-1.77, 0.22, 1.0, 194.7), anim = { dict = 'anim@mp_player_intupperface_palm', clip = 'idle_a', flag = 49 } },
            victim = { pos = vector4(-1.55, -0.6, 1.0, 14.7), anim = { dict = 'misscarsteal4@actor', clip = 'dazed_idle', flag = 1 } },
            line = { at = 0.4, text = '*sniff sniff* ...Peppermint. Cocoa. Joy. Ugh, you reek of Christmas.', ms = 5000 },
        },
        {
            at = 16.5,
            cam = { from = vector3(-0.35, -1.83, 1.75), to = vector3(-0.42, -1.60, 1.72), look = vector3(-1.89, 0.70, 1.50), fov = 46.0 },
            creature = { pos = vector4(-1.89, 0.70, 1.0, 193.7), anim = { dict = 'gestures@m@standing@casual', clip = 'gesture_point', flag = 48 } },
            line = { at = 0.3, text = "You're not even naughty enough to keep. Back down the mountain you go!", ms = 4300 },
        },
        {
            at = 21.0,
            cam = { from = vector3(1.02, 0.23, 1.35), to = vector3(0.84, 0.18, 1.32), look = vector3(-1.55, -1.01, 1.20), fov = 50.0 },
            takedown = { dict = 'melee@unarmed@streamed_variations', creature = 'plyr_takedown_front_backslap', victim = 'victim_takedown_front_backslap', origin = vector4(-2.165, -1.527, 0.0, 104.7), contact = 0.571 },
            line = { at = 0.05, text = 'And STAY nice!', ms = 2600 },
            fadeAt = 2.4,
        },
    },
}
