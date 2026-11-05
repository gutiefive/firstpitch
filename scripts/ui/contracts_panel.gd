class_name ContractsPanel
extends PanelContainer
signal back_requested
var director: ShiftDirector
var wallet: Label
var message: Label
var buttons: Dictionary = {}
var best_labels: Dictionary = {}
var back_button: Button

func text(parent: Node,value: String,font_size: int = 14) -> Label:
 var label := Label.new()
 label.text = value
 label.add_theme_font_size_override("font_size",font_size)
 label.modulate = Color("edf4f3")
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 parent.add_child(label)
 return label

func style(color: Color,margin: int) -> StyleBoxFlat:
 var box := StyleBoxFlat.new()
 box.bg_color = color
 box.set_corner_radius_all(10)
 box.content_margin_left = margin
 box.content_margin_right = margin
 box.content_margin_top = margin
 box.content_margin_bottom = margin
 return box

func _ready() -> void:
 theme = GameUI.theme()
 GameUI.width(self,860)
 add_theme_stylebox_override("panel",style(Color("15252f"),20))
 var content := VBoxContainer.new()
 content.add_theme_constant_override("separation",12)
 add_child(content)
 text(content,"Contract board",28).modulate = Color("76d8bd")
 text(content,"Short, repeatable jobs. Only the listed tasks count toward each contract.")
 wallet = text(content,"",16)
 var jobs := GridContainer.new()
 jobs.columns = 2
 jobs.add_theme_constant_override("h_separation",12)
 jobs.add_theme_constant_override("v_separation",12)
 content.add_child(jobs)
 for id in ShiftSession.PROFILES:
  var profile: Dictionary = ShiftSession.PROFILES[id]
  if not profile.get("contract",false):
   continue
  var card := PanelContainer.new()
  card.add_theme_stylebox_override("panel",style(Color("1b2e39"),12))
  card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  jobs.add_child(card)
  var row := VBoxContainer.new()
  row.add_theme_constant_override("separation",14)
  card.add_child(row)
  var details := VBoxContainer.new()
  details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  row.add_child(details)
  text(details,profile.title,20).modulate = Color("76d8bd")
  var goals := PackedStringArray()
  for i in range(5):
   if profile.goals[i] > 0:
    goals.append("%s %.0f%%" % [ShiftSession.JOB_NAMES[i],profile.goals[i]])
  text(details," · ".join(goals))
  text(details,("GAME DAY · " if profile.get("start","fresh") == "game_day" else "FRESH · ")+"%d min · Up to %d cr · %d cr completion bonus" % [int(profile.duration)/60,floori(100*float(profile.pay_rate))+int(profile.bonus),profile.bonus],13)
  best_labels[id] = text(details,"",13)
  var button := Button.new()
  button.custom_minimum_size.y = 44
  button.clip_text = true
  button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
  button.pressed.connect(func(): director.start_shift(id))
  row.add_child(button)
  buttons[id] = button
 text(content,"Fresh jobs reset the field. Game-day jobs wear it. Equipment parks; each attempt pays once.",13).modulate = Color("76d8bd")
 message = text(content,"",13)
 back_button = Button.new()
 back_button.text = "Back to shift board"
 back_button.custom_minimum_size.y = 40
 back_button.pressed.connect(func(): back_requested.emit())
 content.add_child(back_button)
 director.career.changed.connect(refresh)
 director.session.changed.connect(refresh)
 refresh()

func refresh() -> void:
 var visiting: bool = director.game.club != null and director.game.club.live != null and director.game.club.live.active
 var active := director.session.phase == ShiftSession.Phase.ACTIVE
 wallet.text = "%s · %d cr available · %d cr lifetime earnings" % [director.career.rank_title(),director.career.balance,director.career.earned]
 for id in buttons:
  var minimum := int(ShiftSession.PROFILES[id].get("minimum_earnings",0))
  var locked := director.career.earned < minimum
  buttons[id].disabled = active or locked or visiting
  buttons[id].text = ("Crew Lead required" if minimum >= 1500 else "Field Hand required") if locked else ("Shift active" if active else ("Start game day" if ShiftSession.PROFILES[id].get("start","fresh") == "game_day" else "Start fresh contract"))
  if visiting:
   buttons[id].text = "End park visit first"
  best_labels[id].text = "Best %.1f / 100%s" % [director.career.best.get(id,0.0)," · Unlocks at %d cr lifetime earnings" % minimum if locked else " · Available"]
 message.text = "End the live park visit before taking paid work." if visiting else ("Finish or end the current shift before taking another contract." if active else "Partial work pays too. Full training and full-park shifts remain on the main board.")
