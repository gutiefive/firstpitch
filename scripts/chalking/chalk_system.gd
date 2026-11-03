class_name ChalkSystem
extends Node3D
signal completion_changed(percent: float)
@export var line_start := 0.8
@export var line_end := 103.0
@export var section_length := 0.25
@export var chalk_width := 0.22
@export var update_frequency := 10.0
var covered := PackedByteArray()
var valid := PackedByteArray()
var valid_count := 0
var target_counts := [0,0]
var sections_per_line := 0
var covered_count := 0
var line_counts := [0,0]
var segment_step := 0.0
var guides: MultiMeshInstance3D
var stroke_archive: Array[PackedVector3Array] = []
var pending: Array[PackedVector3Array] = []
var active_strokes: Array[PackedVector3Array] = []
var active_mesh: MeshInstance3D
var chalk_material: StandardMaterial3D
var dirty := false
var elapsed := 0.0
const STROKES_PER_MESH := 128

func line_direction(side: int) -> Vector2:
 return Vector2(-1 if side == 0 else 1,-1).normalized()

func section_center(side: int,index: int) -> Vector2:
 return line_direction(side)*(line_start+(index+0.5)*segment_step)

func is_protected(p: Vector2) -> bool:
 if p.length() < 0.7:
  return true
 for base in [Vector2(19.396,-19.396),Vector2(-19.396,-19.396)]:
  if p.distance_to(base) < 0.55:
   return true
 return false

func ground_height(p: Vector2) -> float:
 var mound_distance := p.distance_to(Vector2(0,-18.44))
 if mound_distance <= 2.2:
  return 0.36
 if mound_distance < 2.8:
  return 0.36*(2.8-mound_distance)/0.6
 for base in [Vector2(19.396,-19.396),Vector2(0,-38.792),Vector2(-19.396,-19.396)]:
  if p.distance_to(base) < 0.38:
   return 0.18
 if p.length() < 6:
  return 0.13
 var diamond := absf(p.x)+absf(p.y+19.396)
 if diamond <= 15.556:
  return 0.083
 if diamond <= 21.921:
  return 0.0375
 if p.y < 0 and absf(p.x) <= -p.y and p.length() <= 99:
  return 0.055
 if p.y < 0 and absf(p.x) <= -p.y and p.length() <= 104:
  return 0.06
 if p.x >= 26.5 and p.x <= 39.5 and p.y >= -23.5 and p.y <= -14.5:
  return 0.05
 if absf(p.x) <= 31.5 and p.y >= 18 and p.y <= 26:
  return 0.035
 return 0

func _ready() -> void:
 sections_per_line = maxi(1,ceili((line_end-line_start)/section_length))
 segment_step = (line_end-line_start)/sections_per_line
 covered.resize(sections_per_line*2)
 valid.resize(covered.size())
 for side in range(2):
  for index in range(sections_per_line):
   if not is_protected(section_center(side,index)):
    valid[side*sections_per_line+index] = 1
    valid_count += 1
    target_counts[side] += 1
 chalk_material = ParkGeometry.material(Color("f5edd6")).duplicate() as StandardMaterial3D
 chalk_material.cull_mode = BaseMaterial3D.CULL_DISABLED
 build_guides()

func build_guides() -> void:
 var mesh := BoxMesh.new()
 mesh.size = Vector3(0.055,0.006,0.5)
 mesh.material = ParkGeometry.material(Color("bda76b"))
 var batch := MultiMesh.new()
 batch.transform_format = MultiMesh.TRANSFORM_3D
 batch.mesh = mesh
 var count := ceili((line_end-line_start)/1.25)
 batch.instance_count = count*2
 for side in range(2):
  var direction := line_direction(side)
  var basis := Basis(Vector3.UP,atan2(-direction.x,-direction.y))
  for i in range(count):
   var point := direction*(line_start+i*1.25+0.25)
   var pose := basis.scaled(Vector3.ZERO) if is_protected(point) else basis
   batch.set_instance_transform(side*count+i,Transform3D(pose,Vector3(point.x,ground_height(point)+0.006,point.y)))
 guides = MultiMeshInstance3D.new()
 guides.name = "FoulLineGuides"
 guides.multimesh = batch
 guides.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 add_child(guides)

