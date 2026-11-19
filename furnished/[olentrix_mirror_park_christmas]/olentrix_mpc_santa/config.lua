Spots = json.decode(LoadResourceFile(GetCurrentResourceName(), 'grotto_spots.json'))

Config = {}

Config.SpawnDistance = 80.0
Config.DespawnDistance = 100.0
Config.PromptDistance = 2.5
Config.ServerReach = 8.0

Config.Santa = {
    model = 'mp_m_freemode_01',
    sit = { dict = 'amb@prop_human_seat_chair@male@generic@base', clip = 'base' },
    seatOffset = vector3(0.0, 0.0, 0.0),
    lookDistance = 8.0,
    mood = 'mood_happy_1',
    look = {
        face = 4,
        skin = 4,
        hair = 0,
        hairColour = 29,
        hairHighlight = 29,
        overlays = {},
    },
    outfit = {
        { slot = 1, name = 'DLC_MP_XMAS_M_BERD0_0' },
        { slot = 11, name = 'DLC_MP_XMAS_M_JBIB1_0' },
        { slot = 4, name = 'DLC_MP_XMAS_M_LEGS0_0' },
        { slot = 6, name = 'DLC_MP_XMAS3_M_FEET_0_0' },
        { slot = 3, name = 'DLC_MP_HEIST_M_TORSO_31_0', fallback = 14 },
        { slot = 8, drawable = 15 },
    },
}

Config.Lap = {
    sit = { dict = 'amb@prop_human_seat_chair@male@generic@base', clip = 'base' },
    thighBone = 51826,
    kneeBone = 36864,
    otherThighBone = 58271,
    along = 0.85,
    raise = -0.25,
    shift = 0.1,
    turn = 40.0,
}

Config.Poses = {
    { label = 'Wave', dict = 'friends@frj@ig_1', clip = 'wave_a', flag = 49 },
    { label = 'Thumbs up', dict = 'anim@mp_player_intupperthumbs_up', clip = 'idle_a', flag = 49 },
    { label = 'Arms crossed', dict = 'amb@world_human_hang_out_street@female_arms_crossed@base', clip = 'base', flag = 1 },
}

Config.LapPoses = {
    { label = 'Wave', dict = 'anim@mp_player_intupperwave', clip = 'idle_a', flag = 49 },
    { label = 'Thumbs up', dict = 'anim@mp_player_intupperthumbs_up', clip = 'idle_a', flag = 49 },
    { label = 'Point at the camera', dict = 'gestures@m@standing@casual', clip = 'gesture_point', flag = 49 },
    { label = 'Arms up, yay!', dict = 'anim@mp_player_intupperraise_the_roof', clip = 'idle_a', flag = 49 },
    { label = 'Whisper to Santa', dict = 'anim@mp_player_intuppershush', clip = 'idle_a', flag = 49 },
}

Config.Flow = {
    subtitleMs = 4500,
    elfLead = 1.5,
    gotItMs = 6000,
    goodbyeDelay = 2.0,
    cardSeconds = 8.0,
    turnWindow = 20,
    queueReach = 20.0,
    idleSeconds = 90,
    warnSeconds = 15,
    chime = { name = 'CHECKPOINT_PERFECT', set = 'HUD_MINI_GAME_SOUNDSET' },
    keys = {
        pose = { control = 38, glyph = '[E]' },
        photo = { control = 47, glyph = '[G]' },
        wish = { control = 74, glyph = '[H]' },
        leave = { control = 202, glyph = '[Backspace]' },
    },
    block = { 38, 46, 51, 47, 58, 74, 177, 194, 202 },
}

