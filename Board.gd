extends Node

func reverse_array(array: Array) -> Array:
	var reversed_array = []
	for i in range(array.size() - 1, -1, -1):
		reversed_array.append(array[i])
	return reversed_array


const BASE = [[0, 0, 0, 0],
			  [0, 0, 0, 0],
			  [0, 0, 0, 0],
			  [0, 0, 0, 0]]

const BOARD_WIDTH  = 4
const BOARD_HEIGHT = 4

var board:Array

const tile_scene = preload("res://Square.tscn")
var graphical_nodes:Array = []


signal onSlide()


func _ready() -> void:
	initialize_board()
	initialize_grapical_board()
	spawn()
	update_graphical_board()

var swipe_start: Vector2 = Vector2.ZERO
var swipe_threshold: float = 50.0  # Минимальное расстояние для распознавания свайпа

func _input(event):
	if event is InputEventScreenTouch:
		if event.is_pressed():
			# Запоминаем начальную точку свайпа
			swipe_start = event.position
		else:
			# Определяем направление свайпа при отпускании
			var swipe_end = event.position
			handle_swipe(swipe_start, swipe_end)
	elif event is InputEventScreenDrag:
		# Обрабатываем свайп в реальном времени, если нужно
		pass

func handle_swipe(start: Vector2, end: Vector2):
	var swipe_vector = end - start

	# Если длина свайпа меньше порога, игнорируем
	if swipe_vector.length() < swipe_threshold:
		return

	# Определяем основное направление свайпа
	if abs(swipe_vector.x) > abs(swipe_vector.y):
		if swipe_vector.x > 0:
			move_right()
		else:
			move_left()
	else:
		if swipe_vector.y > 0:
			move_down()
		else:
			move_up()

func move_left():
	for line in board:
		slide_line(line)
	complete_movement()

func move_up():
	var aux_board = [[], [], [], []]
	for col in range(4):
		var line = []
		for row in range(4):
			line.append(board[row][col])
		slide_line(line)
		aux_board[col] = line

	for col in range(4):
		for row in range(4):
			board[row][col] = aux_board[col][row]
	complete_movement()


func move_right():
	for line in board:
		line = reverse_array_custom(line)
		slide_line(line)
		line = reverse_array_custom(line)
	complete_movement()

func move_down():
	var aux_board = [[], [], [], []]
	for col in range(4):
		var line = []
		for row in range(4):
			line.append(board[row][col])
		line = reverse_array_custom(line)
		slide_line(line)
		line = reverse_array_custom(line)
		aux_board[col] = line

	for col in range(4):
		for row in range(4):
			board[row][col] = aux_board[col][row]
	complete_movement()

func reverse_array_custom(array: Array) -> Array:
	var reversed_array = []
	for i in range(array.size() - 1, -1, -1):
		reversed_array.append(array[i])
	return reversed_array


func _process(delta) -> void:
	if Global.game_over:
		if Global.score > Global.max_score:
			Global.max_score = Global.score
		get_tree().change_scene_to_file("res://GameOver.tscn")
		return
		
	if Input.is_action_just_pressed("ui_left"):
		for line in board:
			slide_line(line)
		complete_movement()
	elif Input.is_action_just_pressed("ui_up"):
		var aux_board = [[],[],[],[]]
		for col in range(0, 4):
			var line = []
			for row in range(0, 4):
				line.push_back(board[row][col])
			slide_line(line)
			aux_board[col] = line
		
		for col in range(0, 4):
			for row in range(0, 4):
				board[col][row] = aux_board[row][col]
		complete_movement()
	elif Input.is_action_just_pressed("ui_right"):
		for i in range(board.size()):
			board[i] = reverse_array(board[i])  # Обращаем строку
			slide_line(board[i])               # Двигаем строку
			board[i] = reverse_array(board[i]) # Обращаем обратно
		complete_movement()


	elif Input.is_action_just_pressed("ui_down"):
		var aux_board = [[],[],[],[]]
		for col in range(0, 4):
			var line = []
			for row in range(0, 4):
				line.push_back(board[row][col])
			line = reverse_array(line) # Обратить массив
			slide_line(line)
			line = reverse_array(line) # Вернуть массив в первоначальный порядок
			aux_board[col] = line
		
		for col in range(0, 4):
			for row in range(0, 4):
				board[col][row] = aux_board[row][col]
		complete_movement()

# Завершающая функция для обновления отображения доски
func complete_movement():
	save_state()  # Сохраняем состояние перед движением
	spawn()  # Спавн новой плитки
	update_graphical_board()  # Обновляем отображение
	update_score()  # Обновляем очки
	emit_signal("onSlide")

# Переменные для хранения предыдущих состояний
var saved_board = []  # Сохраняем доску
var saved_score = 0  # Сохраняем очки
var merged_tiles_history = []  # Сохраняем информацию о слиянии плиток

# Сохранение состояния после выполнения каждого действия
func save_state():
	saved_board = []  # Очистить старое состояние
	for row in board:
		saved_board.append(row.duplicate())  # Сохраняем доску
	saved_score = Global.score  # Сохраняем текущие очки
	merged_tiles_history.clear()  # Очищаем список объединённых плиток

