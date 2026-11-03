class_name SoundPreferences
extends RefCounted
signal changed
const DEFAULTS := {"master":0.7,"effects":0.8,"ambience":0.4}
const BUSES := {"master":"Master","effects":"GroundsEffects","ambience":"GroundsAmbience"}
var levels := DEFAULTS.duplicate()
var muted := false
var path := "user://sound.cfg"
var error := ""

func load_settings() -> void:
 levels = DEFAULTS.duplicate()
 muted = false
 var config := ConfigFile.new()
 if config.load(path) == OK:
  for key in DEFAULTS:
   var value: Variant = config.get_value("sound",key,DEFAULTS[key])
   if typeof(value) in [TYPE_FLOAT,TYPE_INT] and is_finite(float(value)):
    levels[key] = clampf(float(value),0,1)
  var saved_mute: Variant = config.get_value("sound","muted",false)
  if saved_mute is bool:
   muted = saved_mute
 apply()
 changed.emit()

func apply() -> void:
 for key in BUSES:
  var index := AudioServer.get_bus_index(BUSES[key])
  if index < 0:
   AudioServer.add_bus()
   index = AudioServer.bus_count-1
   AudioServer.set_bus_name(index,BUSES[key])
   AudioServer.set_bus_send(index,"Master")
  AudioServer.set_bus_volume_db(index,linear_to_db(maxf(0.0001,levels[key])))
  AudioServer.set_bus_mute(index,muted if key == "master" else levels[key] == 0)
 # A zero master level is silent even while the separate mute switch is off.
 AudioServer.set_bus_mute(0,muted or levels.master == 0)

func set_level(key: String,value: float) -> bool:
 if not DEFAULTS.has(key) or not is_finite(value):
  return false
 levels[key] = clampf(value,0,1)
 apply()
 persist()
 changed.emit()
 return true

func set_muted(value: bool) -> void:
 muted = value
 apply()
 persist()
 changed.emit()

func persist() -> bool:
 var config := ConfigFile.new()
 for key in levels:
  config.set_value("sound",key,levels[key])
 config.set_value("sound","muted",muted)
 var result := config.save(path)
 error = "" if result == OK else "Volume changed, but settings could not be saved."
 return result == OK
