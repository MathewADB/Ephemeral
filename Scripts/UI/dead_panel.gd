extends Control


func _ready() -> void:
	$Panel/Respawn.text = tr("RESPAWN")
	$"Panel/You Died".text = tr("YOU_DIED")

func _on_respawn_pressed() -> void:
	self.visible = false
	await UI.fade_in()
	get_tree().paused = false
	Manager.player.respawn()
	UI.fade_out(3)
