class_name MatchdayAtmosphere
extends Node
var game: Node
var active := false
var evening := false
var caption := "Welcome to Cedar Grove."
var pa: AudioStreamPlayer
var lights: Node3D
var sun: DirectionalLight3D
var world: WorldEnvironment
var original := {}
var previous_stage := ""
var previous_score := Vector2i.ZERO
var previous_inning := 0
func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 sun = game.stadium.find_children("*","DirectionalLight3D",true,false)[0]
 world = game.stadium.find_children("*","WorldEnvironment",true,false)[0]
 pa = AudioStreamPlayer.new()
 pa.stream = game.audio.stream("shift")
 pa.bus = "GroundsAmbience"
 pa.volume_db = -17
 add_child(pa)
 lights = Node3D.new()
 game.stadium.add_child(lights)
 for p in [Vector3(-35,17,5),Vector3(35,17,5),Vector3(-35,17,-45),Vector3(35,17,-45)]:
  var lamp := SpotLight3D.new()
  lamp.position = p
  lights.add_child(lamp)
  lamp.look_at(Vector3(0,0,-20))
  lamp.light_color = Color("ffe9be")
  lamp.light_energy = 6
  lamp.spot_attenuation = 0.3
  lamp.spot_range = 100
  lamp.spot_angle = 55
  lamp.shadow_enabled = false
 lights.visible = false
func begin(date: int) -> void:
 if active:
  return
 previous_stage = ""
 previous_score = Vector2i.ZERO
 previous_inning = 0
 active = true
 original = {"energy":sun.light_energy,"color":sun.light_color,"rotation":sun.rotation_degrees,"env":world.environment}
 var event: String = ClubSchedule.fixture(date-1).event.to_lower()
 evening = event.contains("night") or event.contains("lights")
 if evening:
  world.environment = world.environment.duplicate(true)
  sun.light_energy = 0.4
  sun.light_color = Color("ffb67e")
  sun.rotation_degrees.x = -12
  world.environment.ambient_light_color = Color("8299bd")
  world.environment.ambient_light_energy = 0.7
  world.environment.fog_light_color = Color("73819a")
  var sky := world.environment.sky.sky_material as ProceduralSkyMaterial
  sky.sky_top_color = Color("243750")
  sky.sky_horizon_color = Color("c09983")
  lights.visible = true
func end() -> void:
 if not active:
  return
 sun.light_energy = original.energy
 sun.light_color = original.color
 sun.rotation_degrees = original.rotation
 world.environment = original.env
 lights.visible = false
 active = false
 evening = false
 pa.stop()
func announce(text: String) -> void:
 caption = text
 if active:
  pa.play()
func observe(park: MatchdayPark) -> void:
 if not active:
  return
 var score := Vector2i(park.home_runs,park.away_runs)
 if park.stage != previous_stage:
  var words := {"arrivals":"Welcome, Owls fans. Keep the aisles clear and enjoy your night at the park.","concourse":"Visit our local stands and look out for your neighbors.","game":"First pitch! Let's hear it for the Cedar Grove Owls.","stories":"That's the final. Thank you, fans, volunteers and grounds crew. Travel safely."}
  announce(words[park.stage])
 elif score.x > previous_score.x:
  announce("Owls score! Make some noise, Cedar Grove!")
  game.club.life.reaction.play()
 elif park.inning == 7 and previous_inning != 7:
  announce("Seventh-inning stretch. A wave for the crew keeping our park clean!")
 previous_stage = park.stage
 previous_score = score
 previous_inning = park.inning
func _process(_delta: float) -> void:
 if not active:
  return
 var viewing: bool = game.club.opening.active and not game.club.opening.playback_paused
 pa.stream_paused = get_tree().paused and not viewing
