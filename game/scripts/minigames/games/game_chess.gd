extends MinigameBase

# Full 8x8 Chess vs Alpha-Beta AI (White = Player +1..+6, Black = AI -1..-6)
# 1=Pawn, 2=Knight, 3=Bishop, 4=Rook, 5=Queen, 6=King
const CELL := 44.0
const OX := 52.0
const OY := 24.0
const PIECE_VALS := [0, 100, 320, 330, 500, 900, 20000]

var _board: Array = [] # 8x8 ints
var _turn: int = 1 # 1=White (Player), -1=Black (AI)
var _selected: Vector2i = Vector2i(-1, -1)
var _legal_for_sel: Array[Dictionary] = []
var _last_from: Vector2i = Vector2i(-1, -1)
var _last_to: Vector2i = Vector2i(-1, -1)
var _en_passant: Vector2i = Vector2i(-1, -1)
var _castle_wk: bool = true; var _castle_wq: bool = true
var _castle_bk: bool = true; var _castle_bq: bool = true
var _ai_timer: float = 0.0
var _cap_white: Array[int] = []
var _cap_black: Array[int] = []
var _banner: String = ""


func get_game_title() -> String:
	return "Шахи (проти ШІ)"


func get_controls_hint() -> String:
	return "ЛКМ — обрати фігуру та походити | R — нова партія | Esc — вийти"


func reset_game() -> void:
	_board = [
		[-4, -2, -3, -5, -6, -3, -2, -4],
		[-1, -1, -1, -1, -1, -1, -1, -1],
		[0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0],
		[1, 1, 1, 1, 1, 1, 1, 1],
		[4, 2, 3, 5, 6, 3, 2, 4]
	]
	_turn = 1
	_selected = Vector2i(-1, -1)
	_legal_for_sel.clear()
	_last_from = Vector2i(-1, -1); _last_to = Vector2i(-1, -1)
	_en_passant = Vector2i(-1, -1)
	_castle_wk = true; _castle_wq = true; _castle_bk = true; _castle_bq = true
	_ai_timer = 0.0; _cap_white.clear(); _cap_black.clear(); _banner = ""
	super.reset_game()
	status_changed.emit("Ваш хід (Білі)")


func _clone_board(b: Array) -> Array:
	var nb := []
	for r in range(8):
		nb.append((b[r] as Array).duplicate())
	return nb


func _in_b(r: int, c: int) -> bool:
	return r >= 0 and r < 8 and c >= 0 and c < 8


