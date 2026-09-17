module main
import raylib as rl
import math
import rand
import arrays

enum GameMode {
	start
	playing
	over
	won
}

enum CellType {
	empty
	snake
	apple
	wall
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
	dir Direction
	should_grow bool
	next_dir ?Direction
}

enum Direction {
	up
	down
	left
	right
}

fn move_vector(mut v2 &rl.Vector2, dir Direction) {
	match dir{
		.up { v2.y += -1 }
		.down { v2.y += 1 }
		.left { v2.x += -1 }
		.right { v2.x += 1 }
	}
}

fn is_hit_wall(head rl.Vector2, columns int, rows int) bool {
 	return head.x >= columns || head.x < 0 || head.y >= rows || head.y < 0
}

fn (mut s Snake) update() bool {
	s.move_timer += rl.get_frame_time()

	if s.move_timer < s.move_interval {
			return false
	}

	s.move_timer -= s.move_interval

	old_tail := rl.Vector2{s.body[s.body.len - 1].x, s.body[s.body.len - 1].y}

	if s.next_dir != none {
		s.dir = s.next_dir
		s.next_dir = none
	}

	for i := s.body.len - 1; i > 0; i--{
		s.body[i].x = s.body[i - 1].x
		s.body[i].y = s.body[i - 1].y
	}

	move_vector(mut s.body[0], s.dir)
	// s.body[0].y += s.dir.y
	// s.body[0].x += s.dir.x

	if s.should_grow {
		s.body << old_tail
		s.should_grow = false
	}

	return true
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

fn (mut s Snake) handle_input() {
	key := rl.KeyboardKey.from(rl.get_key_pressed()) or {
		return
	}

	match key {
		.key_up {
			s.set_next_dir(.up)
		}
		.key_down {
			s.set_next_dir(.down)
		}
		.key_left {
			s.set_next_dir(.left)
		}
		.key_right {
			s.set_next_dir(.right)
		}
		else {}
	}
}

fn (mut s Snake) set_next_dir(dir Direction) {
	match dir {
		.up {
			if s.dir != .down {
				s.next_dir = .up
			}
		}
		.down {
			if s.dir != .up {
				s.next_dir = .down
			}
		}
		.left {
			if s.dir != .right {
				s.next_dir = .left
			}
		}
		.right {
			if s.dir != .left {
				s.next_dir = .right
			}
		}
	}
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
	g.snake.move_interval = 0.05
	g.snake.dir = .up
}

fn (g &Game) is_snake_eating() bool {
	head := g.snake.body[0]
	return head.x == g.apple.pos.x && head.y == g.apple.pos.y
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

	camera						rl.Camera2D

	mode							GameMode
	score							int
	biggest_score			int

	apple 						Apple
	snake							Snake

	is_agent_playing	bool
	agent							Agent
	count_playing			int
}

fn (g &Game) draw_apple() {
	x := int(g.cell_width * g.apple.pos.x)
	y := int(g.cell_height * g.apple.pos.y)
	w := 15
	rl.draw_rectangle((x - w /2) + g.cell_width / 2, (y - w/2) + g.cell_height / 2, w, w, rl.Color{255, 10, 10, 255})
}

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

		r := u8(25.0 - 20.0 * t)
		gr := u8(255.0 - 120.0 * t)
		b := u8(10.0 + 30.0 * t)

		color := rl.Color{ r, gr, b, 255 }

		rl.draw_rectangle(
			(x - w / 2) + g.cell_width / 2,
			(y - w / 2) + g.cell_height / 2,
			w,
			w,
			color
		)
	}
}

fn (mut g Game) init() {
	g.rows = 15
	g.columns = 15
	g.screen_width = 600
	g.screen_height = 800
	g.area_height = math.min(g.screen_height, g.screen_width)
	g.area_padding_top = (g.screen_height - g.area_height) / 2
	g.area_padding_left = (g.screen_width - g.area_height) / 2
	g.cell_width = g.area_height / g.columns
	g.cell_height = g.area_height / g.rows

	g.mode = .playing

	if g.score > g.biggest_score {
		g.biggest_score = g.score
	}

	g.score = 0

	g.is_agent_playing = true
	g.count_playing += 1

	g.create_snake()
	g.create_apple()
}

fn (mut g Game) update_start() {
	key := rl.KeyboardKey.from(rl.get_key_pressed()) or { rl.KeyboardKey.key_null }
	if key == .key_space {
		g.mode = .playing
	}
}

