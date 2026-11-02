class_name MowingGrass
extends Node3D
signal completion_changed(percent: float)
@export var field_size := Vector2(150,110)
@export var resolution := Vector2i(450,330)
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
@export var field_origin := Vector2(-75,-110)
@export var outfield_radius := 99.0
@export var diamond_center := Vector2(0,-19.396)
@export var diamond_half_diagonal := 22.0

func is_grass(p: Vector2) -> bool:
 if p.y >= -1 or absf(p.x) >= -p.y or p.length() > outfield_radius:
  return false
 # Diamond exclusion matches the rotated 31 m dirt square.
 return absf(p.x-diamond_center.x) + absf(p.y-diamond_center.y) > diamond_half_diagonal and p.length() > 6.1

func world_to_grid(p: Vector3) -> Vector2i:
 var local := to_local(p)
 return Vector2i(floori((local.x-field_origin.x)/field_size.x*resolution.x),floori((local.z-field_origin.y)/field_size.y*resolution.y))

func cell_world(x: int,y: int) -> Vector2:
 return field_origin + (Vector2(x,y)+Vector2.ONE*0.5)*field_size/Vector2(resolution)

func _ready() -> void:
 image = Image.create(resolution.x,resolution.y,false,Image.FORMAT_RGBA8)
 valid.resize(resolution.x*resolution.y)
 cut.resize(valid.size())
 for y in range(resolution.y):
  for x in range(resolution.x):
   if is_grass(cell_world(x,y)):
    valid[y*resolution.x+x] = 1
    total += 1
    image.set_pixel(x,y,Color(0,0,0,1))
 texture = ImageTexture.create_from_image(image)
 var mesh := PlaneMesh.new()
 mesh.size = field_size
 var surface := MeshInstance3D.new()
 surface.mesh = mesh
 var center := field_origin + field_size*0.5
 surface.position = Vector3(center.x,0.055,center.y)
 var mat := ShaderMaterial.new()
 mat.shader = load("res://shaders/grass.gdshader")
 mat.set_shader_parameter("state_mask",texture)
 surface.material_override = mat
 add_child(surface)

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
   cut[index] = 1
   cut_count += 1
   image.set_pixel(x,y,Color(1,absf(direction.z),0,1))
   dirty = true

func percentage() -> float:
 return 100.0*cut_count/maxi(total,1)

func _process(delta: float) -> void:
 elapsed += delta
 if dirty and elapsed >= 1.0/update_frequency:
  texture.update(image)
  completion_changed.emit(percentage())
  elapsed = 0
  dirty = false
