extends MinigameBase

# Mario states: 0 = Small, 1 = Super (Big), 2 = Fire Mario
var _level: int = 1
var _px: float = 64.0
var _py: float = 290.0
var _vx: float = 0.0
var _vy: float = 0.0
var _facing: float = 1.0
var _on_ground: bool = false
var _coyote_t: float = 0.0
var _jump_buf_t: float = 0.0
var _invuln_t: float = 0.0
var _fire_cd: float = 0.0
var _power_state: int = 0
var _cam_x: float = 0.0
var _won: bool = false
var _won_timer: float = 0.0
var _campaign_won: bool = false
var _flag_slide_t: float = 0.0
var _anim_t: float = 0.0
var _lives: int = 3

# Pipe warp & underground bonus room state
var _pipe_state: int = 0 # 0=normal, 1=sinking down, 2=rising out, 3=entering side pipe
var _pipe_timer: float = 0.0
var _pipe_target: String = ""
var _in_bonus: bool = false
var _bonus_exit_x: float = 2040.0
var _saved_main: Dictionary = {}

var _solids: Array[Dictionary] = []
var _qblocks: Array[Dictionary] = []
var _coins: Array[Dictionary] = []
var _items: Array[Dictionary] = []
var _fireballs: Array[Dictionary] = []
var _enemies: Array[Dictionary] = []
var _popups: Array[Dictionary] = []
var _debris: Array[Dictionary] = []

const LEVEL_END_X := 2680.0
const FLAG_X := 2460.0
const CASTLE_X := 2575.0


func get_game_title() -> String:
	return "Маріо"


func get_controls_hint() -> String:
	return "A/D — біг | W/Пробіл — стрибок | S/▼ на трубі — увійти | Shift — біг/вогонь | R — заново"


func reset_game() -> void:
	_level = 1
	_lives = 3
	_power_state = 0
	_campaign_won = false
	_in_bonus = false
	_pipe_state = 0
	_saved_main.clear()
	_build_level()
	super.reset_game()


func _build_level() -> void:
	_px = 64.0; _py = 312.0 if _power_state == 0 else 302.0
	_vx = 0.0; _vy = 0.0
	_facing = 1.0; _on_ground = false; _coyote_t = 0.0; _jump_buf_t = 0.0
	_invuln_t = 0.0; _fire_cd = 0.0; _cam_x = 0.0
	_won = false; _won_timer = 0.0; _flag_slide_t = 0.0
	_pipe_state = 0; _pipe_timer = 0.0; _in_bonus = false
	_items.clear(); _fireballs.clear(); _popups.clear(); _debris.clear()

	if _level == 1:
		_build_level_1()
	elif _level == 2:
		_build_level_2()
	else:
		_build_level_3()


func _add_staircase_and_goal(base_y: float = 340.0) -> void:
	_solids.append({"rect": Rect2(2240, base_y - 26, 28, 26), "kind": "stone"})
	_solids.append({"rect": Rect2(2268, base_y - 52, 28, 52), "kind": "stone"})
	_solids.append({"rect": Rect2(2296, base_y - 78, 28, 78), "kind": "stone"})
	_solids.append({"rect": Rect2(2324, base_y - 104, 28, 104), "kind": "stone"})
	_solids.append({"rect": Rect2(2352, base_y - 130, 36, 130), "kind": "stone"})
	_solids.append({"rect": Rect2(FLAG_X - 10, base_y - 26, 26, 26), "kind": "stone"})


func _build_level_1() -> void:
	# Level 1-1: Overworld Green Hills (Pipe at x=860 warps to Bonus Cavern -> Exit Pipe x=2040)
	_solids = [
		{"rect": Rect2(0, 340, 620, 60), "kind": "ground"},
		{"rect": Rect2(700, 340, 480, 60), "kind": "ground"},
		{"rect": Rect2(1270, 340, 520, 60), "kind": "ground"},
		{"rect": Rect2(1880, 340, 860, 60), "kind": "ground"},
		{"rect": Rect2(440, 286, 48, 54), "kind": "pipe"},
		{"rect": Rect2(860, 266, 48, 74), "kind": "pipe", "warp": "bonus_1", "exit_x": 2040.0},
		{"rect": Rect2(1420, 254, 48, 86), "kind": "pipe"},
		{"rect": Rect2(2040, 282, 48, 58), "kind": "pipe", "exit_only": true},
		{"rect": Rect2(220, 248, 28, 26), "kind": "brick", "broken": false, "bump": 0.0},
		{"rect": Rect2(276, 248, 28, 26), "kind": "brick", "broken": false, "bump": 0.0},
		{"rect": Rect2(332, 248, 28, 26), "kind": "brick", "broken": false, "bump": 0.0},
		{"rect": Rect2(760, 246, 84, 26), "kind": "brick", "broken": false, "bump": 0.0},
		{"rect": Rect2(1010, 210, 112, 26), "kind": "brick", "broken": false, "bump": 0.0},
		{"rect": Rect2(1540, 236, 84, 26), "kind": "brick", "broken": false, "bump": 0.0},
		{"rect": Rect2(1660, 182, 84, 26), "kind": "brick", "broken": false, "bump": 0.0}
	]
	_add_staircase_and_goal(340.0)

	_qblocks = [
		{"rect": Rect2(192, 248, 28, 26), "used": false, "loot": "coin", "bump": 0.0},
		{"rect": Rect2(248, 248, 28, 26), "used": false, "loot": "power", "bump": 0.0},
		{"rect": Rect2(304, 248, 28, 26), "used": false, "loot": "coin", "bump": 0.0},
		{"rect": Rect2(276, 168, 28, 26), "used": false, "loot": "coin", "bump": 0.0},
		{"rect": Rect2(955, 246, 28, 26), "used": false, "loot": "power", "bump": 0.0},
		{"rect": Rect2(1335, 244, 28, 26), "used": false, "loot": "coin", "bump": 0.0},
		{"rect": Rect2(1624, 236, 28, 26), "used": false, "loot": "power", "bump": 0.0},
		{"rect": Rect2(1955, 238, 28, 26), "used": false, "loot": "coin", "bump": 0.0}
	]

	_coins = [
		{"pos": Vector2(150, 305), "taken": false}, {"pos": Vector2(262, 212), "taken": false},
		{"pos": Vector2(290, 132), "taken": false}, {"pos": Vector2(655, 250), "taken": false},
		{"pos": Vector2(682, 250), "taken": false}, {"pos": Vector2(1045, 174), "taken": false},
		{"pos": Vector2(1080, 174), "taken": false}, {"pos": Vector2(1220, 245), "taken": false},
		{"pos": Vector2(1690, 145), "taken": false}, {"pos": Vector2(1720, 145), "taken": false},
		{"pos": Vector2(1830, 240), "taken": false}, {"pos": Vector2(2150, 290), "taken": false}
	]

	_enemies = [
		{"kind": "goomba", "x": 360.0, "y": 314.0, "vx": -62.0, "min_x": 180.0, "max_x": 420.0, "alive": true, "squish_t": 0.0},
		{"kind": "goomba", "x": 540.0, "y": 314.0, "vx": -68.0, "min_x": 495.0, "max_x": 600.0, "alive": true, "squish_t": 0.0},
		{"kind": "koopa", "x": 780.0, "y": 308.0, "vx": 64.0, "min_x": 710.0, "max_x": 835.0, "alive": true, "shell": false, "squish_t": 0.0},
		{"kind": "goomba", "x": 1030.0, "y": 184.0, "vx": 55.0, "min_x": 1010.0, "max_x": 1098.0, "alive": true, "squish_t": 0.0},
		{"kind": "goomba", "x": 1360.0, "y": 314.0, "vx": -70.0, "min_x": 1280.0, "max_x": 1400.0, "alive": true, "squish_t": 0.0},
		{"kind": "koopa", "x": 1620.0, "y": 308.0, "vx": -75.0, "min_x": 1480.0, "max_x": 1760.0, "alive": true, "shell": false, "squish_t": 0.0},
		{"kind": "goomba", "x": 1970.0, "y": 314.0, "vx": 70.0, "min_x": 1890.0, "max_x": 2020.0, "alive": true, "squish_t": 0.0},
		{"kind": "goomba", "x": 2160.0, "y": 314.0, "vx": -82.0, "min_x": 2095.0, "max_x": 2220.0, "alive": true, "squish_t": 0.0}
	]


