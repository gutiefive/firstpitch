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
var valid_indices := PackedInt32Array()
var pristine: Image
var ruts := PackedByteArray()
var rut_count := 0
var rut_image: Image
var rut_texture: ImageTexture
var moisture_source: Node
var wet_dragging := false
var blocked_puddles := false
var quality_rules := ShiftSession.quality_rules()

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
    valid_indices.append(y*resolution.x+x)
    image.set_pixel(x,y,Color(0,0.5,0,1))
 pristine = image.duplicate()
 ruts.resize(valid.size())
 rut_image = Image.create(resolution.x,resolution.y,false,Image.FORMAT_R8)
 rut_texture = ImageTexture.create_from_image(rut_image)
 set_process(false)
 texture = ImageTexture.create_from_image(image)
 surface_material = ShaderMaterial.new()
 surface_material.shader = preload("res://shaders/infield.gdshader")
 surface_material.set_shader_parameter("condition_mask",texture)
 surface_material.set_shader_parameter("rut_mask",rut_texture)
 surface_material.set_shader_parameter("field_origin",field_origin)
 surface_material.set_shader_parameter("field_size",field_size)

func apply_to(surfaces: Array[MeshInstance3D]) -> void:
 for surface in surfaces:
  surface.material_override = surface_material

func drag_segment(from: Vector3,to: Vector3,forward: Vector3,width: float,depth: float) -> void:
 wet_dragging = false
 blocked_puddles = false
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
   if valid[index] == 0:
    continue
   var offset := cell_world(x,y)-Vector2(local.x,local.z)
   if absf(offset.dot(right)) > width*0.5 or absf(offset.dot(direction)) > depth*0.5:
    continue
   if moisture_source != null and moisture_source.is_puddle(index):
    blocked_puddles = true
    continue
   var wet: bool = moisture_source != null and moisture_source.moisture[index] > float(quality_rules.wet_drag_threshold)
   wet_dragging = wet_dragging or wet
   if ruts[index] != int(wet):
    rut_count += 1 if wet else -1
    ruts[index] = int(wet)
    rut_image.set_pixel(x,y,Color(float(wet),0,0,1))
    dirty = true
   if prepared[index] == 1:
    if dirty:
     set_process(true)
    continue
   prepared[index] = 1
   prepared_count += 1
   image.set_pixel(x,y,Color(1,direction.x*0.5+0.5,direction.y*0.5+0.5,1))
   dirty = true
   set_process(true)

func percentage() -> float:
 return 100.0*prepared_count/maxi(total,1)

func refresh_texture() -> void:
 texture.update(image)
 rut_texture.update(rut_image)
 dirty = false
 elapsed = 0
 set_process(false)
 completion_changed.emit(percentage())

func _process(delta: float) -> void:
 elapsed += delta
 if dirty and elapsed >= 1.0/minf(10,update_frequency):
  refresh_texture()

func snapshot_cells() -> PackedByteArray:
 return prepared.duplicate()

func work_indices() -> PackedInt32Array:
 return valid_indices.duplicate()

func replace_cells(states: PackedByteArray,rut_states: PackedByteArray = PackedByteArray()) -> void:
 prepared = states.duplicate()
 if rut_states.is_empty():
  ruts.fill(0)
 else:
  ruts = rut_states.duplicate()
 recount()
 refresh_texture()

func recount() -> void:
 prepared_count = 0
 rut_count = 0
 for i in valid_indices:
  prepared_count += prepared[i]
  rut_count += ruts[i]
  var p := Vector2i(i%resolution.x,i/resolution.x)
  var color := image.get_pixelv(p)
  color.r = prepared[i]
  image.set_pixelv(p,color)
  rut_image.set_pixelv(p,Color(ruts[i],0,0,1))

func prepare_all() -> void:
 replace_cells(valid)

func reset_quality() -> void:
 ruts.fill(0)
 rut_count = 0
 rut_image.fill(Color(0,0,0,1))
 rut_texture.update(rut_image)
 wet_dragging = false
 blocked_puddles = false

func reset_state() -> void:
 prepared.fill(0)
 prepared_count = 0
 image.copy_from(pristine)
 reset_quality()
 refresh_texture()
