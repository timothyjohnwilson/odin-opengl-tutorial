package main

GameObject :: struct {
    Position: [2]f32,
    Size: [2]f32,
    Velocity: [2]f32,
    Color: [3]f32,
    Rotation: f32,
    IsSolid: b32,
    Destroyed: b32,
    Sprite: Texture2D
}

init_game_object_blank :: proc() -> GameObject {
    return {
        Position = {0.0, 0.0},
        Size = {1.0, 1.0},
        Velocity = {0.0, 0.0},
        Color = {1.0, 1.0, 1.0},
        Rotation = 0.0,
        IsSolid = false,
        Destroyed = false,
    }
}

init_game_object_args :: proc(position: [2]f32, size: [2]f32, sprite: Texture2D, color: [3]f32, velocity: [2]f32) -> GameObject {
    return {
        Position = position,
        Size = size,
        Velocity = velocity,
        Color = color,
        Rotation = 0.0,
        IsSolid = false,
        Destroyed = false,
        Sprite = sprite
    }
}

init_game_object :: proc {
    init_game_object_args,
    init_game_object_blank,
}

draw_game_object :: proc(renderer: ^SpriteRenderer, game_object: ^GameObject) {
    draw_sprite(renderer, &game_object.Sprite, game_object.Position, game_object.Size, game_object.Rotation, game_object.Color)
}