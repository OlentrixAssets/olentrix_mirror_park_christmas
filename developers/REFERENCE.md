# Mirror Park Christmas: developer reference (v1.2.0)

Built from the files in this download. Every resource name below is the folder name you `ensure`.

Start order matters only where a resource lists a dependency; FiveM starts those first. The server folder is set up so that one `ensure [olentrix_mirror_park_christmas]` line starts the core in a working order.

## Resources

| Resource | Part | Dependencies | What it does |
|-|-|-|-|
| `olentrix_mpc_mold` | core | - | Ground |
| `olentrix_mpc_ground` | core | - | Court and road |
| `olentrix_mpc_market` | core | - | Market |
| `olentrix_mpc_ambience` | core | `olentrix_mpc_market` | Ambience and light ceremony |
| `olentrix_mpc_express` | core | `olentrix_mpc_market` | Christmas Express |
| `olentrix_mpc_coaster` | core | `olentrix_mpc_market` | The Sleigh Run coaster |
| `olentrix_mpc_santa` | core | `olentrix_mpc_market` | The grotto, carol singers and letters to Santa |
| `olentrix_mpc_seats` | core | - | Sit on every seat, ride the Ferris wheel, no ambient peds or traffic in the market |
| `olentrix_mpc_skatekit` | core | - | Ice skates and skating animations |
| `olentrix_mpc_skating` | core | `olentrix_mpc_skatekit` | Buy ice skates and skate on the rink |
| `olentrix_mpc_iceshow` | core | `olentrix_mpc_skatekit` | An ice skating show on the rink, started by any player |
| `olentrix_mpc_elf` | core | - | The naughty or nice elf |
| `olentrix_mpc_houses` | add-on | - | Houses, streets, bridges and city squares dressed for Christmas |
| `olentrix_mpc_houses_snow` | add-on | `olentrix_mpc_houses` | Snow on the house dressing, for snowy servers |
| `olentrix_mpc_trees` | add-on | - | Christmas bulbs in the game trees and palms, every copy on the map |
| `olentrix_mpc_streets` | add-on | - | Street lights, signals, shelters and street props dressed for Christmas, map-wide |

## `olentrix_mpc_mold`

Ground.

**Settings:** none (a map resource; it only streams models and map files).

**Streamed files:** 1 .ydr, 1 .ymap, 1 .ytyp

Map files: `olentrix_mpc_mold.ymap`

## `olentrix_mpc_ground`

Court and road.

**Settings:** none (a map resource; it only streams models and map files).

**Streamed files:** 5 .ybn, 7 .ydr, 26 .ymap

Map files: `ch3_06_critical_0.ymap`, `ch3_06_grass_0.ymap`, `ch3_06_long_0.ymap`, `ch3_06_long_1.ymap`, `ch3_06_long_2.ymap`, `ch3_06_strm_0.ymap`, `hei_ch3_06_critical_0.ymap`, `hei_ch3_06_long_0.ymap`, `hei_ch3_06_long_1.ymap`, `hei_ch3_06_long_2.ymap`, `hei_ch3_06_strm_0.ymap`, `hei_id2_21_e_strm_0.ymap`, `hei_id2_21_g.ymap`, `hei_id2_21_g_long_0.ymap`, `hei_id2_21_g_strm_0.ymap`, `hei_id2_rdb.ymap`, `hei_id2_rdb_long_0.ymap`, `hei_id2_rdb_strm_2.ymap`, `id2_21_e_strm_0.ymap`, `id2_21_g.ymap`, `id2_21_g_long_0.ymap`, `id2_21_g_night.ymap`, `id2_21_g_strm_0.ymap`, `id2_rdb.ymap`, `id2_rdb_long_0.ymap`, `id2_rdb_strm_2.ymap`

## `olentrix_mpc_market`

Market.

**Settings:** none (a map resource; it only streams models and map files).

**Streamed files:** 8 .ycd, 210 .ydr, 4 .ymap, 5 .ytd, 210 .ytyp

Map files: `ch1_far_occl_00.ymap`, `ch3_occl_01.ymap`, `hei_ch3_occl_01.ymap`, `olentrix_mpc_market.ymap`

**Exports provided:** `gondolas`

## `olentrix_mpc_ambience`

Ambience and light ceremony.

**Settings:** `config.lua`. Top-level options:

- `Config.Volume` = `0.6`
- `Config.SiteCentre` = `vector3(1372.0, -735.0, 66.2)`
- `Config.Workshop`
- `Config.Train`
- `Config.Effects`
- `Config.Sounds`
- `Config.Ceremony`
- `Config.Passage`
- `Config.ZoneSounds`
- `Config.GlobeTrain`
- `Config.GlobeEffects`
- `Config.Fireflies`

