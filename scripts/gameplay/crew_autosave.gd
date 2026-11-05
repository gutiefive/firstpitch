class_name CrewAutosave
extends Node
var game: Node
var store := FieldSave.new()
var candidate: Dictionary = {}
var dirty := false
var pending := false
var interval := 0.0
var since_write := 1.0
var last_saved := ""
var notice := ""
var last_ms := 0.0
var writes := 0
var quitting := false
func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 if not game.autosave_enabled:
  set_process(false)
  return
 get_tree().auto_accept_quit = false
 for surface in [game.grass,game.infield,game.chalk,game.moisture,game.mound]:
  surface.completion_changed.connect(mark_dirty)
 call_deferred("probe")
func mark_dirty(_percent: float) -> void:
 dirty = true
func request() -> void:
 if game.autosave_enabled and candidate.is_empty():
  pending = true
func paid(id: String) -> bool:
 for record in game.shift.career.data.records:
  if record.id == id:
   return true
 return false
func probe() -> void:
 if not SaveRecovery.exists(store.path):
  return
 var data := store.read(game)
 if data.is_empty():
  var bad := store.path.get_basename()+".bad"
  var quarantined := true
  for suffix in ["",".tmp",".bak"]:
   if not FileAccess.file_exists(store.path+suffix):
    continue
   if FileAccess.file_exists(bad+suffix):
    DirAccess.remove_absolute(bad+suffix)
   quarantined = (DirAccess.rename_absolute(store.path+suffix,bad+suffix) == OK) and quarantined
  notice = "Autosave damaged; started normally."+(" Backup kept as field-autosave.bad." if quarantined else " Could not move damaged backup.")
  game.shift.overlay.autosave_footer.text = notice
  return
 if not store.error.is_empty():
  notice = store.error
  game.shift.overlay.autosave_footer.text = notice
 if data.session.phase == ShiftSession.Phase.ACTIVE or (data.session.phase == ShiftSession.Phase.FINISHED and (not paid(data.session.attempt_id) or game.shift.career.pending_home_game(data.session.attempt_id))):
  candidate = data
  pending = false
  game.shift.open_board()
  game.shift.overlay.show_resume(data)
func resume() -> bool:
 if candidate.is_empty():
  return false
 var data := candidate.duplicate(true)
 if not store.restore(game,game.shift,data):
  notice = store.error
  return false
 candidate.clear()
 if game.shift.session.phase == ShiftSession.Phase.FINISHED:
  var receipt: Dictionary = game.shift.career.claim(game.shift.session.attempt_id,game.shift.session.get_result())
  game.shift.career_message = receipt.message
 game.shift.overlay.resume_card.visible = false
 game.shift.open_board()
 request()
 return true
func start_fresh() -> void:
 candidate.clear()
 game.shift.overlay.resume_card.visible = false
 game.shift.enter_practice()
 game.shift.overlay.refresh()
 request()
func write_now() -> bool:
 if not game.autosave_enabled or not candidate.is_empty() or since_write < 1:
  return false
 game.shift.collect_progress()
 var started := Time.get_ticks_usec()
 var ok := store.write(game,game.shift.session)
 last_ms = (Time.get_ticks_usec()-started)/1000.0
 since_write = 0
 pending = false
 if ok:
  writes += 1
  dirty = false
  var clock := Time.get_time_dict_from_system()
  last_saved = "%02d:%02d:%02d" % [clock.hour,clock.minute,clock.second]
  notice = "Autosaved "+last_saved
 else:
  notice = "Autosave failed: "+store.error
 game.shift.overlay.autosave_footer.text = notice
 return ok
func advance(delta: float) -> void:
 since_write += delta
 if game.shift.session.phase == ShiftSession.Phase.ACTIVE and not get_tree().paused:
  interval += delta
  if interval >= 60:
   interval = 0
   if dirty:
    request()
 if pending and since_write >= 1:
  write_now()
 if quitting and not pending:
  get_tree().quit()
func _process(delta: float) -> void:
 advance(delta)
func prepare_quit() -> void:
 if not game.autosave_enabled:
  return
 get_tree().paused = true
 quitting = true
 request()
func _notification(what: int) -> void:
 if what == NOTIFICATION_WM_CLOSE_REQUEST and game != null and game.autosave_enabled:
  prepare_quit()
