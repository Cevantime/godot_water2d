tool
extends Sprite

var drop_index: int = 0
var area2d: Area2D
var collision_shape: CollisionShape2D
var owner_id: int
var area_rid: RID

signal water_splash

# Called when the node enters the scene tree for the first time.
func _enter_tree():
	print("enter_tree")
	texture = preload("icon.png")
	material = preload("water_shader.tres")
	area2d = Area2D.new()
	collision_shape = CollisionShape2D.new()
	adjust_water_area()
	area2d.add_child(collision_shape)
	area2d.connect("area_shape_entered", self, "_on_Area2D_body_shape_entered") 
	area2d.connect("body_shape_entered", self, "_on_Area2D_body_shape_entered") 
	add_child(area2d)


func _process(delta):
	material.set_shader_param("reftime", OS.get_ticks_msec())

func _on_Water_item_rect_changed():
	adjust_water_area()
	
func adjust_water_area():
	var new_rect = RectangleShape2D.new()
	var sprite_size = get_rect().size
	var new_rect_extents = sprite_size / 2
	new_rect_extents.y *= (1 - material.get_shader_param('water_level'))
	new_rect.extents = new_rect_extents
	collision_shape.set_shape(new_rect)
	area2d.position.y = (sprite_size.y - new_rect_extents.y * 2) / 2
	material.set_shader_param("water_size", sprite_size * scale)
	

func _on_Area2D_body_shape_entered(body_id, body, body_shape, area_shape):
	var size = get_rect().size * scale
	var sprite_top_left = global_position - size / 2;
	var body_pos_relative_top_left = body.global_position - sprite_top_left
	var surface_y = size.y * material.get_shader_param("water_level")
	var impact_pos = Vector2(body_pos_relative_top_left.x, surface_y)
	if impact_pos.y <= body.global_position.y :
		add_impact(impact_pos)
	emit_signal("water_splash", body_id, body, body_shape, area_shape)
	

func add_impact(screen_pos):
	material.set_shader_param("pos" + str(drop_index), screen_pos)
	material.set_shader_param("time" + str(drop_index), OS.get_ticks_msec())
	drop_index = (drop_index + 1) % 7

