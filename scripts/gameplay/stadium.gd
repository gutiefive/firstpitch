extends Node3D
const G = preload("res://scripts/gameplay/geometry.gd")
const Props = preload("res://scripts/environment/park_props.gd")
const CREAM := Color("eee3c6")
const TEAL := Color("28585a")

func _ready() -> void:
 build_field()
 build_boundary()
 build_neighborhood()
 build_atmosphere()

func build_field() -> void:
 G.box(self,Vector3(0,-0.3,-40),Vector3(400,0.6,400),Color("68845b"),true)
 var dirt := Color("b7794c")
 var track := G.sector(self,99,104,0.06,dirt)
 track.material_override = ground_material(Color("ad7951"),Color("ba8c63"),0.8)
 var diamond := G.box(self,Vector3(0,0.025,-19.396),Vector3(31,0.025,31),dirt)
 diamond.rotation.y = PI/4
 diamond.material_override = ground_material(Color("a96140"),Color("bd7950"),1.3)
 # A manicured infield island is decorative: the mowing objective scores the outfield only.
 var island := G.box(self,Vector3(0,0.065,-19.396),Vector3(22,0.035,22),Color("427a50"))
 island.rotation.y = PI/4
 island.material_override = ground_material(Color("3c7248"),Color("477c4e"),1.8)
 var home := G.cylinder(self,Vector3(0,0.07,0),6,0.12,dirt)
 home.material_override = diamond.material_override
 var mound := G.cylinder(self,Vector3(0,0.18,-18.44),2.8,0.36,dirt)
 mound.material_override = diamond.material_override
 G.box(self,Vector3(0,0.38,-18.44),Vector3(0.61,0.05,0.15),CREAM)
 for pos in [Vector3(19.396,0,-19.396),Vector3(0,0,-38.792),Vector3(-19.396,0,-19.396)]:
  var base := G.box(self,pos+Vector3.UP*0.1,Vector3(0.5,0.16,0.5),CREAM)
  base.rotation.y = PI/4
 # A recognizable five-sided home plate, with a rectangular batter's-box pair.
 var plate := G.cylinder(self,Vector3(0,0.15,0),0.32,0.045,CREAM)
 (plate.mesh as CylinderMesh).radial_segments = 5
 for x in [-1.15,1.15]:
  for z in [-1.1,1.1]:
   G.box(self,Vector3(x,0.15,z),Vector3(1.1,0.018,0.06),CREAM)
  for edge in [-0.55,0.55]:
   G.box(self,Vector3(x+edge,0.15,0),Vector3(0.06,0.018,2.2),CREAM)
 for side in [-1,1]:
  var line := G.box(self,Vector3(side*36.5,0.095,-36.5),Vector3(0.16,0.025,103),CREAM)
  line.rotation.y = -side*PI/4
  G.cylinder(self,Vector3(side*73.5,9,-73.5),0.12,18,Color("e7bd54"))

func ground_material(dark: Color,light: Color,scale_value: float) -> ShaderMaterial:
 var mat := ShaderMaterial.new()
 mat.shader = preload("res://shaders/ground.gdshader")
 mat.set_shader_parameter("dark_color",dark.srgb_to_linear())
 mat.set_shader_parameter("light_color",light.srgb_to_linear())
 mat.set_shader_parameter("grain_scale",scale_value)
 return mat

func build_boundary() -> void:
 for i in range(46):
  var a := deg_to_rad(-45.0+i*2)
  var fence := G.box(self,Vector3(sin(a)*104,1.8,-cos(a)*104),Vector3(3.8,3.6,0.35),TEAL,true)
  fence.rotation.y = -a
  var rail := G.box(self,fence.position+Vector3.UP*1.85,Vector3(3.8,0.12,0.45),Color("d8b468"))
  rail.rotation.y = -a
  var seam := G.box(self,fence.position+Vector3(sin(a)*-0.25,0,-cos(a)*-0.25),Vector3(0.06,3.5,0.08),Color("386666"))
  seam.rotation.y = -a
 var advertisers := ["MILLER'S HARDWARE","THE CORNER DELI","CEDAR GROVE\nCOMMUNITY CREDIT","PLAY BALL. STAY LOCAL.","PINE & POST\nFARM SUPPLY"]
 for i in range(5):
  var angle := deg_to_rad(-32+i*16)
  var pos := Vector3(sin(angle)*103.65,2,-cos(angle)*103.65)
  var panel := Props.group(self,"CommunitySign",pos)
  panel.rotation.y = -angle
  G.box(panel,Vector3.ZERO,Vector3(14,1.7,0.06),CREAM if i%2 == 0 else Color("c18c58"))
  var label := G.label(panel,advertisers[i],Vector3(0,0,0.05),44)
  label.pixel_size = 0.014
  label.modulate = TEAL
 for side in [-1,1]:
  var marker := G.label(self,"330",Vector3(side*68,2,-77),64)
  marker.rotation.y = -side*PI/4
  marker.modulate = CREAM
 for x in [-8,-4,0,4,8]:
  G.cylinder(self,Vector3(x,3.5,6),0.065,7,Color("526569"))
 for height in [1.0,3.0,5.0,7.0]:
  G.box(self,Vector3(0,height,6),Vector3(16,0.035,0.035),Color("526569"))
 for side in [-1,1]:
  Props.dugout(self,side)
  Props.grandstand(self,side)
 Props.scoreboard(self)
 for pos in [Vector3(-55,0,-35),Vector3(55,0,-35),Vector3(-35,0,15),Vector3(35,0,15)]:
  Props.light_tower(self,pos)

