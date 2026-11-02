extends Node3D
const G = preload("res://scripts/gameplay/geometry.gd")

func _ready() -> void:
 var green := Color("367351")
 var dirt := Color("b7794c")
 G.box(self,Vector3(0,-0.3,-40),Vector3(250,0.6,250),Color("64844c"),true)
 G.sector(self,0,104,0.012,dirt)
 G.sector(self,0,99,0.018,green)
 # The dirt diamond has 27.43 m sides, rotated 45 degrees.
 var diamond := G.box(self,Vector3(0,0.025,-19.396),Vector3(31,0.025,31),dirt)
 diamond.rotation.y = PI/4
 G.cylinder(self,Vector3(0,0.08,0),6,0.12,dirt)
 G.cylinder(self,Vector3(0,0.18,-18.44),2.8,0.36,dirt)
 G.box(self,Vector3(0,0.38,-18.44),Vector3(0.61,0.05,0.15),Color.WHITE)
 for pos in [Vector3.ZERO,Vector3(19.396,0,-19.396),Vector3(0,0,-38.792),Vector3(-19.396,0,-19.396)]:
  var base := G.box(self,pos+Vector3.UP*0.08,Vector3(0.5,0.12,0.5),Color.WHITE)
  base.rotation.y = PI/4
 for side in [-1,1]:
  var line := G.box(self,Vector3(side*36.5,0.065,-36.5),Vector3(0.12,0.03,103),Color("fff2d1"))
  line.rotation.y = -side*PI/4
 for side in [-1,1]:
  G.cylinder(self,Vector3(side*73.5,9,-73.5),0.12,18,Color("f1c747"))
 # A modest backstop behind home plate.
 for x in [-8,0,8]:
  G.cylinder(self,Vector3(x,3.5,6),0.08,7,Color("547579"))
 for height in [1.0,3.0,5.0,7.0]:
  G.box(self,Vector3(0,height,6),Vector3(16,0.035,0.035),Color("547579"))
 for i in range(46):
  var a := deg_to_rad(-45.0+i*2)
  var fence := G.box(self,Vector3(sin(a)*104,1.8,-cos(a)*104),Vector3(3.8,3.6,0.35),Color("214d49"),true)
  fence.rotation.y = -a
  var rail := G.box(self,fence.position+Vector3.UP*1.9,Vector3(3.8,0.12,0.45),Color("e6bd59"))
  rail.rotation.y = -a
 for side in [-1,1]:
  G.box(self,Vector3(side*27,1.3,-7),Vector3(11,2.6,4),Color("245a65"),true)
  G.box(self,Vector3(side*27,2.8,-7),Vector3(12,0.3,5),Color("e9d9ac"),true)
  G.label(self,"HOME" if side < 0 else "VISITORS",Vector3(side*27,2,-4.9),40)
  for row in range(4):
   G.box(self,Vector3(side*12,0.6+row*0.65,10+row*1.6),Vector3(19,0.35,1.2),Color("d7ac6b"),true)
 G.box(self,Vector3(38,2.3,-11),Vector3(8,4.6,7),Color("c88950"),true)
 G.box(self,Vector3(38,4.7,-11),Vector3(9,0.4,8),Color("254f59"),true)
 G.label(self,"GROUNDS CREW",Vector3(38,3,-7.4),32)
 G.box(self,Vector3(33,0.03,-19),Vector3(13,0.04,9),Color("8a8b7d"))
 G.box(self,Vector3(0,8,-105),Vector3(20,8,0.7),Color("173d40"),true)
 G.label(self,"FIRST PITCH\nGROUNDS CREW\nHOME  0     GUEST  0",Vector3(0,8,-104.5),52)
 for pos in [Vector3(-55,0,-35),Vector3(55,0,-35),Vector3(-35,0,15),Vector3(35,0,15)]:
  G.cylinder(self,pos+Vector3.UP*10,0.24,20,Color("bbc3b5"))
  G.box(self,pos+Vector3.UP*20,Vector3(4,1.1,0.6),Color("fff3c1"))
 var sun := DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-52,-35,0)
 sun.light_color = Color("fff1d3")
 sun.light_energy = 0.85
 sun.shadow_enabled = true
 sun.directional_shadow_max_distance = 180
 add_child(sun)
 var world := WorldEnvironment.new()
 var env := Environment.new()
 env.background_mode = Environment.BG_SKY
 var sky := Sky.new()
 var atmosphere := ProceduralSkyMaterial.new()
 atmosphere.sky_top_color = Color("3978ae")
 atmosphere.sky_horizon_color = Color("b7d9dc")
 atmosphere.ground_horizon_color = Color("b7d9dc")
 atmosphere.ground_bottom_color = Color("769a81")
 sky.sky_material = atmosphere
 env.sky = sky
 env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
 env.ambient_light_energy = 0.4
 env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 world.environment = env
 add_child(world)
