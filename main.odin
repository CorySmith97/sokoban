#+feature dynamic-literals
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

/// This is a game in one file. I just want to finish something. Im tired of never finishing
/// anything. SO Here is a simple game in one file.

// GLOBAL CONSTANTS

player_spritesheet := #load("assets/player.png")

tile_size: f32 = 32.0
textures: map[string]rl.Texture2D
SPRITES := map[string]Sprite {
}
ENTITIES:= map[string]Entity {
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

// UTIL FUNCTIONS

pos_to_index :: proc(w, h: i32, pos: rl.Vector2) -> u32 {
    return u32((f32(w) * pos.y) + pos.x)
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

// position in the entity class is where in the grid world this hoe be living
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

entity_update :: proc(s: ^Scene, ent: ^Entity) {
    //
    // @todo:cs Add the ability to push blocks
    //
    #partial switch ent.e_type {
    case .player: {
        if ent.selected {
            if rl.IsKeyPressed(rl.KeyboardKey.A) {
                ent^.pos.x -= tile_size
            }
            if rl.IsKeyPressed(rl.KeyboardKey.D) {
                ent^.pos.x += tile_size
            }
            if rl.IsKeyPressed(rl.KeyboardKey.W) {
                ent^.pos.y -= tile_size
            }
            if rl.IsKeyPressed(rl.KeyboardKey.S) {
                ent^.pos.y += tile_size
            }
        }
    }
    }
}

entity_draw :: proc(ent: Entity) {
    rl.DrawTextureRec(ent.sprite.sheet, ent.sprite.frame_rec, ent.pos, rl.RAYWHITE)
}


TileType :: enum {
    wall,
    floor,
}

Tile :: struct {
    pos: rl.Vector2,
    width, height: f32,
    color: rl.Color,
    t_type: TileType,
    walkable: bool,
}

tile_update :: proc(tile: ^Tile) {
}

tile_draw :: proc(tile: Tile) {
    rl.DrawRectangleV(tile.pos, {tile.width, tile.height}, tile.color)
    rl.DrawRectangleLinesEx({tile.pos.x, tile.pos.y, tile.width, tile.height}, 1, rl.BLACK)
}

Clear_Conditions :: enum {
    get_to_exit,
}

Scene :: struct {
    id: string,
    width, height: i32,
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

    os.set_current_directory("levels")
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

    s: Scene;
    s.id = name;

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
                    ent.pos = rl.Vector2{f32(x) * tile_size, f32(y) * tile_size};
                    ent.sprite.sheet = get_texture(ent.sprite.sheet_name)
                    fmt.printf("%v\n", ent)
                    scene_add_entity(&s, ent);
                }
            }
            if char == 'B' {
                if tile, t_ok := TILES["FLOOR"]; t_ok {
                    tile.pos = rl.Vector2{f32(x) * tile.width, f32(y) * tile.height};
                    scene_add_tile(&s, tile);
                }
                if ent, t_ok := ENTITIES["BLOCK"]; t_ok {
                    ent.pos = rl.Vector2{f32(x) * tile_size, f32(y) * tile_size};
                    ent.sprite.sheet = get_texture(ent.sprite.sheet_name)
                    fmt.printf("%v\n", ent)
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

scene_add_entity :: proc(s: ^Scene, e: Entity) {
    append(&s.entities, e)
}

scene_add_tile :: proc(s: ^Scene, t: Tile) {
    append(&s.tiles, t)
}

cursor_draw :: proc(gs: ^GameState) {
    rl.DrawRectangleLinesEx({gs.game_cursor.x, gs.game_cursor.y, tile_size, tile_size}, 1, rl.RED)
    rl.DrawCircleV(gs.game_cursor, 1, rl.BLUE)
}

GameMode :: enum {
    menu,
    playing,
    editing,
}

GameState :: struct {
	cursor            : rl.Vector2,
    world_space_cursor: rl.Vector2,
    game_cursor       : rl.Vector2,
	camera            : rl.Camera2D,
	scene             : Scene,
    mode              : GameMode,
    new_level_t       : bool,
}

camera_control :: proc(gs: ^GameState) {
    gc_to_screen := rl.GetWorldToScreen2D(gs.game_cursor, gs.camera)
    if gc_to_screen.x + tile_size/2 >= f32(rl.GetScreenWidth()) {
        gs^.camera.offset.x -= tile_size
    }
    if gc_to_screen.x - tile_size/2 <= 0 {
        gs^.camera.offset.x += tile_size
    }
    if gc_to_screen.y >= f32(rl.GetScreenHeight()) {
        gs^.camera.offset.y -= tile_size
    }
    if gc_to_screen.y <= 0 {
        gs^.camera.offset.y += tile_size
    }
}

//
// MAIN FUNCTIONS
//

main :: proc() {
	rl.InitWindow(800, 600, "Hello")

	gs: GameState

	init(&gs)
    gs.scene = scene_load("l1")

    rl.SetTargetFPS(120.0)

	for !rl.WindowShouldClose() {
		frame(&gs)
	}
}

init :: proc(gs: ^GameState) {
    gs.camera = rl.Camera2D {
        offset   = rl.Vector2{200, 150},
        target   = rl.Vector2(0),
        rotation = 0,
        zoom     = 2,
    }
    gs.scene.id = "l1"
    gs.mode = .playing

}

delta :f32 = 0
frame :: proc(gs: ^GameState) {
    //
    // Input
    //
    if rl.IsKeyPressed(rl.KeyboardKey.L) {
        switch gs.mode {
        case .playing, .menu: gs.mode = .editing
        case .editing: gs.mode = .playing
        }
        fmt.printf("Mode: %s\n", gs.mode)
    }

    #partial switch gs.mode {
    case .playing: {
        if rl.IsKeyPressed(rl.KeyboardKey.LEFT) {
            gs.game_cursor.x -= tile_size
        }
        if rl.IsKeyPressedRepeat(rl.KeyboardKey.LEFT) {
            gs.game_cursor.x -= tile_size
        }
        if rl.IsKeyPressed(rl.KeyboardKey.RIGHT) {
            gs.game_cursor.x += tile_size
        }
        if rl.IsKeyPressedRepeat(rl.KeyboardKey.RIGHT) {
            gs.game_cursor.x += tile_size
        }
        if rl.IsKeyPressed(rl.KeyboardKey.DOWN) {
            gs.game_cursor.y += tile_size
        }
        if rl.IsKeyPressedRepeat(rl.KeyboardKey.DOWN) {
            gs.game_cursor.y += tile_size
        }
        if rl.IsKeyPressed(rl.KeyboardKey.UP) {
            gs.game_cursor.y -= tile_size
        }
        if rl.IsKeyPressedRepeat(rl.KeyboardKey.UP) {
            gs.game_cursor.y -= tile_size
        }
    }
    case .editing: {
        if rl.IsKeyDown(rl.KeyboardKey.A) && rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
            fmt.print("Editing or something\n")
        }

        if rl.IsKeyDown(rl.KeyboardKey.N) {
            gs.new_level_t = true
        }
    }
    }


    //
    // Update
    //

    camera_control(gs)
    gs.cursor = rl.GetMousePosition()
    gs.world_space_cursor = rl.GetScreenToWorld2D(gs.cursor, gs.camera)

    scene_update(&gs.scene)

    //
    // Render
    //
	rl.ClearBackground(rl.RAYWHITE)
	rl.BeginDrawing()
    rl.BeginMode2D(gs.camera)

    scene_draw(&gs.scene)

    cursor_draw(gs)
    rl.EndMode2D()

	rl.DrawText(rl.TextFormat("%.1f , %.1f", gs.cursor.x, gs.cursor.y), 10, 10, 10, rl.WHITE)
	rl.DrawText(rl.TextFormat("%.1f , %.1f", gs.world_space_cursor.x, gs.world_space_cursor.y), 10, 25, 10, rl.WHITE)

	rl.EndDrawing()
}
