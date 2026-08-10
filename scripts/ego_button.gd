class_name EgoButton
extends Standup
## Ein einzelner EGO-Knopf: jeder Treffer hebt den Ego-Multiplikator um
## genau eine Stufe (bis x10) - mit Fanfare.


func _on_hit(body: Node2D) -> void:
	if _cool > 0.0 or not body is PinBall:
		return
	_cool = 0.5
	Sfx.play("ego_up", -2.0)
	Game.add_score(1000, body)
	# Genau eine Stufe rauf: bis zum naechsten Vielfachen von 12 auffuellen
	Game.add_ego(12 - (Game.ego % 12))
	lit = true
	queue_redraw()
	_unlight()


func _unlight() -> void:
	await get_tree().create_timer(0.35, false).timeout
	lit = false
	queue_redraw()
