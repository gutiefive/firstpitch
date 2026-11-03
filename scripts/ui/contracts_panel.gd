class_name ContractsPanel
extends PanelContainer
signal back_requested
var director: ShiftDirector
var wallet: Label
var message: Label
var buttons: Dictionary = {}
var best_labels: Dictionary = {}
var back_button: Button

func text(parent: Node,value: String,size: int = 14) -> Label:
 var label := Label.new()
 label.text = value
 label.add_theme_font_size_override("font_size",size)
 label.modulate = Color("f4ecd8")
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
 custom_minimum_size.x = 780
 add_theme_stylebox_override("panel",style(Color("173c39"),20))
 var content := VBoxContainer.new()
 content.add_theme_constant_override("separation",12)
 add_child(content)
 text(content,"CONTRACT BOARD",28).modulate = Color("e1bb67")
 text(content,"Short, repeatable jobs. Only the listed tasks count toward each contract.")
 wallet = text(content,"",16)
 for id in ShiftSession.PROFILES:
  var profile: Dictionary = ShiftSession.PROFILES[id]
  if not profile.get("contract",false):
   continue
  var card := PanelContainer.new()
  card.add_theme_stylebox_override("panel",style(Color("254b43"),12))
  content.add_child(card)
  var row := HBoxContainer.new()
  row.add_theme_constant_override("separation",14)
  card.add_child(row)
  var details := VBoxContainer.new()
  details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  row.add_child(details)
  text(details,profile.title,20).modulate = Color("e1bb67")
  var goals := PackedStringArray()
  for i in range(5):
   if profile.goals[i] > 0:
    goals.append("%s %.0f%%" % [ShiftSession.JOB_NAMES[i],profile.goals[i]])
  text(details," · ".join(goals))
  text(details,"%d min · Up to %d cr · %d cr completion bonus" % [int(profile.duration)/60,floori(100*float(profile.pay_rate))+int(profile.bonus),profile.bonus],13)
  best_labels[id] = text(details,"",13)
  var button := Button.new()
  button.custom_minimum_size = Vector2(180,42)
  button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
  button.pressed.connect(func(): director.start_shift(id))
  row.add_child(button)
  buttons[id] = button
 text(content,"Starting fresh resets all field work and parks equipment. Each attempt pays once.",13).modulate = Color("e1bb67")
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
 var active := director.session.phase == ShiftSession.Phase.ACTIVE
 wallet.text = "%s · %d cr available · %d cr lifetime earnings" % [director.career.rank_title(),director.career.balance,director.career.earned]
 for id in buttons:
  var minimum := int(ShiftSession.PROFILES[id].get("minimum_earnings",0))
  var locked := director.career.earned < minimum
  buttons[id].disabled = active or locked
  buttons[id].text = "Field Hand required" if locked else ("Shift active" if active else "Start fresh contract")
  best_labels[id].text = "Best %.1f / 100%s" % [director.career.best.get(id,0.0)," · Unlocks at 500 cr lifetime earnings" if locked else " · Available"]
 message.text = "Finish or end the current shift before taking another contract." if active else "Partial work pays too. Full training and full-park shifts remain on the main board."