func _build_level_2() -> void:
	# Level 1-2: Underground Blue-Brick Cavern with Secret Shortcut Pipe
	_solids = [
		{"rect": Rect2(0, 340, 820, 60), "kind": "ground"},
		{"rect": Rect2(910, 340, 560, 60), "kind": "ground"},
		{"rect": Rect2(1560, 340, 1180, 60), "kind": "ground"},
		# Cavern brick ceiling (leaves sky open over castle finish!)
		{"rect": Rect2(140, 44, 1820, 26), "kind": "stone"},
		# Multi-tier cavern platforms & warp pipes
		{"rect": Rect2(260, 250, 112, 26), "kind": "brick", "broken": false, "bump": 0.0},
		{"rect": Rect2(440, 198, 112, 26), "kind": "brick", "broken": false, "bump": 0.0},
		{"rect": Rect2(640, 264, 48, 76), "kind": "pipe"},
		{"rect": Rect2(990, 232, 140, 26), "kind": "brick", "broken": false, "bump": 0.0},
		{"rect": Rect2(1190, 178, 112, 26), "kind": "brick", "broken": false, "bump": 0.0},
		{"rect": Rect2(1380, 264, 48, 76), "kind": "pipe", "warp": "bonus_2", "exit_x": 2060.0},
		{"rect": Rect2(1740, 242, 140, 26), "kind": "brick", "broken": false, "bump": 0.0},
		{"rect": Rect2(2060, 276, 48, 64), "kind": "pipe", "exit_only": true}
	]
	_add_staircase_and_goal(340.0)

	_qblocks = [
		{"rect": Rect2(190, 250, 28, 26), "used": false, "loot": "power", "bump": 0.0},
		{"rect": Rect2(380, 250, 28, 26), "used": false, "loot": "coin", "bump": 0.0},
		{"rect": Rect2(560, 198, 28, 26), "used": false, "loot": "power", "bump": 0.0},
		{"rect": Rect2(1140, 232, 28, 26), "used": false, "loot": "coin", "bump": 0.0},
		{"rect": Rect2(1660, 242, 28, 26), "used": false, "loot": "power", "bump": 0.0},
		{"rect": Rect2(1900, 242, 28, 26), "used": false, "loot": "coin", "bump": 0.0}
	]

	_coins = [
		{"pos": Vector2(280, 212), "taken": false}, {"pos": Vector2(315, 212), "taken": false},
		{"pos": Vector2(465, 160), "taken": false}, {"pos": Vector2(500, 160), "taken": false},
		{"pos": Vector2(535, 160), "taken": false}, {"pos": Vector2(865, 235), "taken": false},
		{"pos": Vector2(1030, 196), "taken": false}, {"pos": Vector2(1070, 196), "taken": false},
		{"pos": Vector2(1220, 142), "taken": false}, {"pos": Vector2(1260, 142), "taken": false},
		{"pos": Vector2(1515, 235), "taken": false}, {"pos": Vector2(1790, 204), "taken": false}
	]

	_enemies = [
		{"kind": "goomba", "x": 320.0, "y": 314.0, "vx": -72.0, "min_x": 160.0, "max_x": 620.0, "alive": true, "squish_t": 0.0},
		{"kind": "koopa", "x": 490.0, "y": 166.0, "vx": 58.0, "min_x": 445.0, "max_x": 525.0, "alive": true, "shell": false, "squish_t": 0.0},
		{"kind": "goomba", "x": 750.0, "y": 314.0, "vx": 74.0, "min_x": 700.0, "max_x": 805.0, "alive": true, "squish_t": 0.0},
		{"kind": "koopa", "x": 1060.0, "y": 308.0, "vx": -78.0, "min_x": 925.0, "max_x": 1360.0, "alive": true, "shell": false, "squish_t": 0.0},
		{"kind": "goomba", "x": 1220.0, "y": 152.0, "vx": 56.0, "min_x": 1192.0, "max_x": 1278.0, "alive": true, "squish_t": 0.0},
		{"kind": "goomba", "x": 1680.0, "y": 314.0, "vx": 82.0, "min_x": 1575.0, "max_x": 2030.0, "alive": true, "squish_t": 0.0},
		{"kind": "koopa", "x": 1820.0, "y": 210.0, "vx": -62.0, "min_x": 1745.0, "max_x": 1855.0, "alive": true, "shell": false, "squish_t": 0.0},
		{"kind": "goomba", "x": 2165.0, "y": 314.0, "vx": -88.0, "min_x": 2120.0, "max_x": 2225.0, "alive": true, "squish_t": 0.0}
	]


