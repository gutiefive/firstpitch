class_name ParkArrival
extends RefCounted
const G = preload("res://scripts/gameplay/geometry.gd")


static func build(parent: Node3D, layout: FieldLayout) -> void:
	var root := Node3D.new()
	root.name = "ParkArrival"
	parent.add_child(root)
	var plaza := G.box(root, Vector3(0, 0.018, 32.5), Vector3(29, 0.025, 13), Color("9e998b"))
	var paving := ShaderMaterial.new()
	paving.shader = preload("res://shaders/paving.gdshader")
	plaza.material_override = paving
	# The entrance frames the existing ticket booth; its walking routes stay open.
	for side in [-1, 1]:
		var x: float = side * 8
		var pier := G.soft_box(root, Vector3(x, 0.6, 33), Vector3(0.65, 1.2, 0.65), Color("8d7761"))
		pier.material_override = G.surface_material(Color("8d7761"), 2)
		G.soft_box(root, Vector3(x, 3.1, 33), Vector3(0.18, 3.8, 0.18), Color("526159"))
		G.soft_box(root, Vector3(x, 1.22, 33), Vector3(0.79, 0.10, 0.79), Color("b7ae97"))
		lamp(root, Vector3(side * 13.3, 0, 28))
		lamp(root, Vector3(side * 13.3, 0, 37))
		planter(root, Vector3(side * 12.6, 0, 34), side)
		bin(root, Vector3(side * 10.7, 0, 28.1))
	var header := G.soft_box(root, Vector3(0, 4.65, 33), Vector3(16.6, 0.85, 0.24), Color("354d46"))
	G.soft_box(header, Vector3(0, 0.39, 0), Vector3(16.8, 0.08, 0.35), Color("a69b7e"))
	var title := G.label(header, "CEDAR GROVE BALLPARK", Vector3(0, 0.03, 0.14), 64)
	title.pixel_size = 0.010
	title.modulate = Color("d0c9b6")
	G.soft_box(root, Vector3(0, 3.93, 33), Vector3(6.6, 0.43, 0.10), Color("354d46"))
	for x in [-2.5, 2.5]:
		G.tube(root, Vector3(x, 4.23, 33), Vector3(x, 4.10, 33), 0.018, Color("a69b7e"))
	var welcome := G.label(root, "HOME OF THE OWLS", Vector3(0, 3.93, 33.065), 36)
	welcome.pixel_size = 0.009
	welcome.modulate = Color("bca977")
	build_backdrop(root, layout)


static func lamp(parent: Node3D, pos: Vector3) -> void:
	var root := ParkProps.group(parent, "ConcourseLamp", pos)
	G.cylinder(root, Vector3(0, 0.12, 0), 0.22, 0.24, Color("62655b"))
	G.cylinder(root, Vector3(0, 2.3, 0), 0.065, 4.6, Color("4c5c54"))
	G.tube(root, Vector3(0, 4.5, 0), Vector3(0.48, 4.5, 0), 0.045, Color("4c5c54"))
	G.soft_box(root, Vector3(0.48, 4.42, 0), Vector3(0.42, 0.12, 0.55), Color("4c5c54"))
	var lens := G.soft_box(root, Vector3(0.48, 4.35, 0), Vector3(0.30, 0.025, 0.43), Color("d5c7a2"))
	var material := G.material(Color("d5c7a2")).duplicate() as StandardMaterial3D
	material.emission_enabled = true
	material.emission = Color("8b7955").srgb_to_linear()
	material.emission_energy_multiplier = 0.4
	lens.material_override = material


static func planter(parent: Node3D, pos: Vector3, side: int) -> void:
	var root := ParkProps.group(parent, "NativePlanting", pos)
	G.soft_box(root, Vector3(0, 0.30, 0), Vector3(1.3, 0.60, 3.1), Color("888378"))
	G.soft_box(root, Vector3(0, 0.59, 0), Vector3(1.12, 0.05, 2.91), Color("554e3a"))
	for i in range(5):
		G.canopy(
			root,
			Vector3(sin(i * 2.4) * 0.20, 0.85, -1.1 + i * 0.55),
			Vector3(0.85, 0.65, 0.80),
			Color("647154"),
			i + side
		)
	for i in range(7):
		var p := Vector3(sin(i * 3.2) * 0.4, 0.90, -1.2 + i * 0.39)
		G.cylinder(root, p, 0.012, 0.5, Color("536748"))
		G.sphere(
			root,
			p + Vector3.UP * 0.27,
			Vector3(0.12, 0.055, 0.12),
			Color("b6a57c") if i % 2 == 0 else Color("9b826f")
		)


static func bin(parent: Node3D, pos: Vector3) -> void:
	var root := ParkProps.group(parent, "ConcourseBin", pos)
	G.cylinder(root, Vector3(0, 0.48, 0), 0.31, 0.96, Color("536057"))
	G.cylinder(root, Vector3(0, 0.99, 0), 0.34, 0.10, Color("36463e"))
	for i in range(12):
		var a := TAU * i / 12
		G.tube(
			root,
			Vector3(sin(a) * 0.313, 0.12, cos(a) * 0.313),
			Vector3(sin(a) * 0.313, 0.88, cos(a) * 0.313),
			0.012,
			Color("718071")
		)


static func build_backdrop(parent: Node3D, layout: FieldLayout) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(18):
		for column in range(44):
			var points := []
			for pair in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
				var x: float = -220 + (column + pair.x) * 10
				var z: float = (row + pair.y) * 9
				var rise := smoothstep(0, 65, z)
				var height := (
					-1.8
					+ rise * (6 + 4 * sin(x * 0.018 + 0.4) * cos(z * 0.025) + 2 * sin(x * 0.037 - z * 0.018))
				)
				points.append(
					(
						Vector3(x, height, -layout.fence_radius - 46 - z)
						+ Vector3(layout.plate_position.x, 0, layout.plate_position.y)
					)
				)
			G.mesh_face(surface, points, Vector3.UP)
	surface.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.name = "DistantRollingLandscape"
	mesh.mesh = surface.commit()
	mesh.material_override = G.surface_material(Color("647057"), 2)
	parent.add_child(mesh)
