class_name ClubPanel
extends PanelContainer
signal back_requested
var director: ClubDirector
var stats: Label
var chapter: Label
var voice: Label
var objective: Label
var schedule: Label
var season_review: Label
var receipt: Label
var notice: Label
var investment: Label
var recap_continue: Button
var join_button: Button
var prep_button: Button
var host_button: Button
var workshop_button: Button
var back_button: Button
var projects := {}
func text(parent: Node,value: String,size: int = 14) -> Label:
 var label := Label.new()
 label.text = value
 label.add_theme_font_size_override("font_size",size)
 label.modulate = Color("f4ecd8")
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 parent.add_child(label)
 return label
func button(parent: Node,value: String) -> Button:
 var node := Button.new()
 node.text = value
 node.custom_minimum_size.y = 40
 node.add_theme_font_size_override("font_size",14)
 parent.add_child(node)
 return node
func _ready() -> void:
 custom_minimum_size.x = 860
 var style := StyleBoxFlat.new()
 style.bg_color = Color("173c39")
 style.set_corner_radius_all(10)
 style.set_content_margin_all(22)
 add_theme_stylebox_override("panel",style)
 var content := VBoxContainer.new()
 content.add_theme_constant_override("separation",8)
 add_child(content)
 text(content,"CEDAR GROVE OWLS · CLUBHOUSE",26).modulate = Color("e1bb67")
 text(content,"LOW-A BASEBALL · A small club with a town to win back",13)
 stats = text(content,"",20)
 receipt = text(content,"",15)
 receipt.modulate = Color("f4ecd8")
 investment = text(content,"",14)
 investment.modulate = Color("b7d0bc")
 recap_continue = button(content,"Continue to next date")
 recap_continue.pressed.connect(func(): prep_button.grab_focus())
 chapter = text(content,"",19)
 chapter.modulate = Color("e1bb67")
 voice = text(content,"",15)
 objective = text(content,"",14)
 objective.modulate = Color("b7d0bc")
 schedule = text(content,"",15)
 schedule.modulate = Color("e1bb67")
 season_review = text(content,"",13)
 var actions := HBoxContainer.new()
 content.add_child(actions)
 join_button = button(actions,"Take the groundskeeper job")
 prep_button = button(actions,"Prepare home game · 20 min")
 host_button = button(actions,"Host home game")
 workshop_button = button(actions,"Buy better tools")
 for item in [join_button,prep_button,host_button,workshop_button]:
  item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 join_button.pressed.connect(director.join)
 prep_button.pressed.connect(director.prepare)
 host_button.pressed.connect(director.host)
 workshop_button.pressed.connect(func():
  director.game.shift.overlay.show_board()
  director.game.shift.overlay.career_button.pressed.emit())
 text(content,"REINVEST IN YOUR BALLPARK",18).modulate = Color("e1bb67")
 var grid := GridContainer.new()
 grid.columns = 3
 grid.add_theme_constant_override("h_separation",12)
 content.add_child(grid)
 for id in ClubProgress.PROJECTS:
  var card := VBoxContainer.new()
  card.custom_minimum_size.x = 250
  card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  grid.add_child(card)
  var item: Dictionary = ClubProgress.PROJECTS[id]
  var buy := button(card,item.title)
  buy.pressed.connect(func(): director.build(id))
  projects[id] = buy
  text(card,"%d cr · %d supporters required" % [item.cost,item.fans],12)
  text(card,item.detail,13)
  if not item.requires.is_empty():
   var required := PackedStringArray()
   for dependency in item.requires:
    required.append(ClubProgress.PROJECTS[dependency].title)
   text(card,"Needs: "+", ".join(required),12).modulate = Color("e1bb67")
 notice = text(content,"",13)
 notice.modulate = Color("e1bb67")
 text(content,"Shared budget: prep pay + net home-game income. Seats cap attendance; volunteers finish routine work. Construction parks equipment. Starting prep ends the practice guide. Home games are simulated.",12)
 back_button = button(content,"Back to shift board")
 back_button.pressed.connect(func(): back_requested.emit())
 director.game.shift.career.changed.connect(refresh)
 director.game.shift.session.changed.connect(refresh)
 refresh()
