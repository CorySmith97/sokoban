#+feature dynamic-literals
package main

import rl"vendor:raylib"

// GLOBAL CONSTANTS

player_spritesheet := #load("../assets/player.png")

tile_size: f32 = 32.0
textures: map[string]rl.Texture2D
SPRITES := map[string]Sprite {
}
ENTITIES := map[string]Entity {
"PLAYER" = {
    id                = "player",
    sprite            = {
        sheet_name    = "../assets/player.png",
        frame_rec     = {0, 0, 32, 32},
        cur_frame     = 0,
        frame_count   = 0,
        frame_speed   = 45,
        animation_row = 1.0,
    },
    rotation          = 0,
    e_type            = .player,
    aabb              = {0, 0, tile_size, tile_size},
    active_ent        = true,
    selected          = true,
},
"BLOCK" = {
    id                = "block",
    sprite            = {
        sheet_name    = "../assets/block.png",
        frame_rec     = {0, 0, 32, 32},
        cur_frame     = 0,
        frame_count   = 0,
        frame_speed   = 0,
        animation_row = 1.0,
    },
    rotation          = 0,
    e_type            = .block,
    aabb              = {0, 0, tile_size, tile_size},
    active_ent        = true,
    selected          = true,
},
}
TILES:= map[string]Tile{
"WALL" = {
    width = tile_size,
    height = tile_size,
    color = rl.GRAY,
    t_type = .wall,
    walkable = false,
},
"FLOOR" = {
    width = tile_size,
    height = tile_size,
    color = rl.BLUE,
    t_type = .floor,
    walkable = true,
}
}
temp_scene: Scene
sw_toggle := false
sh_toggle := false
secret := false
change_level := false
delta :f32 = 0
string_buf: [dynamic]u8 = make([dynamic]u8, 128)
