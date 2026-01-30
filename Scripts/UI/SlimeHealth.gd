extends Control

@export var back_bar: TextureProgressBar
@export var front_bar: TextureProgressBar

@export var is_health : bool = false
@export var low_hp_pulse : bool = true
@export var damage_shake : bool = true

var current_pct := 1.0
var front_tween: Tween
var back_tween: Tween
var pulse_tween: Tween = null

func update_bar(current: float, max_value: float):
	var pct = clamp(current / max_value, 0.0, 1.0)
	
	front_bar.max_value = max_value
	back_bar.max_value = max_value
	
	var is_damage = pct < current_pct
	var is_heal = pct > current_pct
	
	if is_damage:
		if front_tween and front_tween.is_running():
			front_tween.kill()
		if back_tween and back_tween.is_running():
			back_tween.kill()
			
		front_bar.value = current
	
		back_tween = create_tween()
		back_tween.tween_property(back_bar,"value",current,0.45)
		self.position = Vector2(0,0)
		_on_damage()
		
	elif is_heal :
		if front_tween and front_tween.is_running():
			front_tween.kill()
		if front_tween and back_tween.is_running():
			back_tween.kill()

		front_tween = create_tween().set_parallel()
		front_tween.tween_property(front_bar,"value",current,0.25)
		front_tween.tween_property(back_bar,"value",current,0.25)		
		_on_heal()
		
	current_pct = pct
		
func _shake():
	var original_pos = position
	var tw = create_tween()
	tw.tween_property(self,"position",original_pos + Vector2(2,0),0.05)
	tw.tween_property(self,"position",original_pos - Vector2(2,0),0.05)
	tw.tween_property(self,"position",original_pos,0.5)
		
func _flash(flash_color: Color):
	modulate = flash_color
	var t = create_tween()
	t.tween_property(self,"modulate",Color(1,1,1),0.25)
	
func _on_damage():
	_flash(Color(1,0.3,0.3))
	if damage_shake:
		_shake()
	
func _on_heal():
	_flash(Color(0.3, 1, 0.3))
			
