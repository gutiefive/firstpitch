class_name InfieldSurface
extends Node3D
signal completion_changed(percent: float)
@export var layout: FieldLayout = preload("res://resources/layouts/cedar_grove.tres")
@export var resolution := Vector2i.ZERO
@export var update_frequency := 10.0
var image: Image
var texture: ImageTexture
var surface_material: ShaderMaterial
var valid := PackedByteArray()
var prepared := PackedByteArray()
var total := 0
var prepared_count := 0
var dirty := false
var elapsed := 0.0

var field_origin: Vector2:
 get:
  return layout.dirt_origin
var field_size: Vector2:
 get:
  return layout.dirt_size

func is_workable(p: Vector2) -> bool:
 return layout.is_workable(p)

func world_to_grid(p: Vector3) -> Vector2i:
 var local := to_local(p)
 return Vector2i(floori((local.x-field_origin.x)/field_size.x*resolution.x),floori((local.z-field_origin.y)/field_size.y*resolution.y))

func cell_world(x: int,y: int) -> Vector2:
 return field_origin+(Vector2(x,y)+Vector2.ONE*0.5)*field_size/Vector2(resolution)

func _ready() -> void:
 if resolution == Vector2i.ZERO:
  resolution = layout.dirt_resolution
 image = Image.create(resolution.x,resolution.y,false,Image.FORMAT_RGBA8)
 valid.resize(resolution.x*resolution.y)
 prepared.resize(valid.size())
 for y in range(resolution.y):
  for x in range(resolution.x):
   if is_workable(cell_world(x,y)):
    valid[y*resolution.x+x] = 1
    total += 1
    image.set_pixel(x,y,Color(0,0.5,0,1))
 texture = ImageTexture.create_from_image(image)
 surface_material = ShaderMaterial.new()
 surface_material.shader = preload("res://shaders/infield.gdshader")
 surface_material.set_shader_parameter("condition_mask",texture)
 surface_material.set_shader_parameter("field_origin",field_origin)
 surface_material.set_shader_parameter("field_size",field_size)

func apply_to(surfaces: Array[MeshInstance3D]) -> void:
 for surface in surfaces:
  surface.material_override = surface_material

func drag_segment(from: Vector3,to: Vector3,forward: Vector3,width: float,depth: float) -> void:
 var spacing := minf(field_size.x/resolution.x,field_size.y/resolution.y)*0.75
 var steps := maxi(1,ceili(from.distance_to(to)/spacing))
 for i in range(steps+1):
  paint(from.lerp(to,float(i)/steps),forward,width,depth)

func paint(center: Vector3,forward: Vector3,width: float,depth: float) -> void:
 var direction := Vector2(forward.x,forward.z).normalized()
 if direction.length_squared() < 0.5 or width <= 0 or depth <= 0:
  return
 var right := Vector2(-direction.y,direction.x)
 var local := to_local(center)
 var grid := world_to_grid(center)
 var radius := Vector2(width,depth).length()*0.5
 var rx := ceili(radius/field_size.x*resolution.x)+1
 var ry := ceili(radius/field_size.y*resolution.y)+1
 for y in range(maxi(0,grid.y-ry),mini(resolution.y,grid.y+ry+1)):
  for x in range(maxi(0,grid.x-rx),mini(resolution.x,grid.x+rx+1)):
   var index := y*resolution.x+x
   if valid[index] == 0 or prepared[index] == 1:
    continue
   var offset := cell_world(x,y)-Vector2(local.x,local.z)
   if absf(offset.dot(right)) > width*0.5 or absf(offset.dot(direction)) > depth*0.5:
    continue
   prepared[index] = 1
   prepared_count += 1
   image.set_pixel(x,y,Color(1,direction.x*0.5+0.5,direction.y*0.5+0.5,1))
   dirty = true

func percentage() -> float:
 return 100.0*prepared_count/maxi(total,1)

func _process(delta: float) -> void:
 elapsed += delta
 if dirty and elapsed >= 1.0/update_frequency:
  texture.update(image)
  completion_changed.emit(percentage())
  dirty = false
  elapsed = 0

func reset_state() -> void:
 prepared.fill(0)
 prepared_count = 0
 image.fill(Color(0,0,0,0))
 for y in range(resolution.y):
  for x in range(resolution.x):
   if valid[y*resolution.x+x] == 1:
    image.set_pixel(x,y,Color(0,0.5,0,1))
 texture.update(image)
 dirty = false
 elapsed = 0
 completion_changed.emit(0)
