class_name CrewInspection
extends Node
var game: Node
var enabled := false
var selected := -1
var elapsed := 0.0
var refreshes := 0
var missing_markers := 0
var chalk_markers: MultiMeshInstance3D
var mound_markers: MultiMeshInstance3D
var chalk_poses: Array[Transform3D] = []
var mound_poses: Array[Transform3D] = []
func _ready() -> void:
 var chalk_mesh := BoxMesh.new()
 chalk_mesh.size = Vector3(0.34,0.012,game.chalk.segment_step*0.85)
 chalk_markers = batch(chalk_mesh,game.chalk.covered.size())
 for i in range(game.chalk.covered.size()):
  var side: int = i/game.chalk.sections_per_line
  var p: Vector2 = game.chalk.section_center(side,i%game.chalk.sections_per_line)
  var direction: Vector2 = game.chalk.line_direction(side)
  chalk_poses.append(Transform3D(Basis(Vector3.UP,atan2(-direction.x,-direction.y)),Vector3(p.x,game.layout.ground_height(p)+0.045,p.y)))
 var clay := CylinderMesh.new()
 clay.top_radius = game.mound.patch_radius+0.1
 clay.bottom_radius = clay.top_radius
 clay.height = 0.015
 clay.radial_segments = 24
 mound_markers = batch(clay,game.mound.hits.size())
 for i in range(game.mound.hits.size()):
  mound_poses.append(Transform3D(Basis.IDENTITY,game.mound.patch_world(i)+Vector3.UP*0.02))
 for surface in [game.grass,game.infield,game.chalk,game.moisture,game.mound]:
  surface.completion_changed.connect(mark_dirty)
 game.input_device.device_changed.connect(refresh_labels)
 set_process(false)
func batch(mesh: Mesh,count: int) -> MultiMeshInstance3D:
 var node := MultiMeshInstance3D.new()
 var instances := MultiMesh.new()
 instances.transform_format = MultiMesh.TRANSFORM_3D
 instances.mesh = mesh
 instances.instance_count = count
 node.multimesh = instances
 var material := StandardMaterial3D.new()
 material.albedo_color = Color("e1bb67")
 material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 node.material_override = material
 node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 game.add_child(node)
 node.visible = false
 return node
func available_jobs() -> Array:
 var jobs := []
 for i in range(5):
  if game.shift.session.phase != ShiftSession.Phase.ACTIVE or game.shift.session.goals()[i] > 0:
   jobs.append(i)
 return jobs
func cycle(direction: int) -> void:
 var jobs := available_jobs()
 var index := jobs.find(game.selected_task)
 if index < 0:
  index = -1 if direction > 0 else 0
 game.selected_task = jobs[posmod(index+direction,jobs.size())]
 game.update_progress(0)
func set_enabled(value: bool) -> void:
 enabled = value
 selected = -1
 refresh_selection()
func refresh_selection() -> void:
 if selected == game.selected_task:
  return
 selected = game.selected_task
 game.grass.set_inspection(enabled and selected == 0)
 game.infield.surface_material.set_shader_parameter("inspection_job",selected if enabled else -1)
 game.chalk.guides.visible = not (enabled and selected == 2)
 chalk_markers.visible = enabled and selected == 2
 mound_markers.visible = enabled and selected == 4
 game.hud.inspection_panel.visible = enabled
 if enabled:
  refresh()
 else:
  set_process(false)
func mark_dirty(_percent: float) -> void:
 if enabled:
  set_process(true)
func _process(delta: float) -> void:
 elapsed += delta
 if elapsed >= 0.1:
  refresh()
func refresh() -> void:
 missing_markers = 0
 if selected == 2 or selected == 4:
  var poses: Array[Transform3D] = chalk_poses if selected == 2 else mound_poses
  var node := chalk_markers if selected == 2 else mound_markers
  for i in range(poses.size()):
   var missing: bool = game.chalk.valid[i] == 1 and game.chalk.covered[i] == 0 if selected == 2 else game.mound.hits[i] < game.mound.hits_required
   node.multimesh.set_instance_transform(i,poses[i] if missing else Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO),Vector3.ZERO))
   missing_markers += int(missing)
 refresh_labels()
 elapsed = 0
 refreshes += 1
 set_process(false)
func refresh_labels() -> void:
 if not enabled:
  return
 var counts: Array = game.shift.counts()
 var totals: Array = game.shift.totals()
 var remaining := maxi(0,int(totals[selected])-int(counts[selected]))
 var descriptions := ["Gold: uncut grass · Teal: cut","Gold: rough dirt · Orange: ruts · Blue: puddles block drag","Gold bars: missing guide sections","Gold: needs water · Teal: target reached · Blue: stop watering","Gold discs: patches needing impacts"]
 var units := ["grass cells","dirt cells","chalk sections","dirt cells","mound impacts"]
 game.hud.inspection_title.text = "INSPECT · "+ShiftSession.JOB_NAMES[selected]
 game.hud.inspection_legend.text = "%s\n%d %s left" % [descriptions[selected],remaining,units[selected]]
 if selected == 1:
  game.hud.inspection_legend.text += " · %d rutted" % game.infield.rut_count
 game.hud.inspection_controls.text = "%s / %s Job · %s Exit inspection" % [game.binding_text("previous_job"),game.binding_text("next_job"),game.binding_text("inspect_field")]
func _unhandled_input(event: InputEvent) -> void:
 if get_tree().paused or (event is InputEventKey and event.echo):
  return
 if event.is_action_pressed("inspect_field"):
  set_enabled(not enabled)
 elif event.is_action_pressed("previous_job"):
  cycle(-1)
 elif event.is_action_pressed("next_job"):
  cycle(1)
 else:
  return
 get_viewport().set_input_as_handled()
