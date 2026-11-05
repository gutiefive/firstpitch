class_name FieldMarkings
extends Node3D
@export var layout: FieldLayout = preload("res://resources/layouts/cedar_grove.tres")
# Static field furniture: these marks are not part of the playable foul-line task.
const G = preload("res://scripts/gameplay/geometry.gd")
const WHITE := Color("f5edd6")
var plate: MeshInstance3D
var batter_boxes: Array[Node3D] = []
var coach_boxes: Array[Node3D] = []
var on_deck_circles: Array[Node3D] = []


func _ready() -> void:
	name = "FieldMarkings"
	build_home_plate()
	for side in [-1, 1]:
		var box := rectangle(
			"BatterBox",
			Vector3(
				(
					layout.plate_position.x
					+ side * (layout.plate_width * 0.5 + layout.batter_plate_gap + layout.batter_width * 0.5)
				),
				layout.home_height + 0.02,
				layout.plate_position.y - layout.plate_width * 0.25
			),
			layout.batter_width,
			layout.batter_length
		)
		batter_boxes.append(box)
		var along := Vector3(side, 0, -1).normalized()
		var outward := Vector3(side, 0, 1).normalized()
		var center := (
			layout.point3(layout.plate_position)
			+ along * (layout.basepath_length - layout.coach_length * 0.5)
			+ outward * (layout.coach_line_clearance + layout.coach_width * 0.5)
		)
		center.y = 0.012
		var coach := rectangle(
			"ThirdBaseCoachBox" if side < 0 else "FirstBaseCoachBox",
			center,
			layout.coach_width,
			layout.coach_length
		)
		coach.rotation.y = atan2(along.x, along.z)
		coach_boxes.append(coach)
		var circle := Node3D.new()
		circle.name = "HomeOnDeck" if side < 0 else "VisitorOnDeck"
		# Both circles lie 37 ft from home, inside the new foul-side fence.
		circle.position = (
			layout.point3(layout.plate_position)
			+ Vector3(
				side * sqrt(pow(layout.on_deck_distance, 2) - pow(layout.on_deck_back_offset, 2)),
				0,
				-layout.on_deck_back_offset
			)
		)
		add_child(circle)
		var clay := G.cylinder(
			circle, Vector3(0, 0.006, 0), layout.on_deck_clay_radius, 0.012, Color("b7794c")
		)
		(clay.mesh as CylinderMesh).radial_segments = 64
		flat_ring(
			circle,
			layout.on_deck_radius - layout.marking_width * 0.5,
			layout.on_deck_radius + layout.marking_width * 0.5,
			0.016
		)
		on_deck_circles.append(circle)


func rectangle(title: String, center: Vector3, width: float, length: float) -> Node3D:
	var root := Node3D.new()
	root.name = title
	root.position = center
	add_child(root)
	for z in [-length * 0.5, length * 0.5]:
		G.box(
			root, Vector3(0, 0, z), Vector3(width + layout.marking_width, 0.007, layout.marking_width), WHITE
		)
	for x in [-width * 0.5, width * 0.5]:
		G.box(root, Vector3(x, 0, 0), Vector3(layout.marking_width, 0.007, length), WHITE)
	return root


func build_home_plate() -> void:
	var half := layout.plate_width * 0.5
	var points := PackedVector2Array(
		[Vector2(-half, -half), Vector2(half, -half), Vector2(half, 0), Vector2(0, half), Vector2(-half, 0)]
	)
	polygon(points, layout.home_height + 0.015, 1.07, Color("344b45"), "PlateBorder")
	plate = polygon(points, layout.home_height + 0.021, 1, WHITE, "HomePlate")


func polygon(
	points: PackedVector2Array, height: float, scale_value: float, color: Color, title: String
) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in [0, 1, 2, 0, 2, 3, 0, 3, 4]:
		var p := points[index] * scale_value
		surface.set_normal(Vector3.UP)
		surface.add_vertex(layout.point3(layout.plate_position + Vector2(p.x, p.y), height))
	var node := MeshInstance3D.new()
	node.name = title
	node.mesh = surface.commit()
	node.material_override = G.material(color)
	add_child(node)
	return node


func flat_ring(parent: Node3D, inner: float, outer: float, height: float) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(64):
		var a := Vector3(cos(i * TAU / 64), 0, sin(i * TAU / 64))
		var b := Vector3(cos((i + 1) * TAU / 64), 0, sin((i + 1) * TAU / 64))
		for point in [a * inner, a * outer, b * outer, a * inner, b * outer, b * inner]:
			surface.set_normal(Vector3.UP)
			surface.add_vertex(point + Vector3.UP * height)
	var node := MeshInstance3D.new()
	node.name = "OnDeckPaint"
	node.mesh = surface.commit()
	node.material_override = G.material(WHITE)
	parent.add_child(node)
