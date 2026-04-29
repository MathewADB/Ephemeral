extends Control


func _ready() -> void:
	$Panel/Respawn.text = tr("RESPAWN")
	$"Panel/You Died".text = tr("YOU_DIED")

func _on_respawn_pressed() -> void:
	UI.fade.fade_in()
	self.visible = false
	get_tree().paused = false
	Manager.player.respawn()
	UI.fade.fade_out()
