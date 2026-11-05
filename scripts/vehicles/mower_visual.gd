class_name MowerVisual
extends Node3D
const G = preload("res://scripts/gameplay/geometry.gd")
const YELLOW := Color("a38b48")
const DARK := Color("344745")
var wheels: Array[MeshInstance3D] = []
var steering: MeshInstance3D
var deck: Node3D
var driver: CrewVisual


func _ready() -> void:
	# A compact garden tractor: rear fenders, raised hood, inset grille, and wide deck.
	G.soft_box(self, Vector3(0, 0.5, 0), Vector3(1.35, 0.23, 2.2), DARK)
	G.soft_box(self, Vector3(0, 0.72, -0.58), Vector3(1.05, 0.64, 1.05), YELLOW)
	var hood := G.soft_box(self, Vector3(0, 1.08, -0.59), Vector3(1.07, 0.14, 1.1), Color("b9a15c"))
	hood.rotation.x = -0.06
	G.soft_box(self, Vector3(0, 0.85, -1.13), Vector3(0.84, 0.43, 0.055), DARK)
	for i in range(7):
		G.soft_box(self, Vector3(-0.33 + i * 0.11, 0.85, -1.17), Vector3(0.035, 0.34, 0.025), Color("75867b"))
	for x in [-0.44, 0.44]:
		var lamp := G.soft_box(self, Vector3(x, 1.01, -1.16), Vector3(0.16, 0.1, 0.06), Color("d2ccb5"))
		var glass := G.material(Color("c3c8bd")).duplicate() as StandardMaterial3D
		glass.roughness = 0.22
		lamp.material_override = glass
		for rib in range(3):
			G.soft_box(
				lamp, Vector3(-0.045 + rib * 0.045, 0, -0.032), Vector3(0.009, 0.08, 0.006), Color("9caa9d")
			)
		G.soft_box(self, Vector3(x, 0.74, 0.58), Vector3(0.3, 0.12, 1.1), YELLOW)
		G.soft_box(self, Vector3(x * 1.45, 0.45, 0), Vector3(0.28, 0.1, 0.65), DARK)
	for side in [-1, 1]:
		G.soft_box(self, Vector3(side * 0.54, 0.9, 0.6), Vector3(0.3, 0.15, 0.94), YELLOW)
		G.soft_box(self, Vector3(side * 0.548, 0.83, -0.55), Vector3(0.025, 0.07, 0.8), Color("f3dc91"))
		for vent in range(5):
			G.soft_box(
				self, Vector3(side * 0.535, 0.75, -0.82 + vent * 0.105), Vector3(0.018, 0.17, 0.025), DARK
			)
		var badge := G.label(self, "CG • 24", Vector3(side * 0.565, 0.9, -0.55), 32)
		badge.pixel_size = 0.0018
		badge.rotation.y = side * PI / 2
		badge.modulate = DARK
	G.soft_box(self, Vector3(0, 1.02, 0.46), Vector3(0.76, 0.19, 0.65), Color("293d3f"))
	var back := G.soft_box(self, Vector3(0, 1.36, 0.8), Vector3(0.76, 0.66, 0.16), Color("293d3f"))
	back.rotation.x = -0.12
	G.soft_box(self, Vector3(0, 1.37, 0.7), Vector3(0.58, 0.46, 0.03), Color("425659"))
	G.beam(self, Vector3(0, 0.65, -0.05), Vector3(0, 1.4, -0.3), 0.07, DARK)
	steering = G.ring(self, Vector3(0, 1.42, -0.3), 0.22, 0.26, DARK)
	steering.rotation.x = 0.32
	G.soft_box(steering, Vector3.ZERO, Vector3(0.43, 0.035, 0.045), DARK)
	G.soft_box(steering, Vector3(0, 0, 0.1), Vector3(0.04, 0.035, 0.2), DARK)
	deck = G.soft_box(self, Vector3(0, 0.22, -0.3), Vector3(2.4, 0.18, 1.15), Color("bfa13f"))
	for x in [-0.66, 0.66]:
		G.cylinder(deck, Vector3(x, 0.13, 0), 0.44, 0.1, YELLOW)
	G.soft_box(deck, Vector3(1.25, 0.02, 0), Vector3(0.35, 0.12, 0.63), DARK)
	G.soft_box(self, Vector3(0, 0.43, -1.25), Vector3(1.6, 0.13, 0.15), DARK)
	G.cylinder(self, Vector3(0.38, 1.22, -0.75), 0.055, 0.5, DARK)
	for x in [-0.88, 0.88]:
		for z in [-0.85, 0.8]:
			var radius := 0.34 if z < 0 else 0.43
			var wheel := G.ring(self, Vector3(x, radius, z), radius * 0.54, radius, Color("273332"))
			wheel.rotation.z = PI / 2
			wheels.append(wheel)
			G.cylinder(
				wheel,
				Vector3(0, radius * 0.27 if x < 0 else -radius * 0.27, 0),
				radius * 0.54,
				0.035,
				Color("d6d5b7")
			)
			G.cylinder(
				wheel, Vector3(0, radius * 0.34 if x < 0 else -radius * 0.34, 0), radius * 0.19, 0.045, DARK
			)
			for lug in range(20):
				var a := TAU * lug / 20.0
				var tread := G.soft_box(
					wheel,
					Vector3(sin(a) * radius, 0, cos(a) * radius),
					Vector3(0.075, 0.25, 0.025),
					Color("34413b")
				)
				tread.rotation.y = a
	driver = CrewVisual.new()
	driver.seated_pose = true
	driver.position = Vector3(0, -0.05, 0.4)
	add_child(driver)
	driver.visible = false
