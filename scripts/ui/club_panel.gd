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
var ownership_review: Label
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
var sections := {}
var tabs := {}
var selected_section := "matchday"
var metrics := {}
var project_grid: GridContainer
var results_title: Label
func text(parent: Node,value: String,size: int = 14) -> Label:
 return GameUI.label(parent,value,size)
func button(parent: Node,value: String) -> Button:
 return GameUI.button(parent,value)
func _ready() -> void:
 theme = GameUI.theme()
 GameUI.width(self)
 add_theme_stylebox_override("panel",GameUI.box(GameUI.SURFACE,24))
 var content := VBoxContainer.new()
 content.add_theme_constant_override("separation",12)
 add_child(content)
 GameUI.label(content,"CLUB OPERATIONS  /  CEDAR GROVE",11,GameUI.MUTED)
 text(content,"Owls clubhouse",28)
 stats = GameUI.label(content,"",13,GameUI.MUTED)
 var metrics_row := HBoxContainer.new()
 metrics_row.add_theme_constant_override("separation",12)
 content.add_child(metrics_row)
 for key in ["BUDGET","SUPPORTERS","CAPACITY","HOME DATES"]:
  var tile := GameUI.card(metrics_row,key)
  tile.get_parent().add_theme_stylebox_override("panel",GameUI.box(Color("1b2e39"),12))
  metrics[key] = text(tile,"0",23)
 var navigation := HBoxContainer.new()
 navigation.add_theme_constant_override("separation",8)
 content.add_child(navigation)
 for key in ["matchday","stadium","results","season"]:
  var tab := GameUI.button(navigation,String(key).capitalize())
  tab.toggle_mode = true
  tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  tab.pressed.connect(func(): show_section(key); tab.grab_focus())
  tabs[key] = tab
  var section := VBoxContainer.new()
  section.add_theme_constant_override("separation",14)
  content.add_child(section)
  sections[key] = section
 var columns := HFlowContainer.new()
 columns.add_theme_constant_override("h_separation",16)
 columns.add_theme_constant_override("v_separation",16)
 sections.matchday.add_child(columns)
 var play := GameUI.card(columns,"NEXT HOME DATE")
 play.custom_minimum_size.x = 360
 schedule = text(play,"",15)
 var actions := GridContainer.new()
 actions.columns = 2
 actions.add_theme_constant_override("h_separation",8)
 actions.add_theme_constant_override("v_separation",8)
 play.add_child(actions)
 join_button = GameUI.button(actions,"Take the job",true)
 prep_button = GameUI.button(actions,"Prepare home game",true)
 host_button = GameUI.button(actions,"Open the gates",true)
 workshop_button = button(actions,"Upgrade equipment")
 for item in [join_button,prep_button,host_button,workshop_button]:
  item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 join_button.pressed.connect(director.join)
 prep_button.pressed.connect(director.prepare)
 host_button.pressed.connect(director.host)
 workshop_button.pressed.connect(func(): director.game.shift.overlay.career_button.pressed.emit())
 GameUI.label(play,"Finish the assigned prep, then host to collect gate income. Missing a manager request never blocks hosting.",12,GameUI.MUTED)
 var story := GameUI.card(columns,"FROM THE GENERAL MANAGER")
 story.custom_minimum_size.x = 360
 chapter = text(story,"",20)
 voice = text(story,"",14)
 objective = text(story,"",14)
 objective.modulate = GameUI.ACCENT
 recap_continue = GameUI.button(sections.results,"Continue to next date",true)
 recap_continue.pressed.connect(func(): show_section("matchday"); prep_button.grab_focus())
 var result_card := GameUI.card(sections.results,"POSTGAME REPORT")
 results_title = text(result_card,"Your next home game starts here",28)
 receipt = text(result_card,"",16)
 var investment_card := GameUI.card(sections.results,"YOUR NEXT INVESTMENT")
 investment = text(investment_card,"",14)
 GameUI.label(sections.stadium,"Build a better night at the ballpark",24)
 GameUI.label(sections.stadium,"Permanent upgrades share your club budget. Requirements and benefits are shown before you buy.",13,GameUI.MUTED)
 project_grid = GridContainer.new()
 project_grid.columns = 3
 project_grid.add_theme_constant_override("h_separation",12)
 project_grid.add_theme_constant_override("v_separation",12)
 sections.stadium.add_child(project_grid)
 for id in ClubProgress.PROJECTS:
  var card := GameUI.card(project_grid)
  var item: Dictionary = ClubProgress.PROJECTS[id]
  text(card,item.title,19)
  GameUI.label(card,"%d cr  /  %d supporters" % [item.cost,item.fans],13,GameUI.ACCENT)
  text(card,item.detail,13)
  if not item.requires.is_empty():
   var required := PackedStringArray()
   for dependency in item.requires:
    required.append(ClubProgress.PROJECTS[dependency].title)
   GameUI.label(card,"Requires "+", ".join(required),12,GameUI.MUTED)
  var buy := GameUI.button(card,"Build upgrade")
  buy.pressed.connect(func(): director.build(id))
  projects[id] = buy
 var season_card := GameUI.card(sections.season,"SEASON PERFORMANCE")
 season_review = text(season_card,"",18)
 ownership_review = text(GameUI.card(sections.season,"MARA'S OWNERSHIP REVIEW"),"",15)
 notice = GameUI.label(content,"",13,GameUI.GOLD)
 back_button = button(content,"Back to operations")
 back_button.pressed.connect(func(): back_requested.emit())
 director.game.shift.career.changed.connect(refresh)
 director.game.shift.session.changed.connect(refresh)
 get_viewport().size_changed.connect(fit_layout)
 fit_layout()
 refresh()
 show_section("matchday")
