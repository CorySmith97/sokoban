package main

import "core:strings"
import rl"vendor:raylib"

// UTIL FUNCTIONS

pos_to_index :: proc(w, h: int, pos: rl.Vector2) -> u32 {
    return u32((f32(w) * pos.y / tile_size) + pos.x / tile_size)
}

get_texture :: proc(name: string) -> rl.Texture2D {
    if t, t_ok := textures[name]; t_ok {
        return t
    }

    t := rl.LoadTexture(strings.clone_to_cstring(name, context.temp_allocator))

    if t.id != 0 {
        textures[name] = t
    }

    return t
}


