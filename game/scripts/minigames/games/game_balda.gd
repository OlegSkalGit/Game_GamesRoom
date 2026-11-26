extends MinigameBase

# Classic 5x5 Ukrainian Word Board Game ("Балда" from Балда.html / Балда dic.html):
# Place 1 letter orthogonally next to existing letters, then click a contiguous path to spell a word vs AI!

const GRID_N := 5
const BOARD_ORG := Vector2(22.0, 24.0)
const CELL := 48.0
const SEED_WORDS := ["КАЗКА", "МІСТО", "СОКІЛ", "ВІТЕР", "ОЗЕРО", "ЗІРКА", "КНИГА", "СЛОВО"]
const DICT := [
	"КАЗКА", "МІСТО", "СОКІЛ", "ВІТЕР", "ОЗЕРО", "ЗІРКА", "КНИГА", "СЛОВО", "КІТ", "ЛІС",
	"ДІМ", "НІЧ", "СІК", "ТІК", "МІР", "САД", "ДАР", "СИР", "РІК", "БІК", "СОН", "ТОН",
	"ДУБ", "ЗУБ", "ЖУК", "РАК", "ЛАК", "МАК", "БАК", "ПАР", "ГАЗ", "ЧАС", "ВІК", "РОТ",
	"ГОЛ", "БІЙ", "РІЙ", "ВІЛ", "ДІД", "БАЛ", "ЗАЛ", "ВАЛ", "ЛОВ", "БІГ", "ДИМ", "ЗІР",
	"ВОР", "КУБ", "ДУХ", "РУХ", "КУТ", "ШУМ", "ГОРА", "МОРЕ", "ПОЛЕ", "НЕБО", "РІКА",
	"РУКА", "НОГА", "ОКО", "ВУХО", "СЕЛО", "ДИВО", "СИЛА", "ВІРА", "ВОЛЯ", "ДОЛЯ",
	"ВЕЖА", "РАМА", "ЛУК", "МЕЧ", "ЩИТ", "ТРОН", "КЛЮЧ", "СЕЙФ", "ДАХ", "СХІД", "ЗАХІД",
	"ПОРТ", "МОСТ", "ШТОРМ", "ДОЩ", "СНІГ", "ГРОМ", "ЛІТО", "ЗИМА", "ДЕНЬ", "КАВА", "ЧАЙ",
	"ВИНО", "ХЛІБ", "СІЛЬ", "МЕД", "ГРИБ", "СЛИВА", "ВИШНЯ", "КАВУН", "БАНАН", "ГРУША",
	"ТРАСА", "КОЛО", "ШИНА", "ПЕТЛЯ", "БОЛІД", "СТАРТ", "ФІНІШ", "ІСКРА", "СЯЙВО", "ТІНЬ",
	"ЗВУК", "НОТА", "РИТМ", "ТЕМП", "АРКА", "ЗАМОК", "КАРТА", "ФІШКА", "ЛАД", "КРОК",
	"СОСНА", "ПТАХ", "СОВА", "ЛИС", "ОЛЕНЬ", "КАЧКА", "ТРАВА", "ВОДА", "ЗЕМЛЯ", "ХМАРА",
	"ЗОЛОТО", "БРОНЗА", "КАМІНЬ", "СКЕЛЯ", "ДОЛИНА", "КУБОК", "ПРАПОР", "СКАРБ", "САПФІР",
	"ВОГОНЬ", "МОРОЗ", "РАНОК", "ВЕЧІР", "ОСІНЬ", "ВЕСНА", "ДРУГ", "СЛУХ", "СВІТ", "КОТ",
	"ЛАПА", "ХВІСТ", "РОГИ", "КРИЛО", "ДЗЬОБ", "ГІЛКА", "ЛИСТ", "КОРІНЬ", "ПЛОД", "ЦВІТ",
	"МАМА", "ТАТО", "БРАТ", "СИН", "ОРАЧ", "МОСТ", "РОСА", "ТУМАН", "ГІСТЬ", "ЦАР", "ПАН",
	"ТОРТ", "СУП", "КАША", "БОРЩ", "СИР", "МЯСО", "РИБА", "ІКРА", "КОРА", "БОРТ", "ВАЗА",
	"СТОЛ", "ЛАВА", "ЛІЖКО", "ВІКНО", "ДВЕРІ", "СТІНА", "СТЕЛЯ", "ПІДВАЛ", "ГОРИЩЕ", "БІР"
]
const UKR_KEYS := "АБВГҐДЕЄЖЗИІЇЙКЛМНОПРСТУФХЦЧШЩЬЮЯ"