**Network events:** `olentrix_mpc_ambience:ceremony`, `olentrix_mpc_ambience:sync`

**GlobalState keys:** `kora_weathersync`, `currentTime`

## `olentrix_mpc_express`

Christmas Express.

**Settings:** `config.lua`. Top-level options:

- `Config.Volume` = `0.55`
- `Config.Ride`

**Streamed files:** 1 .ycd, 19 .ydr, 1 .ymap, 19 .ytyp

Map files: `olentrix_mpc_express.ymap`

**Network events:** `olentrix_mpc_express:seat`, `olentrix_mpc_express:board`, `olentrix_mpc_express:leave`

## `olentrix_mpc_coaster`

The Sleigh Run coaster.

**Settings:** none (a map resource; it only streams models and map files).

**Streamed files:** 1 .ydr, 1 .ytyp

**Network events:** `olentrix_mpc_coaster:go`, `olentrix_mpc_coaster:wait`, `olentrix_mpc_coaster:ask`, `olentrix_mpc_coaster:done`

## `olentrix_mpc_santa`

The grotto, carol singers and letters to Santa.

**Settings:** `config.lua`. Top-level options:

- `Config.SpawnDistance` = `80.0`
- `Config.DespawnDistance` = `100.0`
- `Config.PromptDistance` = `2.5`
- `Config.ServerReach` = `8.0`
- `Config.Santa`
- `Config.Lap`
- `Config.Poses`
- `Config.LapPoses`
- `Config.Flow`
- `Config.Text`
- `Config.Photo`
- `Config.Elf`
- `Config.Carollers`
- `Config.Letters`

**Network events:** `olentrix_mpc_santa:granted`, `olentrix_mpc_santa:denied`, `olentrix_mpc_santa:queued`, `olentrix_mpc_santa:turn`, `olentrix_mpc_santa:missed`, `olentrix_mpc_santa:photoWait`, `olentrix_mpc_santa:wished`, `olentrix_mpc_santa:photo`, `olentrix_mpc_santa:posted`, `olentrix_mpc_santa:letters`, `olentrix_mpc_santa:take`, `olentrix_mpc_santa:leave`, `olentrix_mpc_santa:unqueue`, `olentrix_mpc_santa:letter`, `olentrix_mpc_santa:wish`

**GlobalState keys:** `xmasSanta`, `xmasSantaLine`, `xmasSantaSpots`

## `olentrix_mpc_seats`

Sit on every seat, ride the Ferris wheel, no ambient peds or traffic in the market.

**Settings:** `config.lua`. Top-level options:

- `Config.Reach` = `1.25`
- `Config.SitZ` = `0.03`
- `Config.Bench` = `'PROP_HUMAN_SEAT_BENCH'`
- `Config.Chair` = `'PROP_HUMAN_SEAT_CHAIR_MP_PLAYER'`
- `Config.Taken` = `0.4`
- `Config.Wheel`
- `Config.Clear`

**Exports used (optional unless listed as a dependency):** `olentrix_mpc_market:gondolas`

**Network events:** `olentrix_mpc_seats:granted`, `olentrix_mpc_seats:boarded`, `olentrix_mpc_seats:claim`, `olentrix_mpc_seats:board`, `olentrix_mpc_seats:leave`, `olentrix_mpc_seats:ridelog`

## `olentrix_mpc_skatekit`

Ice skates and skating animations.

**Settings:** none (a map resource; it only streams models and map files).

**Streamed files:** 1 .ycd, 2 .ydr, 1 .ytd, 2 .ytyp

## `olentrix_mpc_skating`

Buy ice skates and skate on the rink.

**Settings:** `config.lua`. Top-level options:

- `Config.Price` = `50`
- `Config.Item` = `'xmas_skates'`
- `Config.Rink`
- `Config.Gate`
- `Config.Counter`
- `Config.ChangeSpots`
- `Config.ShowExit` = `vector4(1343.9, -764.4, 66.3, 180.0)`
- `Config.ChangeTime` = `4000`
- `Config.KeepRange` = `200.0`
- `Config.Kneel`
- `Config.Skate`
- `Config.Sound`
- `Config.Text`

**Exports used (optional unless listed as a dependency):** `xmas_shops:hasItem`, `xmas_shops:buy`

**Network events:** `olentrix_mpc_skating:go`, `olentrix_mpc_skating:msg`, `olentrix_mpc_skating:buy`, `olentrix_mpc_skating:ask`, `olentrix_mpc_skating:done`

**GlobalState keys:** `xmasIceShow`

**Player state bag keys:** `xmasSkates`

## `olentrix_mpc_iceshow`

An ice skating show on the rink, started by any player.

**Settings:** `config.lua`. Top-level options:

