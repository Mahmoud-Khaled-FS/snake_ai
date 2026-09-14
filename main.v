module main
import raylib as rl
import math
import rand

enum GameMode {
	playing
	over
	won
}

struct Game {
mut:
	rows 							int
	columns 					int
	screen_height 		int
	screen_width 			int
	area_height 			int
	area_padding_top 	int
	area_padding_left int
	cell_width 				int
	cell_height 			int

	mode							GameMode
	score							int

	apple 						Apple
	snake							Snake
}

struct Apple {
mut:
	pos rl.Vector2
}

struct Snake {
mut:
	body []rl.Vector2

	move_timer f32
	move_interval f32
	dir rl.Vector2
	should_grow bool
	next_dir ?rl.Vector2
}

fn (mut g Game) create_apple() {
	mut empty_cells := []rl.Vector2{}
	for r := 0; r < g.rows; r++ {
		cell: for c := 0; c < g.columns; c++ {
			for sb in g.snake.body {
				if sb.x == c && sb.y == r {
					continue cell
				}
			}
			empty_cells << rl.Vector2{c, r}
		}
	}
	if empty_cells.len == 0 {
		g.mode = .won
		return
	}
	i := rand.intn(empty_cells.len) or {0}
	g.apple = Apple {
		pos: empty_cells[i]
	}
}

fn (mut g Game) create_snake() {
	head_pos := rl.Vector2{g.columns / 2, g.rows - 4}
	g.snake = Snake{
		body: []
	}
	g.snake.body << head_pos
	g.snake.body << rl.Vector2{head_pos.x, head_pos.y + 1}
	g.snake.move_interval = 0.15
	g.snake.dir = rl.Vector2{ 0, -1 }
}

fn (g &Game) draw_apple() {
	x := int(g.cell_width * g.apple.pos.x)
	y := int(g.cell_height * g.apple.pos.y)
	w := 15
	rl.draw_rectangle((x - w /2) + g.cell_width / 2, (y - w/2) + g.cell_height / 2, w, w, rl.Color{255, 10, 10, 255})
}

// fn (g &Game) draw_snake() {
// 	for sb in g.snake.body {
// 		// println(sb
// 		x := int(sb.x * g.cell_width)
// 		y := int(sb.y * g.cell_height)
// 		w := g.cell_width - 5
		
// 		rl.draw_rectangle((x - w /2) + g.cell_width / 2, (y - w / 2) + g.cell_height / 2, w, w, rl.Color{25, 255, 10, 255})
// 	}
// }

fn (g &Game) draw_snake() {
	body_len := g.snake.body.len

	for i, sb in g.snake.body {
		x := int(sb.x * g.cell_width)
		y := int(sb.y * g.cell_height)

		w := g.cell_width - 5

		mut t := f32(0.0)

		if body_len > 1 {
			t = f32(i) / f32(body_len - 1)
		}

		// Head: 25,255,10
		// Tail: 5,135,40
		r := u8(25.0 - 20.0 * t)
		gr := u8(255.0 - 120.0 * t)
		b := u8(10.0 + 30.0 * t)

		color := rl.Color{
			r
			gr
			b
			255
		}

		rl.draw_rectangle(
			(x - w / 2) + g.cell_width / 2,
			(y - w / 2) + g.cell_height / 2,
			w,
			w,
			color
		)
	}
}


fn (mut s Snake) update() {
	s.move_timer += rl.get_frame_time()

	if s.move_timer < s.move_interval {
		return
	}

	old_tail := rl.Vector2{s.body[s.body.len - 1].x, s.body[s.body.len - 1].y}
	
	if s.next_dir != none {
		s.dir.x = s.next_dir.x
		s.dir.y = s.next_dir.y
		s.next_dir = none
	}

	s.move_timer -= s.move_interval
	for i := s.body.len - 1; i > 0; i--{
		s.body[i].x = s.body[i - 1].x
		s.body[i].y = s.body[i - 1].y
	}

	s.body[0].y += s.dir.y
	s.body[0].x += s.dir.x
	
	if s.should_grow {
		s.body << old_tail
		s.should_grow = false
	}
}

