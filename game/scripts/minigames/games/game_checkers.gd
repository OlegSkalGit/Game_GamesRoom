extends MinigameBase

# Full Russian/Classic 8x8 Checkers vs AI:
# - Mandatory captures, multi-jump capture chains, flying Kings (Damka)!
# Piece values: 1=White Man, 2=White King, -1=Black Man, -2=Black King
const CELL := 44.0
const OX := 52.0
const OY := 24.0

var _board: Array = []
var _turn: int = 1 # 1=Player(White), -1=AI(Black)
var _selected: Vector2i = Vector2i(-1, -1)
var _chain_pos: Vector2i = Vector2i(-1, -1)
var _legal: Array[Dictionary] = []
var _ai_timer: float = 0.0
var _banner: String = ""


func get_game_title() -> String:
	return "Шашки (проти ШІ)"


func get_controls_hint() -> String:
	return "ЛКМ — обрати шашку й бити/ходити (биття обов'язкове) | R — заново | Esc — вийти"


func reset_game() -> void:
	_board = []
	for r in range(8):
		var row := []
		for c in range(8):
			if (r + c) % 2 == 1:
				if r < 3: row.append(-1)
				elif r > 4: row.append(1)
				else: row.append(0)
			else:
				row.append(0)
		_board.append(row)
	_turn = 1; _selected = Vector2i(-1, -1); _chain_pos = Vector2i(-1, -1)
	_ai_timer = 0.0; _banner = ""
	_refresh_legal()
	super.reset_game()
	status_changed.emit("Ваш хід (Світлі)")


func _in_b(r: int, c: int) -> bool:
	return r >= 0 and r < 8 and c >= 0 and c < 8