fn (mut g Game) update_playing() {
	if g.is_agent_playing {
		action := g.agent.action(g)
		g.snake.set_next_dir(action)
	}

	g.snake.handle_input()

	old_head := g.snake.body[0]
	old_distance := math.abs(old_head.x - g.apple.pos.x) + math.abs(old_head.y - g.apple.pos.y)

	moved := g.snake.update()
	if !moved {
			return
	}

	head := g.snake.body[0]
	new_distance := math.abs(head.x - g.apple.pos.x) + math.abs(head.y - g.apple.pos.y)

	mut reward := -0.1

	if new_distance < old_distance {
			reward += 1
	} else if new_distance > old_distance {
			reward -= 1
	}

	if is_hit_wall(head, g.columns, g.rows) || g.snake.is_collapse() {
		g.mode = .over
		reward = -10
		if g.is_agent_playing {
			g.agent.reward(g, reward, true)
		}
		return
	}

	if g.is_snake_eating() {
		g.snake.should_grow = true
		g.score += 1
		g.create_apple()
		reward = 10
	}
	if g.is_agent_playing {
		g.agent.reward(g, reward, false)
	}
}

fn (mut g Game) update_over() {
	if g.is_agent_playing {
		 g.init()
		 return
	}
	key := rl.KeyboardKey.from(rl.get_key_pressed()) or { rl.KeyboardKey.key_null }
	if key == .key_r {
		 g.init()
	}
}

fn (mut g Game) update_won() {
	key := rl.KeyboardKey.from(rl.get_key_pressed()) or { rl.KeyboardKey.key_null }
	if key == .key_r {
		 g.init()
	}
}

fn (mut g Game) update() {
	match g.mode {
		.start { g.update_start() }
		.playing { g.update_playing() }
		.over { g.update_over() }
		.won { g.update_won() }
	}
}

fn (g &Game) draw_start() {
	rl.draw_text("Press (SPACE) to start", 10, 10, 30, rl.Color{255, 255, 255, 255})
}

fn (g &Game) draw_playing() {
	rl.draw_text("Score (${g.score})", 10, 10, 30, rl.Color{255, 255, 255, 255})
	rl.draw_text("Game: (${g.count_playing})", 10, 40, 30, rl.Color{255, 255, 255, 255})

	rl.begin_mode_2d(g.camera)
	for i := 0; i <= g.rows; i++ {
		rl.draw_rectangle(0, i * g.cell_height, g.area_height, 1, rl.Color{255, 10, 10, 55})
	}

	for i := 0; i <= g.columns; i++ {
		rl.draw_rectangle(i * g.cell_width, 0, 1, g.area_height, rl.Color{255, 10, 10, 55})
	}

	g.draw_apple()
	g.draw_snake()

	rl.end_mode_2d()
}

fn (g &Game) draw_over() {
	rl.draw_text("Press (R) to restart", 10, 10, 30, rl.Color{255, 255, 255, 255})
	rl.draw_text("Score (${g.score})", 10, 50, 30, rl.Color{255, 255, 255, 255})
}

fn (g &Game) draw_won() {
	rl.draw_text("Press (R) to restart", 10, 10, 30, rl.Color{255, 255, 255, 255})
	rl.draw_text("Score (${g.score})", 10, 50, 30, rl.Color{255, 255, 255, 255})
	rl.draw_text("Win!", 10, 90, 30, rl.Color{255, 255, 255, 255})
}

fn (g &Game) draw() {
	match g.mode {
		.start { g.draw_start() }
		.playing { g.draw_playing() }
		.over { g.draw_over() }
		.won { g.draw_won() }
	}
}

struct Agent {
mut:
	q_table map[string][]f64
	last_state ?string
	last_action ?Action
	eps f64
}

enum Action {
	straight
	left
	right
}

fn is_danger(game &Game, dir Direction) bool {
    mut head := game.snake.body[0]
    move_vector(mut head, dir)

    if is_hit_wall(head, game.columns, game.rows) {
        return true
    }

    for i := 1; i < game.snake.body.len; i++ {
        body := game.snake.body[i]

        if head.x == body.x && head.y == body.y {
            return true
        }
    }

    return false
}

// fn get_state(game &Game) string {
//     head := game.snake.body[0]
//     dir := game.snake.dir

//     left_dir := action_to_dir(.left, dir)
//     right_dir := action_to_dir(.right, dir)

//     danger_straight := is_danger(game, dir)
//     danger_left := is_danger(game, left_dir)
//     danger_right := is_danger(game, right_dir)

//     apple_left := game.apple.pos.x < head.x
//     apple_right := game.apple.pos.x > head.x
//     apple_up := game.apple.pos.y < head.y
//     apple_down := game.apple.pos.y > head.y

