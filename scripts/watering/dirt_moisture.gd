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
var puddle_time := PackedFloat32Array()
var overwatered := PackedByteArray()
var active_puddles := PackedInt32Array()
var overwatered_count := 0
var image: Image
var texture: ImageTexture
var watered_image: Image
var watered_texture: ImageTexture
var puddle_image: Image
var puddle_texture: ImageTexture
var total := 0
var wet_count := 0
var dirty := false
var elapsed := 0.0
var quality_rules := ShiftSession.quality_rules()

func bind_surface(value: InfieldSurface) -> void:
 surface = value
 surface.moisture_source = self
 total = surface.total
 moisture.resize(surface.valid.size())
 watered.resize(surface.valid.size())
 puddle_time.resize(surface.valid.size())
 overwatered.resize(surface.valid.size())
 image = Image.create(surface.resolution.x,surface.resolution.y,false,Image.FORMAT_R8)
 puddle_image = Image.create(surface.resolution.x,surface.resolution.y,false,Image.FORMAT_R8)
 watered_image = Image.create(surface.resolution.x,surface.resolution.y,false,Image.FORMAT_R8)
 watered_texture = ImageTexture.create_from_image(watered_image)
 texture = ImageTexture.create_from_image(image)
 puddle_texture = ImageTexture.create_from_image(puddle_image)
 surface.surface_material.set_shader_parameter("moisture_mask",texture)
 surface.surface_material.set_shader_parameter("watered_mask",watered_texture)
 surface.surface_material.set_shader_parameter("puddle_mask",puddle_texture)
 set_process(false)

func moisture_at(point: Vector3) -> float:
 var cell := surface.world_to_grid(point)
 if cell.x < 0 or cell.y < 0 or cell.x >= surface.resolution.x or cell.y >= surface.resolution.y:
  return 0
 return moisture[cell.y*surface.resolution.x+cell.x]

func is_puddle(index: int) -> bool:
 return index >= 0 and index < puddle_time.size() and puddle_time[index] > 0

func puddle_at(point: Vector3) -> bool:
 var cell := surface.world_to_grid(point)
 return is_puddle(cell.y*surface.resolution.x+cell.x) if cell.x >= 0 and cell.y >= 0 and cell.x < surface.resolution.x and cell.y < surface.resolution.y else false

func is_workable(point: Vector3) -> bool:
 var local := surface.to_local(point)
 return surface.is_workable(Vector2(local.x,local.z))

func spray_at(point: Vector3,delta: float) -> void:
 if surface == null or delta <= 0:
  return
 var grid := surface.world_to_grid(point)
 var local := surface.to_local(point)
 var rx := ceili(spray_radius/surface.field_size.x*surface.resolution.x)+1
 var ry := ceili(spray_radius/surface.field_size.y*surface.resolution.y)+1
 for y in range(maxi(0,grid.y-ry),mini(surface.resolution.y,grid.y+ry+1)):
  for x in range(maxi(0,grid.x-rx),mini(surface.resolution.x,grid.x+rx+1)):
   var index := y*surface.resolution.x+x
   if surface.valid[index] == 0:
    continue
   var distance := surface.cell_world(x,y).distance_to(Vector2(local.x,local.z))
   if distance > spray_radius:
    continue
   var dose := application_rate*delta*(0.35+0.65*(1-distance/spray_radius))
   moisture[index] = minf(1,moisture[index]+dose)
   if watered[index] == 0 and moisture[index] >= target_moisture:
    watered[index] = 1
    wet_count += 1
    watered_image.set_pixel(x,y,Color(1,0,0,1))
   if moisture[index] >= float(quality_rules.puddle_threshold):
    if puddle_time[index] <= 0:
     active_puddles.append(index)
    puddle_time[index] = float(quality_rules.puddle_seconds)
    puddle_image.set_pixel(x,y,Color(1,0,0,1))
    if overwatered[index] == 0:
     overwatered[index] = 1
     overwatered_count += 1
   image.set_pixel(x,y,Color(moisture[index],0,0,1))
   dirty = true
 set_process(dirty or not active_puddles.is_empty())

func percentage() -> float:
 return 100.0*wet_count/maxi(total,1)

func advance_drying(delta: float) -> void:
 if delta <= 0 or active_puddles.is_empty():
  return
 var remaining := PackedInt32Array()
 for index in active_puddles:
  puddle_time[index] = maxf(0,puddle_time[index]-delta)
  if puddle_time[index] > 0:
   remaining.append(index)
  else:
   moisture[index] = minf(moisture[index],float(quality_rules.dry_moisture))
   var qualified := int(moisture[index] >= target_moisture)
   wet_count += qualified-watered[index]
   watered[index] = qualified
   watered_image.set_pixel(index%surface.resolution.x,index/surface.resolution.x,Color(qualified,0,0,1))
   var p := Vector2i(index%surface.resolution.x,index/surface.resolution.x)
   image.set_pixelv(p,Color(moisture[index],0,0,1))
   puddle_image.set_pixelv(p,Color(0,0,0,1))
   dirty = true
 active_puddles = remaining

func _process(delta: float) -> void:
 advance_drying(delta)
 elapsed += delta
 if dirty and elapsed >= 1.0/minf(10,update_frequency):
  refresh_texture()
 if not dirty and active_puddles.is_empty():
  set_process(false)

func refresh_texture() -> void:
 texture.update(image)
 watered_texture.update(watered_image)
 puddle_texture.update(puddle_image)
 elapsed = 0
 dirty = false
 completion_changed.emit(percentage())
 set_process(not active_puddles.is_empty())

func snapshot_moisture() -> PackedFloat32Array:
 return moisture.duplicate()

func has_exposure() -> bool:
 for i in surface.work_indices():
  if moisture[i] > 0:
   return true
 return false

func replace_moisture(values: PackedFloat32Array,timers: PackedFloat32Array = PackedFloat32Array(),marks: PackedByteArray = PackedByteArray()) -> void:
 moisture = values.duplicate()
 puddle_time.fill(0)
 overwatered.fill(0)
 if not timers.is_empty():
  puddle_time = timers.duplicate()
 if not marks.is_empty():
  overwatered = marks.duplicate()
 recount()
 refresh_texture()

func recount() -> void:
 wet_count = 0
 overwatered_count = 0
 watered.fill(0)
 active_puddles.clear()
 image.fill(Color(0,0,0,1))
 watered_image.fill(Color(0,0,0,1))
 puddle_image.fill(Color(0,0,0,1))
 for i in surface.work_indices():
  var p := Vector2i(i%surface.resolution.x,i/surface.resolution.x)
  watered[i] = int(moisture[i] >= target_moisture)
  wet_count += watered[i]
  watered_image.set_pixelv(p,Color(watered[i],0,0,1))
  overwatered_count += overwatered[i]
  image.set_pixelv(p,Color(moisture[i],0,0,1))
  if puddle_time[i] > 0:
   active_puddles.append(i)
   puddle_image.set_pixelv(p,Color(1,0,0,1))

func fill_valid(value: float) -> void:
 var values := moisture.duplicate()
 for i in surface.work_indices():
  values[i] = clampf(value,0,1)
 replace_moisture(values)

func reset_quality() -> void:
 overwatered.fill(0)
 overwatered_count = 0

func reset_state() -> void:
 moisture.fill(0)
 watered.fill(0)
 puddle_time.fill(0)
 active_puddles.clear()
 reset_quality()
 wet_count = 0
 image.fill(Color(0,0,0,1))
 watered_image.fill(Color(0,0,0,1))
 puddle_image.fill(Color(0,0,0,1))
 refresh_texture()
