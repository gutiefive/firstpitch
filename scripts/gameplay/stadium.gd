extends Node3D
const G = preload("res://scripts/gameplay/geometry.gd")
const Props = preload("res://scripts/environment/park_props.gd")
const CREAM := Color("eee3c6")
const TEAL := Color("28585a")
var infield_surfaces: Array[MeshInstance3D] = []

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
 infield_surfaces.assign([diamond,home])
 var mound := G.cylinder(self,Vector3(0,0.18,-18.44),2.8,0.36,dirt)
 mound.material_override = diamond.material_override
 var mound_mesh := mound.mesh as CylinderMesh
 mound_mesh.top_radius = 2.2
 mound_mesh.radial_segments = 48
 var mound_body := StaticBody3D.new()
 var mound_shape := CollisionShape3D.new()
 mound_shape.shape = mound_mesh.create_convex_shape()
 mound_body.add_child(mound_shape)
 mound.add_child(mound_body)
 G.box(self,Vector3(0,0.38,-18.44),Vector3(0.61,0.05,0.15),CREAM)
 for pos in [Vector3(19.396,0,-19.396),Vector3(0,0,-38.792),Vector3(-19.396,0,-19.396)]:
  var base := G.box(self,pos+Vector3.UP*0.1,Vector3(0.5,0.16,0.5),CREAM)
  base.rotation.y = PI/4
 var markings := FieldMarkings.new()
 add_child(markings)
 for side in [-1,1]:
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
 build_foul_boundary()
 for side in [-1,1]:
  Props.grandstand(self,side)
 Props.scoreboard(self)
 for pos in [Vector3(-55,0,-35),Vector3(55,0,-35),Vector3(-35,0,15),Vector3(35,0,15)]:
  Props.light_tower(self,pos)

# Fence routes share the dugouts' sideline basis. Fair territory and task masks stay fixed.
func build_foul_boundary() -> void:
 var boundary := Props.group(self,"FoulTerritoryBoundary",Vector3.ZERO)
 fence_run(boundary,Vector3(-8,0,6),Vector3(8,0,6),6.0,"Backstop")
 for side in [-1,1]:
  var start := Vector3(side*8,0,6)
  var corner := Vector3(side*82,0,-73.5)
  var along := (corner-start).normalized()
  var outward := Vector3(side*absf(along.z),0,absf(along.x))
  var dugout := Props.dugout(self,side)
  # Roof and solid rear/side walls sit outside the field; front entries join the fence.
  var front := start+along*20
  fence_run(boundary,start,front-along*5.5,2.4,"HomeWing" if side < 0 else "VisitorWing")
  var after := front+along*5.5
  if side > 0:
   # Keep the existing pad, mower, marker, hose and tamper approaches usable.
   var gate_near := start+along*((6.0+14.5)/absf(along.z))
   var gate_far := start+along*((6.0+27.5)/absf(along.z))
   fence_run(boundary,after,gate_near,2.4,"WorkshopWing")
   fence_run(boundary,gate_far,corner,2.4,"FirstBaseFence")
   var gate := Props.group(boundary,"OpenEquipmentGate",(gate_near+gate_far)*0.5)
   var sign := G.label(gate,"GROUNDS CREW  /  FIELD ACCESS",Vector3(0,3.3,0),32)
   sign.rotation.y = dugout.rotation.y
   sign.pixel_size = 0.006
   sign.modulate = CREAM
   # Open gate leaves lie along the outside fence, clear of the driving lane.
   fence_run(boundary,gate_near+outward*0.3,gate_near+outward*0.3-along*3,2.0,"OpenGateLeaf")
   fence_run(boundary,gate_far+outward*0.3,gate_far+outward*0.3+along*3,2.0,"OpenGateLeaf")
  else:
   fence_run(boundary,after,corner,2.4,"ThirdBaseFence")
  fence_run(boundary,corner,Vector3(side*sqrt(0.5)*104,0,-sqrt(0.5)*104),2.4,"FoulPoleReturn")
  # A continuous narrow walkway outside the fence anchors dugouts to the park.
  var path := G.box(self,(start+corner)*0.5+outward*4+Vector3.UP*0.012,Vector3(3,0.024,start.distance_to(corner)),Color("b9aa8e"))
  path.rotation.y = atan2(along.x,along.z)

func fence_run(parent: Node3D,from: Vector3,to: Vector3,height: float,label: String) -> void:
 var length := from.distance_to(to)
 if length < 0.05:
  return
 var root := Props.group(parent,label,(from+to)*0.5)
 var direction := (to-from).normalized()
 root.rotation.y = atan2(-direction.z,direction.x)
 var mesh := MeshInstance3D.new()
 var quad := QuadMesh.new()
 quad.size = Vector2(length,height)
 mesh.mesh = quad
 mesh.position.y = height*0.5
 var material := ShaderMaterial.new()
 material.shader = preload("res://shaders/chain_link.gdshader")
 material.set_shader_parameter("fence_size",Vector2(length,height))
 mesh.material_override = material
 root.add_child(mesh)
 var body := StaticBody3D.new()
 var collider := CollisionShape3D.new()
 var bounds := BoxShape3D.new()
 bounds.size = Vector3(length,height,0.12)
 collider.shape = bounds
 collider.position.y = height*0.5
 body.add_child(collider)
 root.add_child(body)
 var sections := maxi(1,ceili(length/3))
 for i in range(sections+1):
  G.cylinder(root,Vector3(-length*0.5+length*i/sections,height*0.5,0),0.045,height+0.12,Color("526569"))
 for y in [0.15,height]:
  G.box(root,Vector3(0,y,0),Vector3(length,0.055,0.055),Color("71847c"))

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