func fit_layout() -> void:
 GameUI.width(self)
 project_grid.columns = 2 if get_viewport_rect().size.x < 1200 else 3
func show_section(key: String) -> void:
 selected_section = key
 for id in sections:
  sections[id].visible = id == key
  tabs[id].set_pressed_no_signal(id == key)
 if is_inside_tree() and director.game.shift.overlay.club_screen.visible:
  director.game.shift.overlay.focus_current()
func preferred_focus() -> Control:
 if selected_section == "results" and recap_continue.visible:
  return recap_continue
 if selected_section == "matchday":
  for candidate in [join_button,host_button,prep_button,workshop_button]:
   if candidate.visible and not candidate.disabled:
    return candidate
 if selected_section == "stadium":
  for candidate in projects.values():
   if not candidate.disabled:
    return candidate
 return tabs[selected_section]
func refresh() -> void:
 var career: CareerProfile = director.game.shift.career
 var state: Dictionary = career.club
 var story := ClubProgress.chapter(state)
 var ready := director.available()
 stats.text = career.rank_title()+"  ·  Shared club funds"
 metrics.BUDGET.text = "%d cr" % career.balance
 metrics.SUPPORTERS.text = str(state.fans)
 metrics.CAPACITY.text = str(state.capacity)
 metrics["HOME DATES"].text = str(state.games)
 results_title.text = "Home date %d complete" % state.games if not state.last.is_empty() else "Your first home game"
 chapter.text = story.title
 voice.text = story.voice
 if state.active and state.games == 0 and not career.data.upgrades.is_empty():
  voice.text = "Mara: Your equipment gives us a head start. You cover priority prep and the volunteers finish routine passes. Let's bring the town back to this park."
 objective.text = story.goal
 schedule.visible = true
 season_review.visible = true
 if not state.active:
  schedule.text = "A little club. A town to win back.\nStart with borrowed tools, earn your first gate, and choose how to reinvest."
  season_review.text = "Your first home season begins when you take the job."
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
   schedule.text += "\nSeason target: score %d+ in %d minutes." % [date.target,date.minutes]
  schedule.text += "\n"+GameDay.info(upcoming).title+"\n"+GameDay.request_text(upcoming)
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
  projects[id].text = "Built" if id in state.buildings else ("Build · %d cr" % ClubProgress.PROJECTS[id].cost)
  projects[id].disabled = not ready or not career.healthy or not state.active or not ClubProgress.project_ready(state,id) or career.balance < int(ClubProgress.PROJECTS[id].cost)
 receipt.text = "Next checklist: "+GameDay.checklist(GameDay.profile(state.games))+". Up to 160 cr prep pay, plus gate income and eligible manager bonus."
 if not state.last.is_empty():
  receipt.text = GameDay.recap(career)
 investment.text = GameDay.investment_text(career) if state.active else ""
 ownership_review.visible = true
 ownership_review.text = director.ownership.get("text","Complete your first six hosted home dates to receive Mara’s ownership review and a concrete objective for next season.")
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
 show_section("results")
 await get_tree().process_frame
 await get_tree().process_frame
 if is_inside_tree() and director.game.shift.overlay.club_screen.visible:
  director.game.shift.overlay.club_screen.scroll_vertical = 0
