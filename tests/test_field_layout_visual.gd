extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func capture(camera: Camera3D,from: Vector3,to: Vector3,path: String) -> void:
 camera.position = from
 camera.look_at(to)
 for i in range(5):
  await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(path)
func run() -> void:
 var g = load("res://scenes/main/main.tscn").instantiate()
 g.career_save_path = "user://test-test_field_layout_visual-career.dat"
 DirAccess.remove_absolute(g.career_save_path)
 root.add_child(g)
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 for i in range(30):
  await physics_frame
 g.set_process(false)
 g.hud.visible = false
 g.shift.overlay.visible = false
 var camera := Camera3D.new()
 g.add_child(camera)
 camera.current = true
 camera.fov = 55
 camera.far = 500
 await capture(camera,Vector3(100,130,100),Vector3(0,0,-35),"/tmp/firstpitch-field-layout.png")
 await capture(camera,Vector3(0,47,32),Vector3(0,0,-9),"/tmp/firstpitch-dugout-layout.png")
 await capture(camera,Vector3(7,4,-23),Vector3(23,1.2,-7),"/tmp/firstpitch-visitor-dugout.png")
 await capture(camera,Vector3(-7,4,-23),Vector3(-23,1.2,-7),"/tmp/firstpitch-home-dugout.png")
 await capture(camera,Vector3(18,5,-28),Vector3(34,1.2,-21),"/tmp/firstpitch-field-access.png")
 await capture(camera,Vector3(0,18,8),Vector3(0,0,-1),"/tmp/firstpitch-home-area.png")
 await capture(camera,Vector3(0,3,2.8),Vector3(0,0.13,-0.1),"/tmp/firstpitch-home-plate.png")
 await capture(camera,Vector3(24,6,-19),Vector3(21,0,-13),"/tmp/firstpitch-coach-box.png")
 print("Field layout: overhead, both field-facing dugouts and equipment gate captured")
 g.queue_free()
 await create_timer(0.15).timeout
 quit()