func refresh() -> void:
 var career: CareerProfile = director.game.shift.career
 var state: Dictionary = career.club
 var story := ClubProgress.chapter(state)
 var ready := director.available()
 stats.text = "%d cr budget  ·  %d supporters  ·  %d seats  ·  %d home games" % [career.balance,state.fans,state.capacity,state.games]
 chapter.text = story.title
 voice.text = story.voice
 if state.active and state.games == 0 and not career.data.upgrades.is_empty():
  voice.text = "Mara: Your equipment gives us a head start. You cover priority prep and the volunteers finish routine passes. Let's bring the town back to this park."
 objective.text = story.goal
 schedule.visible = state.active
 season_review.visible = state.active
 if state.active:
  var date := ClubSchedule.fixture(state.games)
  var upcoming := GameDay.profile(state.games)
  var session: ShiftSession = director.game.shift.session
  if session.phase == ShiftSession.Phase.ACTIVE and ShiftSession.PROFILES[session.profile_id].get("club",false):
   upcoming = session.profile_id
  for record in career.data.records:
   if record.id == state.pending:
    upcoming = record.result.profile_id
    break
  prep_button.text = "Prepare · %d min" % (int(ShiftSession.PROFILES[upcoming].duration)/60)
  schedule.text = ClubSchedule.title(state.games)
  if upcoming == "home_game":
   schedule.text += "\n"+String(date.brief)+"\nSeason target: score %d+ in %d minutes." % [date.target,date.minutes]
  schedule.text += "\n"+GameDay.info(upcoming).title+": "+GameDay.info(upcoming).brief+"\n"+GameDay.request_text(upcoming)
  var review := ClubSchedule.report(career)
  season_review.text = "Season %d review · %d / 6 hosted · %d prep targets met · %.1f average score" % [review.season,review.played,review.targets,review.average]
  if review.played > 0:
   season_review.text += "\nLast date: "+("Mara's prep target met." if review.last_met else "Prep target missed; the game still went ahead. Try again next date.")
  if review.played == 6:
   season_review.text += "\nHome season complete! Your supporters, stadium and tools carry into the next season."

 join_button.visible = not state.active
 join_button.disabled = not ready or not career.healthy
 prep_button.visible = state.active
 host_button.visible = state.active
 prep_button.disabled = not ready or not career.healthy or not String(state.pending).is_empty()
 host_button.disabled = not ready or not career.healthy or String(state.pending).is_empty()
 for id in projects:
  projects[id].text = ClubProgress.PROJECTS[id].title+(" · BUILT" if id in state.buildings else "")
  projects[id].disabled = not ready or not career.healthy or not state.active or not ClubProgress.project_ready(state,id) or career.balance < int(ClubProgress.PROJECTS[id].cost)
 receipt.text = "Next checklist: "+GameDay.checklist(GameDay.profile(state.games))+". Up to 160 cr prep pay, plus gate income and eligible manager bonus."
 if not state.last.is_empty():
  receipt.text = GameDay.recap(career)
 investment.text = GameDay.investment_text(career) if state.active else ""
 recap_continue.visible = state.active and not state.last.is_empty() and ready and String(state.pending).is_empty()
 if not String(state.pending).is_empty():
  for record in career.data.records:
   if record.id == state.pending:
    var preview := ClubProgress.forecast(state,record.result)
    receipt.text += "\nReady to host: %d expected attendance · %d cr net at current facilities" % [preview.attendance,preview.net]
    receipt.text += " · manager bonus %d cr" % int(preview.get("priority_bonus",0))
    break
 notice.text = career.error if not career.error.is_empty() else director.message

func scroll_to_recap() -> void:
 # Wait for text wrapping/focus following to settle before aligning the heading.
 await get_tree().process_frame
 await get_tree().process_frame
 if not is_inside_tree() or not director.game.shift.overlay.club_screen.visible:
  return
 var scroll: ScrollContainer = director.game.shift.overlay.club_screen
 scroll.scroll_vertical = 0