func _pseudo_moves_for(b: Array, r: int, c: int, ep: Vector2i, cwk: bool, cwq: bool, cbk: bool, cbq: bool) -> Array[Dictionary]:
	var moves: Array[Dictionary] = []
	var p := int(b[r][c])
	if p == 0: return moves
	var side := 1 if p > 0 else -1
	var kind := absi(p)

	match kind:
		1: # Pawn
			var dir := -1 if side == 1 else 1
			var start_r := 6 if side == 1 else 1
			if _in_b(r + dir, c) and int(b[r + dir][c]) == 0:
				moves.append({"from": Vector2i(c, r), "to": Vector2i(c, r + dir), "ep": false, "castle": 0})
				if r == start_r and int(b[r + dir * 2][c]) == 0:
					moves.append({"from": Vector2i(c, r), "to": Vector2i(c, r + dir * 2), "ep": false, "castle": 0})
			for dc: int in [-1, 1]:
				var nc: int = c + dc
				var nr: int = r + dir
				if _in_b(nr, nc):
					var t := int(b[nr][nc])
					if t != 0 and (1 if t > 0 else -1) != side:
						moves.append({"from": Vector2i(c, r), "to": Vector2i(nc, nr), "ep": false, "castle": 0})
					elif Vector2i(nc, nr) == ep:
						moves.append({"from": Vector2i(c, r), "to": Vector2i(nc, nr), "ep": true, "castle": 0})
		2: # Knight
			for off: Vector2i in [Vector2i(-2,-1),Vector2i(-2,1),Vector2i(2,-1),Vector2i(2,1),Vector2i(-1,-2),Vector2i(-1,2),Vector2i(1,-2),Vector2i(1,2)]:
				var nr := r + off.y; var nc := c + off.x
				if _in_b(nr, nc):
					var t := int(b[nr][nc])
					if t == 0 or (1 if t > 0 else -1) != side:
						moves.append({"from": Vector2i(c, r), "to": Vector2i(nc, nr), "ep": false, "castle": 0})
		3, 4, 5: # Bishop / Rook / Queen
			var dirs: Array[Vector2i] = []
			if kind in [3, 5]:
				dirs.append_array([Vector2i(1,1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(-1,-1)])
			if kind in [4, 5]:
				dirs.append_array([Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)])
			for d in dirs:
				var nr := r + d.y; var nc := c + d.x
				while _in_b(nr, nc):
					var t := int(b[nr][nc])
					if t == 0:
						moves.append({"from": Vector2i(c, r), "to": Vector2i(nc, nr), "ep": false, "castle": 0})
					else:
						if (1 if t > 0 else -1) != side:
							moves.append({"from": Vector2i(c, r), "to": Vector2i(nc, nr), "ep": false, "castle": 0})
						break
					nr += d.y; nc += d.x
		6: # King
			for dr: int in [-1, 0, 1]:
				for dc: int in [-1, 0, 1]:
					if dr == 0 and dc == 0: continue
					var nr: int = r + dr; var nc: int = c + dc
					if _in_b(nr, nc):
						var t := int(b[nr][nc])
						if t == 0 or (1 if t > 0 else -1) != side:
							moves.append({"from": Vector2i(c, r), "to": Vector2i(nc, nr), "ep": false, "castle": 0})
			if side == 1 and r == 7 and c == 4:
				if cwk and int(b[7][5]) == 0 and int(b[7][6]) == 0 and int(b[7][7]) == 4:
					if not _is_attacked(b, 7, 4, -1) and not _is_attacked(b, 7, 5, -1) and not _is_attacked(b, 7, 6, -1):
						moves.append({"from": Vector2i(4, 7), "to": Vector2i(6, 7), "ep": false, "castle": 1})
				if cwq and int(b[7][3]) == 0 and int(b[7][2]) == 0 and int(b[7][1]) == 0 and int(b[7][0]) == 4:
					if not _is_attacked(b, 7, 4, -1) and not _is_attacked(b, 7, 3, -1) and not _is_attacked(b, 7, 2, -1):
						moves.append({"from": Vector2i(4, 7), "to": Vector2i(2, 7), "ep": false, "castle": 2})
			elif side == -1 and r == 0 and c == 4:
				if cbk and int(b[0][5]) == 0 and int(b[0][6]) == 0 and int(b[0][7]) == -4:
					if not _is_attacked(b, 0, 4, 1) and not _is_attacked(b, 0, 5, 1) and not _is_attacked(b, 0, 6, 1):
						moves.append({"from": Vector2i(4, 0), "to": Vector2i(6, 0), "ep": false, "castle": 1})
				if cbq and int(b[0][3]) == 0 and int(b[0][2]) == 0 and int(b[0][1]) == 0 and int(b[0][0]) == -4:
					if not _is_attacked(b, 0, 4, 1) and not _is_attacked(b, 0, 3, 1) and not _is_attacked(b, 0, 2, 1):
						moves.append({"from": Vector2i(4, 0), "to": Vector2i(2, 0), "ep": false, "castle": 2})
	return moves


