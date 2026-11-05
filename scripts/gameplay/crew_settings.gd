class_name CrewSettings
extends RefCounted
var path := "user://settings.cfg"
var tutorial_done := false
var tutorial_step := 0
var pad_sensitivity := 2.2
var error := ""


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return
	var done: Variant = config.get_value("tutorial", "done", false)
	var step: Variant = config.get_value("tutorial", "step", 0)
	var sensitivity: Variant = config.get_value("input", "pad_sensitivity", 2.2)
	if done is bool:
		tutorial_done = done
	if step is int and step >= 0 and step < 7:
		tutorial_step = step
	if (
		typeof(sensitivity) in [TYPE_INT, TYPE_FLOAT]
		and is_finite(float(sensitivity))
		and sensitivity >= 0.5
		and sensitivity <= 5
	):
		pad_sensitivity = sensitivity


func save() -> bool:
	var config := ConfigFile.new()
	config.load(path)
	config.set_value("tutorial", "done", tutorial_done)
	config.set_value("tutorial", "step", tutorial_step)
	config.set_value("input", "pad_sensitivity", pad_sensitivity)
	error = "" if config.save(path) == OK else "Settings could not be saved."
	return error.is_empty()
