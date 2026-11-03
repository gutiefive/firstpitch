extends SceneTree
var failures := 0
func check(ok: bool,message: String) -> void:
 if ok:
  print("PASS: ",message)
 else:
  failures += 1
  push_error(message)
func ray(from: Vector3,to: Vector3,g: Node3D) -> Dictionary:
 return g.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,to))
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var g = load("res://scenes/main/main.tscn").instantiate()
 g.career_save_path = "user://test-test_field_layout-career.dat"
 g.tutorial_enabled = false
 g.autosave_enabled = false
 DirAccess.remove_absolute(g.career_save_path)
 root.add_child(g)
 for i in range(10):
  await physics_frame
 var stadium: Node3D = g.get_child(0)
 for side in [-1,1]:
  var name := "HomeDugout" if side < 0 else "VisitorDugout"
  var dugout: Node3D = stadium.get_node(name)
  var front := dugout.to_global(Vector3(0,1,2.2))
  var toward_field := Vector3(-side,0,-1).normalized()
  check(dugout.global_basis.z.dot(toward_field)>0.99,name+" opens toward the diamond")
  check(absf(dugout.position.x)+dugout.position.z>8,name+" stays outside fair territory")
  for x in [-4.5,4.5]:
   check(ray(dugout.to_global(Vector3(x,0.7,3.5)),dugout.to_global(Vector3(x,0.7,0.5)),g).is_empty(),name+" has a clear walk-in opening")
  g.player.global_position = dugout.to_global(Vector3(4.5,0.1,4))
  g.player.velocity = Vector3.ZERO
  g.yaw = dugout.rotation.y
  g.player.yaw = g.yaw
  Input.action_press("forward")
  for i in range(45):
   await physics_frame
  Input.action_release("forward")
  check(dugout.to_local(g.player.global_position).z < 2,name+" can be entered by walking through its front opening")
  check(not ray(dugout.to_global(Vector3(0,1.5,0)),dugout.to_global(Vector3(0,1.5,-3)),g).is_empty(),name+" has a solid rear wall")
  check(not ray(Vector3(side*50,1,-35),Vector3(side*30,1,-35),g).is_empty(),"foul-side perimeter blocks exit into the neighborhood")
 check(not ray(Vector3(0,2,3),Vector3(0,2,9),g).is_empty(),"backstop closes the field behind home plate")
 check(ray(Vector3(38,1,-19),Vector3(27,1,-25),g).is_empty(),"wide equipment entrance stays clear of fence collisions")
 check(ray(Vector3(19,1,-19),Vector3(60,1,-60),g).is_empty(),"first-base foul line remains unobstructed")
 check(ray(Vector3(-19,1,-19),Vector3(-60,1,-60),g).is_empty(),"third-base foul line remains unobstructed")
 # Drive the actual mower across the opening rather than only checking its center ray.
 g.mower.global_position = Vector3(35,0.1,-19)
 g.mower.rotation.y = PI/4
 g.mower.speed = 0
 g.mower.set_occupied(true)
 g.driving = true
 g.player.set_seated(true)
 Input.action_press("forward")
 for i in range(150):
  await physics_frame
 Input.action_release("forward")
 check(g.mower.global_position.x<30 and g.mower.global_position.z < -24,"mower can drive through the workshop opening onto the field")
 check(g.grass.total > 60000 and g.infield.total > 10000,"field work masks retain their original scored areas")
 g.queue_free()
 await create_timer(0.15).timeout
 print("Field layout failures: ",failures)
 quit(1 if failures else 0)
