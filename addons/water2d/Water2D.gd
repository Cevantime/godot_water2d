tool
extends Sprite

var drop_index: int = 0
var area2d: Area2D
var collision_shape: CollisionShape2D
var owner_id: int
var area_rid: RID

enum SURFACE_TYPES {
	PLAIN,
	GRADIENT
}
export(bool) var automatic_impact = true
export(SURFACE_TYPES) var surface_type = SURFACE_TYPES.GRADIENT setget set_surface_type

export(Vector2) var deformation_speed_1 = Vector2(1.0, 1.0) setget set_deformation_speed_1
export(Vector2) var deformation_speed_2 = Vector2(-2.0, -2.0) setget set_deformation_speed_2
export(Vector2) var deformation_strength = Vector2(1.0, 1.0) setget set_deformation_strength
export(Vector2) var deformation_size = Vector2(1.0, 1.0) setget set_deformation_size

export(float, 0.0, 10000.0) var water_level = 20.0 setget set_water_level
export(Color) var water_color = Color(0.0, 0.0,1.0, 0.75) setget set_water_color

export(float, 0.0, 10000.0) var surface_width = 2.0 setget set_surface_width
export(Color) var surface_color = Color(1.0, 1.0,1.0, 0.75) setget set_surface_color
export(float, 0.0, 10000.0) var surface_deformation_strength = 1.0 setget set_surface_deformation_strength

export(float, 0.0, 10000.0) var wave_speed = 1.0 setget set_wave_speed
export(float, 0.0, 10000.0) var wave_distance_attenuation = 1.0 setget set_wave_distance_attenuation
export(float, 0.0, 10000.0) var wave_time_attenuation = 1.0 setget set_wave_time_attenuation

signal water_entered(water, impact_pos, body_id, body, body_shape, area_shape)
signal water_exited(water, impact_pos, body_id, body, body_shape, area_shape)
signal water_splashed(water, impact_pos, body_id, body, body_shape, area_shape)

# Called when the node enters the scene tree for the first time.
func _enter_tree():
	texture = preload("icon.png")
	material = preload("water2D_material.tres")
	add_shape()
	
func add_shape():
	if not Engine.editor_hint:
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
	if not Engine.editor_hint:
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
	var impact_pos = compute_impact_pos(body)
	if impact_pos.y <= body.global_position.y :
		if automatic_impact : 
			add_impact(impact_pos, 10.0, 5.0)
		emit_signal("water_splashed", self, impact_pos, body_id, body, body_shape, area_shape)
	emit_signal("water_entered", self, impact_pos, body_id, body, body_shape, area_shape)
	
func _on_Area2D_body_shape_exited(body_id, body, body_shape, area_shape):
	var impact_pos = compute_impact_pos(body)
	emit_signal("water_exited", self, impact_pos, body_id, body, body_shape, area_shape)
	
func add_impact(pos, length, height):
	material.set_shader_param("impact_height_" + str(drop_index), height)
	material.set_shader_param("impact_length_" + str(drop_index), length)
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
	
func set_surface_type(_value):
	surface_type = _value
	material.set_shader_param("surface_type", _value)
	
func set_deformation_speed_1( _value ):
	deformation_speed_1 = _value
	material.set_shader_param("deformation_speed_1", _value)
	
func set_deformation_speed_2( _value ):
	deformation_speed_2 = _value
	material.set_shader_param("deformation_speed_2", _value)
	
func set_deformation_strength( _value ):
	deformation_strength = _value
	material.set_shader_param("deformation_strength", _value)
	
func set_deformation_size( _value ):
	deformation_size = _value
	material.set_shader_param("tile_factor", Vector2(1.0 / _value.x, 1.0 / _value.y))
	
func set_water_level( _value ):
	water_level = _value
	material.set_shader_param("water_level", _value)
	
func set_water_color( _value ):
	water_color = _value
	material.set_shader_param("water_color", _value)
	
func set_surface_width( _value ):
	surface_width = _value
	material.set_shader_param("surface_width", _value)
	
func set_surface_color( _value ):
	surface_color = _value
	material.set_shader_param("surface_color", _value)
	
func set_surface_deformation_strength( _value ):
	surface_deformation_strength = _value
	material.set_shader_param("surface_deformation_strength", _value)
	
func set_wave_speed( _value ):
	wave_speed = _value
	material.set_shader_param("wave_speed", _value)
	
func set_wave_distance_attenuation( _value ):
	wave_distance_attenuation = _value
	material.set_shader_param("wave_distance_attenuation", _value)
	
func set_wave_time_attenuation( _value ):
	wave_time_attenuation = _value
	material.set_shader_param("wave_time_attenuation", _value)