func build_neighborhood() -> void:
 # Concourse and workshop use the existing collision footprint and driving lane.
 var path := G.box(self,Vector3(0,0.018,22),Vector3(63,0.035,8),Color("c9b590"))
 path.material_override = ground_material(Color("bbab8e"),Color("d0bf9f"),1.5)
 for z in [18.1,25.9]:
  G.box(self,Vector3(0,0.07,z),Vector3(63,0.12,0.18),CREAM)
 G.box(self,Vector3(33,0.03,-19),Vector3(13,0.04,9),Color("8b9987"))
 for x in [27.2,32,36.8]:
  G.box(self,Vector3(x,0.065,-21),Vector3(0.07,0.02,4),CREAM)
 Props.shed(self)
 for side in [-1,1]:
  Props.bench(self,Vector3(side*26,0,22))
  for i in range(5):
   Props.tree(self,Vector3(side*(39+i*8),0,23+i*3),7.5+(i%3),i)
 # A deterministic tree line frames the stadium instead of an empty test plane.
 for i in range(39):
  var a := deg_to_rad(-75+i*4)
  var distance := 117.0+(i%3)*7
  Props.tree(self,Vector3(sin(a)*distance,0,-cos(a)*distance),9.0+(i%5)*1.4,i)
 for x in [-25,25]:
  var flagpole := Vector3(x,0,30)
  G.cylinder(self,flagpole+Vector3.UP*5,0.06,10,CREAM)
  G.box(self,flagpole+Vector3(0.9,9.1,0),Vector3(1.8,1,0.04),TEAL)
  G.box(self,flagpole+Vector3(0.9,9.1,0.03),Vector3(0.18,1,0.02),CREAM)
 # Small ticket booth and its striped awning at the back of the stands.
 var booth := Props.group(self,"TicketBooth",Vector3(0,0,29))
 G.box(booth,Vector3(0,1.5,0),Vector3(5,3,3),TEAL,true)
 G.box(booth,Vector3(0,2.05,1.56),Vector3(3.5,1.1,0.12),CREAM)
 G.box(booth,Vector3(0,2.05,1.64),Vector3(3.2,0.85,0.06),Color("587f89"))
 for stripe in range(10):
  G.box(booth,Vector3(-2.7+stripe*0.6,3.1,1.25),Vector3(0.6,0.12,3.2),CREAM if stripe%2 == 0 else Color("b75e44"))
 var tickets := G.label(booth,"T I C K E T S",Vector3(0,2.9,2.95),40)
 tickets.pixel_size = 0.008
 tickets.modulate = TEAL

func build_atmosphere() -> void:
 var sun := DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-38,-38,0)
 sun.light_color = Color("fff0d5")
 sun.light_energy = 0.72
 sun.light_angular_distance = 1.2
 sun.shadow_enabled = true
 sun.shadow_bias = 0.04
 sun.directional_shadow_max_distance = 220
 add_child(sun)
 var world := WorldEnvironment.new()
 var env := Environment.new()
 env.background_mode = Environment.BG_SKY
 var sky := Sky.new()
 var atmosphere := ProceduralSkyMaterial.new()
 atmosphere.sky_top_color = Color("4e94bb")
 atmosphere.sky_horizon_color = Color("d4e4dd")
 atmosphere.ground_horizon_color = Color("d4e4dd")
 atmosphere.ground_bottom_color = Color("899f7c")
 sky.sky_material = atmosphere
 env.sky = sky
 env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
 env.ambient_light_energy = 0.45
 env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 env.fog_enabled = true
 env.fog_light_color = Color("b9d1c7")
 env.fog_density = 0.0007
 world.environment = env
 add_child(world)