func _captures_for_piece(b: Array, r: int, c: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var p := int(b[r][c])
	if p == 0: return out
	var side := 1 if p > 0 else -1
	var is_k := absi(p) == 2

	for d: Vector2i in [Vector2i(1,1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(-1,-1)]:
		if not is_k:
			var mr := r + d.y; var mc := c + d.x
			var lr := r + d.y * 2; var lc := c + d.x * 2
			if _in_b(lr, lc) and int(b[mr][mc]) * side < 0 and int(b[lr][lc]) == 0:
				out.append({"from": Vector2i(c, r), "to": Vector2i(lc, lr), "cap": Vector2i(mc, mr)})
		else:
			var nr := r + d.y; var nc := c + d.x
			var enemy := Vector2i(-1, -1)
			while _in_b(nr, nc):
				var v := int(b[nr][nc])
				if v != 0:
					if v * side > 0 or enemy.x >= 0:
						break
					enemy = Vector2i(nc, nr)
				elif enemy.x >= 0:
					out.append({"from": Vector2i(c, r), "to": Vector2i(nc, nr), "cap": enemy})
				nr += d.y; nc += d.x
	return out


func _all_moves_for(b: Array, side: int, only_pos: Vector2i = Vector2i(-1, -1)) -> Array[Dictionary]:
	var caps: Array[Dictionary] = []
	var steps: Array[Dictionary] = []
	for r in range(8):
		for c in range(8):
			if only_pos.x >= 0 and Vector2i(c, r) != only_pos: continue
			var p := int(b[r][c])
			if p * side <= 0: continue
			caps.append_array(_captures_for_piece(b, r, c))

	if not caps.is_empty():
		return caps
	if only_pos.x >= 0:
		return []

	for r in range(8):
		for c in range(8):
			var p := int(b[r][c])
			if p * side <= 0: continue
			var is_k := absi(p) == 2
			if not is_k:
				var dr := -1 if side == 1 else 1
				for dc in [-1, 1]:
					if _in_b(r + dr, c + dc) and int(b[r + dr][c + dc]) == 0:
						steps.append({"from": Vector2i(c, r), "to": Vector2i(c + dc, r + dr), "cap": Vector2i(-1, -1)})
			else:
				for d: Vector2i in [Vector2i(1,1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(-1,-1)]:
					var nr := r + d.y; var nc := c + d.x
					while _in_b(nr, nc) and int(b[nr][nc]) == 0:
						steps.append({"from": Vector2i(c, r), "to": Vector2i(nc, nr), "cap": Vector2i(-1, -1)})
						nr += d.y; nc += d.x
	return steps


func _refresh_legal() -> void:
	_legal = _all_moves_for(_board, _turn, _chain_pos)


func _apply_step(mv: Dictionary) -> void:
	var f: Vector2i = mv["from"]; var t: Vector2i = mv["to"]; var cap: Vector2i = mv["cap"]
	var p := int(_board[f.y][f.x])
	_board[t.y][t.x] = p
	_board[f.y][f.x] = 0
	if p == 1 and t.y == 0: _board[t.y][t.x] = 2
	elif p == -1 and t.y == 7: _board[t.y][t.x] = -2

	if cap.x >= 0:
		_board[cap.y][cap.x] = 0
		if _turn == 1: add_score(50)
		AudioSfx.play_brick_break()
		var more := _captures_for_piece(_board, t.y, t.x)
		if not more.is_empty():
			_chain_pos = t
			_selected = t
			_refresh_legal()
			if _turn == -1: _ai_timer = 0.25
			queue_redraw()
			return
	else:
		AudioSfx.play_tetris_move()

	_chain_pos = Vector2i(-1, -1)
	_selected = Vector2i(-1, -1)
	_turn = -_turn
	_refresh_legal()
	if _legal.is_empty():
		game_over = true
		if _turn == -1:
			add_score(400); AudioSfx.play_fanfare()
			_banner = "ВИ ПЕРЕМОГЛИ!"
		else:
			AudioSfx.play_hit()
			_banner = "ПЕРЕМІГ ШІ!"
		status_changed.emit(_banner)
	elif _turn == -1:
		_ai_timer = 0.30
		status_changed.emit("Хід комп'ютера...")
	else:
		status_changed.emit("Ваш хід (Світлі)")
	queue_redraw()


func _ai_score(b: Array) -> int:
	var sc := 0
	for r in range(8):
		for c in range(8):
			var v := int(b[r][c])
			if v == 1: sc -= 100 + (7 - r) * 5
			elif v == 2: sc -= 280
			elif v == -1: sc += 100 + r * 5
			elif v == -2: sc += 280
	return sc


func _pick_ai_move() -> Dictionary:
	if _legal.is_empty(): return {}
	var best_mv: Dictionary = _legal[0]
	var best_val := -999999
	var cands := _legal.duplicate()
	cands.shuffle()
	for mv: Dictionary in cands:
		var nb := []
		for r in range(8): nb.append((_board[r] as Array).duplicate())
		var f: Vector2i = mv["from"]; var t: Vector2i = mv["to"]; var cap: Vector2i = mv["cap"]
		var p := int(nb[f.y][f.x])
		nb[t.y][t.x] = p; nb[f.y][f.x] = 0
		if cap.x >= 0: nb[cap.y][cap.x] = 0
		if p == -1 and t.y == 7: nb[t.y][t.x] = -2
		var val := _ai_score(nb)
		# Check worst reply by player
		var replies := _all_moves_for(nb, 1)
		var min_rep := val
		for rmv in replies:
			var nb2 := []
			for r2 in range(8): nb2.append((nb[r2] as Array).duplicate())
			var rf: Vector2i = rmv["from"]; var rt: Vector2i = rmv["to"]; var rcap: Vector2i = rmv["cap"]
			nb2[rt.y][rt.x] = nb2[rf.y][rf.x]; nb2[rf.y][rf.x] = 0
			if rcap.x >= 0: nb2[rcap.y][rcap.x] = 0
			min_rep = mini(min_rep, _ai_score(nb2))
		if min_rep > best_val:
			best_val = min_rep
			best_mv = mv
	return best_mv


func step_game(delta: float) -> void:
	if game_over: return
	if _turn == -1:
		_ai_timer -= delta
		if _ai_timer <= 0.0:
			var mv := _pick_ai_move()
			if not mv.is_empty():
				_apply_step(mv)


func on_mouse_click(pos: Vector2) -> void:
	if game_over or _turn != 1: return
	var gc := int((pos.x - OX) / CELL)
	var gr := int((pos.y - OY) / CELL)
	if not _in_b(gr, gc): return
	for mv in _legal:
		if (mv["from"] as Vector2i) == _selected and (mv["to"] as Vector2i) == Vector2i(gc, gr):
			_apply_step(mv)
			return
	if _chain_pos.x < 0 and int(_board[gr][gc]) > 0:
		_selected = Vector2i(gc, gr)
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.10, 0.07, 0.05))
	draw_rect(Rect2(OX - 8, OY - 8, CELL * 8 + 16, CELL * 8 + 16), Color(0.28, 0.16, 0.09))
	draw_rect(Rect2(OX - 8, OY - 8, CELL * 8 + 16, CELL * 8 + 16), Color(0.75, 0.58, 0.24), false, 2.0)

	var w_cnt := 0; var b_cnt := 0
	for r in range(8):
		for c in range(8):
			var sq := Rect2(OX + c * CELL, OY + r * CELL, CELL, CELL)
			var col := Color(0.86, 0.76, 0.58) if (r + c) % 2 == 0 else Color(0.32, 0.18, 0.10)
			if Vector2i(c, r) == _selected: col = Color(0.28, 0.62, 0.36)
			draw_rect(sq, col)

			var v := int(_board[r][c])
			if v != 0:
				if v > 0: w_cnt += 1
				else: b_cnt += 1
				var ctr := sq.get_center()
				var base_c := Color(0.94, 0.90, 0.80) if v > 0 else Color(0.68, 0.12, 0.14)
				draw_circle(ctr + Vector2(1.5, 2.5), 16.0, Color(0, 0, 0, 0.32))
				draw_circle(ctr, 16.0, base_c)
				draw_arc(ctr, 11.5, 0, TAU, 20, base_c.darkened(0.30), 2.0)
				draw_arc(ctr, 16.0, 0, TAU, 24, Color(0.22, 0.14, 0.10), 1.6)
				if absi(v) == 2:
					draw_circle(ctr, 6.0, Color(0.96, 0.80, 0.20))

	for mv in _legal:
		if _selected.x < 0 or (mv["from"] as Vector2i) == _selected:
			var t: Vector2i = mv["to"]
			var ctr := Vector2(OX + t.x * CELL + CELL * 0.5, OY + t.y * CELL + CELL * 0.5)
			if _selected.x >= 0:
				draw_circle(ctr, 7.0, Color(0.22, 0.85, 0.38, 0.85))
			elif (mv["cap"] as Vector2i).x >= 0:
				var fpos: Vector2i = mv["from"]
				draw_rect(Rect2(OX + fpos.x * CELL + 2, OY + fpos.y * CELL + 2, CELL - 4, CELL - 4), Color(0.95, 0.78, 0.22), false, 2.5)

	var f := ThemeDB.fallback_font
	draw_rect(Rect2(432, 24, 188, 352), Color(0.08, 0.06, 0.05))
	draw_rect(Rect2(432, 24, 188, 352), Color(0.68, 0.52, 0.22), false, 1.8)
	draw_string(f, Vector2(446, 56), "ШАШКИ", HORIZONTAL_ALIGNMENT_CENTER, 160, 22, Color(0.96, 0.84, 0.42))
	draw_string(f, Vector2(446, 98), "Ваш хід (Світлі)" if _turn == 1 else "Думає ШІ...", HORIZONTAL_ALIGNMENT_CENTER, 160, 15, Color(0.86, 0.94, 0.86))
	draw_string(f, Vector2(446, 142), "Ваші шашки: %d" % w_cnt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.94, 0.90, 0.80))
	draw_string(f, Vector2(446, 168), "ШІ шашки: %d" % b_cnt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.88, 0.36, 0.36))
	draw_game_over_banner(_banner + " — [R] Знову")
