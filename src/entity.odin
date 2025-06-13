package main

import rl"vendor:raylib"

//
// TYPES
//

// Sprite position is the actual draw position.
Sprite :: struct {
    pos           : rl.Vector2,
    sheet_name    : string,
    sheet         : rl.Texture2D,
    frame_rec     : rl.Rectangle,
    cur_frame     : f32,
    frame_count   : f32,
    frame_speed   : f32,
    animation_row : f32,
}


EntityType :: enum {
    player,
    exit,
    block,
    teleporter,
}

//
// position in the entity class is where in the grid world this hoe be living
// @cleanup:cs There is a bunch of extra stuff in here atm.
//
Entity :: struct {
    id                : string,
    pos               : rl.Vector2,
    idx               : u32,
    sprite            : Sprite,
    rotation          : f32,
    e_type            : EntityType,
    aabb              : rl.Rectangle,
    push_dir          : rl.Vector2,
    pushed            : bool,
    player_standing_on: bool,
    active_ent        : bool,
    selected          : bool,
}

//
// This is a really big function. I dont really feel the need
// to completely split it up. Again just want to make app
// post something very simple to itch.io. So for the mean time
// this finna be ugly as heck. Enjoy the read.
//
entity_update :: proc(s: ^Scene, ent: ^Entity) {

    push_allowed := true

    #partial switch ent.e_type {
    case .player: {
        if ent.selected {
            if rl.IsKeyPressed(rl.KeyboardKey.A) {
                target := ent.sprite.pos - rl.Vector2{tile_size, 0}
                idx := pos_to_index(s.width, s.height, target)
                if s.tiles[idx].t_type == .floor {
                    for &e in s.entities {
                        if e.idx == ent.idx {
                            continue
                        }
                        if e.idx == idx && e.e_type == .block {
                            push := rl.Vector2{-tile_size, 0}
                            push_idx := pos_to_index(s.width, s.height, e.sprite.pos + push)
                            if s.tiles[push_idx].t_type == .wall {
                                push_allowed = false
                                continue
                            }
                            e.push_dir = push
                        }
                    }
                    if push_allowed {
                        ent^.idx = idx
                        ent^.sprite.pos = target
                    }
                }
            }
            if rl.IsKeyPressed(rl.KeyboardKey.D) {
                target := ent.sprite.pos + rl.Vector2{tile_size, 0}
                idx := pos_to_index(s.width, s.height, target)
                if s.tiles[idx].t_type == .floor {
                    for &e in s.entities {
                        if e.idx == ent.idx {
                            continue
                        }
                        if e.idx == idx && e.e_type == .block {
                            push := rl.Vector2{tile_size, 0}
                            push_idx := pos_to_index(s.width, s.height, e.sprite.pos + push)
                            if s.tiles[push_idx].t_type == .wall {
                                push_allowed = false
                                continue
                            }
                            e.push_dir = push
                        }
                    }
                    if push_allowed {
                        ent^.idx = idx
                        ent^.sprite.pos = target
                    }
                }
            }
            if rl.IsKeyPressed(rl.KeyboardKey.W) {
                target := ent.sprite.pos - rl.Vector2{0, tile_size}
                idx := pos_to_index(s.width, s.height, target)
                if s.tiles[idx].t_type == .floor {
                    for &e in s.entities {
                        if e.idx == ent.idx {
                            continue
                        }
                        if e.idx == idx && e.e_type == .block {
                            push := rl.Vector2{0, -tile_size}
                            push_idx := pos_to_index(s.width, s.height, e.sprite.pos + push)
                            if s.tiles[push_idx].t_type == .wall {
                                push_allowed = false
                                continue
                            }
                            e.push_dir = push
                        }
                    }
                    if push_allowed {
                        ent^.idx = idx
                        ent^.sprite.pos = target
                    }

                }
            }
            if rl.IsKeyPressed(rl.KeyboardKey.S) {
                target := ent.sprite.pos + rl.Vector2{0, tile_size}
                idx := pos_to_index(s.width, s.height, target)
                if s.tiles[idx].t_type == .floor {
                    for &e in s.entities {
                        if e.idx == ent.idx {
                            continue
                        }
                        if e.idx == idx && e.e_type == .block {
                            push := rl.Vector2{0, tile_size}
                            push_idx := pos_to_index(s.width, s.height, e.sprite.pos + push)
                            if s.tiles[push_idx].t_type == .wall {
                                push_allowed = false
                                continue
                            }
                            e.push_dir = push
                        }
                    }
                    if push_allowed {
                        ent^.idx = idx
                        ent^.sprite.pos = target
                    }
                }
            }
        }
    }
    case .block: {
        ent^.sprite.pos += ent.push_dir
        ent^.idx = pos_to_index(s.width, s.height, ent.sprite.pos)
        ent.push_dir = {}
    }
    }
}

entity_draw :: proc(ent: Entity) {
    rl.DrawTextureRec(ent.sprite.sheet, ent.sprite.frame_rec, ent.sprite.pos, rl.RAYWHITE)
}