func _build_level_3() -> void:
	# Level 1-3: Twilight Sky Bridges & Grand Final Castle
	_solids = [
		{"rect": Rect2(0, 340, 420, 60), "kind": "ground"},
		# Elevated stone/brick sky-bridges over abyss!
		{"rect": Rect2(480, 292, 220, 24), "kind": "stone"},
		{"rect": Rect2(760, 246, 200, 24), "kind": "stone"},
		{"rect": Rect2(1020, 290, 220, 24), "kind": "stone"},
		{"rect": Rect2(1090, 216, 48, 74), "kind": "pipe", "warp": "bonus_3", "exit_x": 1980.0},
		{"rect": Rect2(1310, 248, 220, 24), "kind": "stone"},
		{"rect": Rect2(1590, 198, 190, 24), "kind": "stone"},
		{"rect": Rect2(1860, 340, 880, 60), "kind": "ground"},
		{"rect": Rect2(1980, 264, 48, 76), "kind": "pipe", "exit_only": true},
		{"rect": Rect2(540, 202, 84, 26), "kind": "brick", "broken": false, "bump": 0.0},
		{"rect": Rect2(1370, 158, 84, 26), "kind": "brick", "broken": false, "bump": 0.0}
	]
	_add_staircase_and_goal(340.0)

	_qblocks = [
		{"rect": Rect2(260, 250, 28, 26), "used": false, "loot": "power", "bump": 0.0},
		{"rect": Rect2(580, 120, 28, 26), "used": false, "loot": "coin", "bump": 0.0},
		{"rect": Rect2(845, 160, 28, 26), "used": false, "loot": "power", "bump": 0.0},
		{"rect": Rect2(1410, 158, 28, 26), "used": false, "loot": "coin", "bump": 0.0},
		{"rect": Rect2(1660, 114, 28, 26), "used": false, "loot": "power", "bump": 0.0},
		{"rect": Rect2(1920, 240, 28, 26), "used": false, "loot": "coin", "bump": 0.0}
	]

	_coins = [
		{"pos": Vector2(450, 250), "taken": false}, {"pos": Vector2(560, 168), "taken": false},
		{"pos": Vector2(600, 168), "taken": false}, {"pos": Vector2(730, 205), "taken": false},
		{"pos": Vector2(820, 208), "taken": false}, {"pos": Vector2(890, 208), "taken": false},
		{"pos": Vector2(1275, 205), "taken": false}, {"pos": Vector2(1560, 160), "taken": false},
		{"pos": Vector2(1630, 162), "taken": false}, {"pos": Vector2(1690, 162), "taken": false},
		{"pos": Vector2(1820, 235), "taken": false}, {"pos": Vector2(2140, 290), "taken": false}
	]

	_enemies = [
		{"kind": "goomba", "x": 310.0, "y": 314.0, "vx": -75.0, "min_x": 140.0, "max_x": 395.0, "alive": true, "squish_t": 0.0},
		{"kind": "koopa", "x": 580.0, "y": 260.0, "vx": 68.0, "min_x": 490.0, "max_x": 675.0, "alive": true, "shell": false, "squish_t": 0.0},
		{"kind": "goomba", "x": 850.0, "y": 220.0, "vx": -70.0, "min_x": 770.0, "max_x": 935.0, "alive": true, "squish_t": 0.0},
		{"kind": "koopa", "x": 1400.0, "y": 216.0, "vx": 74.0, "min_x": 1320.0, "max_x": 1500.0, "alive": true, "shell": false, "squish_t": 0.0},
		{"kind": "goomba", "x": 1680.0, "y": 172.0, "vx": -72.0, "min_x": 1600.0, "max_x": 1755.0, "alive": true, "squish_t": 0.0},
		{"kind": "koopa", "x": 2120.0, "y": 308.0, "vx": -88.0, "min_x": 2050.0, "max_x": 2215.0, "alive": true, "shell": false, "squish_t": 0.0}
	]


func _enter_bonus_room(warp_id: String, exit_x: float) -> void:
	_saved_main = {
		"solids": _solids.duplicate(true),
		"qblocks": _qblocks.duplicate(true),
		"coins": _coins.duplicate(true),
		"enemies": _enemies.duplicate(true),
		"items": _items.duplicate(true),
		"exit_x": exit_x
	}
	_bonus_exit_x = exit_x
	_in_bonus = true
	_px = 78.0
	_py = 96.0
	_vx = 0.0
	_vy = 0.0
	_cam_x = 0.0
	_fireballs.clear()

	# Classic Subterranean Coin Vault!
	_solids = [
		{"rect": Rect2(0, 340, 640, 60), "kind": "ground"},
		{"rect": Rect2(0, 0, 28, 340), "kind": "stone"},
		{"rect": Rect2(140, 24, 420, 28), "kind": "stone"},
		{"rect": Rect2(190, 240, 196, 26), "kind": "brick", "broken": false, "bump": 0.0},
		{"rect": Rect2(548, 200, 92, 140), "kind": "stone"},
		# Horizontal green L-pipe on the right leading back to the surface!
		{"rect": Rect2(506, 286, 44, 48), "kind": "side_pipe", "exit_trigger": true}
	]
	_qblocks = [
		{"rect": Rect2(274, 152, 28, 26), "used": false, "loot": "power", "bump": 0.0}
	]
	_coins = []
	for cx in range(175, 415, 34):
		_coins.append({"pos": Vector2(cx, 205), "taken": false})
		_coins.append({"pos": Vector2(cx, 305), "taken": false})
	_enemies = []
	_items = []
	_add_popup(Vector2(240, 110), "БОНУСНА КІМНАТА!", Color(0.45, 0.95, 1.0))


