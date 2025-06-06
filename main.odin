#+feature dynamic-literals
package main

import "core:strings"
import "core:encoding/json"
import "core:fmt"
import "core:log"
import "core:os"
import rl "vendor:raylib"
import "core:math"

/// This is a game in one file. I just want to finish something. Im tired of never finishing
/// anything. SO Here is a simple game in one file.

// GLOBAL CONSTANTS

tile_size: f32 = 32.0
textures: map[string]rl.Texture2D
SPRITES := map[string]Sprite {
}
ENTITIES:= map[string]Entity {
}
TILES:= map[string]Tile{
}
temp_scene: Scene
sw_toggle := false
sh_toggle := false

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

Sprite :: struct {
    sheet         : rl.Texture2D,
    frame_rec     : rl.Rectangle,
    cur_frame     : f32,
    frame_count   : f32,
    frame_speed   : f32,
    animation_row : f32,
}


EntityType :: enum {
    default
}

Entity :: struct {
    id       : string,
    pos      : rl.Vector2,
    sprite   : Sprite,
    rotation : f32,
    e_type   : EntityType,
    aabb     : rl.Rectangle,
}

entity_update :: proc(ent: ^Entity) {
    switch ent.e_type {
    case .default:

    }
}

entity_draw :: proc(ent: Entity) {
    rl.DrawTextureRec(ent.sprite.sheet, ent.sprite.frame_rec, ent.pos, rl.RAYWHITE)
}


TileType :: enum {
    grass
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


Scene :: struct {
    id: string,
    width, height: i32,
	entities: [dynamic]Entity,
    tiles: [dynamic]Tile,
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
        entity_update(&entity)
    }
}

scene_load :: proc(name: string) -> Scene {
    file_name, _ := strings.concatenate({name, ".json"})

    data, success := os.read_entire_file_from_filename(file_name)
    if !success {
        return {}
    }

    s: Scene

    err := json.unmarshal(data, &s)
    if err != nil {
        fmt.eprintfln("Error: %s", err)
    }
    return s
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

    for i := 0; i < 100; i += 1 {
        scene_add_tile(&gs.scene, {
            pos      = {f32(i % 10) * tile_size, f32(i / 10) * tile_size},
            width    = 32,
            height   = 32,
            color    = rl.GREEN,
            walkable = true,
        })
    }
    scene_write(&gs.scene)

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
	rl.ClearBackground(rl.GRAY)
	rl.BeginDrawing()
    rl.BeginMode2D(gs.camera)

    scene_draw(&gs.scene)

    cursor_draw(gs)
    rl.EndMode2D()

    if gs.new_level_t {
        new_window_rec := rl.Rectangle{f32(rl.GetScreenWidth()/2 - 200), f32(rl.GetScreenHeight()/2 - 200), 400, 400}
        if rl.GuiWindowBox(new_window_rec, "New Level") == 1 {
            gs.new_level_t = false
        }
        if rl.GuiValueBox({new_window_rec.x + 50, new_window_rec.y + 50, 100, 30}, "width", &temp_scene.width, 1, 200, sw_toggle) == 1 {
            sw_toggle = !sw_toggle
        }
        if rl.GuiValueBox({new_window_rec.x + 50, new_window_rec.y + 100, 100, 30}, "height", &temp_scene.height, 1, 200, sh_toggle) == 1 {
            sh_toggle = !sh_toggle
        }
    }

	rl.DrawText(rl.TextFormat("%.1f , %.1f", gs.cursor.x, gs.cursor.y), 10, 10, 10, rl.WHITE)
	rl.DrawText(rl.TextFormat("%.1f , %.1f", gs.world_space_cursor.x, gs.world_space_cursor.y), 10, 25, 10, rl.WHITE)

	rl.EndDrawing()
}