const BTN_SUBMIT := Rect2(290, 290, 154, 36)
const BTN_CANCEL := Rect2(454, 290, 162, 36)
const BTN_PASS := Rect2(290, 336, 326, 34)

var _board: Array[String] = [] # 25 chars ("" = empty)
var _used: Dictionary = {}
var _p_score: int = 0
var _ai_score: int = 0
var _placed_idx: int = -1
var _path: Array[int] = []
var _last_ai_word: String = ""
var _msg: String = ""


func get_game_title() -> String:
	return "Балда"


func get_controls_hint() -> String:
	return "1) Клік по сусідній порожній клітинці й літері  2) Клік по літерах слова -> Enter/Здати | Backspace — відміна"


func reset_game() -> void:
	_board.clear()
	for _i: int in range(25):
		_board.append("")
	_used.clear()
	var seed_w: String = SEED_WORDS[randi() % SEED_WORDS.size()]
	for c: int in range(5):
		_board[2 * 5 + c] = seed_w[c]
	_used[seed_w] = true
	_p_score = 0
	_ai_score = 0
	_placed_idx = -1
	_path.clear()
	_last_ai_word = ""
	_msg = "Початкове слово: %s. Оберіть клітинку!" % seed_w
	super.reset_game()
	status_changed.emit("Ви %d : %d Бот | %s" % [_p_score, _ai_score, _msg])
	queue_redraw()


func _has_filled_neighbor(idx: int) -> bool:
	var r := idx / 5; var c := idx % 5
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var rr := r + d.y; var cc := c + d.x
		if rr >= 0 and rr < 5 and cc >= 0 and cc < 5 and _board[rr * 5 + cc] != "":
			return true
	return false


func _is_adj(a: int, b: int) -> bool:
	return abs(a / 5 - b / 5) + abs(a % 5 - b % 5) == 1


func _cur_word() -> String:
	var w := ""
	for idx: int in _path:
		w += _board[idx]
	return w


func _kb_rect(i: int) -> Rect2:
	var col := i % 9
	var row := i / 9
	return Rect2(290.0 + float(col) * 36.0, 92.0 + float(row) * 34.0, 32.0, 30.0)


func on_mouse_click(pos: Vector2) -> void:
	if game_over:
		return
	if BTN_SUBMIT.has_point(pos):
		_submit_player_word(); return
	if BTN_CANCEL.has_point(pos):
		_cancel_turn(); return
	if BTN_PASS.has_point(pos):
		_msg = "Пас — хід Бота!"
		_cancel_turn()
		_ai_turn()
		return

	# Check board cells
	for r: int in range(5):
		for c: int in range(5):
			var rect := Rect2(BOARD_ORG + Vector2(float(c), float(r)) * CELL, Vector2(CELL, CELL))
			if rect.has_point(pos):
				var idx := r * 5 + c
				if _board[idx] == "" and _placed_idx < 0:
					if _has_filled_neighbor(idx):
						_placed_idx = idx
						_msg = "Оберіть літеру справа!"
						AudioSfx.play_ui_click()
					else:
						AudioSfx.play_brick_bump()
						_msg = "Клітинка має межувати з літерою!"
					queue_redraw()
					return
				elif _board[idx] != "":
					if _placed_idx < 0 or _board[_placed_idx] == "":
						_msg = "Спочатку впишіть нову літеру!"
						queue_redraw(); return
					if idx in _path:
						if _path[_path.size() - 1] == idx:
							_path.pop_back(); AudioSfx.play_switch()
					elif _path.is_empty() or _is_adj(_path[_path.size() - 1], idx):
						_path.append(idx); AudioSfx.play_ui_click()
					queue_redraw()
					return

	# Check Ukrainian on-screen keyboard
	if _placed_idx >= 0 and _board[_placed_idx] == "":
		for i: int in range(UKR_KEYS.length()):
			if _kb_rect(i).has_point(pos):
				_board[_placed_idx] = UKR_KEYS[i]
				_path.clear()
				_path.append(_placed_idx)
				_msg = "З'єднайте літери слова (клік) і натисніть Здати!"
				AudioSfx.play_puzzle_snap()
				queue_redraw()
				return


