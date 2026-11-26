extends MinigameBase

# Classic 8x8 Corners (Уголки, 3x3=9 pieces each) vs Smart BFS Multi-Hop AI!
const CELL := 44.0
const OX := 52.0
const OY := 24.0

var _board: Array = [] # 0=empty, 1=Player(bottom-left), -1=AI(top-right)
var _turn: int = 1
var _selected: Vector2i = Vector2i(-1, -1)
var _reachable: Array[Vector2i] = []
var _turns_count: int = 0
var _ai_timer: float = 0.0
var _banner: String = ""


func get_game_title() -> String:
	return "Уголки (проти ШІ)"


func get_controls_hint() -> String:
	return "ЛКМ — переставити фішку у протилежний кут (стрибки ланцюжком!) | R — заново | Esc — вийти"


func reset_game() -> void:
	_board = []
	for r in range(8):
		var row := []
		for c in range(8):
			if r <= 2 and c >= 5: row.append(-1) # AI home (top-right)
			elif r >= 5 and c <= 2: row.append(1) # Player home (bottom-left)
			else: row.append(0)
		_board.append(row)
	_turn = 1; _selected = Vector2i(-1, -1); _reachable.clear()
	_turns_count = 0; _ai_timer = 0.0; _banner = ""
	super.reset_game()
	status_changed.emit("Ваш хід — займіть верхній правий кут!")


func _in_b(r: int, c: int) -> bool:
	return r >= 0 and r < 8 and c >= 0 and c < 8


