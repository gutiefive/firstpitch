class_name GroundsAudio
extends Node
var game: Node3D
var settings := SoundPreferences.new()
var loops: Dictionary = {}
var targets: Dictionary = {}
var step: AudioStreamPlayer3D
var tamp: AudioStreamPlayer3D
var preview: AudioStreamPlayer
var step_distance := 0.0
var previous_position := Vector3.ZERO

func stream(id: String,loop: bool = false) -> AudioStreamWAV:
 var sound: AudioStreamWAV = load("res://assets/audio/"+id+".wav").duplicate()
 sound.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
 sound.loop_begin = 0
 sound.loop_end = sound.data.size()/2
 return sound

func spatial(id: String,loop: bool = false) -> AudioStreamPlayer3D:
 var sound := AudioStreamPlayer3D.new()
 sound.stream = stream(id,loop)
 sound.bus = "GroundsEffects"
 sound.unit_size = 12
 sound.max_distance = 65
 sound.volume_db = -12
 add_child(sound)
 return sound

func _ready() -> void:
 settings.load_settings()
 for id in ["engine","hose","drag","chalk"]:
  loops[id] = spatial(id,true)
  targets[id] = false
 for id in ["wind","birds"]:
  var sound := AudioStreamPlayer.new()
  sound.stream = stream(id,true)
  sound.bus = "GroundsAmbience"
  sound.volume_db = -18 if id == "wind" else -17
  add_child(sound)
  loops[id] = sound
  targets[id] = true
  sound.play()
 step = spatial("step")
 tamp = spatial("tamp")
 preview = AudioStreamPlayer.new()
 preview.stream = stream("shift")
 preview.bus = "GroundsEffects"
 preview.volume_db = -12
 # The same short chime can be previewed while the board pauses the world.
 preview.process_mode = Node.PROCESS_MODE_ALWAYS
 add_child(preview)
 previous_position = game.player.global_position
 game.tamper.impact.connect(on_impact)
 game.shift.session.finished.connect(func(_result): preview.play())

func on_impact(point: Vector3) -> void:
 tamp.global_position = point
 tamp.pitch_scale = 1
 tamp.play()

func _process(delta: float) -> void:
 var mower: RidingMower = game.mower
 targets.engine = mower.occupied
 targets.hose = game.watering.spraying
 targets.drag = mower.occupied and mower.active_tool == RidingMower.WorkTool.DRAG and mower.drag.lowered and mower.speed > 0.15 and mower.is_on_floor()
 targets.chalk = game.chalk_marker.occupied and game.chalk_marker.gate_open and game.chalk_marker.speed > 0.05 and game.chalk_marker.is_on_floor()
 loops.engine.global_position = mower.global_position+Vector3.UP
 loops.hose.global_position = game.watering.target if game.watering.spraying else game.player.global_position
 loops.drag.global_position = mower.drag.global_position
 loops.chalk.global_position = game.chalk_marker.global_position
 loops.engine.pitch_scale = lerpf(0.8,1.35,clampf(absf(mower.speed)/mower.max_speed,0,1))
 for id in ["engine","hose","drag","chalk"]:
  var sound: AudioStreamPlayer3D = loops[id]
  var target_db := -12.0 if targets[id] else -60.0
  sound.volume_db = move_toward(sound.volume_db,target_db,120*delta)
  if targets[id] and not sound.playing:
   sound.play()
  elif not targets[id] and sound.volume_db <= -59:
   sound.stop()
 update_steps()

func update_steps() -> void:
 var player: Groundskeeper = game.player
 var point := player.global_position
 var distance := Vector2(point.x-previous_position.x,point.z-previous_position.z).length()
 previous_position = point
 if player.seated or not player.is_on_floor() or distance > 1 or Vector2(player.velocity.x,player.velocity.z).length() < 0.3:
  step_distance = 0
  return
 step_distance += distance
 if step_distance >= 1.6:
  step_distance = fmod(step_distance,1.6)
  step.global_position = point
  step.play()

func reset_tools() -> void:
 for id in ["engine","hose","drag","chalk"]:
  loops[id].stop()
  loops[id].volume_db = -60
  targets[id] = false
 step.stop()
 tamp.stop()
 preview.stop()
 step_distance = 0
 previous_position = game.player.global_position

func _exit_tree() -> void:
 for sound in loops.values():
  sound.stop()
 step.stop()
 tamp.stop()
 preview.stop()