func paint_segment(from: Vector3,to: Vector3) -> void:
 var a := Vector2(from.x,from.z)
 var b := Vector2(to.x,to.z)
 if a.distance_to(b) < 0.001:
  return
 # Section coverage is measured against the actual continuous chalk stroke.
 for side in range(2):
  var direction := line_direction(side)
  var lo := mini(floori((a.dot(direction)-line_start)/segment_step),floori((b.dot(direction)-line_start)/segment_step))-1
  var hi := maxi(ceili((a.dot(direction)-line_start)/segment_step),ceili((b.dot(direction)-line_start)/segment_step))+1
  for index in range(maxi(0,lo),mini(sections_per_line,hi+1)):
   var key := side*sections_per_line+index
   if valid[key] == 0 or covered[key] == 1:
    continue
   var center := section_center(side,index)
   if center.distance_to(Geometry2D.get_closest_point_to_segment(center,a,b)) <= chalk_width*0.5:
    covered[key] = 1
    covered_count += 1
    line_counts[side] += 1
    dirty = true
 # Off-guide chalk is still drawn at its actual position; it earns no shortcut score.
 var steps := maxi(1,ceili(a.distance_to(b)/0.12))
 for i in range(steps):
  var start := a.lerp(b,float(i)/steps)
  var finish := a.lerp(b,float(i+1)/steps)
  if is_protected((start+finish)*0.5):
   continue
  var across := Vector2(-(finish-start).y,(finish-start).x).normalized()*chalk_width*0.5
  var corners := PackedVector3Array()
  for point in [start-across,start+across,finish+across,finish-across]:
   corners.append(Vector3(point.x,ground_height(point)+0.025,point.y))
  pending.append(corners)
  stroke_archive.append(corners)

func percentage() -> float:
 return 100.0*covered_count/maxi(valid_count,1)

func line_percentage(side: int) -> float:
 return 100.0*line_counts[side]/maxi(target_counts[side],1)

func distance_to_guide(point: Vector3) -> float:
 var p := Vector2(point.x,point.z)
 var result := INF
 for side in range(2):
  var direction := line_direction(side)
  result = minf(result,p.distance_to(Geometry2D.get_closest_point_to_segment(p,direction*line_start,direction*line_end)))
 return result

func rebuild_active_mesh() -> void:
 var geometry := SurfaceTool.new()
 geometry.begin(Mesh.PRIMITIVE_TRIANGLES)
 for stroke in active_strokes:
  for i in [0,2,1,0,3,2]:
   geometry.set_normal(Vector3.UP)
   geometry.add_vertex(stroke[i])
 active_mesh.mesh = geometry.commit()

func flush_visuals() -> void:
 if pending.is_empty():
  return
 for stroke in pending:
  if active_mesh == null:
   active_mesh = MeshInstance3D.new()
   active_mesh.name = "ChalkStrokeBatch"
   active_mesh.material_override = chalk_material
   active_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
   add_child(active_mesh)
  active_strokes.append(stroke)
  if active_strokes.size() == STROKES_PER_MESH:
   rebuild_active_mesh()
   active_mesh = null
   active_strokes.clear()
 pending.clear()
 if active_mesh != null and not active_strokes.is_empty():
  rebuild_active_mesh()

func _process(delta: float) -> void:
 elapsed += delta
 if elapsed < 1.0/update_frequency:
  return
 flush_visuals()
 if dirty:
  completion_changed.emit(percentage())
  dirty = false
 elapsed = 0

func reset_state() -> void:
 covered.fill(0)
 covered_count = 0
 line_counts = [0,0]
 pending.clear()
 stroke_archive.clear()
 active_strokes.clear()
 active_mesh = null
 for child in get_children():
  if child != guides:
   remove_child(child)
   child.queue_free()
 dirty = false
 elapsed = 0
 completion_changed.emit(0)
