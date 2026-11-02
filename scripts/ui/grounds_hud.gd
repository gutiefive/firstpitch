class_name GroundsHUD
extends CanvasLayer
const CREAM := Color("f4ecd8")
const GOLD := Color("e1bb67")
var mode_label: Label
var prompt: Label
var percent_label: Label
var progress: ProgressBar

func text_label(text: String,size: int,color: Color = CREAM) -> Label:
 var label := Label.new()
 label.text = text
 label.add_theme_font_size_override("font_size",size)
 label.add_theme_color_override("font_color",color)
 return label

func panel_style(color: Color) -> StyleBoxFlat:
 var style := StyleBoxFlat.new()
 style.bg_color = color
 style.corner_radius_top_left = 8
 style.corner_radius_top_right = 8
 style.corner_radius_bottom_left = 8
 style.corner_radius_bottom_right = 8
 style.content_margin_left = 20
 style.content_margin_right = 20
 style.content_margin_top = 14
 style.content_margin_bottom = 14
 return style

func _ready() -> void:
 var panel := PanelContainer.new()
 panel.position = Vector2(24,24)
 panel.custom_minimum_size = Vector2(320,0)
 var style := panel_style(Color(0.055,0.14,0.14,0.93))
 style.border_width_top = 3
 style.border_color = GOLD
 panel.add_theme_stylebox_override("panel",style)
 add_child(panel)
 var stack := VBoxContainer.new()
 stack.add_theme_constant_override("separation",6)
 panel.add_child(stack)
 stack.add_child(text_label("FIRST PITCH",26,GOLD))
 stack.add_child(text_label("G R O U N D S   C R E W",12))
 var gap := Control.new()
 gap.custom_minimum_size.y = 8
 stack.add_child(gap)
 stack.add_child(text_label("CEDAR GROVE  /  MORNING PREP",11,Color("aac2ad")))
 stack.add_child(text_label("Mow the outfield",19))
 var row := HBoxContainer.new()
 stack.add_child(row)
 percent_label = text_label("0.00%",26,GOLD)
 percent_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 row.add_child(percent_label)
 var status := text_label("FIELD PREPARED",10,Color("aac2ad"))
 status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 row.add_child(status)
 progress = ProgressBar.new()
 progress.custom_minimum_size = Vector2(280,7)
 progress.show_percentage = false
 progress.add_theme_stylebox_override("background",panel_style(Color("314d48")))
 progress.add_theme_stylebox_override("fill",panel_style(GOLD))
 # Remove panel padding on the narrow progress track.
 for name_value in ["background","fill"]:
  var track := progress.get_theme_stylebox(name_value) as StyleBoxFlat
  track.content_margin_left = 0
  track.content_margin_right = 0
  track.content_margin_top = 0
  track.content_margin_bottom = 0
 stack.add_child(progress)
 mode_label = text_label("ON FOOT",11,Color("aac2ad"))
 stack.add_child(mode_label)
 var bottom := PanelContainer.new()
 bottom.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
 bottom.offset_left = -465
 bottom.offset_right = 465
 bottom.offset_top = -60
 bottom.offset_bottom = -18
 bottom.add_theme_stylebox_override("panel",panel_style(Color(0.055,0.14,0.14,0.90)))
 add_child(bottom)
 prompt = text_label("",15)
 prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 bottom.add_child(prompt)
 var reminder := text_label("MOUSE  Orbit     SCROLL  Zoom     ESC  Cursor",12)
 reminder.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
 reminder.offset_left = -360
 reminder.offset_right = -24
 reminder.offset_top = 26
 reminder.offset_bottom = 52
 reminder.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 reminder.add_theme_color_override("font_shadow_color",Color("203e36"))
 reminder.add_theme_constant_override("shadow_outline_size",4)
 add_child(reminder)