func _is_attacked(b: Array, r: int, c: int, by_side: int) -> bool:
	var pawn_row := r + (1 if by_side == 1 else -1)
	for dc in [-1, 1]:
		if _in_b(pawn_row, c + dc) and int(b[pawn_row][c + dc]) == by_side:
			return true
	for off: Vector2i in [Vector2i(-2,-1),Vector2i(-2,1),Vector2i(2,-1),Vector2i(2,1),Vector2i(-1,-2),Vector2i(-1,2),Vector2i(1,-2),Vector2i(1,2)]:
		if _in_b(r + off.y, c + off.x) and int(b[r + off.y][c + off.x]) == by_side * 2:
			return true
	for d: Vector2i in [Vector2i(1,1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(-1,-1)]:
		var nr := r + d.y; var nc := c + d.x
		while _in_b(nr, nc):
			var t := int(b[nr][nc])
			if t != 0:
				if t == by_side * 3 or t == by_side * 5: return true
				break
			nr += d.y; nc += d.x
	for d: Vector2i in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
		var nr := r + d.y; var nc := c + d.x
		while _in_b(nr, nc):
			var t := int(b[nr][nc])
			if t != 0:
				if t == by_side * 4 or t == by_side * 5: return true
				break
			nr += d.y; nc += d.x
	for dr in [-1, 0, 1]:
		for dc in [-1, 0, 1]:
			if dr != 0 or dc != 0:
				if _in_b(r + dr, c + dc) and int(b[r + dr][c + dc]) == by_side * 6:
					return true
	return false


func _find_king(b: Array, side: int) -> Vector2i:
	for r in range(8):
		for c in range(8):
			if int(b[r][c]) == side * 6:
				return Vector2i(c, r)
	return Vector2i(-1, -1)


func _in_check(b: Array, side: int) -> bool:
	var k := _find_king(b, side)
	if k.x < 0: return true
	return _is_attacked(b, k.y, k.x, -side)


func _apply_sim(b: Array, mv: Dictionary) -> Array:
	var nb := _clone_board(b)
	var f: Vector2i = mv["from"]; var t: Vector2i = mv["to"]
	var p := int(nb[f.y][f.x])
	nb[t.y][t.x] = p
	nb[f.y][f.x] = 0
	if bool(mv["ep"]):
		nb[f.y][t.x] = 0
	if int(mv["castle"]) == 1:
		nb[t.y][5] = nb[t.y][7]; nb[t.y][7] = 0
	elif int(mv["castle"]) == 2:
		nb[t.y][3] = nb[t.y][0]; nb[t.y][0] = 0
	if p == 1 and t.y == 0: nb[t.y][t.x] = 5
	elif p == -1 and t.y == 7: nb[t.y][t.x] = -5
	return nb


func _legal_moves(b: Array, side: int, ep: Vector2i, cwk: bool, cwq: bool, cbk: bool, cbq: bool) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r in range(8):
		for c in range(8):
			var p := int(b[r][c])
			if p == 0 or (1 if p > 0 else -1) != side: continue
			for mv in _pseudo_moves_for(b, r, c, ep, cwk, cwq, cbk, cbq):
				var nb := _apply_sim(b, mv)
				if not _in_check(nb, side):
					out.append(mv)
	return out


func _execute_move(mv: Dictionary) -> void:
	var f: Vector2i = mv["from"]; var t: Vector2i = mv["to"]
	var cap := int(_board[t.y][t.x])
	if bool(mv["ep"]):
		cap = int(_board[f.y][t.x])
	var mover := int(_board[f.y][f.x])

	if cap > 0: _cap_white.append(cap)
	elif cap < 0: _cap_black.append(cap)

	_board = _apply_sim(_board, mv)
	_last_from = f; _last_to = t

	# Update castling rights & en-passant
	if mover == 6: _castle_wk = false; _castle_wq = false
	elif mover == -6: _castle_bk = false; _castle_bq = false
	if f == Vector2i(7, 7) or t == Vector2i(7, 7): _castle_wk = false
	if f == Vector2i(0, 7) or t == Vector2i(0, 7): _castle_wq = false
	if f == Vector2i(7, 0) or t == Vector2i(7, 0): _castle_bk = false
	if f == Vector2i(0, 0) or t == Vector2i(0, 0): _castle_bq = false

	_en_passant = Vector2i(-1, -1)
	if absi(mover) == 1 and absi(t.y - f.y) == 2:
		_en_passant = Vector2i(f.x, (f.y + t.y) / 2)

	if cap != 0:
		AudioSfx.play_brick_break()
		if _turn == 1: add_score(PIECE_VALS[absi(cap)] / 10)
	else:
		AudioSfx.play_tetris_move()

	_turn = -_turn
	_selected = Vector2i(-1, -1)
	_legal_for_sel.clear()

	var next_moves := _legal_moves(_board, _turn, _en_passant, _castle_wk, _castle_wq, _castle_bk, _castle_bq)
	if next_moves.is_empty():
		game_over = true
		if _in_check(_board, _turn):
			if _turn == -1:
				add_score(500); AudioSfx.play_fanfare()
				_banner = "ШАХ І МАТ! ВИ ПЕРЕМОГЛИ!"
			else:
				AudioSfx.play_hit()
				_banner = "ШАХ І МАТ! ПЕРЕМІГ ШІ"
		else:
			_banner = "ПАТ — НІЧИЯ"
		status_changed.emit(_banner)
	elif _turn == -1:
		_ai_timer = 0.28
		status_changed.emit("Хід комп'ютера..." + (" (ШАХ!)" if _in_check(_board, -1) else ""))
	else:
		status_changed.emit("Ваш хід" + (" (ШАХ ВАМ!)" if _in_check(_board, 1) else ""))
	queue_redraw()


func _eval_board(b: Array) -> int:
	var sc := 0
	for r in range(8):
		for c in range(8):
			var p := int(b[r][c])
			if p == 0: continue
			var s := 1 if p > 0 else -1
			var v: int = PIECE_VALS[absi(p)]
			var center := 4 - absi(3 - r) - absi(3 - c)
			if absi(p) == 1:
				v += (6 - r if s == 1 else r - 1) * 10
			elif absi(p) in [2, 3]:
				v += center * 10
			sc += s * v
	return sc


func _minimax(b: Array, depth: int, alpha: int, beta: int, maximizing: bool) -> int:
	if depth == 0:
		return _eval_board(b)
	var side := 1 if maximizing else -1
	var moves := _legal_moves(b, side, Vector2i(-1, -1), false, false, false, false)
	if moves.is_empty():
		if _in_check(b, side):
			return -19000 if maximizing else 19000
		return 0
	if maximizing:
		var best := -999999
		for mv in moves:
			var val := _minimax(_apply_sim(b, mv), depth - 1, alpha, beta, false)
			best = maxi(best, val)
			alpha = maxi(alpha, best)
			if beta <= alpha: break
		return best
	else:
		var best := 999999
		for mv in moves:
			var val := _minimax(_apply_sim(b, mv), depth - 1, alpha, beta, true)
			best = mini(best, val)
			beta = mini(beta, best)
			if beta <= alpha: break
		return best


func _pick_ai_move() -> Dictionary:
	var moves := _legal_moves(_board, -1, _en_passant, _castle_wk, _castle_wq, _castle_bk, _castle_bq)
	if moves.is_empty():
		return {}
	moves.shuffle()
	# Simple capture sort first for fast alpha-beta pruning
	moves.sort_custom(func(a: Dictionary, b_mv: Dictionary) -> bool:
		var ta: Vector2i = a["to"]; var tb: Vector2i = b_mv["to"]
		return absi(int(_board[ta.y][ta.x])) > absi(int(_board[tb.y][tb.x]))
	)
	var best_mv: Dictionary = moves[0]
	var best_val := 999999
	for mv in moves:
		var val := _minimax(_apply_sim(_board, mv), 1, -999999, 999999, true)
		if val < best_val:
			best_val = val
			best_mv = mv
	return best_mv


func step_game(delta: float) -> void:
	if game_over:
		return
	if _turn == -1:
		_ai_timer -= delta
		if _ai_timer <= 0.0:
			var mv := _pick_ai_move()
			if not mv.is_empty():
				_execute_move(mv)


func on_mouse_click(pos: Vector2) -> void:
	if game_over or _turn != 1:
		return
	var gc := int((pos.x - OX) / CELL)
	var gr := int((pos.y - OY) / CELL)
	if not _in_b(gr, gc):
		return
	for mv in _legal_for_sel:
		if (mv["to"] as Vector2i) == Vector2i(gc, gr):
			_execute_move(mv)
			return
	var clicked := int(_board[gr][gc])
	if clicked > 0:
		_selected = Vector2i(gc, gr)
		_legal_for_sel.clear()
		var all := _legal_moves(_board, 1, _en_passant, _castle_wk, _castle_wq, _castle_bk, _castle_bq)
		for mv in all:
			if (mv["from"] as Vector2i) == _selected:
				_legal_for_sel.append(mv)
		queue_redraw()


func _draw_staunton(center: Vector2, p: int) -> void:
	var is_w := p > 0
	var fill := Color(0.95, 0.92, 0.84) if is_w else Color(0.18, 0.16, 0.18)
	var rim := Color(0.24, 0.18, 0.12) if is_w else Color(0.74, 0.64, 0.48)
	var kind := absi(p)
	draw_circle(center + Vector2(1.5, 2.5), 14.0, Color(0, 0, 0, 0.25))
	draw_rect(Rect2(center.x - 11, center.y + 9, 22, 5), fill)
	draw_rect(Rect2(center.x - 11, center.y + 9, 22, 5), rim, false, 1.3)
	match kind:
		1: # Pawn
			draw_colored_polygon(PackedVector2Array([center + Vector2(-7, 9), center + Vector2(7, 9), center + Vector2(3, -3), center + Vector2(-3, -3)]), fill)
			draw_circle(center + Vector2(0, -7), 6.2, fill)
			draw_arc(center + Vector2(0, -7), 6.2, 0, TAU, 16, rim, 1.4)
		2: # Knight
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(-8, 9), center + Vector2(9, 9), center + Vector2(8, -6),
				center + Vector2(2, -14), center + Vector2(-10, -7), center + Vector2(-5, 0)
			]), fill)
			draw_circle(center + Vector2(-2, -7), 1.6, rim)
		3: # Bishop
			draw_colored_polygon(PackedVector2Array([center + Vector2(-8, 9), center + Vector2(8, 9), center + Vector2(4, -5), center + Vector2(-4, -5)]), fill)
			draw_circle(center + Vector2(0, -8), 6.5, fill)
			draw_circle(center + Vector2(0, -15), 2.2, rim)
		4: # Rook
			draw_rect(Rect2(center.x - 8, center.y - 8, 16, 17), fill)
			for tx in [-8, -2, 4]:
				draw_rect(Rect2(center.x + tx, center.y - 13, 4, 5), fill)
			draw_rect(Rect2(center.x - 8, center.y - 8, 16, 17), rim, false, 1.2)
		5: # Queen
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(-9, 9), center + Vector2(9, 9), center + Vector2(12, -8),
				center + Vector2(4, -3), center + Vector2(0, -13), center + Vector2(-4, -3), center + Vector2(-12, -8)
			]), fill)
			for qx in [-11, 0, 11]:
				draw_circle(center + Vector2(qx, -10 if qx != 0 else -14), 2.3, rim)
		6: # King
			draw_colored_polygon(PackedVector2Array([center + Vector2(-9, 9), center + Vector2(9, 9), center + Vector2(10, -7), center + Vector2(-10, -7)]), fill)
			draw_rect(Rect2(center.x - 2, center.y - 17, 4, 11), rim)
			draw_rect(Rect2(center.x - 5, center.y - 14, 10, 3.5), rim)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.11, 0.08, 0.06))
	draw_rect(Rect2(OX - 8, OY - 8, CELL * 8 + 16, CELL * 8 + 16), Color(0.28, 0.17, 0.09))
	draw_rect(Rect2(OX - 8, OY - 8, CELL * 8 + 16, CELL * 8 + 16), Color(0.75, 0.58, 0.24), false, 2.0)

	var f := ThemeDB.fallback_font
	var chk_pos := _find_king(_board, _turn) if _in_check(_board, _turn) else Vector2i(-1, -1)

	for r in range(8):
		draw_string(f, Vector2(OX - 20, OY + r * CELL + 28), str(8 - r), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.84, 0.76, 0.60))
		for c in range(8):
			var sq := Rect2(OX + c * CELL, OY + r * CELL, CELL, CELL)
			var col := Color(0.86, 0.77, 0.61) if (r + c) % 2 == 0 else Color(0.42, 0.26, 0.16)
			if Vector2i(c, r) == _last_from or Vector2i(c, r) == _last_to:
				col = col.lerp(Color(0.85, 0.78, 0.25), 0.35)
			if Vector2i(c, r) == _selected:
				col = Color(0.32, 0.68, 0.42)
			elif Vector2i(c, r) == chk_pos:
				col = Color(0.85, 0.20, 0.20)
			draw_rect(sq, col)

			var p := int(_board[r][c])
			if p != 0:
				_draw_staunton(sq.get_center(), p)

	for mv in _legal_for_sel:
		var t: Vector2i = mv["to"]
		var ctr := Vector2(OX + t.x * CELL + CELL * 0.5, OY + t.y * CELL + CELL * 0.5)
		if int(_board[t.y][t.x]) != 0:
			draw_arc(ctr, 19.0, 0, TAU, 24, Color(0.95, 0.25, 0.20, 0.85), 3.0)
		else:
			draw_circle(ctr, 6.5, Color(0.18, 0.78, 0.34, 0.78))

	for c in range(8):
		draw_string(f, Vector2(OX + c * CELL + 17, OY + CELL * 8 + 18), char(65 + c), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.84, 0.76, 0.60))

	# Right Info Side Panel strictly inside 640x400
	draw_rect(Rect2(432, 24, 188, 352), Color(0.08, 0.06, 0.05))
	draw_rect(Rect2(432, 24, 188, 352), Color(0.68, 0.52, 0.22), false, 1.8)
	draw_string(f, Vector2(446, 54), "ШАХИ", HORIZONTAL_ALIGNMENT_CENTER, 160, 22, Color(0.96, 0.84, 0.42))
	var turn_txt := "Ваш хід (Білі)" if _turn == 1 else "Думає ШІ..."
	draw_string(f, Vector2(446, 92), turn_txt, HORIZONTAL_ALIGNMENT_CENTER, 160, 15, Color(0.86, 0.94, 0.86))
	draw_string(f, Vector2(446, 135), "Взяті білими: %d" % _cap_black.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85, 0.85, 0.85))
	draw_string(f, Vector2(446, 160), "Взяті чорними: %d" % _cap_white.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85, 0.85, 0.85))

	if game_over:
		draw_game_over_banner(_banner + " — [R] Знову")
