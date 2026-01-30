extends CharacterBody2D
class_name Entity

var entity_type := "player"

var max_speed := 130.0
var current_speed := 0.0
var acceleration := 1800.0
var jump_force := -300.0

var max_health := 100
var current_health := max_health
var damage := 10 

var direction : Vector2 = Vector2.ZERO
var last_direction : Vector2 = Vector2.RIGHT

var gravity := 1800
