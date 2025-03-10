extends Node3D

var clock = 0
var fluid = preload("res://fluid.tscn")
@export var spawn_delta: float

func _process(_delta: float) -> void:
	clock += _delta
	if clock > spawn_delta:
		clock = 0
		var scene = fluid.instantiate()
		add_child(scene)
		
		
		
