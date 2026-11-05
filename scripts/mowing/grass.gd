class_name MowingGrass
extends Node3D
signal completion_changed(percent: float)
@export var layout: FieldLayout = preload("res://resources/layouts/cedar_grove.tres")
@export var resolution := Vector2i.ZERO
@export var tuft_count := 28000
@export var deck_width := 2.4
@export var update_frequency := 10.0
var image: Image
var texture: ImageTexture
var valid := PackedByteArray()
var cut := PackedByteArray()
var total := 0
var cut_count := 0
var dirty := false
var elapsed := 0.0
var surface_material: ShaderMaterial
var tufts: MultiMeshInstance3D
var pristine: Image
var stripe_samples := 0
var stripe_matches := 0
var quality_rules := ShiftSession.quality_rules()

var field_origin: Vector2:
 get:
  return layout.grass_origin
var field_size: Vector2:
 get:
  return layout.grass_size

func is_grass(p: Vector2) -> bool:
 return layout.is_grass(p)

func world_to_grid(p: Vector3) -> Vector2i:
 var local := to_local(p)
 return Vector2i(floori((local.x-field_origin.x)/field_size.x*resolution.x),floori((local.z-field_origin.y)/field_size.y*resolution.y))

func cell_world(x: int,y: int) -> Vector2:
 return field_origin + (Vector2(x,y)+Vector2.ONE*0.5)*field_size/Vector2(resolution)

func _ready() -> void:
 if resolution == Vector2i.ZERO:
  resolution = layout.grass_resolution
 image = Image.create(resolution.x,resolution.y,false,Image.FORMAT_RGBA8)
 valid.resize(resolution.x*resolution.y)
 cut.resize(valid.size())
 for y in range(resolution.y):
  for x in range(resolution.x):
   if is_grass(cell_world(x,y)):
    valid[y*resolution.x+x] = 1
    total += 1
    image.set_pixel(x,y,Color(0,0,0,1))
 pristine = image.duplicate()
 set_process(false)
 texture = ImageTexture.create_from_image(image)
 var mesh := PlaneMesh.new()
 mesh.size = field_size
 var surface := MeshInstance3D.new()
 surface.mesh = mesh
 var center := field_origin + field_size*0.5
 surface.position = Vector3(center.x,layout.grass_height,center.y)
 surface_material = ShaderMaterial.new()
 var mat := surface_material
 mat.shader = load("res://shaders/grass.gdshader")
 mat.set_shader_parameter("state_mask",texture)
 mat.set_shader_parameter("visual_mask",texture)
 surface.material_override = mat
 add_child(surface)
 if tuft_count > 0:
  build_tufts()

func mow_segment(from: Vector3,to: Vector3,direction: Vector3) -> void:
 var steps := maxi(1,ceili(from.distance_to(to)/(deck_width*0.2)))
 for i in range(steps+1):
  paint(from.lerp(to,float(i)/steps),direction)

func paint(center: Vector3,direction: Vector3) -> void:
 var grid := world_to_grid(center)
 var radius := deck_width*0.5
 var rx := ceili(radius/field_size.x*resolution.x)+1
 var ry := ceili(radius/field_size.y*resolution.y)+1
 var local := to_local(center)
 for y in range(maxi(0,grid.y-ry),mini(resolution.y,grid.y+ry+1)):
  for x in range(maxi(0,grid.x-rx),mini(resolution.x,grid.x+rx+1)):
   var index := y*resolution.x+x
   if valid[index] == 0 or cut[index] == 1:
    continue
   if cell_world(x,y).distance_to(Vector2(local.x,local.z)) > radius:
    continue
   var heading := absf(direction.z)
   for neighbor in [Vector2i(x-1,y),Vector2i(x+1,y),Vector2i(x,y-1),Vector2i(x,y+1)]:
    if neighbor.x >= 0 and neighbor.y >= 0 and neighbor.x < resolution.x and neighbor.y < resolution.y and cut[neighbor.y*resolution.x+neighbor.x] == 1:
     stripe_samples += 1
     stripe_matches += 1 if absf(image.get_pixelv(neighbor).g-heading) <= float(quality_rules.stripe_tolerance) else 0
   cut[index] = 1
   cut_count += 1
   image.set_pixel(x,y,Color(1,absf(direction.z),0,1))
   dirty = true
   set_process(true)

