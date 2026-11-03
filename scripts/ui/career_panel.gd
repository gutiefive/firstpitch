class_name CareerPanel
extends PanelContainer
signal back_requested
var director: ShiftDirector
var summary: Label
var progress: Label
var record: Label
var history: Label
var message: Label
var shop: Dictionary = {}
var back_button: Button
var retry_button: Button

func text(content: VBoxContainer,value: String,size: int = 16) -> Label:
 var label := Label.new()
 label.text = value
 label.add_theme_font_size_override("font_size",size)
 label.modulate = Color("f4ecd8")
 content.add_child(label)
 return label

func _ready() -> void:
 custom_minimum_size.x = 740
 var style := StyleBoxFlat.new()
 style.bg_color = Color("173c39")
 style.set_corner_radius_all(10)
 style.content_margin_left = 24
 style.content_margin_right = 24
 style.content_margin_top = 20
 style.content_margin_bottom = 20
 add_theme_stylebox_override("panel",style)
 var content := VBoxContainer.new()
 content.add_theme_constant_override("separation",10)
 add_child(content)
 text(content,"CREW CAREER",28).modulate = Color("e1bb67")
 summary = text(content,"",22)
 progress = text(content,"",14)
 record = text(content,"",14)
 text(content,"Training: 1 cr/point + 50 for completion. Full prep: 3 cr/point + 150.",13)
 text(content,"Partial work pays; practice does not. Each attempt pays once. Credits round down.",13)
 text(content,"EQUIPMENT UPGRADES",18).modulate = Color("e1bb67")
 for id in CareerProfile.UPGRADES:
  var button := Button.new()
  button.custom_minimum_size.y = 40
  button.pressed.connect(func():
   director.career.purchase(id)
   refresh())
  content.add_child(button)
  shop[id] = button
  text(content,CareerProfile.UPGRADES[id].detail,13)
 text(content,"RECENT SHIFTS",18).modulate = Color("e1bb67")
 history = text(content,"",14)
 history.custom_minimum_size.y = 92
 message = text(content,"",13)
 message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 retry_button = Button.new()
 retry_button.text = "Reload career / retry last reward"
 retry_button.pressed.connect(func():
  director.retry_career()
  refresh())
 content.add_child(retry_button)
 back_button = Button.new()
 back_button.text = "Back to shift board"
 back_button.custom_minimum_size.y = 40
 back_button.pressed.connect(func(): back_requested.emit())
 content.add_child(back_button)
 director.career.changed.connect(refresh)
 refresh()

func refresh() -> void:
 var career := director.career
 summary.text = "%s  /  %d credits" % [career.rank_title(),career.balance]
 progress.text = "%d lifetime earnings · %s" % [career.earned,career.next_rank_text()]
 record.text = "%d shifts · %d completed · Best training %.1f / full %.1f" % [career.data.records.size(),career.completed,career.best.training,career.best.full]
 for id in shop:
  var item: Dictionary = CareerProfile.UPGRADES[id]
  shop[id].text = "%s  ·  %s" % [item.title,"OWNED" if career.owns(id) else str(item.cost)+" cr"]
  shop[id].disabled = not career.healthy or career.owns(id) or career.balance < int(item.cost)
 var rows := PackedStringArray()
 for i in range(career.data.records.size()-1,maxi(-1,career.data.records.size()-6),-1):
  var result: Dictionary = career.data.records[i].result
  var outcome := {"completed":"Complete","time_up":"Time up","ended_early":"Ended early"}
  rows.append("%s · %.1f pts · %s · +%d cr" % [result.title,result.score,outcome[result.reason],CareerProfile.payout(result)])
 history.text = "No shifts recorded yet. Start a training shift from the board." if rows.is_empty() else "\n".join(rows)
 message.text = career.error if not career.error.is_empty() else (director.career_message if not director.career_message.is_empty() else "Career and purchases save automatically, separately from the field slot.")
 retry_button.visible = not career.error.is_empty() or not career.healthy or director.session.phase == ShiftSession.Phase.FINISHED
