package main

import rl"vendor:raylib"

//
// TILES
//

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


