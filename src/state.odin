package main

import rl"vendor:raylib"

//
// GAME STATE STUFF
//

GameMode :: enum {
    menu,
    playing,
    editing,
}

GameState :: struct {
    cursor            : rl.Vector2,
    world_space_cursor: rl.Vector2,
    camera            : rl.Camera2D,
    scene             : Scene,
    mode              : GameMode,
    new_level_t       : bool,
}