- `Config.Rink`
- `Config.Start`
- `Config.Cooldown` = `600`
- `Config.Lead` = `60`
- `Config.ShowRange` = `120.0`
- `Config.Text`
- `Config.Skaters`
- `Config.StandHeight` = `0.98`
- `Config.Skates`
- `Config.Sound`
- `Config.Lights`

**Exports provided:** `isRunning`

**Network events:** `olentrix_mpc_iceshow:play`, `olentrix_mpc_iceshow:soon`, `olentrix_mpc_iceshow:notice`, `olentrix_mpc_iceshow:start`, `olentrix_mpc_iceshow:sync`

**GlobalState keys:** `xmasIceShow`, `xmasIceShowNext`

## `olentrix_mpc_elf`

The naughty or nice elf.

**Settings:** `config.lua`. Top-level options:

- `Config.SpawnDistance` = `90.0`
- `Config.DespawnDistance` = `110.0`
- `Config.PromptDistance` = `2.2`
- `Config.ServerReach` = `6.0`
- `Config.ChoiceSeconds` = `20`
- `Config.Cooldown` = `60`
- `Config.Move`
- `Config.Volume` = `0.8`
- `Config.Keys`
- `Config.Elf`
- `Config.Treat`
- `Config.Knock`
- `Config.Wake`
- `Config.Text`
- `Config.Scene`

**Streamed files:** 2 .ydr, 1 .ymap, 1 .ytd, 2 .ytyp

Map files: `xe_lair.ymap`

**Exports used (optional unless listed as a dependency):** `qbx_core:Notify`

**Network events:** `olentrix_mpc_elf:ask`, `olentrix_mpc_elf:refuse`, `olentrix_mpc_elf:act`, `olentrix_mpc_elf:talk`, `olentrix_mpc_elf:cancel`, `olentrix_mpc_elf:choose`, `olentrix_mpc_elf:woke`

**GlobalState keys:** `xmasElf`

## `olentrix_mpc_houses`

Houses, streets, bridges and city squares dressed for Christmas.

**Settings:** none (a map resource; it only streams models and map files).

**Streamed files:** 111 .ydr, 22 .ymap, 1 .ytd, 111 .ytyp

Map files: `xh_br_raillift.ymap`, `xh_br_signal.ymap`, `xh_br_skidrow.ymap`, `xh_eb_heights.ymap`, `xh_ev_strip.ymap`, `xh_gs_covenant.ymap`, `xh_gs_cul.ymap`, `xh_gs_grove.ymap`, `xh_mp_blvd_east.ymap`, `xh_mp_blvd_west.ymap`, `xh_mp_lake_north.ymap`, `xh_mp_lake_south.ymap`, `xh_mp_nikola.ymap`, `xh_mp_west.ymap`, `xh_sp_I023.ymap`, `xh_sp_I024.ymap`, `xh_sp_I025.ymap`, `xh_sp_I026.ymap`, `xh_sp_I027.ymap`, `xh_sp_I028.ymap`, `xh_sp_I029.ymap`, `xh_sp_I030.ymap`

## `olentrix_mpc_houses_snow`

Snow on the house dressing, for snowy servers.

**Settings:** none (a map resource; it only streams models and map files).

**Streamed files:** 5 .ydr, 21 .ymap, 5 .ytyp

Map files: `xh_br_signal_snow.ymap`, `xh_br_skidrow_snow.ymap`, `xh_eb_heights_snow.ymap`, `xh_ev_strip_snow.ymap`, `xh_gs_covenant_snow.ymap`, `xh_gs_cul_snow.ymap`, `xh_gs_grove_snow.ymap`, `xh_mp_blvd_east_snow.ymap`, `xh_mp_blvd_west_snow.ymap`, `xh_mp_lake_north_snow.ymap`, `xh_mp_lake_south_snow.ymap`, `xh_mp_nikola_snow.ymap`, `xh_mp_west_snow.ymap`, `xh_sp_I023_snow.ymap`, `xh_sp_I024_snow.ymap`, `xh_sp_I025_snow.ymap`, `xh_sp_I026_snow.ymap`, `xh_sp_I027_snow.ymap`, `xh_sp_I028_snow.ymap`, `xh_sp_I029_snow.ymap`, `xh_sp_I030_snow.ymap`

## `olentrix_mpc_trees`

Christmas bulbs in the game trees and palms, every copy on the map.

**Settings:** none (a map resource; it only streams models and map files).

**Streamed files:** 17 .ydr

## `olentrix_mpc_streets`

Street lights, signals, shelters and street props dressed for Christmas, map-wide.

**Settings:** none (a map resource; it only streams models and map files).

**Streamed files:** 3 .ydr, 36 .yft