func _exit_bonus_room() -> void:
	if _saved_main.is_empty():
		return
	_solids = _saved_main["solids"]
	_qblocks = _saved_main["qblocks"]
	_coins = _saved_main["coins"]
	_enemies = _saved_main["enemies"]
	_items = _saved_main["items"]
	var exit_x: float = float(_saved_main.get("exit_x", _bonus_exit_x))
	_saved_main.clear()
	_in_bonus = false
	_fireballs.clear()

	# Place Mario inside the surface Exit Pipe lip and rise out cleanly!
	var pipe_top := 276.0
	var pipe_cx := exit_x + 24.0
	for s in _solids:
		var r: Rect2 = s["rect"]
		if str(s["kind"]) == "pipe" and absf(r.position.x - exit_x) < 20.0:
			pipe_top = r.position.y
			pipe_cx = r.get_center().x
			break
	_px = pipe_cx - _player_w() * 0.5
	_py = pipe_top + 4.0
	_vx = 0.0
	_vy = 0.0
	_cam_x = clampf(_px - 230.0, 0.0, LEVEL_END_X - CANVAS_SIZE.x)
	_invuln_t = 1.0
	_pipe_state = 2
	_pipe_timer = float(_player_h() + 6.0) / 86.0
	_pipe_target = str(pipe_top - _player_h())
	AudioSfx.play_pipe_warp()


func _player_w() -> float:
	return 22.0 if _power_state == 0 else 26.0


func _player_h() -> float:
	return 28.0 if _power_state == 0 else 38.0


func on_key_pressed(phys_key: int) -> void:
	if game_over or _won or _pipe_state != 0:
		return
	if is_up_key(phys_key) or is_action_key(phys_key):
		_jump_buf_t = 0.12
	elif (phys_key == KEY_SHIFT or phys_key == KEY_F) and _power_state == 2 and _fire_cd <= 0.0:
		_fire_cd = 0.32
		_fireballs.append({"pos": Vector2(_px + _facing * 18.0, _py + 16.0), "vx": _facing * 320.0, "vy": 60.0})
		AudioSfx.play_laser()


func _add_popup(pos: Vector2, txt: String, col: Color = Color(1.0, 0.94, 0.35)) -> void:
	_popups.append({"pos": pos, "txt": txt, "col": col, "t": 0.75})


func _hit_block_from_below() -> void:
	var pw := _player_w()
	var probe := Rect2(_px + 3.0, _py - 6.0, pw - 6.0, 8.0)
	for qb in _qblocks:
		if not bool(qb["used"]) and probe.intersects(qb["rect"]):
			qb["used"] = true
			qb["bump"] = 0.16
			var r: Rect2 = qb["rect"]
			if str(qb["loot"]) == "power":
				var kind := "mushroom" if _power_state == 0 else "flower"
				_items.append({"kind": kind, "pos": Vector2(r.position.x + 2, r.position.y - 24), "vx": 78.0, "vy": -90.0})
				AudioSfx.play_powerup()
			else:
				add_score(100)
				_add_popup(r.position + Vector2(6, -10), "+100")
				AudioSfx.play_coin()
			return

	for s in _solids:
		if str(s["kind"]) == "brick" and not bool(s["broken"]) and probe.intersects(s["rect"]):
			var r: Rect2 = s["rect"]
			if _power_state >= 1 and r.size.x <= 32.0:
				s["broken"] = true
				add_score(50)
				AudioSfx.play_brick_break()
				for dv in [Vector2(-85, -220), Vector2(85, -220), Vector2(-55, -130), Vector2(55, -130)]:
					_debris.append({"pos": r.get_center(), "vel": dv, "t": 0.7})
			else:
				s["bump"] = 0.14
				AudioSfx.play_brick_bump()
			return


func _hurt_mario() -> void:
	if _invuln_t > 0.0:
		return
	if _power_state > 0:
		_power_state = 0
		_py += 10.0
		_invuln_t = 1.6
		AudioSfx.play_hit()
		_add_popup(Vector2(_px, _py - 10), "МАЛИЙ!", Color(1.0, 0.55, 0.35))
	else:
		_lives -= 1
		AudioSfx.play_hit()
		if _lives <= 0:
			game_over = true
			status_changed.emit("ГРА ЗАВЕРШЕНА!")
		else:
			_build_level()
			_invuln_t = 1.4
			status_changed.emit("Рівень 1-%d  |  Життів: %d" % [_level, _lives])


