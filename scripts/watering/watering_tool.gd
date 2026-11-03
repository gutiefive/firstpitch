class_name WateringTool
extends Node3D
signal equipped_changed(equipped: bool)
@export var layout: FieldLayout = preload("res://resources/layouts/cedar_grove.tres")
var station_position: Vector3:
 get:
  return layout.water_station_position
@export var pickup_distance := 3.0
@export var hose_reach := 65.0
@export var spray_reach := 12.0
var player: Groundskeeper
var camera: Camera3D
var moisture: DirtMoisture
var surface_height: Callable
# Optional input adapter for headless tests; desktop play uses the actual cursor mode.
var capture_query: Callable
var equipped := false
var spraying := false
var target_valid := false
var target := Vector3.ZERO
var feedback := "READY"
var nozzle: Node3D
var droplets: MultiMeshInstance3D
var target_ring: MeshInstance3D
var hose_mesh: MeshInstance3D
var hose_segment: CylinderMesh
var hose_timer := 0.0
var last_hose_end := Vector3.INF
const G = preload("res://scripts/gameplay/geometry.gd")

func _ready() -> void:
 build_station()
 if player == null or moisture == null:
  return
 nozzle = Node3D.new()
 nozzle.name = "HeldWaterNozzle"
 nozzle.position = Vector3(0.32,1.02,-0.52)
 player.visual.add_child(nozzle)
 var barrel := G.cylinder(nozzle,Vector3(0,0,-0.12),0.035,0.3,Color("c8a55a"))
 barrel.rotation.x = PI/2
 G.box(nozzle,Vector3(0,-0.08,0.02),Vector3(0.055,0.14,0.055),Color("365f58"))
 nozzle.visible = false
 hose_mesh = MeshInstance3D.new()
 hose_mesh.material_override = G.material(Color("315b4c"))
 add_child(hose_mesh)
 hose_segment = CylinderMesh.new()
 hose_segment.top_radius = 0.025
 hose_segment.bottom_radius = 0.025
 hose_segment.height = 1
 hose_segment.radial_segments = 6
 var batch := MultiMesh.new()
 batch.transform_format = MultiMesh.TRANSFORM_3D
 var drop := SphereMesh.new()
 drop.radius = 0.035
 drop.height = 0.07
 drop.radial_segments = 8
 drop.rings = 4
 batch.mesh = drop
 batch.instance_count = 36
 droplets = MultiMeshInstance3D.new()
 droplets.multimesh = batch
 droplets.material_override = G.material(Color("a1d3dc"))
 droplets.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 add_child(droplets)
 target_ring = G.ring(self,Vector3.ZERO,moisture.spray_radius-0.025,moisture.spray_radius,Color("83c4cf"))
 target_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 set_visuals_off()

func build_station() -> void:
 G.box(self,station_position+Vector3(0,0.65,0),Vector3(0.7,1.3,0.45),Color("28585a"),true)
 for side in [-1,1]:
  var reel := G.cylinder(self,station_position+Vector3(side*0.26,1,0),0.4,0.06,Color("c9b079"))
  reel.rotation.z = PI/2
 var coil := G.cylinder(self,station_position+Vector3(0,1,0),0.32,0.45,Color("315b4c"))
 coil.rotation.z = PI/2
 G.box(self,station_position+Vector3(0,1.7,0),Vector3(2.1,0.5,0.12),Color("eee3c6"))
 var sign := G.label(self,"WATER STATION\nF  TAKE / STOW HOSE",station_position+Vector3(0,1.7,0.08),34)
 sign.pixel_size = 0.004
 sign.modulate = Color("28585a")

func toggle_equipped() -> bool:
 if player == null or player.seated:
  return false
 if not equipped and player.global_position.distance_to(station_position) > pickup_distance:
  return false
 set_equipped(not equipped)
 return true

func set_equipped(value: bool) -> void:
 equipped = value
 spraying = false
 nozzle.visible = value
 (player.visual as CrewVisual).watering_pose = value
 if not value:
  set_visuals_off()
 equipped_changed.emit(value)

func set_visuals_off() -> void:
 droplets.visible = false
 target_ring.visible = false
 hose_mesh.visible = false

func height_at(point: Vector2) -> float:
 return float(surface_height.call(point)) if surface_height.is_valid() else 0.0

func can_reach(point: Vector3) -> bool:
 return player.global_position.distance_to(station_position) <= hose_reach and nozzle.global_position.distance_to(point) <= spray_reach

func unobstructed(point: Vector3) -> bool:
 var query := PhysicsRayQueryParameters3D.create(nozzle.global_position,point+Vector3.UP*0.03,1,[player.get_rid()])
 var hit := get_world_3d().direct_space_state.intersect_ray(query)
 return hit.is_empty() or (hit.position as Vector3).distance_to(point) < 0.25

