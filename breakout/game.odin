package main

Game :: struct {
	state:  GameState,
	keys:   [1024]b32,
	width:  u32,
	height: u32,
}

GameState :: enum {
    GAME_ACTIVE,
    GAME_MENU,
    GAME_WIN
}


init :: proc(game: Game) {

}

process_input :: proc(dt: f32) {

}

update :: proc(dt: f32) {

}

render :: proc() {

}