func step_game(delta: float) -> void:
	_anim_t += delta
	_invuln_t = maxf(0.0, _invuln_t - delta)
	_fire_cd = maxf(0.0, _fire_cd - delta)
	_coyote_t = maxf(0.0, _coyote_t - delta)
	_jump_buf_t = maxf(0.0, _jump_buf_t - delta)

	for s in _solids:
		if s.has("bump") and float(s["bump"]) > 0.0:
			s["bump"] = maxf(0.0, float(s["bump"]) - delta)
	for qb in _qblocks:
		if float(qb["bump"]) > 0.0:
			qb["bump"] = maxf(0.0, float(qb["bump"]) - delta)
	for i in range(_popups.size() - 1, -1, -1):
		_popups[i]["t"] = float(_popups[i]["t"]) - delta
		_popups[i]["pos"] = (_popups[i]["pos"] as Vector2) + Vector2(0, -34.0 * delta)
		if float(_popups[i]["t"]) <= 0.0:
			_popups.remove_at(i)
	for i in range(_debris.size() - 1, -1, -1):
		_debris[i]["t"] = float(_debris[i]["t"]) - delta
		_debris[i]["vel"] = (_debris[i]["vel"] as Vector2) + Vector2(0, 720.0 * delta)
		_debris[i]["pos"] = (_debris[i]["pos"] as Vector2) + (_debris[i]["vel"] as Vector2) * delta
		if float(_debris[i]["t"]) <= 0.0:
			_debris.remove_at(i)

	# Handle classic Pipe Warp slide animations cleanly
	if _pipe_state == 1:
		_pipe_timer -= delta
		_py += 64.0 * delta
		if _pipe_timer <= 0.0:
			_pipe_state = 0
			_enter_bonus_room(_pipe_target, _bonus_exit_x)
		queue_redraw()
		return
	elif _pipe_state == 2:
		_pipe_timer -= delta
		var target_y := float(_pipe_target)
		_py = move_toward(_py, target_y, 86.0 * delta)
		if _pipe_timer <= 0.0 or _py <= target_y + 0.5:
			_py = target_y
			_pipe_state = 0
			_on_ground = true
		queue_redraw()
		return
	elif _pipe_state == 3:
		_pipe_timer -= delta
		_px += 68.0 * delta
		if _pipe_timer <= 0.0:
			_pipe_state = 0
			_exit_bonus_room()
		queue_redraw()
		return

	if _won:
		if _flag_slide_t < 1.2:
			_flag_slide_t += delta
			_py = minf(340.0 - _player_h(), _py + 170.0 * delta)
		elif _px < CASTLE_X + 26.0:
			_px += 120.0 * delta
		else:
			_won_timer += delta
			if _won_timer >= 0.50:
				if _level < 3:
					_level += 1
					_build_level()
					AudioSfx.play_powerup()
					_add_popup(Vector2(140, 200), "РІВЕНЬ 1-%d!" % _level, Color(0.45, 1.0, 0.55))
				else:
					_campaign_won = true
					game_over = true
					AudioSfx.play_fanfare()
					status_changed.emit("ПЕРЕМОГА! Усі 3 рівні пройдено!")
		_cam_x = clampf(_px - 260.0, 0.0, LEVEL_END_X - CANVAS_SIZE.x)
		queue_redraw()
		return

	if game_over:
		queue_redraw()
		return

	var sprint := is_phys_held(KEY_SHIFT)
	var max_spd := 275.0 if sprint else 195.0
	var move := 0.0
	if is_left_held(): move -= 1.0; _facing = -1.0
	if is_right_held(): move += 1.0; _facing = 1.0

	if move != 0.0:
		_vx = move_toward(_vx, move * max_spd, delta * 920.0)
	else:
		_vx = move_toward(_vx, 0.0, delta * 1050.0)

	if _on_ground:
		_coyote_t = 0.10
	if _jump_buf_t > 0.0 and _coyote_t > 0.0:
		_vy = -515.0 - absf(_vx) * 0.15
		_on_ground = false
		_coyote_t = 0.0
		_jump_buf_t = 0.0
		AudioSfx.play_jump()

	var jump_held := is_up_held() or is_action_held()
	if _vy < -140.0 and not jump_held:
		_vy *= pow(0.06, delta)

	_vy = minf(_vy + 1320.0 * delta, 640.0)

	var pw := _player_w()
	var ph := _player_h()
	var max_world_x := (CANVAS_SIZE.x - pw) if _in_bonus else (LEVEL_END_X - pw)

	_px += _vx * delta
	_px = clampf(_px, 8.0, max_world_x)
	var prect := Rect2(_px, _py, pw, ph)
	for s in _solids:
		if bool(s.get("broken", false)):
			continue
		var r: Rect2 = s["rect"]
		if bool(s.get("exit_trigger", false)) and prect.intersects(r) and _vx > 10.0:
			_pipe_state = 3
			_pipe_timer = 0.34
			_vx = 0.0; _vy = 0.0
			AudioSfx.play_pipe_warp()
			queue_redraw()
			return
		if prect.intersects(r):
			if _vx > 0.0: _px = r.position.x - pw
			elif _vx < 0.0: _px = r.end.x
			_vx = 0.0
			prect.position.x = _px
	for qb in _qblocks:
		var r: Rect2 = qb["rect"]
		if prect.intersects(r):
			if _vx > 0.0: _px = r.position.x - pw
			elif _vx < 0.0: _px = r.end.x
			_vx = 0.0
			prect.position.x = _px

	_py += _vy * delta
	_on_ground = false
	prect = Rect2(_px, _py, pw, ph)
	for s in _solids:
		if bool(s.get("broken", false)):
			continue
		var r: Rect2 = s["rect"]
		if prect.intersects(r):
			if _vy > 0.0:
				_py = r.position.y - ph
				_vy = 0.0
				_on_ground = true
			elif _vy < 0.0:
				_py = r.end.y
				_vy = 35.0
				_hit_block_from_below()
			prect.position.y = _py
	for qb in _qblocks:
		var r: Rect2 = qb["rect"]
		if prect.intersects(r):
			if _vy > 0.0:
				_py = r.position.y - ph
				_vy = 0.0
				_on_ground = true
			elif _vy < 0.0:
				_py = r.end.y
				_vy = 35.0
				_hit_block_from_below()
			prect.position.y = _py

	# Check pressing S / Down on top of a Warp Pipe!
	if _on_ground and is_down_held() and not _in_bonus:
		var foot_cx := _px + pw * 0.5
		var foot_y := _py + ph
		for s in _solids:
			if str(s["kind"]) == "pipe" and s.has("warp"):
				var r: Rect2 = s["rect"]
				if absf(foot_cx - r.get_center().x) <= r.size.x * 0.44 and absf(foot_y - r.position.y) <= 4.0:
					_pipe_state = 1
					_pipe_timer = 0.42
					_pipe_target = str(s["warp"])
					_bonus_exit_x = float(s.get("exit_x", 2040.0))
					_px = r.get_center().x - pw * 0.5
					_vx = 0.0; _vy = 0.0
					AudioSfx.play_pipe_warp()
					queue_redraw()
					return

	if _py > 435.0:
		_power_state = 0
		_invuln_t = 0.0
		_hurt_mario()
		queue_redraw()
		return

	for c in _coins:
		if not bool(c["taken"]) and Vector2(_px + pw * 0.5, _py + ph * 0.5).distance_to(c["pos"]) < 24.0:
			c["taken"] = true
			add_score(50)
			_add_popup(c["pos"], "+50")
			AudioSfx.play_coin()

	for ii in range(_items.size() - 1, -1, -1):
		var it: Dictionary = _items[ii]
		var ip: Vector2 = it["pos"]
		if str(it["kind"]) == "mushroom":
			var vy := float(it["vy"]) + 980.0 * delta
			ip.x += float(it["vx"]) * delta
			ip.y += vy * delta
			var ir := Rect2(ip, Vector2(22, 22))
			for s in _solids:
				if bool(s.get("broken", false)): continue
				var sr: Rect2 = s["rect"]
				if ir.intersects(sr):
					if vy > 0.0 and ip.y + 22.0 - sr.position.y < 16.0:
						ip.y = sr.position.y - 22.0
						vy = 0.0
					else:
						it["vx"] = -float(it["vx"])
						ip.x += float(it["vx"]) * delta * 2.0
					ir.position = ip
			it["pos"] = ip
			it["vy"] = vy
		if Rect2(ip, Vector2(22, 22)).intersects(prect):
			if str(it["kind"]) == "mushroom":
				if _power_state == 0:
					_power_state = 1
					_py -= 10.0
			else:
				_power_state = 2
			add_score(1000)
			_add_popup(ip, "+1000!", Color(0.45, 1.0, 0.55))
			AudioSfx.play_powerup()
			_items.remove_at(ii)

	# Fireballs bouncing realistically off real floor/bridge surfaces
	for fi in range(_fireballs.size() - 1, -1, -1):
		var fb: Dictionary = _fireballs[fi]
		var fp: Vector2 = fb["pos"]
		var prev_y := fp.y
		var fvx := float(fb["vx"])
		var fvy := float(fb["vy"]) + 980.0 * delta
		fp += Vector2(fvx, fvy) * delta
		var hit_wall := fp.x < _cam_x - 20.0 or fp.x > _cam_x + CANVAS_SIZE.x + 20.0 or fp.y > 420.0
		for s in _solids:
			if bool(s.get("broken", false)): continue
			var sr: Rect2 = s["rect"]
			if sr.has_point(fp):
				if prev_y <= sr.position.y + 6.0 and fvy > 0.0:
					fp.y = sr.position.y - 4.0
					fvy = -255.0
				else:
					hit_wall = true
					break
		fb["pos"] = fp; fb["vy"] = fvy
		var hit_enemy := false
		for e in _enemies:
			if bool(e["alive"]) and Rect2(float(e["x"]), float(e["y"]), 26, 26).has_point(fp):
				e["alive"] = false
				add_score(200)
				_add_popup(fp, "+200")
				AudioSfx.play_stomp()
				hit_enemy = true; break
		if hit_wall or hit_enemy:
			_fireballs.remove_at(fi)

	for ei in range(_enemies.size()):
		var e: Dictionary = _enemies[ei]
		if not bool(e["alive"]):
			if float(e["squish_t"]) > 0.0:
				e["squish_t"] = maxf(0.0, float(e["squish_t"]) - delta)
			continue
		var ex := float(e["x"]) + float(e["vx"]) * delta
		if ex < float(e["min_x"]) or ex > float(e["max_x"]):
			e["vx"] = -float(e["vx"])
			ex = clampf(ex, float(e["min_x"]), float(e["max_x"]))
		e["x"] = ex

		var is_shell := bool(e.get("shell", false))
		var shell_spd := float(e["vx"])
		if is_shell and absf(shell_spd) > 10.0:
			for oj in range(_enemies.size()):
				if oj != ei and bool(_enemies[oj]["alive"]):
					var ox := float(_enemies[oj]["x"])
					if absf(ex - ox) < 24.0 and absf(float(e["y"]) - float(_enemies[oj]["y"])) < 26.0:
						_enemies[oj]["alive"] = false
						add_score(300)
						_add_popup(Vector2(ox, float(_enemies[oj]["y"])), "+300")
						AudioSfx.play_stomp()

		var er := Rect2(ex + 2, float(e["y"]), 22, 26)
		if prect.intersects(er):
			if _vy > 20.0 and _py + ph - 12.0 < float(e["y"]) + 10.0:
				_vy = -360.0
				if str(e["kind"]) == "koopa":
					if not is_shell:
						e["shell"] = true
						e["vx"] = 0.0
						e["y"] = float(e["y"]) + 8.0
						add_score(100)
						AudioSfx.play_stomp()
					else:
						e["vx"] = _facing * 260.0 if absf(shell_spd) < 10.0 else 0.0
						AudioSfx.play_kick()
				else:
					e["alive"] = false
					e["squish_t"] = 0.45
					add_score(150)
					_add_popup(Vector2(ex, float(e["y"])), "+150")
					AudioSfx.play_stomp()
			else:
				if is_shell and absf(shell_spd) < 10.0:
					e["vx"] = _facing * 260.0
					e["x"] = float(e["x"]) + _facing * 14.0
					AudioSfx.play_kick()
				else:
					_hurt_mario()
					break

	if not _in_bonus and _px >= FLAG_X - 8.0 and not _won:
		_won = true
		_won_timer = 0.0
		_vx = 0.0; _vy = 0.0
		var height_bonus := int(clampf((340.0 - _py) * 4.0, 100.0, 1000.0))
		add_score(height_bonus)
		_add_popup(Vector2(FLAG_X, _py), "+%d" % height_bonus)
		AudioSfx.play_fanfare()
		status_changed.emit("РІВЕНЬ 1-%d ПРОЙДЕНО! +%d" % [_level, height_bonus])

	_cam_x = 0.0 if _in_bonus else clampf(_px - 230.0, 0.0, LEVEL_END_X - CANVAS_SIZE.x)
	if not _won and not game_over:
		var mode_txt := "Вогняний" if _power_state == 2 else ("Великий" if _power_state == 1 else "Малий")
		var area := "Бонус-підвал" if _in_bonus else ("1-%d" % _level)
		status_changed.emit("Рівень %s  |  Життів: %d  |  %s Маріо" % [area, _lives, mode_txt])
	queue_redraw()


