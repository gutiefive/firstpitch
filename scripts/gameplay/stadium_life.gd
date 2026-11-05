class_name StadiumLife
extends Node3D
var game: Node
var loops := {}
var targets := {}
var reaction: AudioStreamPlayer3D
var reaction_time := 0.0
var reactions := 0
func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 for id in ["crowd","snacks","grill"]:
  var player := AudioStreamPlayer3D.new()
  player.stream = game.audio.stream("crowd" if id == "crowd" else "concessions",true)
  player.bus = "GroundsAmbience"
  player.unit_size = 8 if id == "crowd" else 4
  player.max_distance = 65
  player.volume_db = -60
  add_child(player)
  loops[id] = player
  targets[id] = false
 loops.crowd.position = Vector3(0,1.5,11)
 loops.snacks.position = Vector3(31,1.4,20)
 loops.grill.position = Vector3(-32,1.4,20)
 reaction = AudioStreamPlayer3D.new()
 reaction.stream = game.audio.stream("crowd_cheer")
 reaction.bus = "GroundsAmbience"
 reaction.unit_size = 10
 reaction.max_distance = 65
 reaction.volume_db = -12
 reaction.position = Vector3(0,2,11)
 add_child(reaction)
func _process(delta: float) -> void:
 var state: Dictionary = game.shift.career.club
 var presenting: bool = game.club.opening != null and game.club.opening.active and not game.club.opening.playback_paused
 var allowed: bool = state.active and not state.last.is_empty() and game.shift.session.phase == ShiftSession.Phase.PRACTICE and (not get_tree().paused or presenting)
 targets.crowd = allowed
 targets.snacks = allowed and "snack_shack" in state.buildings
 targets.grill = allowed and "grill_stand" in state.buildings
 for id in loops:
  var player: AudioStreamPlayer3D = loops[id]
  player.stream_paused = get_tree().paused and not presenting
  var db := -14.0
  if id == "crowd" and allowed:
   db = -20+10*clampf(float(state.last.attendance)/state.capacity,0,1)
  player.volume_db = move_toward(player.volume_db,db if targets[id] else -60,45*delta)
  if targets[id] and not player.playing:
   player.play()
  elif not targets[id] and player.volume_db <= -59:
   player.stop()
 reaction.stream_paused = get_tree().paused and not presenting
 if allowed:
  reaction_time += delta
  if reaction_time >= 18:
   reaction_time = 0
   reactions += 1
   reaction.play()
 else:
  reaction_time = 0
  if game.shift.session.phase != ShiftSession.Phase.PRACTICE:
   reaction.stop()
func _exit_tree() -> void:
 for player in loops.values():
  player.stop()
 if reaction != null:
  reaction.stop()
