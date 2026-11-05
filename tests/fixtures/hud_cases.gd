extends RefCounted


static func cases() -> Array:
	return [
		{"name": "walking"},
		{"name": "stowed chalk", "job": 2},
		{"name": "stowed hose", "job": 3},
		{"name": "stowed tamper", "job": 4},
		{"name": "drag on foot", "drag": true},
		{"name": "mowing", "drive": true},
		{"name": "mowing moving", "drive": true, "speed": 2.0},
		{"name": "drag raised", "drive": true, "drag": true},
		{"name": "drag lowered", "drive": true, "drag": true, "lowered": true},
		{"name": "drag wet", "drive": true, "drag": true, "lowered": true, "speed": 2.0, "wet": true},
		{"name": "drag puddle", "drive": true, "drag": true, "lowered": true, "speed": 2.0, "blocked": true},
		{"name": "drag reverse", "drive": true, "drag": true, "lowered": true, "speed": -2.0},
		{"name": "chalk closed", "chalk": true},
		{"name": "chalk open", "chalk": true, "gate": true},
		{"name": "chalk offguide", "chalk": true, "gate": true, "offguide": true},
		{"name": "chalk guide moving", "chalk": true, "gate": true, "guide": true, "speed": 2.0},
		{"name": "watering", "water": true},
		{"name": "puddle watering", "water": true, "puddle": true},
		{"name": "tamping", "tamp": true},
		{"name": "near marker", "near": "marker"},
		{"name": "near tractor away", "near": "tractor"},
		{"name": "near tractor bay", "near": "bay"},
		{"name": "near tamper", "near": "tamper"},
		{"name": "near hose", "near": "hose"}
	]


static func apply(g: Node, c: Dictionary) -> void:
	g.player.position = Vector3(90, 0.1, 40)
	g.mower.position = Vector3(70, 0.1, 40)
	g.driving = c.get("drive", false)
	g.pushing_chalk = c.get("chalk", false)
	g.selected_task = int(c.get("job", CrewJob.MOW))
	g.tamper.equipped = c.get("tamp", false)
	g.tamper.feedback = "READY"
	g.tamper.target_index = -1
	g.watering.equipped = c.get("water", false)
	g.watering.feedback = "READY"
	g.watering.target_valid = c.get("puddle", false)
	var index: int = g.infield.valid.find(1)
	var cell: Vector2 = g.infield.cell_world(
		index % g.infield.resolution.x, int(index / g.infield.resolution.x)
	)
	g.watering.target = Vector3(cell.x, 0, cell.y)
	g.moisture.puddle_time[index] = 1 if c.get("puddle", false) else 0
	g.mower.active_tool = RidingMower.WorkTool.DRAG if c.get("drag", false) else RidingMower.WorkTool.MOWER
	g.mower.speed = float(c.get("speed", 0))
	g.mower.drag.lowered = c.get("lowered", false)
	g.infield.wet_dragging = c.get("wet", false)
	g.infield.blocked_puddles = c.get("blocked", false)
	g.chalk_marker.speed = float(c.get("speed", 0))
	g.chalk_marker.gate_open = c.get("gate", false)
	g.chalk_marker.guide_active = c.get("guide", false)
	g.chalk_marker.nozzle.global_position = Vector3(12, 0, -10 if c.get("offguide", false) else -12)
	match c.get("near", ""):
		"marker":
			g.player.position = g.chalk_marker.position
		"tractor":
			g.player.position = g.mower.position
		"bay":
			g.mower.position = g.tool_bay.position
			g.player.position = g.mower.position
		"tamper":
			g.player.position = g.tamper.rack_position
		"hose":
			g.player.position = g.watering.station_position
