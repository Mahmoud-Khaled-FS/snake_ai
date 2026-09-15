module raylib

#include <raylib.h>
#flag -lraylib

struct C.Vector2 {
	x f32
	y f32
}
pub type Vector2 = C.Vector2

struct C.Vector3 {
	x f32
	y f32
	z f32
}
pub type Vector3 = C.Vector3

struct C.Vector4 {
	x f32
	y f32
	z f32
	w f32
}
pub type Vector4 = C.Vector4

struct C.Rectangle {
	x f32
	y f32
	width f32
	height f32
}
pub type Rectangle = C.Rectangle

struct C.Color {
	r u8
	g u8
	b u8
	a u8
}
pub type Color = C.Color

struct C.Camera2D {
	offset Vector2
	target Vector2
	rotation f32
	zoom f32
}
pub type Camera2D = C.Camera2D

fn C.InitWindow(int, int, &char)
@[inline]
pub fn init_window(width int, height int, title string) {
	C.InitWindow(width, height, &char(title.str))
}

fn C.CloseWindow()
@[inline]
pub fn close_window() {
	C.CloseWindow()
}

fn C.WindowShouldClose() bool
@[inline]
pub fn window_should_close() bool {
	return C.WindowShouldClose()
}

fn C.BeginDrawing()
@[inline]
pub fn begin_drawing() {
	C.BeginDrawing()
}

fn C.EndDrawing()
@[inline]
pub fn end_drawing() {
	C.EndDrawing()
}

fn C.ClearBackground(Color)
@[inline]
pub fn clear_background(color Color) {
	C.ClearBackground(color)
}

fn C.DrawRectangle(int, int, int, int, Color)
@[inline]
pub fn draw_rectangle(pos_x int, pos_y int, width int, height int, color Color) {
	C.DrawRectangle(pos_x, pos_y, width, height, color)
}

fn C.BeginMode2D(Camera2D)
@[inline]
pub fn begin_mode_2d(camera2d Camera2D) {
	C.BeginMode2D(camera2d)
}

fn C.EndMode2D()
@[inline]
pub fn end_mode_2d() {
	C.EndMode2D()
}

fn C.SetTargetFPS(int)
@[inline]
pub fn set_target_fps(fps int){
	C.SetTargetFPS(fps)
}

fn C.GetFrameTime() f32
@[inline]
pub fn get_frame_time() f32 {
	return C.GetFrameTime()
}

fn C.GetKeyPressed() int
@[inline]
pub fn get_key_pressed() int {
	return C.GetKeyPressed()
}

fn C.DrawText(&char, int, int, int, Color)
@[inline]
pub fn draw_text(text string, pos_x int, pos_y int, font_size int, color Color) {
	C.DrawText(&char(text.str), pos_x, pos_y, font_size, color)
}

pub enum KeyboardKey {
	key_null				= 0
	key_space       = 32
	key_r						= 82
	key_right				= 262
	key_left        = 263
	key_down				= 264
	key_up          = 265
}