fn (s &Snake) is_collapse() bool {
	head := s.body[0]
	for i := 1; i < s.body.len; i++ {
		if head.x == s.body[i].x && head.y == s.body[i].y {
			return true
		}
	}
	return false
}

fn (g &Game) is_snake_eating() bool {
	head := g.snake.body[0]
	return head.x == g.apple.pos.x && head.y == g.apple.pos.y
}

fn (mut g Game) update() {
	g.snake.update()

	head := g.snake.body[0]
	if head.x >= g.columns || head.x < 0 || head.y >= g.rows || head.y < 0 || g.snake.is_collapse() {
		g.mode = .over
		return
	}

	if g.is_snake_eating() {
		g.snake.should_grow = true
		g.score += 1
		g.create_apple()
	}
}

fn Game.new() Game {
	mut game := Game{}
	game.rows = 20
	game.columns = 20
	game.screen_width = 600
	game.screen_height = 800
	game.area_height = math.min(game.screen_height, game.screen_width)
	game.area_padding_top = (game.screen_height - game.area_height) / 2
	game.area_padding_left = (game.screen_width - game.area_height) / 2
	game.cell_width = game.area_height / game.columns
	game.cell_height = game.area_height / game.rows
	game.mode = .playing

	game.create_snake()
	game.create_apple()
	
	return game
}

fn (mut s Snake) handle_input() {
	key := rl.KeyboardKey.from(rl.get_key_pressed()) or {
		return
	}

	match key {
		.key_up {
			if s.dir.y == 0 {
				s.next_dir = rl.Vector2{0, -1}
			}
		}
		.key_down {
			if s.dir.y == 0 {
				s.next_dir = rl.Vector2{0, 1}
			}
		}
		.key_left {
			if s.dir.x == 0 {
				s.next_dir = rl.Vector2{-1, 0}
			}
		}
		.key_right {
			if s.dir.x == 0 {
				s.next_dir = rl.Vector2{1, 0}
			}
		}
		else {}
	}
}


fn main() {

	mut game := Game.new()

	rl.init_window(game.screen_width, game.screen_height, "hello world")
	camera := rl.Camera2D{
		target: rl.Vector2{-game.area_padding_left, -game.area_padding_top},
		offset: rl.Vector2{0, 0},
		rotation: 0,
		zoom: 1
	}

	rl.set_target_fps(60)

	for !rl.window_should_close() {
		if game.mode != .playing {
			key := rl.KeyboardKey.from(rl.get_key_pressed()) or { rl.KeyboardKey.key_null }
			if key == .key_r {
				game = Game.new()
			}
		} else {

		// game.create_apple()
		// game
			game.snake.handle_input()
			game.update()
		}

		rl.begin_drawing()

			rl.clear_background(rl.Color{25, 25, 25, 255})
			
			if game.mode != .playing {
				rl.draw_text("Press (R) to restart", 10, 10, 30, rl.Color{255, 255, 255, 255})
				rl.draw_text("Score (${game.score})", 10, 50, 30, rl.Color{255, 255, 255, 255})
				if game.mode == .won {
					rl.draw_text("Win!", 10, 90, 30, rl.Color{255, 255, 255, 255})
				}
			} else {
				rl.draw_text("Score (${game.score})", 10, 10, 30, rl.Color{255, 255, 255, 255})

				rl.begin_mode_2d(camera)
				for i := 0; i <= game.rows; i++ {
					rl.draw_rectangle(0, i * game.cell_height, game.area_height, 1, rl.Color{255, 10, 10, 55})
				}

				for i := 0; i <= game.columns; i++ {
					rl.draw_rectangle(i * game.cell_width, 0, 1, game.area_height, rl.Color{255, 10, 10, 55})
				}

				game.draw_apple()
				game.draw_snake()

				rl.end_mode_2d()
			}


		rl.end_drawing()
	}

	rl.close_window()
}