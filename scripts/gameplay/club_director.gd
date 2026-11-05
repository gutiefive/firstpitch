class_name ClubDirector
extends Node
var game: Node
var world: ClubStadium
var message := ""
var life: StadiumLife
var opening: OpeningGates
var ownership := {}
var matchday: MatchdayPark
var live: LiveMatchday
var atmosphere: MatchdayAtmosphere
func _ready() -> void:
 world = ClubStadium.new()
 world.game = game
 add_child(world)
 life = StadiumLife.new()
 life.game = game
 add_child(life)
 matchday = MatchdayPark.new()
 matchday.game = game
 add_child(matchday)
 opening = OpeningGates.new()
 opening.game = game
 add_child(opening)
 atmosphere = MatchdayAtmosphere.new()
 atmosphere.game = game
 add_child(atmosphere)
 live = LiveMatchday.new()
 live.game = game
 add_child(live)
 ownership = ClubOwnership.review(game.shift.career)
 game.shift.overlay.attach_club(self)
 game.shift.career.changed.connect(sync)
 game.shift.session.changed.connect(refresh_spectators)
 sync()
func available() -> bool:
 return (live == null or not live.active) and game.shift.session.phase != ShiftSession.Phase.ACTIVE and (game.autosave == null or game.autosave.candidate.is_empty())
func refresh_spectators() -> void:
 var visible_crowd: bool = game.shift.session.phase == ShiftSession.Phase.PRACTICE
 for node in world.structures.get_children():
  if node.get_meta("club_crowd",false):
   (node as Node3D).visible = visible_crowd
func sync() -> void:
 var career: CareerProfile = game.shift.career
 world.sync(career.club)
 matchday.sync(career.club)
 refresh_spectators()
 ownership = ClubOwnership.review(career)
 game.hud.park_label.text = "OWLS · %d fans · %d seats" % [career.club.fans,career.club.capacity] if career.club_started() else "CEDAR GROVE / MORNING PREP"
 game.shift.overlay.club_panel.refresh()
 game.shift.overlay.refresh()
 if game.shift.overlay.club_screen.visible:
  game.shift.overlay.focus_current()
func join() -> bool:
 if not available() or not game.shift.career.start_club():
  message = game.shift.career.error
  return false
 game.shift.reset_equipment()
 game.update_progress(0)
 message = "Mara: Welcome to the Owls. Let's get Opening Day ready."
 sync()
 return true
func prepare() -> bool:
 if not available() or not game.shift.career.healthy or not game.shift.career.club_started() or not String(game.shift.career.club.pending).is_empty():
  return false
 if game.tutorial.can_run():
  game.tutorial.finish()
 opening.finish()
 return game.shift.start_shift(GameDay.profile(game.shift.career.club.games))
func host() -> bool:
 if not available():
  return false
 var id: String = game.shift.career.club.pending
 var receipt: Dictionary = game.shift.career.host_game(id)
 message = receipt.message
 if receipt.status != "hosted":
  sync()
  return false
 # The player has finished the assigned checklist. Volunteers complete routine passes.
 # No active attempt receives this work or any extra coverage pay.
 game.shift.enter_practice()
 game.grass.prepare_all()
 game.infield.prepare_all()
 game.moisture.fill_valid(0.8)
 game.chalk.prepare_all()
 game.mound.prepare_all()
 game.shift.collect_progress()
 game.update_progress(0)
 game.shift.overlay.refresh()
 if game.autosave != null:
  game.autosave.request()
 game.shift.open_board()
 game.shift.overlay.club_button.pressed.emit()
 sync()
 game.shift.overlay.club_panel.show_section("results")
 game.shift.overlay.club_panel.recap_continue.grab_focus()
 game.shift.overlay.club_panel.call_deferred("scroll_to_recap")
 opening.present(receipt.receipt)
 return true
func build(id: String) -> bool:
 if not available():
  return false
 opening.finish()
 if not available() or not game.shift.career.purchase_stadium(id):
  message = game.shift.career.error if not game.shift.career.error.is_empty() else "Meet the fan, budget and project requirements first."
  sync()
  return false
 game.shift.reset_equipment()
 game.update_progress(0)
 message = "Mara: %s is open. That's what reinvesting in the club looks like." % ClubProgress.PROJECTS[id].title
 sync()
 return true

func can_watch() -> bool:
 return available() and game.shift.session.phase == ShiftSession.Phase.PRACTICE and not game.shift.career.club.last.is_empty() and String(game.shift.career.club.pending).is_empty()
func watch_last_game() -> bool:
 if not can_watch() or opening.active:
  return false
 game.shift.open_board()
 game.shift.overlay.club_button.pressed.emit()
 game.shift.overlay.club_panel.show_section("results")
 opening.present(game.shift.career.club.last)
 return true