func _get_moves_from(b: Array, start: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var seen: Dictionary = {start: true}
	var dirs: Array[Vector2i] = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	# 1-tile orthogonal steps
	for d in dirs:
		var nr := start.y + d.y; var nc := start.x + d.x
		if _in_b(nr, nc) and int(b[nr][nc]) == 0:
			out.append(Vector2i(nc, nr))
	# Multi-hop orthogonal jump BFS over any piece!
	var q: Array[Vector2i] = [start]
	while not q.is_empty():
		var cur: Vector2i = q.pop_front()
		for d in dirs:
			var mr := cur.y + d.y; var mc := cur.x + d.x
			var jr := cur.y + d.y * 2; var jc := cur.x + d.x * 2
			var jp := Vector2i(jc, jr)
			if _in_b(jr, jc) and int(b[mr][mc]) != 0 and int(b[jr][jc]) == 0 and not seen.has(jp):
				seen[jp] = true
				out.append(jp)
				q.append(jp)
	return out


func _check_win(b: Array, side: int) -> bool:
	if side == 1:
		for r in range(0, 3):
			for c in range(5, 8):
				if int(b[r][c]) != 1: return false
		return true
	else:
		for r in range(5, 8):
			for c in range(0, 3):
				if int(b[r][c]) != -1: return false
		return true


func _do_move(from_p: Vector2i, to_p: Vector2i) -> void:
	_board[to_p.y][to_p.x] = _board[from_p.y][from_p.x]
	_board[from_p.y][from_p.x] = 0
	AudioSfx.play_tetris_move()
	if _turn == 1:
		_turns_count += 1
		var gain := (from_p.y - to_p.y) + (to_p.x - from_p.x)
		if gain > 0: add_score(gain * 5)

	if _check_win(_board, _turn):
		game_over = true
		if _turn == 1:
			add_score(500); AudioSfx.play_fanfare()
			_banner = "ПЕРЕМОГА ЗА %d ХОДІВ!" % _turns_count
		else:
			AudioSfx.play_hit()
			_banner = "ШІ ЗІБРАВ КУТ ПЕРШИМ!"
		status_changed.emit(_banner)
		queue_redraw()
		return

	_turn = -_turn
	_selected = Vector2i(-1, -1)
	_reachable.clear()
	if _turn == -1:
		_ai_timer = 0.25
		status_changed.emit("Хід суперника...")
	else:
		status_changed.emit("Ваш хід (ходів: %d)" % _turns_count)
	queue_redraw()


func _ai_move() -> void:
	var best_score := -999999.0
	var best_f := Vector2i(-1, -1); var best_t := Vector2i(-1, -1)
	var goal := Vector2(0.5, 6.5)
	for r in range(8):
		for c in range(8):
			if int(_board[r][c]) != -1: continue
			var fp := Vector2i(c, r)
			var dests := _get_moves_from(_board, fp)
			for dp in dests:
				var cur_d := Vector2(fp).distance_to(goal)
				var new_d := Vector2(dp).distance_to(goal)
				var sc := (cur_d - new_d) * 100.0 + float(dp.y - dp.x) * 6.0 + randf() * 2.0
				if r >= 5 and c <= 2 and (dp.y < 5 or dp.x > 2):
					sc -= 120.0
				if sc > best_score:
					best_score = sc; best_f = fp; best_t = dp
	if best_f.x >= 0:
		_do_move(best_f, best_t)


func step_game(delta: float) -> void:
	if game_over: return
	if _turn == -1:
		_ai_timer -= delta
		if _ai_timer <= 0.0:
			_ai_move()


func on_mouse_click(pos: Vector2) -> void:
	if game_over or _turn != 1: return
	var gc := int((pos.x - OX) / CELL)
	var gr := int((pos.y - OY) / CELL)
	if not _in_b(gr, gc): return
	var clicked := Vector2i(gc, gr)
	if _reachable.has(clicked) and _selected.x >= 0:
		_do_move(_selected, clicked)
		return
	if int(_board[gr][gc]) == 1:
		_selected = clicked
		_reachable = _get_moves_from(_board, _selected)
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.08, 0.11, 0.09))
	draw_rect(Rect2(OX - 8, OY - 8, CELL * 8 + 16, CELL * 8 + 16), Color(0.24, 0.16, 0.10))
	draw_rect(Rect2(OX - 8, OY - 8, CELL * 8 + 16, CELL * 8 + 16), Color(0.75, 0.58, 0.24), false, 2.0)

	for r in range(8):
		for c in range(8):
			var sq := Rect2(OX + c * CELL, OY + r * CELL, CELL, CELL)
			var col := Color(0.84, 0.80, 0.70) if (r + c) % 2 == 0 else Color(0.34, 0.42, 0.36)
			if r <= 2 and c >= 5: col = col.lerp(Color(0.95, 0.72, 0.20), 0.22)
			elif r >= 5 and c <= 2: col = col.lerp(Color(0.22, 0.55, 0.90), 0.22)
			if Vector2i(c, r) == _selected: col = Color(0.28, 0.72, 0.44)
			draw_rect(sq, col)

			var v := int(_board[r][c])
			if v != 0:
				var ctr := sq.get_center()
				var pc := Color(0.95, 0.75, 0.20) if v == 1 else Color(0.22, 0.56, 0.92)
				draw_circle(ctr + Vector2(1.5, 2.5), 15.0, Color(0, 0, 0, 0.30))
				draw_circle(ctr, 15.0, pc)
				draw_arc(ctr, 10.0, 0, TAU, 18, pc.darkened(0.25), 2.0)
				draw_arc(ctr, 15.0, 0, TAU, 22, Color(0.14, 0.12, 0.10), 1.5)

	for dp in _reachable:
		var ctr := Vector2(OX + dp.x * CELL + CELL * 0.5, OY + dp.y * CELL + CELL * 0.5)
		draw_circle(ctr, 6.5, Color(0.24, 0.92, 0.40, 0.85))

	var f := ThemeDB.fallback_font
	draw_rect(Rect2(432, 24, 188, 352), Color(0.06, 0.08, 0.07))
	draw_rect(Rect2(432, 24, 188, 352), Color(0.68, 0.52, 0.22), false, 1.8)
	draw_string(f, Vector2(446, 56), "УГОЛКИ", HORIZONTAL_ALIGNMENT_CENTER, 160, 22, Color(0.96, 0.84, 0.42))
	draw_string(f, Vector2(446, 98), "Ходів: %d" % _turns_count, HORIZONTAL_ALIGNMENT_CENTER, 160, 16, Color(0.86, 0.94, 0.86))
	draw_string(f, Vector2(446, 138), "Ваша ціль:\nверхній правий кут", HORIZONTAL_ALIGNMENT_LEFT, 160, 13, Color(0.95, 0.78, 0.30))
	draw_game_over_banner(_banner + " — [R] Знову")