func on_key_pressed(phys_key: int) -> void:
	if phys_key == KEY_BACKSPACE:
		_cancel_turn()
	elif phys_key == KEY_ENTER or phys_key == KEY_KP_ENTER:
		_submit_player_word()


func _cancel_turn() -> void:
	if _placed_idx >= 0:
		_board[_placed_idx] = ""
	_placed_idx = -1
	_path.clear()
	AudioSfx.play_switch()
	queue_redraw()


func _submit_player_word() -> void:
	if game_over or _placed_idx < 0 or not (_placed_idx in _path):
		AudioSfx.play_brick_bump(); return
	var w := _cur_word()
	if w.length() < 3:
		_msg = "Слово має бути від 3 літер!"; AudioSfx.play_brick_bump(); queue_redraw(); return
	if _used.has(w):
		_msg = "Слово '%s' вже було!" % w; AudioSfx.play_brick_bump(); queue_redraw(); return
	# Accept any dictionary word cleanly (plus allow creative 4+ words? Better verify dictionary or allow 3+ words if valid in DICT — keep fair against AI!)
	if not (w in DICT):
		_msg = "'%s' відсутнє у словнику гри!" % w
		AudioSfx.play_brick_bump()
		queue_redraw()
		return

	_used[w] = true
	var pts := w.length() * 20
	_p_score += pts
	add_score(pts)
	_placed_idx = -1
	_path.clear()
	_msg = "Ви склали: %s (+%d)" % [w, pts]
	AudioSfx.play_coin()
	_ai_turn()


func _ai_turn() -> void:
	if not ("" in _board):
		_finish_game(); return
	# Search dictionary for any unused word fitable by adding 1 letter adjacent to existing board
	var best_w := ""
	var best_cell := -1
	var best_ch := ""
	for cand: String in DICT:
		if _used.has(cand) or cand.length() <= best_w.length():
			continue
		var fit := _find_ai_placement(cand)
		if int(fit["cell"]) >= 0:
			best_w = cand
			best_cell = int(fit["cell"])
			best_ch = str(fit["ch"])
	if best_cell >= 0:
		_board[best_cell] = best_ch
		_used[best_w] = true
		var pts := best_w.length() * 20
		_ai_score += pts
		_last_ai_word = "%s (+%d)" % [best_w, pts]
	else:
		_last_ai_word = "Пас"
	if not ("" in _board):
		_finish_game()
	else:
		status_changed.emit("Ви %d : %d Бот | Бот: %s" % [_p_score, _ai_score, _last_ai_word])
	queue_redraw()


func _find_ai_placement(word: String) -> Dictionary:
	# Quick DFS from every cell allowing at most 1 blank insertion
	for r: int in range(5):
		for c: int in range(5):
			var idx := r * 5 + c
			var b_ch := _board[idx]
			if b_ch == word[0] or (b_ch == "" and _has_filled_neighbor(idx)):
				var res := _dfs_word(word, 0, idx, [idx], idx if b_ch == "" else -1, word[0] if b_ch == "" else "")
				if int(res["cell"]) >= 0:
					return res
	return {"cell": -1, "ch": ""}


