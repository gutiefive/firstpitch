class_name MoundSurface
extends Node3D
signal completion_changed(percent: float)
@export var top_height := 0.36
@export var patch_radius := 0.42
@export var hits_required := 3
@export var patch_positions := PackedVector2Array([Vector2(-0.75,0.25),Vector2(0,1.25),Vector2(0.8,0.7),Vector2(-1.35,-0.55),Vector2(1.25,-0.6),Vector2(0.25,-1.4)])
var hits := PackedInt32Array()
var work_done := 0
var repaired_count := 0
var total_work := 0
var materials: Array[ShaderMaterial] = []
var clumps: Array[Node3D] = []

func _ready() -> void:
 hits.resize(patch_positions.size())
 total_work = hits_required*patch_positions.size()
 for index in range(patch_positions.size()):
  var point := patch_positions[index]
  var plane := MeshInstance3D.new()
  plane.name = "WornClayPatch"+str(index+1)
  var mesh := PlaneMesh.new()
  mesh.size = Vector2.ONE*patch_radius*2
  plane.mesh = mesh
  plane.position = Vector3(point.x,top_height+0.009,point.y)
  var mat := ShaderMaterial.new()
  mat.shader = preload("res://shaders/mound_patch.gdshader")
  mat.set_shader_parameter("dark_color",Color("a96140").srgb_to_linear())
  mat.set_shader_parameter("light_color",Color("bd7950").srgb_to_linear())
  plane.material_override = mat
  add_child(plane)
  materials.append(mat)
  var lumps := Node3D.new()
  lumps.position = Vector3(point.x,top_height,point.y)
  add_child(lumps)
  for i in range(3):
   var angle := index+i*TAU/3
   var lump := ParkGeometry.sphere(lumps,Vector3(sin(angle)*0.3,0.025,cos(angle)*0.3),Vector3(0.15,0.05,0.12),Color("905431"))
   lump.rotation.y = angle
  clumps.append(lumps)

func patch_world(index: int) -> Vector3:
 var point := patch_positions[index]
 return to_global(Vector3(point.x,top_height,point.y))

func patch_at(point: Vector3) -> int:
 var local := to_local(point)
 var flat := Vector2(local.x,local.z)
 for index in range(patch_positions.size()):
  if flat.distance_to(patch_positions[index]) <= patch_radius:
   return index
 return -1

func apply_tamp(index: int) -> bool:
 if index < 0 or index >= hits.size() or hits[index] >= hits_required:
  return false
 hits[index] += 1
 work_done += 1
 if hits[index] == hits_required:
  repaired_count += 1
 var fraction := float(hits[index])/hits_required
 materials[index].set_shader_parameter("compaction",fraction)
 clumps[index].scale.y = maxf(0.01,1-fraction)
 clumps[index].visible = fraction < 1
 completion_changed.emit(percentage())
 return true

func percentage() -> float:
 return 100.0*work_done/maxi(total_work,1)

func reset_state() -> void:
 hits.fill(0)
 work_done = 0
 repaired_count = 0
 for index in range(hits.size()):
  materials[index].set_shader_parameter("compaction",0.0)
  clumps[index].scale.y = 1
  clumps[index].visible = true
 completion_changed.emit(0)
