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
    sit = { dict = 'amb@prop_human_seat_chair@female@legs_crossed@base', clip = 'base' },
    thighBone = 51826,
    kneeBone = 36864,
    otherThighBone = 58271,
    along = 0.5,
    raise = 0.1,
    shift = 0.0,
    turn = 20.0,
}

Config.Poses = {
    { label = 'Wave', dict = 'friends@frj@ig_1', clip = 'wave_a', flag = 49 },
    { label = 'Thumbs up', dict = 'anim@mp_player_intupperthumbs_up', clip = 'idle_a', flag = 49 },
    { label = 'Arms crossed', dict = 'amb@world_human_hang_out_street@female_arms_crossed@base', clip = 'base', flag = 1 },
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
    singers = {
        { model = 'a_m_m_prolhost_01', position = vector4(1409.08, -774.88, 66.17, 45.0) },
        { model = 'a_f_m_prolhost_01', position = vector4(1408.73, -775.53, 66.17, 78.0) },
        { model = 'u_f_o_prolhost_01', position = vector4(1408.79, -776.29, 66.17, 112.0) },
        { model = 'a_m_m_prolhost_01', position = vector4(1409.25, -776.86, 66.17, 145.0) },
    },
}

Config.Letters = {
    position = vector3(1312.8, -742.4, 66.17),
    promptDistance = 2.5,
    reach = 6.0,
    maxLength = 250,
    cooldown = 60,
    file = 'letters.json',
    command = 'santaletters',
    show = 20,
}