func apply_spray(point: Vector3,delta: float) -> bool:
 if not equipped or player.seated or not player.is_on_floor() or not can_reach(point) or not unobstructed(point):
  return false
 moisture.spray_at(point,delta)
 return true

func cursor_is_captured() -> bool:
 return bool(capture_query.call()) if capture_query.is_valid() else Input.mouse_mode == Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
 if player == null or moisture == null or nozzle == null:
  return
 spraying = false
 target_valid = false
 if not equipped or player.seated:
  set_visuals_off()
  return
 # Keep the held hand tool facing the camera's aim while walking or standing.
 player.visual.rotation.y = lerp_angle(player.visual.rotation.y,player.yaw,1-exp(-12*delta))
 var center := get_viewport().get_visible_rect().size*0.5
 var start := camera.project_ray_origin(center)
 var end := start+camera.project_ray_normal(center)*150
 var query := PhysicsRayQueryParameters3D.create(start,end,1,[player.get_rid()])
 var hit := get_world_3d().direct_space_state.intersect_ray(query)
 feedback = "AIM AT GROUND"
 if not hit.is_empty() and (hit.normal as Vector3).y > 0.8 and (hit.position as Vector3).y < 0.25:
  target = hit.position
  if player.global_position.distance_to(station_position) > hose_reach:
   feedback = "HOSE OUT OF REACH"
  elif not can_reach(target):
   feedback = "TARGET TOO FAR"
  elif not unobstructed(target):
   feedback = "SPRAY BLOCKED"
  else:
   target_valid = true
   feedback = "HOLD LMB TO SOAK" if moisture.is_workable(target) else "NO WORKABLE DIRT"
   if cursor_is_captured() and Input.is_action_pressed("spray_water"):
    spraying = apply_spray(target,delta)
    if spraying and moisture.is_workable(target):
     feedback = "SOAKING DIRT"
   if moisture.is_workable(target) and moisture.moisture_at(target) >= moisture.target_moisture:
    feedback = "AIM POINT SOAKED"
 if not cursor_is_captured():
  feedback = "ESC TO RECAPTURE CURSOR"
 if target_valid:
  var point := Vector2(target.x,target.z)
  target_ring.global_position = Vector3(target.x,height_at(point)+0.04,target.z)
  nozzle.look_at(target+Vector3.UP*0.05)
 target_ring.visible = target_valid
 droplets.visible = spraying
 if spraying:
  update_droplets()
 hose_timer += delta
 if hose_timer >= 0.1 and nozzle.global_position.distance_to(last_hose_end) > 0.1:
  rebuild_hose()
  last_hose_end = nozzle.global_position
  hose_timer = 0
 hose_mesh.visible = true

func update_droplets() -> void:
 var start := nozzle.global_position-nozzle.global_basis.z*0.28
 var finish := Vector3(target.x,height_at(Vector2(target.x,target.z))+0.04,target.z)
 var time := Time.get_ticks_msec()*0.001
 for index in range(droplets.multimesh.instance_count):
  var t := fposmod(float(index)/droplets.multimesh.instance_count+time*1.4,1)
  var scatter := Vector3(sin(index*2.4),0,cos(index*2.4))*t*t*moisture.spray_radius*0.75
  var point := start.lerp(finish,t)+Vector3.UP*sin(t*PI)*0.35+scatter
  droplets.multimesh.set_instance_transform(index,Transform3D(Basis.IDENTITY,point))

func rebuild_hose() -> void:
 var end := nozzle.global_position+nozzle.global_basis.z*0.06
 var offset := Vector2(end.x-station_position.x,end.z-station_position.z)
 var across := Vector2(-offset.y,offset.x).normalized()*minf(1.4,offset.length()*0.04)
 var points := PackedVector3Array()
 for i in range(25):
  var t := i/24.0
  var xz := Vector2(station_position.x,station_position.z).lerp(Vector2(end.x,end.z),t)+across*sin(t*PI)
  var ground := height_at(xz)+0.035
  var y := lerpf(station_position.y+0.8,ground,smoothstep(0,0.16,t))
  if t > 0.84:
   y = lerpf(ground,end.y,smoothstep(0.84,1,t))
  points.append(Vector3(xz.x,y,xz.y))
 var geometry := SurfaceTool.new()
 geometry.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in range(points.size()-1):
  var direction := points[i+1]-points[i]
  var basis := Basis(Quaternion(Vector3.UP,direction.normalized())).scaled(Vector3(1,direction.length(),1))
  geometry.append_from(hose_segment,0,Transform3D(basis,(points[i+1]+points[i])*0.5))
 hose_mesh.mesh = geometry.commit()
