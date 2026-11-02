extends SceneTree
var failures := 0
func check(condition: bool,message: String) -> void:
 if not condition:
  push_error(message)
  failures += 1
 else:
  print("PASS: ",message)

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var grass := MowingGrass.new()
 root.add_child(grass)
 check(grass.world_to_grid(Vector3(-75,0,-110)) == Vector2i.ZERO,"grid origin")
 check(grass.world_to_grid(Vector3.ZERO) == Vector2i(225,330),"world origin mapping")
 check(grass.total > 0,"mowable grass exists")
 grass.paint(Vector3(0,0,-18.44),Vector3.FORWARD)
 check(grass.cut_count == 0,"mound and dirt excluded")
 grass.paint(Vector3(0,0,-102),Vector3.FORWARD)
 check(grass.cut_count == 0,"warning track excluded")
 grass.mow_segment(Vector3(0,0,-60),Vector3(8,0,-68),Vector3(1,0,-1).normalized())
 var count := grass.cut_count
 check(count > 100,"diagonal swept deck cuts cells")
 check(grass.image.get_pixelv(grass.world_to_grid(Vector3(0.8,0,-60))).r > 0.5,"deck has broad footprint")
 check(grass.image.get_pixelv(grass.world_to_grid(Vector3(-3,0,-60))).r < 0.5,"outside deck stays uncut")
 grass.mow_segment(Vector3(0,0,-60),Vector3(8,0,-68),Vector3.FORWARD)
 check(grass.cut_count == count,"overlapping passes count once")
 check(is_equal_approx(grass.percentage(),100.0*count/grass.total),"percentage uses unique cells")
 var mower := RidingMower.new()
 root.add_child(mower)
 mower.set_occupied(true)
 check(mower.occupied,"mower enters occupied state")
 mower.speed = 2
 check(not mower.can_exit(),"exit blocked while moving")
 mower.speed = 0
 check(mower.can_exit(),"exit permitted when stopped")
 mower.set_occupied(false)
 check(not mower.occupied,"mower exits occupied state")
 print("Failures: ",failures)
 quit(1 if failures else 0)
