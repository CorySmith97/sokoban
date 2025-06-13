package main

import "core:strings"
import "core:encoding/json"
import "core:fmt"
import "core:log"
import "core:os"
import "core:math"
import "core:strconv"
import "core:mem"
import rl "vendor:raylib"

//
// SCENES
//

Clear_Conditions :: enum {
    get_to_exit,
}

Scene :: struct {
    id: string,
    width, height: int,
    entities: [dynamic]Entity,
    tiles: [dynamic]Tile,
    clear_condition: Clear_Conditions,
}

scene_draw :: proc(s: ^Scene) {
    for tile in s.tiles {
        tile_draw(tile)
    }
    for entity in s.entities {
        entity_draw(entity)
    }
}

scene_update :: proc(s: ^Scene) {
    for &tile in s.tiles {
        tile_update(&tile)
    }
    for &entity in s.entities {
        entity_update(s, &entity)
    }
}

scene_load :: proc(name: string) -> Scene {
    file_name, _ := strings.concatenate({name, ".txt"});

    data, success := os.read_entire_file_from_filename(file_name);
    if !success {
        fmt.eprintln("Failed to load file:", file_name);
        return {};
    }
    text := string(data)

    lines := strings.split_lines(text);
    if len(lines) < 3 {
        fmt.eprintln("Not enough data in level file");
        return {};
    }

    width, _  := strconv.parse_int(lines[0])
    height, _ := strconv.parse_int(lines[1])

    if width <= 0 || height <= 0 {
        fmt.eprintln("Invalid level dimensions");
        return {};
    }

    s: Scene
    s.id = name
    s.width = width
    s.height = height

    for y in 0 ..< height {
        if y + 2 >= len(lines) {
            break;
        }

        row := lines[y + 2];
        for x in 0 ..< min(width, len(row)) {
            char := row[x];

            if char == 'W' {
                if tile, t_ok := TILES["WALL"]; t_ok {
                    tile.pos = rl.Vector2{f32(x) * tile.width, f32(y) * tile.height};
                    scene_add_tile(&s, tile);
                }
            }
            if char == 'F' {
                if tile, t_ok := TILES["FLOOR"]; t_ok {
                    tile.pos = rl.Vector2{f32(x) * tile.width, f32(y) * tile.height};
                    scene_add_tile(&s, tile);
                }
            }
            if char == 'P' {
                if tile, t_ok := TILES["FLOOR"]; t_ok {
                    tile.pos = rl.Vector2{f32(x) * tile.width, f32(y) * tile.height};
                    scene_add_tile(&s, tile);
                }
                if ent, t_ok := ENTITIES["PLAYER"]; t_ok {
                    ent.sprite.pos = rl.Vector2{f32(x) * tile_size, f32(y) * tile_size};
                    ent.idx = pos_to_index(width, height, ent.sprite.pos)
                    ent.sprite.sheet = get_texture(ent.sprite.sheet_name)
                    scene_add_entity(&s, ent);
                }
            }
            if char == 'B' {
                if tile, t_ok := TILES["FLOOR"]; t_ok {
                    tile.pos = rl.Vector2{f32(x) * tile.width, f32(y) * tile.height};
                    scene_add_tile(&s, tile);
                }
                if ent, t_ok := ENTITIES["BLOCK"]; t_ok {
                    ent.sprite.pos = rl.Vector2{f32(x) * tile_size, f32(y) * tile_size};
                    ent.idx = pos_to_index(width, height, ent.sprite.pos)
                    ent.sprite.sheet = get_texture(ent.sprite.sheet_name)
                    scene_add_entity(&s, ent);
                }
            }
        }
    }

    return s;
}


scene_write :: proc(s: ^Scene) {

    if str, err := json.marshal(s^, json.Marshal_Options{
        pretty = true,
        use_spaces = true,
        use_enum_names = true,
        spaces = 1
    }); err == nil {

        file_name, _ := strings.concatenate({s.id, ".json"})
        os.set_current_directory("levels")
        file, e := os.open(file_name, os.O_RDWR | os.O_CREATE | os.O_TRUNC, 0o644)
        defer os.close(file)

        //fmt.printf("%s", str)
        if e != nil {
            fmt.eprint(e)
            return
        }
        _, _ = os.write(file, str)

    }
}

scene_reload :: proc(s: ^Scene) {
    s^ = scene_load(s.id)
}

scene_add_entity :: proc(s: ^Scene, e: Entity) {
    append(&s.entities, e)
}

scene_add_tile :: proc(s: ^Scene, t: Tile) {
    append(&s.tiles, t)
}
