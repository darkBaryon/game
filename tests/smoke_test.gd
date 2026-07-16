extends Node

const MainScene := preload("res://scenes/main.tscn")

var _failures: int = 0


func _ready() -> void:
	GameState.persistence_enabled = false
	GameState.reset_progress()

	_expect(GameState.scrap == 12, "new game starts with 12 scrap")
	_expect(GameState.energy == 3, "new game starts with 3 energy")
	_expect(GameState.repair_reactor(), "reactor can be repaired")
	_expect(GameState.scrap == 4, "reactor repair consumes scrap")
	_expect(GameState.energy == 15, "reactor repair restores energy")

	var main := MainScene.instantiate()
	add_child(main)
	await get_tree().process_frame
	_expect(main.current_view != null, "ship view is created")

	main._start_expedition()
	await get_tree().process_frame
	await get_tree().process_frame
	var expedition: Node = main.current_view
	_expect(expedition != null, "expedition view is created")
	_expect(expedition.player != null, "expedition player is created")
	_expect(get_tree().get_nodes_in_group("enemies").size() >= 5, "initial enemy wave is spawned")

	var first_enemy: ExpeditionEnemy = get_tree().get_first_node_in_group("enemies") as ExpeditionEnemy
	_expect(first_enemy != null, "an enemy can be targeted")
	if first_enemy != null:
		first_enemy.take_damage(9999.0)
	await get_tree().process_frame
	_expect(expedition.kills == 1, "enemy defeat is counted")

	expedition._on_scrap_collected(20)
	expedition._finish(true, "smoke test")
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(GameState.scrap == 24, "recovered scrap returns to the ship")
	_expect(GameState.energy == 13, "expedition consumes ship energy")
	_expect(GameState.mission_count == 1, "mission count advances")

	if _failures == 0:
		print("SMOKE TEST PASSED")
		get_tree().quit(0)
	else:
		push_error("SMOKE TEST FAILED: %d assertion(s)" % _failures)
		get_tree().quit(1)


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		_failures += 1
		push_error("FAIL: %s" % description)
