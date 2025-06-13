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

//
// MAIN FUNCTIONS
//

main :: proc() {
    rl.InitWindow(768, 640, "Hello")

    gs: GameState

    os.set_current_directory("levels")
    init(&gs)
    gs.scene = scene_load("l2")

    rl.SetTargetFPS(120.0)

    for !rl.WindowShouldClose() {
        frame(&gs)
    }
}

init :: proc(gs: ^GameState) {
    gs.camera = rl.Camera2D {
        offset   = rl.Vector2{0, 0},
        target   = rl.Vector2(0),
        rotation = 0,
        zoom     = 2,
    }
    gs.scene.id = "l1"
    gs.mode = .playing

}

frame :: proc(gs: ^GameState) {
    //
    // Input
    //
    if rl.IsKeyPressed(rl.KeyboardKey.ZERO) {
        change_level = !change_level
    }
    if rl.IsKeyPressed(rl.KeyboardKey.EIGHT) {
        scene_reload(&gs.scene)
    }

    if rl.IsKeyPressed(rl.KeyboardKey.NINE) {
        switch gs.mode {
        case .playing, .menu: gs.mode = .editing
        case .editing: gs.mode = .playing
        }
        fmt.printf("Mode: %s\n", gs.mode)
    }

    #partial switch gs.mode {
    case .playing: {
        if rl.IsKeyPressed(rl.KeyboardKey.LEFT) {
            gs.camera.offset.x += 5
        }
        if rl.IsKeyPressed(rl.KeyboardKey.RIGHT) {
            gs.camera.offset.x -= 5
        }
        if rl.IsKeyPressed(rl.KeyboardKey.DOWN) {
            gs.camera.offset.y += 5
        }
        if rl.IsKeyPressed(rl.KeyboardKey.UP) {
            gs.camera.offset.y -= 5
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

    rl.EndMode2D()

    if change_level {
        if rl.GuiTextInputBox({10, 10, 300, 150}, "title", "message", "ok;bad", cstring(&string_buf[0]), 12, nil) == 1 {
            // @todo:cs deinit
            level_name, _  := strings.clone_from_cstring((cstring(&string_buf[0])))
            fmt.print(level_name)
            gs.scene = scene_load(level_name)

            change_level = false
        }
    }

    rl.EndDrawing()
}
