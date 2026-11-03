extends SceneTree
# Run with isolated XDG roots: godot --path . --script tools/capture_art_review.gd -- pass-name
var tag := "review"
func _initialize() -> void:
 if not OS.get_cmdline_user_args().is_empty():
  tag = OS.get_cmdline_user_args()[0].validate_filename()
 call_deferred("run")
func capture(camera: Camera3D,position: Vector3,focus: Vector3,label: String) -> void:
 camera.current = true
 camera.position = position
 camera.look_at(focus)
 for i in range(6):
  await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/firstpitch-art/%s-%s.png" % [tag,label])
func award(c: CareerProfile,profile: String) -> String:
 var s := ShiftSession.new()
 s.start(profile)
 s.set_progress(s.goals(),[true,true,true,true,true])
 s.advance(0)
 var id := s.attempt_id
 c.claim(id,s.get_result())
 s.free()
 return id
func run() -> void:
 var g = load("res://scenes/main/main.tscn").instantiate()
 g.career_save_path = "user://art-review-career.dat"
 g.settings_save_path = "user://art-review-settings.cfg"
 g.autosave_enabled = false
 g.tutorial_enabled = false
 DirAccess.remove_absolute(g.career_save_path)
 root.add_child(g)
 for i in range(8):
  await physics_frame
 g.hud.visible = false
 g.shift.overlay.visible = false
 var camera := Camera3D.new()
 g.add_child(camera)
 camera.current = true
 camera.fov = 52
 await capture(camera,Vector3(25,3,-7),Vector3(31,1.1,-17),"workshop")
 await capture(camera,Vector3(8,3.8,-5),Vector3(0,0,-28),"field")
 var crew: Node3D = g.player.visual
 g.player.global_position = Vector3(28,0.05,-17)
 crew.rotation.y = 0.5
 await capture(camera,Vector3(25,1.7,-21),Vector3(28,0.95,-17),"crew")
 g.player.set_physics_process(false)
 (crew as CrewVisual).animate_walk(4.5,0.18)
 await capture(camera,Vector3(25,1.7,-21),Vector3(28,0.95,-17),"walking")
 (crew as CrewVisual).animate_walk(0,1)
 g.player.set_physics_process(true)
 g.club.join()
 var c: CareerProfile = g.shift.career
 for i in range(15):
  award(c,"full")
  c.host_game(award(c,"home_game"))
 for id in ["bleachers","snack_shack","grandstand","grill_stand","scoreboard","video_board"]:
  g.club.build(id)
 await capture(camera,Vector3(-43,16,37),Vector3(-3,1,12),"stadium")
 await capture(camera,Vector3(-7,2.2,7.5),Vector3(-7,1.4,11),"seating")
 await capture(camera,Vector3(-32,2.1,11),Vector3(-32,1.5,20),"concession")
 DirAccess.remove_absolute(g.career_save_path)
 g.queue_free()
 await process_frame
 print("Art review captures: ",tag)
 quit()