func _draw_mario_sprite() -> void:
	if _invuln_t > 0.0 and int(_anim_t * 16.0) % 2 != 0 and _pipe_state == 0:
		return
	var pw := _player_w(); var ph := _player_h()
	var pp := Vector2(_px - _cam_x, _py)
	var sc_y := ph / 32.0
	var sc_x := pw / 24.0
	var shirt := Color(0.98, 0.96, 0.94) if _power_state == 2 else Color(0.88, 0.16, 0.14)
	var overall := Color(0.88, 0.18, 0.14) if _power_state == 2 else Color(0.16, 0.34, 0.84)
	var stride := sin(_anim_t * 18.0) * (3.0 if absf(_vx) > 25.0 and _on_ground else 0.0)
	draw_rect(Rect2(pp + Vector2(3 * sc_x, 26 * sc_y), Vector2(7 * sc_x, 6 * sc_y + stride * 0.4)), Color(0.32, 0.16, 0.08))
	draw_rect(Rect2(pp + Vector2(14 * sc_x, 26 * sc_y), Vector2(7 * sc_x, 6 * sc_y - stride * 0.4)), Color(0.32, 0.16, 0.08))
	draw_rect(Rect2(pp + Vector2(3 * sc_x, 15 * sc_y), Vector2(18 * sc_x, 12 * sc_y)), overall)
	draw_rect(Rect2(pp + Vector2(2 * sc_x, 10 * sc_y), Vector2(20 * sc_x, 7 * sc_y)), shirt)
	draw_rect(Rect2(pp + Vector2(4 * sc_x, 4 * sc_y), Vector2(16 * sc_x, 8 * sc_y)), Color(0.96, 0.78, 0.62))
	draw_rect(Rect2(pp + Vector2(2 * sc_x, 0), Vector2(20 * sc_x, 5 * sc_y)), shirt)
	var eye_x := pp.x + (15 * sc_x if _facing > 0 else 5 * sc_x)
	draw_rect(Rect2(eye_x, pp.y + 5 * sc_y, 3, 3), Color.BLACK)
	draw_rect(Rect2(eye_x - (2 if _facing > 0 else 0), pp.y + 9 * sc_y, 7, 2), Color(0.24, 0.12, 0.06))