# Функция для слияния плиток и сохранения слияния
func merge_tiles_and_save(line: Array, index1: int, index2: int) -> void:
	merged_tiles_history.append(Vector2(index1, line.size() - index1 - 1))  # Сохраняем позицию первой плитки
	merged_tiles_history.append(Vector2(index2, line.size() - index2 - 1))  # Сохраняем позицию второй плитки
	var merged_value = line[index1] * 2  # Суммируем плитки
	line[index1] = merged_value  # Обновляем первую плитку
	line[index2] = 0  # Обнуляем вторую плитку
	Global.score += merged_value  # Добавляем очки

# Отмена последнего действия
func undo_move() -> void:
	if saved_board.size() > 0:  # Если есть сохранённое состояние
		# Восстанавливаем доску из сохранённого состояния
		board = []  # Очистить текущую доску
		for row in saved_board:
			board.append(row.duplicate())
		
		# Восстанавливаем очки
		Global.score = saved_score

		# Восстанавливаем плитки в исходное состояние
		for tile in merged_tiles_history:
			var pos = tile
			var prev_value = 2  # Предположим, что мы восстанавливаем плитки как "2"
			if board[pos.x][pos.y] == 4:
				prev_value = 2
			board[pos.x][pos.y] = prev_value

		# Обновляем отображение доски и очков
		update_graphical_board()
		update_score()



func get_element(pos:Vector2) -> int:
	return board[pos.x][pos.y]


func set_element(pos:Vector2, val:int) -> void:
	board[pos.x][pos.y] = val


#
# Realiza o slide para a esquerda no array
#
func slide_line(line: Array) -> void:
	var result = [0, 0, 0, 0]  # Массив для результата
	var last_index = 0         # Индекс для записи объединённых значений
	
	for i in range(line.size()):
		if line[i] != 0:
			# Если предыдущий элемент совпадает, объединяем
			if result[last_index] == line[i]:
				result[last_index] *= 2
				last_index += 1
			elif result[last_index] == 0:
				result[last_index] = line[i]
			else:
				last_index += 1
				result[last_index] = line[i]
	
	# Обновляем строку на основе результата
	for i in range(line.size()):
		line[i] = result[i]



func is_on_border(element:Vector2, direction:Vector2) -> bool:
	if direction == Vector2.UP:
		return element.y == 0
	elif direction == Vector2.DOWN:
		return element.y == BOARD_HEIGHT - 1
	elif direction == Vector2.LEFT:
		return element.x == 0
	elif direction == Vector2.RIGHT:
		return element.x == BOARD_WIDTH - 1
	else:
		push_warning("Unknown direction")
		return false


func is_equal(el1, el2) -> bool:
	return get_element(el1) == get_element(el2)


func replace(pos:Vector2, val:int) -> void:
	set_element(pos, val)


func get_score() -> int:
	var sum:int = 0
	for line in board:
		for val in line:
			sum += val
	return sum


func update_score() -> void:
	Global.score = get_score()


func spawn() -> void:
	if is_board_full():
		var game_over = true

		# Чек вертикалей
		for i in range(1, BOARD_WIDTH):
			for j in range(0, BOARD_HEIGHT):
				if board[i - 1][j] == board[i][j]:
					game_over = false
					break

		# Чек горизонталей
		for i in range(0, BOARD_WIDTH):
			for j in range(1, BOARD_HEIGHT):
				if board[i][j - 1] == board[i][j]:
					game_over = false
					break

		if game_over:
			Global.game_over = true
	else:
		var rng = RandomNumberGenerator.new()
		rng.randomize()

		# Найти пустую ячейку
		var empty_cells = []
		for row in range(BOARD_HEIGHT):
			for col in range(BOARD_WIDTH):
				if board[row][col] == 0:
					empty_cells.append(Vector2(row, col))

		if empty_cells.size() > 0:
			var pos = empty_cells[rng.randi_range(0, empty_cells.size() - 1)]

			# Установить значение плитки с вероятностью 90% для "2" и 10% для "4"
			var spawned_value = 2 if rng.randi_range(1, 10) <= 9 else 4
			replace(pos, spawned_value)




func is_board_full() -> bool:
	for line in board:
		for number in line:
			if number == 0:
				return false
	return true


func is_occupied(pos:Vector2) -> bool:
	return get_element(pos) > 0


#
# Inicializa o board interno
#
func initialize_board() -> void:
	board = BASE.duplicate(true)


#
# Inicializa o board a ser exibido
#
func initialize_grapical_board() -> void:
	for n in range (0, BOARD_WIDTH * BOARD_HEIGHT):
		var node = tile_scene.instantiate()
		node.set_value(0)
		graphical_nodes.push_front(node)
		$Container/Grid.add_child(node)


#
# Atualiza o board a ser exibido
#
# Функция для обновления графического отображения
func update_graphical_board():
	for i in range(0, BOARD_WIDTH * BOARD_HEIGHT):
		graphical_nodes[BOARD_WIDTH * BOARD_HEIGHT - (i + 1)].set_value(board[floor(i / BOARD_WIDTH)][i % BOARD_HEIGHT])


# Обработчик кнопки New Game
func _on_NewGame_button_up():
	Global.score = 0  # Сбросить очки
	Global.game_over = false  # Игра продолжается
	initialize_board()  # Инициализируем новую доску
	spawn()  # Спавним новую плитку
	update_graphical_board()  # Обновляем отображение доски
	update_score()  # Обновляем очки



var previous_board: Array = []
var previous_score: int = 0


# Обработчик кнопки UNDO
func _on_UndoButton_button_up():
	undo_move()  # Восстановить состояние доски и очков на одно действие назад