func percentage() -> float:
 return 100.0*cut_count/maxi(total,1)

func _process(delta: float) -> void:
 elapsed += delta
 if dirty and elapsed >= 1.0/minf(10,update_frequency):
  texture.update(image)
  completion_changed.emit(percentage())
  elapsed = 0
  dirty = false
  set_process(false)

func build_tufts() -> void:
 # One draw batch, no per-blade nodes; the same GPU mask hides freshly cut tufts.
 var geometry := SurfaceTool.new()
 geometry.begin(Mesh.PRIMITIVE_TRIANGLES)
 for rotation_index in range(2):
  var work_basis := Basis(Vector3.UP,rotation_index*PI/2)
  var vertices := [Vector3(-0.018,0,0),Vector3(-0.009,0.055,0),Vector3(0.012,0.055,0),Vector3(-0.018,0,0),Vector3(0.012,0.055,0),Vector3(0.018,0,0),Vector3(-0.009,0.055,0),Vector3(0.025,0.11,0),Vector3(0.012,0.055,0)]
  for vertex in vertices:
   geometry.set_normal(Vector3.UP)
   geometry.set_uv(Vector2(0,vertex.y/0.11))
   geometry.add_vertex(work_basis*vertex)
 var mesh := geometry.commit()
 var mat := ShaderMaterial.new()
 mat.shader = preload("res://shaders/grass_tufts.gdshader")
 mat.set_shader_parameter("state_mask",texture)
 mat.set_shader_parameter("field_origin",field_origin)
 mat.set_shader_parameter("field_size",field_size)
 mesh.surface_set_material(0,mat)
 var batch := MultiMesh.new()
 batch.transform_format = MultiMesh.TRANSFORM_3D
 batch.mesh = mesh
 batch.instance_count = tuft_count
 var rng := RandomNumberGenerator.new()
 rng.seed = 9137
 for index in range(tuft_count):
  var point := Vector2.ZERO
  # Rejection sampling stays within the exact scored grass layout.
  var found := false
  for attempt in range(100):
   point = field_origin+Vector2(rng.randf(),rng.randf())*field_size
   if is_grass(point):
    found = true
    break
  var work_basis := Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*rng.randf_range(0.75,1.35))
  if not found:
   work_basis = work_basis.scaled(Vector3.ZERO)
  batch.set_instance_transform(index,Transform3D(work_basis,Vector3(point.x,layout.grass_height+0.003,point.y)))
 tufts = MultiMeshInstance3D.new()
 tufts.name = "UncutGrassTufts"
 tufts.multimesh = batch
 tufts.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 add_child(tufts)

func reset_quality() -> void:
 stripe_samples = 0
 stripe_matches = 0

func reset_state() -> void:
 cut.fill(0)
 cut_count = 0
 image.copy_from(pristine)
 texture.update(image)
 dirty = false
 elapsed = 0
 reset_quality()
 set_process(false)
 completion_changed.emit(0)

func set_inspection(enabled: bool) -> void:
 surface_material.set_shader_parameter("inspection_enabled",enabled)
 if tufts != null:
  tufts.visible = not enabled

func prepare_all() -> void:
 image.copy_from(pristine)
 cut = valid.duplicate()
 cut_count = total
 for i in range(valid.size()):
  if valid[i] == 1:
   image.set_pixel(i%resolution.x,i/resolution.x,Color(1,0.5,0,1))
 reset_quality()
 texture.update(image)
 dirty = false
 elapsed = 0
 set_process(false)
 completion_changed.emit(100)
