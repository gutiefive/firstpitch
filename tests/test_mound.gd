extends SceneTree
var failures := 0
func check(condition: bool,message: String) -> void:
 if condition:
  print("PASS: ",message)
 else:
  push_error(message)
  failures += 1
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var mound := MoundSurface.new()
 mound.position = mound.layout.point3(mound.layout.mound_position)
 root.add_child(mound)
 check(mound.hits.size() == 6 and mound.total_work == 18,"six clay patches require eighteen total strokes")
 check(mound.percentage() == 0 and mound.repaired_count == 0,"mound begins worn and unrepaired")
 check(mound.patch_at(mound.patch_world(0)) == 0,"world target maps to correct patch")
 check(mound.patch_at(mound.layout.point3(mound.layout.mound_position,mound.layout.mound_height)) == -1,"pitching rubber is not a repair patch")
 check(mound.patch_at(Vector3(10,0,-10)) == -1,"off-mound dirt is not a repair target")
 check(not mound.apply_tamp(-1) and not mound.apply_tamp(99),"invalid patch indices cannot earn work")
 var events := [0]
 mound.completion_changed.connect(func(_value: float): events[0] += 1)
 check(mound.apply_tamp(0),"first valid stroke is accepted")
 check(mound.hits[0] == 1 and mound.work_done == 1 and mound.repaired_count == 0,"partial compaction is tracked without declaring repair")
 check(is_equal_approx(float(mound.materials[0].get_shader_parameter("compaction")),1.0/3),"stroke updates visible clay compaction")
 check(mound.clumps[0].scale.y < 1 and mound.clumps[0].visible,"partly repaired clay clumps visibly settle")
 mound.apply_tamp(0)
 mound.apply_tamp(0)
 check(mound.repaired_count == 1 and not mound.clumps[0].visible,"third stroke finishes and flattens patch")
 check(not mound.apply_tamp(0) and mound.work_done == 3,"repeated strikes cannot overcount repaired patch")
 check(mound.hits[1] == 0,"repairing one patch leaves other patches worn")
 for index in range(1,mound.hits.size()):
  for hit in range(mound.hits_required):
   mound.apply_tamp(index)
 check(mound.work_done == mound.total_work and mound.repaired_count == mound.hits.size(),"all distinct patches can be fully repaired")
 check(mound.percentage() == 100,"complete repair is exactly 100 percent")
 check(events[0] == mound.total_work,"only accepted strokes publish work events")
 print("Mound failures: ",failures)
 quit(1 if failures else 0)