func _dfs_word(w: String, wi: int, cur: int, vis: Array, ins_cell: int, ins_ch: String) -> Dictionary:
	if wi == w.length() - 1:
		return {"cell": ins_cell, "ch": ins_ch} if ins_cell >= 0 else {"cell": -1, "ch": ""}
	var r := cur / 5; var c := cur % 5
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var rr := r + d.y; var cc := c + d.x
		if rr < 0 or rr >= 5 or cc < 0 or cc >= 5: continue
		var ni := rr * 5 + cc
		if ni in vis: continue
		var nxt := _board[ni]
		var target := w[wi + 1]
		if nxt == target:
			var r1 := _dfs_word(w, wi + 1, ni, vis + [ni], ins_cell, ins_ch)
			if int(r1["cell"]) >= 0: return r1
		elif nxt == "" and ins_cell < 0 and _has_filled_neighbor(ni):
			var r2 := _dfs_word(w, wi + 1, ni, vis + [ni], ni, target)
			if int(r2["cell"]) >= 0: return r2
	return {"cell": -1, "ch": ""}


func _finish_game() -> void:
	game_over = true
	if _p_score >= _ai_score:
		AudioSfx.play_fanfare()
		add_score(150)
		status_changed.emit("ФІНАЛ: ВИ ПЕРЕМОГЛИ %d : %d! | R — заново" % [_p_score, _ai_score])
	else:
		AudioSfx.play_hit()
		status_changed.emit("ФІНАЛ: Бот переміг %d : %d | R — реванш" % [_ai_score, _p_score])


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.07, 0.09, 0.12))
	var f := ThemeDB.fallback_font
	for r: int in range(5):
		for c: int in range(5):
			var idx := r * 5 + c
			var rect := Rect2(BOARD_ORG + Vector2(float(c), float(r)) * CELL, Vector2(CELL, CELL)).grow(-2.5)
			var bg := Color(0.14, 0.18, 0.24)
			if idx == _placed_idx: bg = Color(0.18, 0.42, 0.26)
			elif idx in _path: bg = Color(0.22, 0.36, 0.56)
			draw_rect(rect, bg)
			draw_rect(rect, Color(0.95, 0.80, 0.28) if idx in _path else Color(0.35, 0.42, 0.52), false, 1.8)
			if _board[idx] != "":
				draw_string(f, Vector2(rect.position.x, rect.position.y + 31), _board[idx], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 22, Color.WHITE)

	draw_string(f, Vector2(22, 294), "Слово: " + _cur_word(), HORIZONTAL_ALIGNMENT_LEFT, 250, 17, Color(0.32, 0.96, 0.62))
	draw_string(f, Vector2(22, 322), _msg, HORIZONTAL_ALIGNMENT_LEFT, 250, 12, Color(0.92, 0.88, 0.72))
	draw_string(f, Vector2(22, 352), "Рахунок: Ви %d — %d Бот" % [_p_score, _ai_score], HORIZONTAL_ALIGNMENT_LEFT, 250, 15, Color(0.98, 0.84, 0.34))

	draw_string(f, Vector2(290, 44), "АЛФАВІТ (для обраної клітинки)", HORIZONTAL_ALIGNMENT_CENTER, 326, 15, Color(0.98, 0.84, 0.34))
	draw_string(f, Vector2(290, 68), "Останнє слово Бота: %s" % (_last_ai_word if _last_ai_word != "" else "—"), HORIZONTAL_ALIGNMENT_CENTER, 326, 13, Color(0.76, 0.84, 0.88))
	for i: int in range(UKR_KEYS.length()):
		MinigameBase.draw_ui_btn(self, _kb_rect(i), UKR_KEYS[i], _placed_idx >= 0 and _board[_placed_idx] == "")

	MinigameBase.draw_ui_btn(self, BTN_SUBMIT, "Здати слово [Enter]", _cur_word().length() >= 3 and not game_over, Color(0.24, 0.88, 0.46))
	MinigameBase.draw_ui_btn(self, BTN_CANCEL, "Відміна [Bksp]", _placed_idx >= 0 and not game_over, Color(0.86, 0.52, 0.24))
	MinigameBase.draw_ui_btn(self, BTN_PASS, "Пропустити хід (Пас)", not game_over)
