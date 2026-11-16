# [FREE] [MAP] Mirror Park Christmas

> [!CAUTION]
> **STILL BEING WORKED ON.** This map is a work in progress and things will keep changing.
> If you're going to complain that it isn't ready, don't use it yet.

Welcome to Mirror Park Christmas.

A Christmas village on the hill above Mirror Park: wooden market cabins, an ice rink, a Ferris wheel, a big tree, a fireside lounge, and a little steam train that does laps of the whole thing.

## Download

| Version | File |
|-|-|
| **1.1.0** | [olentrix_mirror_park_christmas_v1.1.0.zip](https://github.com/OlentrixAssets/olentrix_mirror_park_christmas/releases/download/v1.1.0/olentrix_mirror_park_christmas_v1.1.0.zip) |
| **Props pack 1.1.0** | [olentrix_mirror_park_christmas_props_v1.1.0.zip](https://github.com/OlentrixAssets/olentrix_mirror_park_christmas/releases/download/v1.1.0/olentrix_mirror_park_christmas_props_v1.1.0.zip) |
| 1.0.0 | [olentrix_mirror_park_christmas_v1.0.0.zip](https://github.com/OlentrixAssets/olentrix_mirror_park_christmas/releases/download/v1.0.0/olentrix_mirror_park_christmas_v1.0.0.zip) |

Or hit **Code → Download ZIP**.

**Questions, bugs, screenshots?** Come say hi on [Discord](https://discord.gg/FTZTtQRsfR).

<details>
<summary><b>Features</b></summary>

- 15 wooden market cabins, each with its own stall and stock
- Ice rink with a viewing terrace and skate hire
- Ferris wheel, main Christmas tree and a fireside lounge
- Toy workshop with a miniature of the whole village in the window
- The Christmas Express: a small steam train you can ride round the whole market
- A snow globe at the end of a lantern-lit tunnel through the hill, with a snowy village inside
- Santa's Sleigh Run: a roller coaster from the snow globe out over the hill and back
- Santa's grotto: sit on Santa's lap or stand beside him, pick a pose, and an elf counts you down for the photo. An on-screen guide walks you through the visit, with a queue when Santa is busy
- Carol singers by the big tree, and a Letters to Santa postbox players can write to
- Sit on every bench, sofa and chair in the market, and ride the Ferris wheel's gondolas
- No ambient pedestrians or traffic wandering through the market
- A tree farm, glowing reindeer, a snowman family and a skate-change deck
- Cabin and workshop doors that open like any other door in the game
- The railway bridge sign reads TWINKLE TOWN and lights up letter by letter
- Music, carols, bells and a crackling fire near the attractions
- An evening light ceremony that lights the village up landmark by landmark
- A gateway entrance, with a privacy fence and evergreens along the road in
- Road markings, parking and a paved compass medallion in the turnaround

</details>

<details>
<summary><b>Installation</b></summary>

Drop the `[olentrix_mirror_park_christmas]` folder into your resources folder, add `ensure [olentrix_mirror_park_christmas]` to your server.cfg, and restart your server.

It comes as eight resources that work together. Keep them all:

| Resource | What it does |
|-|-|
| `olentrix_mpc_mold` | The level ground the village stands on |
| `olentrix_mpc_ground` | Clears the old court and repaves the road in |
| `olentrix_mpc_market` | The village itself |
| `olentrix_mpc_ambience` | Sound, the workshop train and the light ceremony |
| `olentrix_mpc_express` | The Christmas Express |
| `olentrix_mpc_coaster` | Santa's Sleigh Run |
| `olentrix_mpc_santa` | Santa, the grotto photos, the carol singers and the letters |
| `olentrix_mpc_seats` | Seats you can sit on, Ferris wheel rides, and no ambient peds or traffic in the market |

</details>

<details>
<summary><b>Optional add-ons</b></summary>

Four extras sit next to the `[olentrix_mirror_park_christmas]` folder, not inside it, so they don't start unless you want them. Drop in the ones you want and add an `ensure` line for each:

| Resource | What it does |
|-|-|
| `olentrix_mpc_houses` | Lights, wreaths, garlands and yard decorations on the houses around Mirror Park, East Vinewood, Grove Street and El Burro Heights, plus the Skid Row and port lift bridges and a few city squares |
| `olentrix_mpc_houses_snow` | Snow drifts and snowy wreaths, garlands and swags for the house decorations. Needs `olentrix_mpc_houses` |
| `olentrix_mpc_trees` | Christmas bulbs built into the game's own trees and palms, on every copy across the map |
| `olentrix_mpc_streets` | Christmas decorations on street lights, traffic signals, bus shelters, post boxes, hydrants, benches, bins and more, across the map |

```
ensure olentrix_mpc_houses
ensure olentrix_mpc_houses_snow
ensure olentrix_mpc_trees
ensure olentrix_mpc_streets
```

The house decorations look right in sunny weather on their own. Add `olentrix_mpc_houses_snow` only if your server runs snow.

</details>

<details>
<summary><b>Props pack</b></summary>

Just want the props for your own build? The props pack is a single resource, `olentrix_mpc_props`, with 136 of the market's props and their textures, and no map or scripts, so you can place them anywhere with your map tool of choice.

Drop the `olentrix_mpc_props` folder into your resources folder and add `ensure olentrix_mpc_props` to your server.cfg. Don't run it alongside the full map, which already includes every one of these.

Left out are the pieces built to fit this hill only: the ground, the snow globe and its tunnel, the coaster track, the fence runs and the road paint.

```
xv_armchair
xv_armchair_b
xv_bed_a
xv_bed_b
xv_bed_c
xv_bed_d
xv_bed_e
xv_bench
xv_bin
xv_cab_bakery
xv_cab_bakery_door
xv_cab_candles
xv_cab_candles_door
xv_cab_chestnut
xv_cab_chestnut_door
xv_cab_cocoa
xv_cab_cocoa_door
xv_cab_corner
xv_cab_corner_door
xv_cab_gifts
xv_cab_gifts_door
xv_cab_ginger
xv_cab_ginger_door
xv_cab_glass
xv_cab_glass_door
xv_cab_mulled
xv_cab_mulled_door
xv_cab_nuts
xv_cab_nuts_door
xv_cab_ornament
xv_cab_ornament_door
xv_cab_skates
xv_cab_skates_door
xv_cab_souvenir
xv_cab_souvenir_door
xv_cab_waffle
xv_cab_waffle_door
xv_cab_wreath
xv_cab_wreath_door
xv_canopy
xv_cpost
xv_deco_lanterns
xv_deco_parcels
xv_deco_trough
xv_firepit
xv_gate
xv_globe_traincar
xv_globe_trainloco
xv_lamp
xv_lounge
xv_loveseat
xv_lpost
xv_menuboard
xv_pouffe
xv_queue
xv_reindeer
xv_rink
xv_shelter
xv_shelter_g
xv_shelter_v
xv_signpost
xv_signpost_sq
xv_skatedisp
xv_sleigh
xv_sleighbower
xv_snowscene
xv_sofa
xv_span
xv_sqcanopy
xv_stable
xv_standtable
xv_story_1
xv_story_2
xv_story_3
xv_story_4
xv_toydisp
xv_tree_bh
xv_tree_fa
xv_tree_fa_rgb
xv_tree_fb
xv_tree_fb_rgb
xv_tree_fc
xv_tree_fc_rgb
xv_tree_fd
xv_tree_fd_rgb
xv_tree_fe
xv_tree_fe_rgb
xv_tree_ff
xv_tree_fg
xv_tree_main
xv_tree_sa
xv_tree_sb
xv_tree_sc
xv_tree_sd
xv_treering
xv_village
xv_w_cane
xv_w_cocoacart
xv_w_deerfirs
xv_w_deerwire
xv_w_door_l
xv_w_door_r
xv_w_dropsign
xv_w_farmfirs
xv_w_farmlights
xv_w_farmyard
xv_w_grotto
xv_w_letters
xv_w_mistletoe
xv_w_pickup
xv_w_potfir
xv_w_rdlamp
xv_w_santasign
xv_w_skatedeck
xv_w_snowmen
xv_w_snowshrub_a
xv_w_snowshrub_b
xv_wheel_base
xv_wheel_gond_g
xv_wheel_gond_r
xv_wheel_rim
xv_workshop
xv_workshop_door
xv_wpocket_a
xv_wpocket_b
xv_wpocket_fox
xv_wpocket_owl
xv_wrap
xv_wthresh
xv_wtrain_c
xv_wtrain_l
xv_wtrain_t
xv_xtree_a
xv_xtree_b
xv_xtree_c
xv_xtree_d
```

</details>

<details>
<summary><b>The Christmas Express</b></summary>

The train stops at the station on the north side. Walk up to a coach and press **E** to board, and **E** again to step off when it's back at the station.

</details>

<details>
<summary><b>Santa's Sleigh Run</b></summary>

The sleigh waits at the station inside the snow globe. Walk up to it and press **E** to ride. One rider at a time.

</details>

<details>
<summary><b>Santa's grotto and letters</b></summary>

Walk up to the grotto and press **E** to pick a photo spot. Once you're in place, **E** picks a pose, **G** takes the photo, **H** whispers your wish to Santa and **Backspace** hops off. If someone else is with Santa you join the line and get told when it's your turn. Letters posted at the Letters to Santa box are kept by the server; staff can read the latest with the `santaletters` command (ace `command.santaletters`).

</details>

<details>
<summary><b>Light ceremony</b></summary>

Runs on its own at 18:00, 20:00 and 22:00 game time if your server uses Renewed-Weathersync. Staff can also start it with the `xmasceremony` command (ace `command.xmasceremony`).

</details>

> [!WARNING]
> This replaces the game's own map files for the hill court and road above Mirror Park. Other maps that change the same spot will clash with it.
>
> The `olentrix_mpc_trees` and `olentrix_mpc_streets` add-ons replace the game's own tree, palm and street prop models. Other resources that replace the same models will clash with them.

<details>
<summary><b>Preview</b></summary>

</details>