func _draw() -> void:
	var underground := _in_bonus or _level == 2
	if underground:
		draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.05, 0.06, 0.14))
	elif _level == 3:
		draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.16, 0.12, 0.28))
		draw_rect(Rect2(0, 200, CANVAS_SIZE.x, 200), Color(0.55, 0.24, 0.28, 0.45))
	else:
		draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color(0.36, 0.64, 0.98))
		draw_rect(Rect2(0, 220, CANVAS_SIZE.x, 180), Color(0.50, 0.76, 1.0, 0.55))

	if not underground:
		for i in range(7):
			if _level == 1:
				var hx := fmod(float(i * 440) - _cam_x * 0.45 + 3200.0, 3200.0) - 160.0
				draw_circle(Vector2(hx, 360), 95, Color(0.14, 0.54, 0.22))
				draw_circle(Vector2(hx + 24, 368), 68, Color(0.18, 0.62, 0.28))
			var cx := fmod(float(i * 390 + 90) - _cam_x * 0.28 + 2800.0, 2800.0) - 120.0
			var cy := 58.0 + float(i % 2) * 32.0
			var c_col := Color(0.98, 0.82, 0.72, 0.75) if _level == 3 else Color(0.98, 0.99, 1.0)
			draw_circle(Vector2(cx, cy), 22, c_col)
			draw_circle(Vector2(cx + 20, cy + 2), 18, c_col)
			draw_circle(Vector2(cx - 18, cy + 4), 16, c_col)

	var f := ThemeDB.fallback_font
	# When entering/exiting a pipe, draw Mario behind pipes so he slides cleanly inside!
	if _pipe_state != 0:
		_draw_mario_sprite()

	for s in _solids:
		if bool(s.get("broken", false)): continue
		var r: Rect2 = s["rect"]
		var bump_off := -sin(clampf(float(s.get("bump", 0.0)) / 0.14, 0.0, 1.0) * PI) * 7.0
		var dr := Rect2(r.position - Vector2(_cam_x, -bump_off), r.size)
		if dr.end.x < -20 or dr.position.x > CANVAS_SIZE.x + 20: continue
		var kind := str(s["kind"])
		if kind == "ground":
			if underground:
				draw_rect(dr, Color(0.14, 0.30, 0.48))
				draw_rect(Rect2(dr.position.x, dr.position.y, dr.size.x, 8), Color(0.26, 0.52, 0.78))
			else:
				draw_rect(dr, Color(0.58, 0.30, 0.14))
				draw_rect(Rect2(dr.position.x, dr.position.y, dr.size.x, 9), Color(0.22, 0.72, 0.24) if _level == 1 else Color(0.75, 0.54, 0.22))
				draw_rect(Rect2(dr.position.x, dr.position.y, dr.size.x, 3), Color(0.45, 0.90, 0.42) if _level == 1 else Color(0.94, 0.78, 0.36))
		elif kind == "pipe":
			draw_rect(dr, Color(0.10, 0.56, 0.18))
			draw_rect(Rect2(dr.position.x + 6, dr.position.y, 8, dr.size.y), Color(0.28, 0.84, 0.36))
			draw_rect(Rect2(dr.position.x - 4, dr.position.y, dr.size.x + 8, 16), Color(0.12, 0.68, 0.22))
			draw_rect(Rect2(dr.position.x - 2, dr.position.y + 2, 10, 12), Color(0.36, 0.92, 0.42))
			draw_rect(Rect2(dr.position.x - 4, dr.position.y, dr.size.x + 8, 16), Color(0.04, 0.24, 0.06), false, 1.8)
			if s.has("warp") and _pipe_state == 0:
				var bob := sin(_anim_t * 5.0) * 3.0
				draw_string(f, Vector2(dr.get_center().x - 6, dr.position.y - 10 + bob), "▼", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.92, 0.35))
		elif kind == "side_pipe":
			draw_rect(dr, Color(0.10, 0.58, 0.18))
			draw_rect(Rect2(dr.position.x, dr.position.y + 6, dr.size.x, 9), Color(0.28, 0.86, 0.36))
			draw_rect(Rect2(dr.position.x, dr.position.y - 3, 14, dr.size.y + 6), Color(0.12, 0.70, 0.22))
			draw_rect(Rect2(dr.position.x, dr.position.y - 3, 14, dr.size.y + 6), Color(0.04, 0.24, 0.06), false, 1.8)
			draw_string(f, Vector2(dr.position.x - 20, dr.get_center().y + 5), "▶", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1.0, 0.92, 0.35))
		elif kind == "stone":
			var sc := Color(0.20, 0.36, 0.56) if underground else Color(0.52, 0.50, 0.48)
			draw_rect(dr, sc)
			draw_rect(dr, sc.darkened(0.45), false, 2.0)
		else:
			var bc := Color(0.24, 0.42, 0.64) if underground else Color(0.74, 0.36, 0.18)
			draw_rect(dr, bc)
			draw_line(dr.position + Vector2(0, dr.size.y * 0.5), dr.position + Vector2(dr.size.x, dr.size.y * 0.5), bc.darkened(0.45), 2.0)
			draw_rect(dr, bc.darkened(0.45), false, 2.0)

	for qb in _qblocks:
		var r: Rect2 = qb["rect"]
		var bump_off := -sin(clampf(float(qb["bump"]) / 0.16, 0.0, 1.0) * PI) * 8.0
		var dr := Rect2(r.position - Vector2(_cam_x, -bump_off), r.size)
		if dr.end.x < -20 or dr.position.x > CANVAS_SIZE.x + 20: continue
		var used := bool(qb["used"])
		var pulse := 0.0 if used else sin(_anim_t * 6.0) * 0.08
		draw_rect(dr, Color(0.46, 0.36, 0.24) if used else Color(0.96 + pulse, 0.74 + pulse, 0.14))
		draw_rect(dr, Color(0.30, 0.18, 0.05), false, 2.0)
		if not used:
			draw_string(f, dr.position + Vector2(9, 19), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.38, 0.18, 0.02))

	if not _in_bonus:
		var cx := CASTLE_X - _cam_x
		if cx < CANVAS_SIZE.x + 120:
			draw_rect(Rect2(cx, 232, 92, 108), Color(0.68, 0.34, 0.18))
			draw_rect(Rect2(cx + 18, 196, 56, 38), Color(0.62, 0.30, 0.15))
			for merlon in range(5):
				draw_rect(Rect2(cx + merlon * 19, 224, 12, 10), Color(0.68, 0.34, 0.18))
			draw_rect(Rect2(cx + 32, 282, 28, 58), Color(0.08, 0.06, 0.08))
			draw_circle(Vector2(cx + 46, 282), 14, Color(0.08, 0.06, 0.08))

		var fx := FLAG_X - _cam_x
		draw_rect(Rect2(fx, 130, 6, 184), Color(0.90, 0.92, 0.94))
		draw_circle(Vector2(fx + 3, 128), 6.0, Color(0.96, 0.84, 0.20))
		var fy_off := clampf(_flag_slide_t * 140.0, 0.0, 150.0) if _won else 0.0
		draw_colored_polygon(PackedVector2Array([Vector2(fx + 6, 136 + fy_off), Vector2(fx + 52, 152 + fy_off), Vector2(fx + 6, 168 + fy_off)]), Color(0.18, 0.80, 0.22))

	for c in _coins:
		if not bool(c["taken"]):
			var cp: Vector2 = c["pos"] - Vector2(_cam_x, 0)
			if cp.x < -20 or cp.x > CANVAS_SIZE.x + 20: continue
			var w := 3.5 + absf(sin(_anim_t * 5.5)) * 5.0
			draw_rect(Rect2(cp.x - w, cp.y - 10, w * 2.0, 20), Color(0.98, 0.84, 0.16))
			draw_rect(Rect2(cp.x - w * 0.4, cp.y - 6, w * 0.8, 12), Color(1.0, 0.95, 0.65))

	for it in _items:
		var ip: Vector2 = (it["pos"] as Vector2) - Vector2(_cam_x, 0)
		if str(it["kind"]) == "mushroom":
			draw_rect(Rect2(ip.x + 5, ip.y + 10, 12, 12), Color(0.96, 0.88, 0.72))
			draw_circle(ip + Vector2(11, 10), 10.5, Color(0.90, 0.16, 0.14))
			draw_circle(ip + Vector2(6, 8), 3.0, Color.WHITE)
			draw_circle(ip + Vector2(15, 8), 3.0, Color.WHITE)
		else:
			draw_rect(Rect2(ip.x + 9, ip.y + 11, 4, 11), Color(0.18, 0.76, 0.24))
			draw_circle(ip + Vector2(11, 8), 8.0, Color(0.98, 0.42, 0.14))
			draw_circle(ip + Vector2(11, 8), 4.0, Color(1.0, 0.92, 0.24))

	for fb in _fireballs:
		var fp: Vector2 = (fb["pos"] as Vector2) - Vector2(_cam_x, 0)
		draw_circle(fp, 5.5, Color(1.0, 0.45, 0.12))
		draw_circle(fp, 3.0, Color(1.0, 0.92, 0.35))

	for e in _enemies:
		var ex := float(e["x"]) - _cam_x
		if ex < -40 or ex > CANVAS_SIZE.x + 40: continue
		var ey := float(e["y"])
		if not bool(e["alive"]):
			if float(e["squish_t"]) > 0.0:
				draw_rect(Rect2(ex, ey + 18, 26, 8), Color(0.52, 0.24, 0.10))
			continue
		if str(e["kind"]) == "koopa":
			var is_sh := bool(e.get("shell", false))
			if is_sh:
				draw_circle(Vector2(ex + 13, ey + 15), 11.0, Color(0.16, 0.72, 0.24))
				draw_rect(Rect2(ex + 4, ey + 16, 18, 8), Color(0.92, 0.84, 0.56))
			else:
				draw_rect(Rect2(ex + 5, ey + 2, 14, 12), Color(0.94, 0.84, 0.48))
				draw_circle(Vector2(ex + 13, ey + 20), 11.0, Color(0.16, 0.72, 0.24))
		else:
			draw_circle(Vector2(ex + 13, ey + 11), 12.0, Color(0.58, 0.28, 0.12))
			draw_rect(Rect2(ex + 5, ey + 15, 16, 8), Color(0.88, 0.76, 0.58))
			draw_rect(Rect2(ex + 6, ey + 7, 4, 5), Color.WHITE)
			draw_rect(Rect2(ex + 16, ey + 7, 4, 5), Color.WHITE)
			var step_off := 3.0 * sin(_anim_t * 14.0)
			draw_rect(Rect2(ex + 3 + step_off, ey + 22, 8, 4), Color(0.18, 0.12, 0.08))
			draw_rect(Rect2(ex + 15 - step_off, ey + 22, 8, 4), Color(0.18, 0.12, 0.08))

	if _pipe_state == 0:
		_draw_mario_sprite()

	for d in _debris:
		var dp: Vector2 = (d["pos"] as Vector2) - Vector2(_cam_x, 0)
		draw_rect(Rect2(dp - Vector2(4, 4), Vector2(8, 8)), Color(0.76, 0.38, 0.18))

	for pop in _popups:
		var pp_txt: Vector2 = (pop["pos"] as Vector2) - Vector2(_cam_x, 0)
		draw_string(f, pp_txt, str(pop["txt"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, pop["col"])

	if _campaign_won:
		draw_game_over_banner("ПЕРЕМОГА! Усі 3 рівні пройдено! — [R] Спочатку")
	else:
		draw_game_over_banner("МАРІО ВТРАТИВ ЖИТТЯ — [R] Спробувати знову")
