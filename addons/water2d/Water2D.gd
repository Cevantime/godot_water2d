tool
extends Sprite

var drop_index: int = 0
var area2d: Area2D
var collision_shape: CollisionShape2D
var owner_id: int
var area_rid: RID

signal water_entered
signal water_exited
signal water_splashed

# Called when the node enters the scene tree for the first time.
func _enter_tree():
	texture = preload("icon.png")
	material = preload("water2D_material.tres")
	add_shape()
	
func add_shape():
	area2d = Area2D.new()
	collision_shape = CollisionShape2D.new()
	adjust_water_area()
	area2d.add_child(collision_shape)
	area2d.connect("area_shape_entered", self, "_on_Area2D_body_shape_entered") 
	area2d.connect("body_shape_entered", self, "_on_Area2D_body_shape_entered") 
	area2d.connect("area_shape_exited", self, "_on_Area2D_body_shape_exited") 
	area2d.connect("body_shape_exited", self, "_on_Area2D_body_shape_exited")
	add_child(area2d)
	
func adjust_water_area():
	var new_rect = RectangleShape2D.new()
	var sprite_size = get_rect().size
	var new_rect_extents = sprite_size / 2
	var half_water_level = material.get_shader_param('water_level')/ 2 / scale.y
	new_rect_extents.y -= half_water_level
	if new_rect_extents.y < 0.0 : new_rect_extents.y = 0
	new_rect.extents = new_rect_extents
	collision_shape.set_shape(new_rect)
	area2d.position.y = half_water_level

func _ready() :
	material.set_shader_param("scale", scale)
	
func compute_impact_pos(body):
	var size = get_rect().size * scale
	var sprite_top_left = global_position - size / 2;
	var body_pos_relative_top_left = body.global_position - sprite_top_left
	var surface_y = material.get_shader_param("water_level")
	return Vector2(body_pos_relative_top_left.x, surface_y)
	
func _on_Area2D_body_shape_entered(body_id, body, body_shape, area_shape):
	print("entered")
	var impact_pos = compute_impact_pos(body)
	if impact_pos.y <= body.global_position.y :
		print("add_impact : ", impact_pos)
		add_impact(impact_pos)
		emit_signal("water_splashed", impact_pos, body_id, body, body_shape, area_shape)
	emit_signal("water_entered", body_id, body, body_shape, area_shape)
	
func _on_Area2D_body_shape_exited(body_id, body, body_shape, area_shape):
	var impact_pos = compute_impact_pos(body)
	emit_signal("water_exited", impact_pos, body_id, body, body_shape, area_shape)
	
func add_impact(pos):
	material.set_shader_param("impact_pos_" + str(drop_index), pos)
	material.set_shader_param("impact_time_" + str(drop_index), OS.get_ticks_msec() / 1000.0)
	drop_index = (drop_index + 1) % 8
	
func _process(delta):
	var current_time = OS.get_ticks_msec() / 1000.0
	material.set_shader_param("current_time", current_time)
	if Engine.editor_hint:
		if ! area2d:
			add_shape()
		material.set_shader_param("scale", scale)
		adjust_water_area()

func _on_Water2D_item_rect_changed():
	adjust_water_area()
	material.set_shader_param("scale", scale)
	
