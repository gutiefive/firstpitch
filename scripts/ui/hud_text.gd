class_name HUDText
extends RefCounted


static func mode_text(state: Dictionary) -> String:
	if state.tamping:
		return "MOUND REPAIR  /  " + state.tamp_feedback
	if state.watering:
		if state.puddle:
			return "OVERWATERING — LET PUDDLE DRY"
		return "WATERING  /  " + state.water_feedback
	if state.chalking:
		var text := "CHALKING  /  GATE CLOSED"
		if state.gate_open:
			text = "CHALKING  /  GATE OPEN"
			if state.off_guide:
				text = "CHALKING  /  OFF GUIDE — NO LINE CREDIT"
		if state.guide_active:
			text += " / GUIDE WHEEL"
		return text
	if not state.driving:
		match int(state.job):
			CrewJob.MOUND:
				return "ON FOOT  /  TAMPER STOWED"
			CrewJob.WATER:
				return "ON FOOT  /  HOSE STOWED"
			CrewJob.CHALK:
				return "ON FOOT  /  CHALK MARKER PARKED"
		if state.dragging:
			return "ON FOOT  /  DRAG EQUIPPED"
		return "ON FOOT  /  MOWER EQUIPPED"
	if state.dragging:
		if state.lowered:
			if state.speed > 0.15 and state.wet:
				return "DRAGGING WET DIRT — RUTS"
			if state.speed > 0.15 and state.blocked:
				return "PUDDLES — WAIT BEFORE DRAGGING"
			if state.speed < -0.15:
				return "DRAGGING  /  REVERSE — NO PREPARATION"
			return "DRAGGING  /  LOWERED"
		return "DRAGGING  /  RAISED"
	return "MOWING  /  DECK ENGAGED"


static func prompt_text(state: Dictionary) -> String:
	if state.tamping:
		return "{move} walk  •  Aim worn clay  •  Stop + press {tamp} to tamp  •  {mound} stow tamper"
	if state.watering:
		return "{move} walk  •  Aim with {look}  •  Hold {spray} to water  •  {water} stow hose  •  {cursor} cursor"
	if state.chalking:
		return (
			"{move} push / steer  •  {lift} chalk gate  •  {brake} brake  •  "
			+ ("{interact} leave marker" if state.marker_exit else "Stop to leave marker")
		)
	if state.driving and state.dragging:
		if state.lowered:
			return (
				"{move} drive  •  {lift} raise drag  •  {brake} brake  •  "
				+ ("{interact} exit" if state.mower_exit else "Stop to exit")
			)
		return "{move} drive  •  Stop + {lift} lower drag  •  {brake} brake  •  {interact} exit when stopped"
	if state.driving:
		if state.mower_exit:
			return "{move} drive  •  {brake} brake  •  {interact} exit"
		return "{move} drive  •  {brake} brake  •  Stop to exit"
	if state.near_marker:
		return "{interact} use chalk marker  •  Follow the dashed gold foul-line guides"
	if state.near_mower:
		if state.at_bay:
			return "{interact} enter tractor  •  {swap} swap mower / drag"
		return "{interact} enter tractor  •  Return to tool bay to swap equipment"
	if state.near_tamper:
		return "{mound} take tamper  •  Repair worn clay patches on the pitcher’s mound"
	if state.near_hose:
		return "{water} take hose  •  Water the workable infield dirt"
	return "{move} walk  •  {sprint} sprint  •  {jump} jump  •  Find equipment beside the workshop"
