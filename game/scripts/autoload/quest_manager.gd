class_name QuestManager
extends RefCounted

signal state_changed
signal quest_event(msg: String, is_complete: bool)

var chips: int = 0
var quests: Array[Dictionary] = [
	{
		"id": "explorer_basement",
		"title": "Таємниці Підземелля",
		"desc": "Відвідайте Виставочний зал, Винний погріб і Сховище в підвалі",
		"reward": 150,
		"targets": ["exhibition", "cellar", "vault"],
		"done_steps": {},
		"completed": false
	},
	{
		"id": "relic_hunter",
		"title": "Мисливець за Реліквіями",
		"desc": "Огляньте Кубок, Винну Амфору та Сапфір у залах підвалу",
		"reward": 250,
		"targets": ["relic_cup", "relic_amphora", "relic_sapphire"],
		"done_steps": {},
		"completed": false
	},
	{
		"id": "arcade_newcomer",
		"title": "Поціновувач Новинок",
		"desc": "Зіграйте на триногах у «2048», «Зуму» та «Пазли»",
		"reward": 200,
		"targets": ["2048", "zuma", "puzzle"],
		"done_steps": {},
		"completed": false
	},
	{
		"id": "vault_heist",
		"title": "Сейф Сховища й ВІП-Диско",
		"desc": "Відкрийте Сейф у сховищі та увімкніть ВІП-диско",
		"reward": 150,
		"targets": ["vault_safe", "disco_button"],
		"done_steps": {},
		"completed": false
	},
	{
		"id": "stunt_driver",
		"title": "Король Гірської Траси",
		"desc": "Проїдьте Мертву петлю і виконайте Стрибок через прірву",
		"reward": 300,
		"targets": ["loop", "jump"],
		"done_steps": {},
		"completed": false
	},
	{
		"id": "valley_master",
		"title": "Спостерігач Долини",
		"desc": "Подивіться в бінокль (мансарда), вівтар погоди та гриб-батут",
		"reward": 200,
		"targets": ["binoculars", "weather_altar", "bounce_shroom"],
		"done_steps": {},
		"completed": false
	}
]


func record_step(quest_id: String, step_key: String) -> bool:
	for q in quests:
		if str(q["id"]) != quest_id or bool(q["completed"]):
			continue
		var targets: Array = q["targets"]
		if not (step_key in targets):
			return false
		var done_map: Dictionary = q["done_steps"]
		if done_map.has(step_key):
			return false
		done_map[step_key] = true
		var cnt := done_map.size()
		var total := targets.size()
		if cnt >= total:
			q["completed"] = true
			var rw := int(q["reward"])
			chips += rw
			quest_event.emit("✅ Квест виконано: «%s» (+%d фішок!)" % [q["title"], rw], true)
		else:
			quest_event.emit("📜 Прогрес квесту «%s»: %d/%d" % [q["title"], cnt, total], false)
		state_changed.emit()
		return true
	return false


func record_any(step_key: String) -> void:
	for q in quests:
		if not bool(q["completed"]) and (step_key in (q["targets"] as Array)):
			record_step(str(q["id"]), step_key)


func add_chips(amount: int) -> void:
	chips += amount
	state_changed.emit()


func get_completed_count() -> int:
	var n := 0
	for q in quests:
		if bool(q["completed"]):
			n += 1
	return n


func get_hud_summary() -> String:
	var done_n := get_completed_count()
	var next_line := "Усі квести виконано!"
	for q in quests:
		if not bool(q["completed"]):
			var d: Dictionary = q["done_steps"]
			var t: Array = q["targets"]
			next_line = "%s (%d/%d)" % [q["title"], d.size(), t.size()]
			break
	return "📜 Квести: %d/%d  |  Фішки: %d  |  [Q] Журнал\nНаст.: %s" % [done_n, quests.size(), chips, next_line]


func format_journal_text() -> String:
	var lines: Array[String] = []
	lines.append("Зібрано фішок: %d   |   Виконано квестів: %d / %d\n" % [chips, get_completed_count(), quests.size()])
	for q in quests:
		var done_m: Dictionary = q["done_steps"]
		var t_arr: Array = q["targets"]
		var icon := "✅" if bool(q["completed"]) else "🔸"
		lines.append("%s %s  [%d/%d]  (+%d фішок)" % [icon, q["title"], done_m.size(), t_arr.size(), int(q["reward"])])
		lines.append("    %s\n" % q["desc"])
	return "\n".join(lines)
