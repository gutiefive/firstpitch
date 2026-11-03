class_name DirtMoisture
extends Node
signal completion_changed(percent: float)
@export var spray_radius := 1.8
@export var application_rate := 0.8
@export var target_moisture := 0.65
@export var update_frequency := 10.0
var surface: InfieldSurface
var moisture := PackedFloat32Array()
var watered := PackedByteArray()
var image: Image
var texture: ImageTexture
var total := 0
var wet_count := 0
var dirty := false
var elapsed := 0.0

func bind_surface(value: InfieldSurface) -> void:
 surface = value
 total = surface.total
 moisture.resize(surface.valid.size())
 watered.resize(surface.valid.size())
 moisture.fill(0)
 watered.fill(0)
 wet_count = 0
 dirty = false
 image = Image.create(surface.resolution.x,surface.resolution.y,false,Image.FORMAT_R8)
 texture = ImageTexture.create_from_image(image)
 surface.surface_material.set_shader_parameter("moisture_mask",texture)

func moisture_at(point: Vector3) -> float:
 var cell := surface.world_to_grid(point)
 if cell.x < 0 or cell.y < 0 or cell.x >= surface.resolution.x or cell.y >= surface.resolution.y:
  return 0
 return moisture[cell.y*surface.resolution.x+cell.x]

func is_workable(point: Vector3) -> bool:
 var local := surface.to_local(point)
 return surface.is_workable(Vector2(local.x,local.z))

func spray_at(point: Vector3,delta: float) -> void:
 if surface == null or delta <= 0:
  return
 var grid := surface.world_to_grid(point)
 var local := surface.to_local(point)
 var radius := spray_radius
 var rx := ceili(radius/surface.field_size.x*surface.resolution.x)+1
 var ry := ceili(radius/surface.field_size.y*surface.resolution.y)+1
 for y in range(maxi(0,grid.y-ry),mini(surface.resolution.y,grid.y+ry+1)):
  for x in range(maxi(0,grid.x-rx),mini(surface.resolution.x,grid.x+rx+1)):
   var index := y*surface.resolution.x+x
   if surface.valid[index] == 0 or moisture[index] >= 1:
    continue
   var distance := surface.cell_world(x,y).distance_to(Vector2(local.x,local.z))
   if distance > radius:
    continue
   var dose := application_rate*delta*(0.35+0.65*(1-distance/radius))
   moisture[index] = minf(1,moisture[index]+dose)
   if watered[index] == 0 and moisture[index] >= target_moisture:
    watered[index] = 1
    wet_count += 1
   image.set_pixel(x,y,Color(moisture[index],0,0,1))
   dirty = true

func percentage() -> float:
 return 100.0*wet_count/maxi(total,1)

func _process(delta: float) -> void:
 elapsed += delta
 if dirty and elapsed >= 1.0/update_frequency:
  texture.update(image)
  completion_changed.emit(percentage())
  elapsed = 0
  dirty = false

func reset_state() -> void:
 moisture.fill(0)
 watered.fill(0)
 wet_count = 0
 image.fill(Color(0,0,0,1))
 texture.update(image)
 dirty = false
 elapsed = 0
 completion_changed.emit(0)