//     return "${danger_straight},${danger_left},${danger_right}," +
//         "${apple_left},${apple_right},${apple_up},${apple_down}"
// }

fn get_state(game &Game) string {
	head := game.snake.body[0]

	view_size := 6
	half := view_size / 2

	mut state := ""

	for y := 0; y < view_size; y++ {
		for x := 0; x < view_size; x++ {
			grid_x := int(head.x) + x - half
			grid_y := int(head.y) + y - half

			mut cell := CellType.empty

			if grid_x < 0 ||
				grid_x >= game.columns ||
				grid_y < 0 ||
				grid_y >= game.rows {

				cell = .wall
			} else if game.apple.pos.x == grid_x &&
				game.apple.pos.y == grid_y {

				cell = .apple
			} else {
				for i, body in game.snake.body {
					if body.x == grid_x && body.y == grid_y {
						cell = .snake
						break
					}
				}
			}

			state += match cell {
				.empty { "0" }
				.snake { "1" }
				.apple { "2" }
				.wall { "3" }
			}
		}
	}

	// Add current direction.
	state += match game.snake.dir {
		.up { "U" }
		.down { "D" }
		.left { "L" }
		.right { "R" }
	}

	return state
}



fn action_to_dir(action Action, dir Direction) Direction {
	match action {
		.straight {
			return dir
		}
		.left {
			return match dir {
				.up { .left }
				.left { .down }
				.down { .right }
				.right { .up }
			}
		}
		.right {
			return match dir {
				.up { .right }
				.right { .down }
				.down { .left }
				.left { .up }
			}
		}
	}
}

fn (mut a Agent) action(game &Game) Direction {
	snake := game.snake
	mut snake_head := game.snake.body[0]
	state := get_state(game)
	a.last_state = state

	if state !in a.q_table {
		a.q_table[state] = [0.0, 0.0, 0.0]
		for i, _ in a.q_table[state] {
			mut head := snake_head
			dir := action_to_dir(Action.from(i) or {panic(err)}, snake.dir)
			move_vector(mut head, dir)
			if is_danger(game, dir) {
				a.q_table[state][i] = -10.0
			}
		}
	}

	mut rand_index := 0

	if rand.f32() < a.eps {
		rand_index = rand.intn(3) or { 0 }
	} else {
		rand_index = arrays.idx_max(a.q_table[state]) or { panic(err) }
	}

	a.eps *= 0.995

	if a.eps < 0.05 {
			a.eps = 0.05
	}

	action := Action.from(rand_index) or { Action.straight }
	a.last_action = action

	return action_to_dir(action, snake.dir)
}

fn (mut a Agent) reward(game &Game, reward f64, terminal bool) {
	last_state := a.last_state or { panic("missing last state") }
	last_action := a.last_action or { panic("missing last action") }

	al := 0.1
	f := 0.9

	value := a.q_table[last_state][last_action]

	mut target := reward

	if !terminal {
		snake_head := game.snake.body[0]
		state := get_state(game)
		if state !in a.q_table {
			a.q_table[state] = [0.0, 0.0, 0.0]
			for i, _ in a.q_table[state] {
				mut head := snake_head
				dir := action_to_dir(Action.from(i) or {panic(err)}, game.snake.dir)
				if is_danger(game, dir) {
					a.q_table[state][i] = -10.0
				}
			}
		}

		max_qi := arrays.idx_max(a.q_table[state]) or { panic(err) }
		max_q := a.q_table[state][max_qi]
		target += f * max_q
	}

	a.q_table[last_state][last_action] = value + al * (target - value)
	println(a.q_table[last_state])
	a.last_state = none
	a.last_action = none
}

fn main() {
	mut game := Game{}
	game.init()
	game.mode = .start

	rl.init_window(game.screen_width, game.screen_height, "hello world")

	game.camera = rl.Camera2D{
		target: rl.Vector2{-game.area_padding_left, -game.area_padding_top},
		offset: rl.Vector2{0, 0},
		rotation: 0,
		zoom: 1
	}

	// mut q_values := []State{len: (game.columns * game.rows) ** 2}

	// for i := 0; i < q_table.length; i++ {
	// 	q_values[i] =
	// }
	mut agent := Agent{}
	agent.q_table = map[string][]f64{}
	agent.eps = 0.8
	game.agent = agent
	// println(q_table)

	rl.set_target_fps(60)

	for !rl.window_should_close() {

		game.update()

		rl.begin_drawing()

			rl.clear_background(rl.Color{25, 25, 25, 255})
			game.draw()

		rl.end_drawing()
	}

	rl.close_window()
}
