extends Panel

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var credit_text: RichTextLabel = $"ScrollContainer/Credits Text"
@onready var scrollbar: VScrollBar = credit_text.get_v_scroll_bar()

@export var scroll_speed := 30.0
@export var fade_time := 0.5
@export var start_delay := 1.0

var scrolling := false


func _ready():
	scrollbar.visible = false
	set_process(false)
	modulate.a = 0.0  
	
	credit_text.text = tr("CREDITS_TEXT")

func _process(delta):	
	scroll_container.scroll_vertical += scroll_speed * delta
	
	if scrollbar.value >= scrollbar.max_value:
		scrollbar.value = scrollbar.max_value
		stop()

func start():
	show()
	scrollbar.value = 0
	scrolling = false
	modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	
	await get_tree().create_timer(start_delay).timeout
	scrolling = true
	set_process(true)

func stop():
	scrolling = false
	set_process(false)
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	scrollbar.value = 0
	hide()