Config.Text = {
    santaName = '~r~Santa~s~',
    elfName = '~g~Elf~s~',
    prompt = 'Photos with Santa',
    menuTitle = 'Photos with Santa',
    menuHint = 'Arrows: move    E: pick    Backspace: close',
    spots = {
        lap = { label = "Sit on Santa's lap", desc = 'The classic photo.' },
        left = { label = 'Stand beside Santa (left)', desc = 'Strike a pose next to him.' },
        right = { label = 'Stand beside Santa (right)', desc = 'Strike a pose next to him.' },
    },
    taken = ' (taken)',
    takenDesc = 'Someone is there. Pick it to join the line.',
    notNow = 'Maybe later',
    posesTitle = 'Strike a pose',
    noPose = 'Just smile',
    panelTitle = "Santa's grotto",
    stepPose = 'Pick a pose',
    stepPhoto = 'Smile for the photo',
    stepLeave = 'Hop off',
    again = 'Another one?',
    newPose = 'New pose',
    allDone = 'All done',
    wish = 'Whisper your wish to Santa',
    done = 'Done',
    welcome = 'Ho ho ho! Have you been good this year?',
    elfSqueeze = 'Everybody squeeze in... say Merry Christmas!',
    gotIt = "Got it! Take your screenshot now if you didn't (F12 on Steam).",
    photoWait = 'One moment, the camera is still winding on!',
    wishThanks = "I'll see what the elves can do!",
    wishWait = 'Ho ho, one wish at a time! Ask me again in a minute.',
    goodbye = 'Merry Christmas! Off you go now.',
    nextVisitor = 'Time to let the next visitor up. Merry Christmas!',
    fairUse = 'Santa needs to see the next visitor in %d s...',
    cardTitle = "Thanks for visiting Santa's grotto!",
    cardBody = 'Post a letter at the Letters to Santa box by the market, or catch the Christmas Express.',
    queueNext = "Santa has a visitor. You're next in line.",
    queuePlace = "Santa has a visitor. You're number %d in line.",
    lineNext = "You're next in line",
    linePlace = "You're number %d in line",
    leaveLine = 'Leave the line',
    yourTurn = 'Your turn!',
    turnSeconds = ' %d s',
    missedTurn = 'You missed your turn. Hop back in line any time!',
    denied = 'Come a little closer to the grotto first.',
    letterTitle = 'Dear Santa...',
    letterPrompt = '[E] Write a letter to Santa',
    letterPosted = 'Your letter is on its way to the North Pole.',
    letterWait = 'Santa is still reading your last letter. Try again in a minute.',
    lettersPrinted = 'Letters to Santa printed to your F8 console.',
}

Config.Photo = {
    countdown = 3,
    hideSeconds = 4.0,
    cooldown = 8,
    reach = 40.0,
}

Config.Elf = {
    model = 'mp_f_freemode_01',
    look = {
        face = 25,
        skin = 25,
        hair = 4,
        hairColour = 18,
        hairHighlight = 18,
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
    pose = { dict = 'amb@world_human_paparazzi@male@base', clip = 'base' },
    camera = { model = 'prop_pap_camera_01', bone = 28422, offset = vector3(0.0, 0.0, 0.0), rotation = vector3(0.0, 0.0, 0.0) },
}

Config.Carollers = {
    centre = vector3(1410.0, -775.8, 66.17),
    pose = { dict = 'cellphone@', clip = 'cellphone_text_read_base' },
    book = { model = 'prop_novel_01', bone = 6286, offset = vector3(0.15, 0.03, -0.065), rotation = vector3(0.0, 180.0, 90.0) },
    face = 'mood_talking_1',
    chatter = { dict = 'mp_facial', clip = 'mic_chatter', every = { 1.5, 3.5 } },
    look = { every = { 2.5, 6.0 }, ahead = 5.0, height = 1.6, playerReach = 10.0 },
    singers = {
        { model = 'a_m_m_prolhost_01', position = vector4(1409.08, -774.88, 66.17, 45.0) },
        { model = 'a_f_m_prolhost_01', position = vector4(1408.73, -775.53, 66.17, 78.0) },
        { model = 'u_f_o_prolhost_01', position = vector4(1408.79, -776.29, 66.17, 112.0) },
        { model = 'a_m_m_prolhost_01', position = vector4(1409.25, -776.86, 66.17, 145.0) },
    },
}

Config.Letters = {
    position = vector3(1312.8, -742.4, 66.17),
    spots = {
        vector3(164.92, -976.53, 29.2),
    },
    promptDistance = 2.5,
    reach = 6.0,
    maxLength = 250,
    cooldown = 60,
    file = 'letters.json',
    command = 'santaletters',
    show = 20,
}
