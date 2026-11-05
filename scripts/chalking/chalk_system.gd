class_name ChalkSystem
extends Node3D
signal completion_changed(percent: float)
@export var layout: FieldLayout = preload("res://resources/layouts/cedar_grove.tres")
var line_start: float:
 get:
  return layout.line_start
var line_end: float:
 get:
  return layout.line_end
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
var offguide_metres := 0.0
const STROKES_PER_MESH := 128

func line_direction(side: int) -> Vector2:
 return Vector2(-1 if side == 0 else 1,-1).normalized()

func section_center(side: int,index: int) -> Vector2:
 return layout.plate_position+line_direction(side)*(line_start+(index+0.5)*segment_step)

func is_protected(p: Vector2) -> bool:
 return layout.is_chalk_protected(p)

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
 set_process(false)

func build_guides() -> void:
 var mesh := BoxMesh.new()
 mesh.size = Vector3(0.055,0.006,0.5)
 var guide_material := ShaderMaterial.new()
 guide_material.shader = preload("res://shaders/chalk_guide.gdshader")
 mesh.material = guide_material
 var batch := MultiMesh.new()
 batch.transform_format = MultiMesh.TRANSFORM_3D
 batch.mesh = mesh
 var count := ceili((line_end-line_start)/1.25)
 batch.instance_count = count*2
 for side in range(2):
  var direction := line_direction(side)
  var work_basis := Basis(Vector3.UP,atan2(-direction.x,-direction.y))
  for i in range(count):
   var point := layout.plate_position+direction*(line_start+i*1.25+0.25)
   var pose := work_basis.scaled(Vector3.ZERO) if is_protected(point) else work_basis
   batch.set_instance_transform(side*count+i,Transform3D(pose,Vector3(point.x,layout.ground_height(point)+0.006,point.y)))
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
 mark_coverage(a,b)
 # Off-guide chalk is still drawn at its actual position; it earns no shortcut score.
 var steps := maxi(1,ceili(a.distance_to(b)/0.12))
 for i in range(steps):
  var start := a.lerp(b,float(i)/steps)
  var finish := a.lerp(b,float(i+1)/steps)
  if is_protected((start+finish)*0.5):
   continue
  if distance_to_guide(Vector3((start.x+finish.x)*0.5,0,(start.y+finish.y)*0.5)) > chalk_width*0.5:
   offguide_metres += start.distance_to(finish)
  var across := Vector2(-(finish-start).y,(finish-start).x).normalized()*chalk_width*0.5
  var corners := PackedVector3Array()
  for point in [start-across,start+across,finish+across,finish-across]:
   corners.append(Vector3(point.x,layout.ground_height(point)+0.025,point.y))
  pending.append(corners)
  stroke_archive.append(corners)
  dirty = true
  set_process(true)

func mark_coverage(a: Vector2,b: Vector2) -> void:
 for side in range(2):
  var direction := line_direction(side)
  var lo := mini(floori(((a-layout.plate_position).dot(direction)-line_start)/segment_step),floori(((b-layout.plate_position).dot(direction)-line_start)/segment_step))-1
  var hi := maxi(ceili(((a-layout.plate_position).dot(direction)-line_start)/segment_step),ceili(((b-layout.plate_position).dot(direction)-line_start)/segment_step))+1
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

func percentage() -> float:
 return 100.0*covered_count/maxi(valid_count,1)

func line_percentage(side: int) -> float:
 return 100.0*line_counts[side]/maxi(target_counts[side],1)

func distance_to_guide(point: Vector3) -> float:
 var p := Vector2(point.x,point.z)
 var result := INF
 for side in range(2):
  var direction := line_direction(side)
  result = minf(result,p.distance_to(Geometry2D.get_closest_point_to_segment(p,layout.plate_position+direction*line_start,layout.plate_position+direction*line_end)))
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
 if elapsed < 1.0/minf(10,update_frequency):
  return
 flush_visuals()
 if dirty:
  completion_changed.emit(percentage())
  dirty = false
 elapsed = 0
 set_process(false)

func reset_state() -> void:
 offguide_metres = 0
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
 set_process(false)
 completion_changed.emit(0)

func snapshot_coverage() -> PackedByteArray:
 return covered.duplicate()

func valid_sections() -> PackedByteArray:
 return valid.duplicate()

func snapshot_strokes() -> Array:
 return stroke_archive.duplicate(true)

func reset_quality() -> void:
 offguide_metres = 0

func replace_strokes(strokes: Array,coverage: PackedByteArray = PackedByteArray(),offguide: float = 0) -> void:
 reset_state()
 for stroke in strokes:
  stroke_archive.append(stroke.duplicate())
  pending.append(stroke.duplicate())
  if coverage.is_empty():
   var a: Vector3 = (stroke[0]+stroke[1])*0.5
   var b: Vector3 = (stroke[2]+stroke[3])*0.5
   mark_coverage(Vector2(a.x,a.z),Vector2(b.x,b.z))
 if not coverage.is_empty():
  covered = coverage.duplicate()
 recount()
 offguide_metres = offguide
 flush_visuals()
 dirty = false
 set_process(false)
 completion_changed.emit(percentage())

func recount() -> void:
 covered_count = 0
 line_counts = [0,0]
 for i in range(covered.size()):
  covered_count += covered[i]
  line_counts[i/sections_per_line] += covered[i]

func scuff_sections(clear: PackedByteArray) -> void:
 var keep := []
 for stroke in stroke_archive:
  var start: Vector3 = (stroke[0]+stroke[1])*0.5
  var finish: Vector3 = (stroke[2]+stroke[3])*0.5
  var a := Vector2(start.x,start.z)
  var b := Vector2(finish.x,finish.z)
  var remove := false
  for side in range(2):
   var direction := line_direction(side)
   var lo := floori((minf((a-layout.plate_position).dot(direction),(b-layout.plate_position).dot(direction))-line_start)/segment_step)-1
   var hi := ceili((maxf((a-layout.plate_position).dot(direction),(b-layout.plate_position).dot(direction))-line_start)/segment_step)+1
   for index in range(maxi(0,lo),mini(sections_per_line,hi+1)):
    if clear[side*sections_per_line+index] == 1 and section_center(side,index).distance_to(Geometry2D.get_closest_point_to_segment(section_center(side,index),a,b)) <= chalk_width*0.5:
     remove = true
     break
   if remove:
    break
  if not remove:
   keep.append(stroke)
 replace_strokes(keep)

func prepare_all() -> void:
 reset_state()
 for side in range(2):
  var direction := line_direction(side)
  paint_segment(layout.point3(layout.plate_position+direction*line_start),layout.point3(layout.plate_position+direction*line_end))
 flush_visuals()
 dirty = false
 set_process(false)
 completion_changed.emit(percentage())
