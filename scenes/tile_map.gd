extends Node2D

@onready var board_layer: TileMapLayer = $board
@onready var active_layer: TileMapLayer = $active
@onready var HUD: CanvasLayer = $HUD

#tetrominoes
var I := [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)]
var T := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]
var O := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
var Z := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)]
var S := [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)]
var L := [Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]
var J := [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]


var shapes := [I, T, O, Z, S, J, L]
var bag1 := shapes.duplicate()

#grid variables
const COLS : int = 10
const ROWS : int = 20

#movement variables
const directions := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]
var steps : Array
const steps_req : int = 50
const start_pos := Vector2i(4, 0)
var cur_pos : Vector2i
var speed : float
const ACCEL : float = 0.25

#game piece variables
var piece_type
var next_piece_type
var rotation_index : int = 0
var active_piece : Array

#game variables
var score : int
const REWARD : int = 100
var game_running : bool

#tilemap variables
var tile_id : int = 0
var piece_atlas : Vector2i
var next_piece_atlas : Vector2i



# Called when the node enters the scene tree for the first time.
func _ready(seed=1234):
	seed(1234)
	new_game()
	HUD.get_node("StartButton").pressed.connect(new_game)

func new_game():
	#reset variables
	score = 0
	speed = 1.0
	game_running = true
	steps = [0, 0, 0] #0:left, 1:right, 2:down
	HUD.get_node("GameOverLabel").hide()
	#clear everything
	clear_piece()
	clear_board()
	clear_panel()
	piece_type = pick_piece()
	piece_atlas = Vector2i(bag1.find(piece_type), 0)
	next_piece_type = pick_piece()
	next_piece_atlas = Vector2i(bag1.find(next_piece_type), 0)
	create_piece()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# HAVE TO MAKE A NEW CONTROLLER SCRIPT THAT DEALS WITH INPUTS // je m'en occupe comme je l'ai fait avant
	if game_running:
		if Input.is_action_pressed("ui_left"):
			steps[0] += 10
		elif Input.is_action_pressed("ui_right"):
			steps[1] += 10
		elif Input.is_action_pressed("ui_down"):
			steps[2] += 10

		
		#apply downward movement every frame
		steps[2] += speed
		#move the piece
		for i in range(steps.size()):
			if steps[i] > steps_req:
				move_piece(directions[i])
				steps[i] = 0

func pick_piece():
	var piece
	if not shapes.is_empty():
		shapes.shuffle()
		piece = shapes.pop_front()
	else:
		shapes = bag1.duplicate()
		shapes.shuffle()
		piece = shapes.pop_front()
	return piece

func create_piece():
	#reset variables
	steps = [0, 0, 0] #0:left, 1:right, 2:down
	cur_pos = start_pos
	active_piece = piece_type
	draw_piece(active_piece, cur_pos, piece_atlas)
	#show next piece
	draw_piece(next_piece_type, Vector2i(15, 6), next_piece_atlas)

func clear_piece():
	for i in active_piece:
		active_layer.erase_cell(cur_pos + i)

func draw_piece(piece, pos, atlas):
	for i in piece:
		active_layer.set_cell(pos + i, tile_id, atlas)



func move_piece(dir):
	if can_move(dir):
		clear_piece()
		cur_pos += dir
		draw_piece(active_piece, cur_pos, piece_atlas)
	else:
		if dir == Vector2i.DOWN:
			land_piece()
			check_rows()
			piece_type = next_piece_type
			piece_atlas = next_piece_atlas
			next_piece_type = pick_piece()
			next_piece_atlas = Vector2i(bag1.find(next_piece_type), 0)
			clear_panel()
			create_piece()
			check_game_over()

func can_move(dir):
	#check if there is space to move
	var cm = true
	for i in active_piece:
		if not is_free(i + cur_pos + dir):
			cm = false
	return cm



func is_free(pos):
	return board_layer.get_cell_source_id(pos) == -1

func land_piece():
	#remove each segment from the active layer and move to board layer
	for i in active_piece:
		active_layer.erase_cell(cur_pos + i)
		board_layer.set_cell(cur_pos + i, tile_id, piece_atlas)

func clear_panel():
	for i in range(14, 19):
		for j in range(5, 9):
			active_layer.erase_cell(Vector2i(i, j))

func check_rows():
	var row : int = ROWS
	while row > 0:
		var count = 0
		for i in range(COLS):
			if not is_free(Vector2i(i + 1, row)):
				count += 1
		#if row is full then erase it
		if count == COLS:
			shift_rows(row)
			score += REWARD
			$HUD.get_node("ScoreLabel").text = "SCORE: " + str(score)
			speed += ACCEL
		else:
			row -= 1

func shift_rows(row): #shift rows down on line clear
	var atlas
	for i in range(row, 1, -1):
		for j in range(COLS):
			atlas = board_layer.get_cell_atlas_coords(Vector2i(j + 1, i - 1))
			if atlas == Vector2i(-1, -1):
				board_layer.erase_cell(Vector2i(j + 1, i))
			else:
				active_layer.set_cell(Vector2i(j + 1, i), tile_id, atlas)

func clear_board():
	for i in range(ROWS):
		for j in range(COLS):
			board_layer.erase_cell(Vector2i(j + 1, i + 1))

func check_game_over():
	for i in active_piece:
		if not is_free(i + cur_pos):
			land_piece()
			$HUD.get_node("GameOverLabel").show()
			game_running = false
