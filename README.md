# Snake AI in V

A small Snake game written in [V](https://vlang.io/) using a local [raylib](https://www.raylib.com/) binding. The snake is controlled by an online Q-learning agent that learns while the game is running.

## Features

- Snake rendered with raylib on a 15 × 15 grid.
- Q-learning agent with epsilon-greedy exploration.
- State representation based on a 6 × 6 view around the snake's head and its current direction.
- Three relative actions: move straight, turn left, or turn right.
- Rewards for moving towards the apple, eating the apple, and avoiding or hitting hazards.
- Automatic restart after the agent loses.

The learned Q-table is held in memory, so it is reset whenever the program starts.

## Requirements

- V 0.4 or newer
- A C compiler supported by V
- raylib 4.x or newer, including the raylib headers and library

The binding in [`raylib/raylib.c.v`](raylib/raylib.c.v) includes `raylib.h` and links with `-lraylib`. Install raylib using your operating system's package manager, then make sure the compiler can find the library and headers.

For example, on Debian or Ubuntu:

```sh
sudo apt install build-essential libraylib-dev
```

On macOS, raylib can be installed with Homebrew:

```sh
brew install raylib
```

## Run

Clone the repository and enter its directory, then run:

```sh
v run .
```

To build a native executable:

```sh
v .
./snake_ai
```

The window opens at 600 × 800 pixels. Press **Space** to start the game. The agent then chooses actions and updates its Q-table after each move. Press **R** on a game-over or win screen to restart, and close the window to exit.

Arrow keys can also provide manual direction input while the game is running. The agent remains enabled by default, so keyboard input is useful for observing or influencing a run rather than switching to a separate human-only mode.

## How the learning works

For each decision, the agent builds a state from:

1. A 6 × 6 window centered on the snake's head. Each cell is encoded as empty, snake, apple, or wall.
2. The snake's current direction (`up`, `down`, `left`, or `right`).

The agent stores three Q-values for each state, one for each relative action:

| Action | Meaning |
| --- | --- |
| `straight` | Continue in the current direction |
| `left` | Turn 90 degrees left |
| `right` | Turn 90 degrees right |

The update uses a learning rate of `0.1`, a discount factor of `0.9`, and an exploration rate that starts at `0.8`, decays after each action, and is capped at `0.05`.

Rewards are shaped as follows:

- `+1` when a move reduces the Manhattan distance to the apple
- `-1` when a move increases that distance
- `-0.1` for the normal movement cost
- `+10` for eating an apple
- `-10` for hitting a wall or the snake's body

The Q-table is not serialized. To continue learning between runs, add persistence for `Agent.q_table` before closing the program and load it when initializing the agent.

## Project structure

```text
.
├── main.v              # Game loop, Snake implementation, and Q-learning agent
├── raylib/
│   └── raylib.c.v      # V wrappers around the raylib C API used by the game
└── v.mod               # V module metadata
```

## Configuration

Most gameplay values are set in `Game.init()` and the `Agent` implementation in `main.v`. Useful values to experiment with include:

- `rows` and `columns` for board size
- `screen_width` and `screen_height` for the window size
- `snake.move_interval` for movement speed
- `agent.eps` for the initial exploration rate
- `al` and `f` in `Agent.reward()` for the learning rate and discount factor
- `view_size` in `get_state()` for the agent's local observation window

## License

This project is licensed under the MIT License.
