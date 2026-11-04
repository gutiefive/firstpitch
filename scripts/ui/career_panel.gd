class_name CareerPanel
extends PanelContainer
signal back_requested
var director: ShiftDirector
var heading: Label
var summary: Label
var progress: Label
var record: Label
var history: Label
var message: Label
var shop: Dictionary = {}
var details: Dictionary = {}
var availability := {}
var savings := {}
var purchase_feedback: Label
var back_button: Button
var retry_button: Button

func text(content: VBoxContainer,value: String,size: int = 16) -> Label:
 var label := Label.new()
 label.text = value
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.add_theme_font_size_override("font_size",size)
 label.modulate = Color("edf4f3")
 content.add_child(label)
 return label

func _ready() -> void:
 theme = GameUI.theme()
 GameUI.width(self,860)
 var style := StyleBoxFlat.new()
 style.bg_color = Color("15252f")
 style.set_corner_radius_all(10)
 style.content_margin_left = 24
 style.content_margin_right = 24
 style.content_margin_top = 20
 style.content_margin_bottom = 20
 add_theme_stylebox_override("panel",style)
 var content := VBoxContainer.new()
 content.add_theme_constant_override("separation",10)
 add_child(content)
 heading = text(content,"Equipment workshop",28)
 heading.modulate = Color("76d8bd")
 summary = text(content,"",22)
 progress = text(content,"",14)
 record = text(content,"",14)
 text(content,"Training: 1 cr/point + 50 for completion. Full prep: 3 cr/point + 150.",13)
 text(content,"Partial work pays; practice does not. Each attempt pays once. Credits round down.",13)
 text(content,"EQUIPMENT UPGRADES",18).modulate = Color("76d8bd")
 var equipment := GridContainer.new()
 equipment.columns = 2
 equipment.add_theme_constant_override("h_separation",12)
 equipment.add_theme_constant_override("v_separation",12)
 content.add_child(equipment)
 for id in CareerProfile.UPGRADES:
  var item := GameUI.card(equipment)
  text(item,CareerProfile.UPGRADES[id].title,19)
  var detail := text(item,CareerProfile.UPGRADES[id].detail,13)
  details[id] = detail
  savings[id] = GameUI.meter(item)
  availability[id] = GameUI.label(item,"",12,GameUI.MUTED)
  var button := Button.new()
  button.custom_minimum_size.y = 40
  button.add_theme_font_size_override("font_size",14)
  button.pressed.connect(func():
   var bought := director.career.purchase(id)
   purchase_feedback.text = "%s installed · %d cr remaining" % [CareerProfile.UPGRADES[id].title,director.career.balance] if bought else (director.career.error if not director.career.error.is_empty() else "Purchase unavailable. Check the requirements below.")
   purchase_feedback.visible = true
   refresh()
   if director.game.shift.overlay.career_screen.visible:
    director.game.shift.overlay.focus_current()
    finish_purchase_focus())
  item.add_child(button)
  shop[id] = button
 text(content,"RECENT SHIFTS",18).modulate = Color("76d8bd")
 history = text(content,"",14)
 history.custom_minimum_size.y = 92
 message = text(content,"",13)
 message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 purchase_feedback = GameUI.label(content,"",14,GameUI.ACCENT)
 purchase_feedback.visible = false
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
 heading.text = "OWLS WORKSHOP" if career.club_started() else "CREW CAREER"
 summary.text = "%s  /  %d credits" % [career.rank_title(),career.balance]
 progress.text = "%d lifetime earnings · %s" % [career.earned,career.next_rank_text()]
 record.text = "%d shifts · %d completed · Best training %.1f / full %.1f" % [career.data.records.size(),career.completed,career.best.training,career.best.full]
 for id in shop:
  var item: Dictionary = CareerProfile.UPGRADES[id]
  details[id].text = item.detail
  if career.club_started():
   details[id].text = {"wide_deck":"Replace the 1.8 m starter deck with a 3.0 m deck.","hose_nozzle":"Replace the worn hose: application rises from 0.65 to 1.0.","wide_drag":"Replace the 2.4 m starter mat with a 3.5 m drag. Requires Field Hand."}.get(id,item.detail)
  var term := "OWNED" if career.owns(id) else str(item.cost)+" cr"
  shop[id].text = term if career.owns(id) else ("Locked · "+term if not career.upgrade_unlocked(id) else "Buy · "+term)
  shop[id].clip_text = true
  shop[id].disabled = not career.healthy or not career.upgrade_unlocked(id) or career.owns(id) or career.balance < int(item.cost)
  savings[id].value = minf(100,100.0*career.balance/int(item.cost))
  savings[id].visible = not career.owns(id)
  var status := GameUI.funding(career.balance,int(item.cost))
  if not career.upgrade_unlocked(id):
   status = "Reach Field Hand · %d / 500 lifetime cr" % career.earned
  if not career.healthy:
   status = "Reload your career before buying."
  if career.owns(id):
   status = "Installed · available on your equipment"
  availability[id].text = status
  availability[id].add_theme_color_override("font_color",GameUI.ACCENT if career.owns(id) or not shop[id].disabled else GameUI.GOLD)
  shop[id].tooltip_text = item.title+"\n"+status

 var rows := PackedStringArray()
 for i in range(career.data.records.size()-1,maxi(-1,career.data.records.size()-6),-1):
  var result: Dictionary = career.data.records[i].result
  var outcome := {"completed":"Complete","time_up":"Time up","ended_early":"Ended early"}
  rows.append("%s · %.1f pts · %s · +%d cr" % [result.title,result.score,outcome[result.reason],CareerProfile.payout(result)])
 history.text = "No shifts recorded yet. Start a training shift from the board." if rows.is_empty() else "\n".join(rows)
 message.text = career.error if not career.error.is_empty() else (director.career_message if not director.career_message.is_empty() else "Career and purchases save automatically, separately from the field slot.")
 retry_button.visible = not career.error.is_empty() or not career.healthy or director.session.phase == ShiftSession.Phase.FINISHED

func finish_purchase_focus() -> void:
 await get_tree().process_frame
 await get_tree().process_frame
 if not is_inside_tree():
  return
 var screen: ScrollContainer = director.game.shift.overlay.career_screen
 var owner := get_viewport().gui_get_focus_owner()
 if screen.is_visible_in_tree() and owner != null and screen.is_ancestor_of(owner):
  screen.ensure_control_visible(owner)
